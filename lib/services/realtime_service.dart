import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum RealtimeConnectionStatus { connecting, connected, reconnecting, failed }

final realtimeStatus = ValueNotifier<RealtimeConnectionStatus>(
  RealtimeConnectionStatus.connecting,
);

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

      await Future.delayed(Duration(seconds: 2 * attempt));
    }
  }

  realtimeStatus.value = RealtimeConnectionStatus.failed;
  throw Exception(
    '❌ Failed to connect to Supabase Realtime after $retries attempts',
  );
}

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
        return null;
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
