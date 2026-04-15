import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Connection state
// ─────────────────────────────────────────────────────────────────────────────

enum RealtimeConnectionStatus { connecting, connected, reconnecting, failed }

/// Global notifier — listen to this anywhere in the widget tree to react to
/// Supabase Realtime connection state changes.
final realtimeStatus = ValueNotifier<RealtimeConnectionStatus>(
  RealtimeConnectionStatus.connecting,
);

// ─────────────────────────────────────────────────────────────────────────────
// Wake-up helper
// ─────────────────────────────────────────────────────────────────────────────

/// Sends a lightweight query to ensure the Supabase database is fully awake
/// before a Realtime connection is attempted.
///
/// On free-tier projects the DB can be paused (cold start). Calling this first
/// prevents the [UnableToConnectToProject] error that occurs when
/// [supabase.channel()] is called before the DB is ready.
Future<void> wakeUpSupabase(
  SupabaseClient supabase, {
  String tableName = 'issues',
}) async {
  try {
    await supabase.from(tableName).select().limit(1);
    debugPrint('✅ Supabase is awake');
  } catch (e) {
    debugPrint('⚠️ Wake-up query failed (will still attempt connection): $e');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full cold-start initialisation (recommended entry point)
// ─────────────────────────────────────────────────────────────────────────────

/// Cold-start safe initialisation flow:
///   1. Wake the DB with a lightweight query.
///   2. Wait [warmupDelay] so Realtime has time to finish booting.
///   3. Connect with exponential-backoff retry.
///   4. Updates [realtimeStatus] so the UI can show loading / connected state.
///
/// Use this instead of calling [connectRealtimeWithRetry] directly when the
/// project may be starting from a paused / cold state.
Future<RealtimeChannel> initRealtime(
  SupabaseClient supabase, {
  String channelName = 'app',
  String tableName = 'issues',
  Duration warmupDelay = const Duration(seconds: 2),
  int retries = 5,
}) async {
  realtimeStatus.value = RealtimeConnectionStatus.connecting;
  await wakeUpSupabase(supabase, tableName: tableName);
  await Future.delayed(warmupDelay);
  return connectRealtimeWithRetry(
    supabase,
    channelName: channelName,
    retries: retries,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Retry-on-startup connection
// ─────────────────────────────────────────────────────────────────────────────

/// Connects to a Supabase Realtime channel with exponential-backoff retry.
/// Updates [realtimeStatus] on every state transition.
///
/// Returns the active [RealtimeChannel] on success.
/// Throws an [Exception] after all retries are exhausted.
Future<RealtimeChannel> connectRealtimeWithRetry(
  SupabaseClient supabase, {
  String channelName = 'app',
  int retries = 5,
}) async {
  realtimeStatus.value = RealtimeConnectionStatus.connecting;
  int attempt = 0;

  while (attempt < retries) {
    final channel = supabase.channel(channelName);

    try {
      final completer = Completer<String>();

      channel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          if (!completer.isCompleted) completer.complete('SUBSCRIBED');
        } else if (status == RealtimeSubscribeStatus.channelError) {
          if (!completer.isCompleted) completer.completeError('CHANNEL_ERROR');
        } else if (status == RealtimeSubscribeStatus.timedOut) {
          if (!completer.isCompleted) completer.completeError('TIMED_OUT');
        }
      });

      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Realtime subscribe timed out'),
      );

      realtimeStatus.value = RealtimeConnectionStatus.connected;
      debugPrint('✅ Connected to realtime channel: $channelName');
      return channel;
    } catch (err) {
      attempt++;
      await supabase.removeChannel(channel);

      debugPrint('Realtime connect error: $err — Retry $attempt/$retries...');
      realtimeStatus.value = RealtimeConnectionStatus.reconnecting;

      if (attempt >= retries) break;

      // Exponential backoff: 2 s, 4 s, 6 s, …
      await Future.delayed(Duration(seconds: 2 * attempt));
    }
  }

  realtimeStatus.value = RealtimeConnectionStatus.failed;
  throw Exception(
    '❌ Failed to connect to Supabase Realtime after $retries attempts',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Persistent auto-reconnect subscription
// ─────────────────────────────────────────────────────────────────────────────

/// Subscribes to a Supabase Realtime channel and automatically reconnects
/// whenever a [RealtimeSubscribeStatus.channelError] or
/// [RealtimeSubscribeStatus.timedOut] event is received.
/// Updates [realtimeStatus] on every state transition.
///
/// Returns the initial [RealtimeChannel]. The channel self-heals; you do not
/// need to call subscribe() yourself again after a disconnect.
RealtimeChannel subscribeWithAutoReconnect(
  SupabaseClient supabase, {
  String channelName = 'app',
  Duration reconnectDelay = const Duration(seconds: 3),
  void Function(String status)? onStatusChange,
}) {
  RealtimeChannel? channel;

  void attach() {
    channel = supabase.channel(channelName);

    channel!.subscribe((status, [error]) {
      debugPrint('Realtime status: $status');
      onStatusChange?.call(status.name);

      if (status == RealtimeSubscribeStatus.subscribed) {
        realtimeStatus.value = RealtimeConnectionStatus.connected;
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        realtimeStatus.value = RealtimeConnectionStatus.reconnecting;
        debugPrint('Reconnecting in ${reconnectDelay.inSeconds}s...');

        Future.delayed(reconnectDelay, () async {
          if (channel != null) {
            await supabase.removeChannel(channel!);
          }
          attach();
        });
      }
    });
  }

  attach();
  return channel!;
}

// ─────────────────────────────────────────────────────────────────────────────
// UI widget — drop this anywhere to show a live connection status banner
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps [child] and shows a slim status banner at the top whenever Supabase
/// Realtime is not fully connected.
///
/// Usage:
/// ```dart
/// ConnectionStatusBanner(
///   child: YourPageBody(),
/// )
/// ```
class ConnectionStatusBanner extends StatelessWidget {
  final Widget child;
  const ConnectionStatusBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RealtimeConnectionStatus>(
      valueListenable: realtimeStatus,
      builder: (context, status, _) {
        final banner = _bannerFor(status);
        return Column(
          children: [
            if (banner != null) banner,
            Expanded(child: child),
          ],
        );
      },
    );
  }

  Widget? _bannerFor(RealtimeConnectionStatus status) {
    switch (status) {
      case RealtimeConnectionStatus.connecting:
        return _Banner(
          color: Colors.orange.shade700,
          icon: Icons.sync,
          message: 'Connecting to server…',
          showSpinner: true,
        );
      case RealtimeConnectionStatus.reconnecting:
        return _Banner(
          color: Colors.orange.shade700,
          icon: Icons.sync_problem,
          message: 'Reconnecting…',
          showSpinner: true,
        );
      case RealtimeConnectionStatus.failed:
        return _Banner(
          color: Colors.red.shade700,
          icon: Icons.cloud_off,
          message: 'Could not connect. Data may be outdated.',
        );
      case RealtimeConnectionStatus.connected:
        return null; // no banner when healthy
    }
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;
  final bool showSpinner;

  const _Banner({
    required this.color,
    required this.icon,
    required this.message,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            if (showSpinner)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
