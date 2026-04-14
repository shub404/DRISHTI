from fastapi import FastAPI, UploadFile, Form
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from PIL import Image
import torch
import io
import requests
from transformers import CLIPProcessor, CLIPModel
from torchvision.transforms import functional as F

app = FastAPI(title="DRISHTI AI Backend")

# ── CONFIGURATION ──────────────────────────────────────────────────────────
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32").to(device)
processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")

# All 13 civic categories — descriptive CLIP text labels
CLIP_LABELS = [
    "potholes damaged pavement and cracked asphalt road",
    "water leaking from pipes or water supply main burst",
    "broken street lights dark road and electrical pole hazards",
    "piles of garbage trash waste dump and overflowing bins",
    "fallen trees broken branches and overgrown park vegetation",
    "stray animals cows dogs and cattle on the road",
    "loud speakers and noisy construction machinery",
    "traffic congestion illegal parking and broken signals",
    "illegal building construction walls and encroachment",
    "fire hazard smoke gas leak and burning materials",
    "open sewage dead animals and mosquito breeding sites",
    "broken cctv camera and unsafe dark street areas",
    "waterlogged flooded roads and blocked drainage systems",
    "a normal clean area with no visible civic issues or problems",
]

CLIP_TO_CATEGORY = {
    "potholes damaged pavement and cracked asphalt road": "ROAD",
    "water leaking from pipes or water supply main burst": "WATER",
    "broken street lights dark road and electrical pole hazards": "ELECTRICITY",
    "piles of garbage trash waste dump and overflowing bins": "SANITATION",
    "fallen trees broken branches and overgrown park vegetation": "TREE",
    "stray animals cows dogs and cattle on the road": "STRAY ANIMALS",
    "loud speakers and noisy construction machinery": "NOISE",
    "traffic congestion illegal parking and broken signals": "TRAFFIC",
    "illegal building construction walls and encroachment": "BUILDING",
    "fire hazard smoke gas leak and burning materials": "FIRE HAZARD",
    "open sewage dead animals and mosquito breeding sites": "PUBLIC HEALTH",
    "broken cctv camera and unsafe dark street areas": "CRIME",
    "waterlogged flooded roads and blocked drainage systems": "FLOOD DRAINAGE",
    "a normal clean area with no visible civic issues or problems": "UNCATEGORISED",
}

DEPARTMENT_MAP = {
    "ROAD":          "Roads Dept",
    "WATER":         "Water Supply Dept",
    "ELECTRICITY":   "Electricity / Streetlights Dept",
    "SANITATION":    "Sanitation Dept",
    "TREE":          "Horticulture Dept",
    "STRAY ANIMALS": "Animal Control Dept",
    "NOISE":         "Pollution Control Board",
    "TRAFFIC":       "Traffic Police",
    "BUILDING":      "Town Planning Dept",
    "FIRE HAZARD":   "Fire Dept",
    "PUBLIC HEALTH": "Health Dept",
    "CRIME":         "Police Dept",
    "FLOOD DRAINAGE":"Drainage Dept",
    "UNCATEGORISED": "General Admin",
}

# ── PRIORITY AUTO-ASSIGNMENT ────────────────────────────────────────────────
def calculate_priority(category: str, text: str) -> str:
    """AI automatically assigns issue urgency based on category and description keywords."""
    t = text.lower()
    
    # 1. Check for immediate critical keywords
    critical_keywords = ['collapse', 'fire', 'explosion', 'gas', 'open manhole', 'accident', 'dead body', 'murder', 'blood', 'unsafe', 'trap', 'current', 'spark']
    if any(k in t for k in critical_keywords):
        return "Critical"
        
    # 2. Check by Category defaults
    if category in ['FIRE HAZARD', 'CRIME']: 
        return "Critical"
    if category in ['WATER', 'ELECTRICITY', 'FLOOD DRAINAGE']: 
        return "High"
    if category in ['ROAD', 'PUBLIC HEALTH', 'TRAFFIC', 'NOISE', 'BUILDING', 'SANITATION']: 
        return "Medium"
        
    # 3. Default to Low (e.g. TREE, STRAY ANIMALS, UNCATEGORISED)
    return "Low"

# ── IMAGE CLASSIFICATION ────────────────────────────────────────────────────
def apply_tta(image):
    return [image, F.hflip(image), F.rotate(image, 10), F.rotate(image, -10)]

def predict_image(image, confidence_threshold=0.30):
    """Use CLIP to classify image against all 13 civic categories."""
    image = image.resize((224, 224))
    probs_list = []
    for img in apply_tta(image):
        inputs = processor(text=CLIP_LABELS, images=img, return_tensors="pt", padding=True)
        inputs = {k: v.to(device) for k, v in inputs.items()}
        with torch.no_grad():
            outputs = model(**inputs)
            logits = outputs.logits_per_image
            probs_list.append(torch.softmax(logits, dim=1).cpu())

    avg_probs = torch.stack(probs_list).mean(dim=0)
    confidence, pred_idx_tensor = torch.max(avg_probs, dim=1)
    pred_idx = int(pred_idx_tensor.item())
    conf = float(confidence.item())

    label = CLIP_LABELS[pred_idx]
    cat = CLIP_TO_CATEGORY.get(label, "UNCATEGORISED") if conf >= confidence_threshold else "UNCATEGORISED"
    return cat, conf

# ── TEXT CLASSIFICATION ─────────────────────────────────────────────────────
def predict_text(text: str) -> str:
    """Keyword-based text classification covering all 13 categories + Hindi terms."""
    t = text.lower()
    if any(k in t for k in ['pothole', 'road', 'pavement', 'sadak', 'gaddha', 'asphalt', 'tarmac', 'crack']): return "ROAD"
    if any(k in t for k in ['water', 'leak', 'pipe', 'paani', 'nall', 'tanki', 'supply', 'burst']): return "WATER"
    if any(k in t for k in ['light', 'electric', 'bijli', 'pole', 'bulb', 'khamba', 'current', 'power', 'dark']): return "ELECTRICITY"
    if any(k in t for k in ['garbage', 'trash', 'waste', 'kachra', 'gandagi', 'dustbin', 'safai', 'dump', 'smell', 'overflowing']): return "SANITATION"
    if any(k in t for k in ['tree', 'park', 'ped', 'jhaad', 'garden', 'fallen', 'bench', 'bush', 'horticulture']): return "TREE"
    if any(k in t for k in ['dog', 'cow', 'animal', 'stray', 'aawara', 'kutte', 'janwar', 'cattle', 'bull']): return "STRAY ANIMALS"
    if any(k in t for k in ['noise', 'sound', 'loud', 'shor', 'awaaz', 'speaker', 'music night', 'disturb']): return "NOISE"
    if any(k in t for k in ['traffic', 'signal', 'parking', 'jam', 'chalaan', 'road sign', 'signal broken']): return "TRAFFIC"
    if any(k in t for k in ['building', 'construction', 'nirman', 'encroach', 'wall', 'collapse', 'illegal']): return "BUILDING"
    if any(k in t for k in ['fire', 'aag', 'gas', 'spark', 'smoke', 'explosion', 'burning', 'hazard']): return "FIRE HAZARD"
    if any(k in t for k in ['health', 'mosquito', 'dead animal', 'sewage', 'bimari', 'disease', 'breeding', 'dengue']): return "PUBLIC HEALTH"
    if any(k in t for k in ['crime', 'cctv', 'unsafe', 'theft', 'robbery', 'dark', 'security', 'burglary']): return "CRIME"
    if any(k in t for k in ['flood', 'drain', 'naali', 'barish', 'waterlog', 'pani bhara', 'blocked drain', 'overflow']): return "FLOOD DRAINAGE"
    return "UNCATEGORISED"

# ── MULTI-MODAL ANALYSIS ────────────────────────────────────────────────────
def analyze_issue(text_input: str, image_url: str = None):
    """Combine CLIP image + text keywords for best possible classification."""
    image_cat = "UNCATEGORISED"
    image_conf = 0.0
    text_cat = predict_text(text_input)
    print(f"[TEXT]  '{text_input}' → {text_cat}")

    if image_url:
        try:
            print(f"[IMAGE] Downloading: {image_url[:70]}...")
            resp = requests.get(image_url, timeout=10)
            if resp.status_code == 200:
                img = Image.open(io.BytesIO(resp.content)).convert("RGB")
                image_cat, image_conf = predict_image(img)
                print(f"[IMAGE] CLIP → {image_cat} ({image_conf:.2%})")
        except Exception as e:
            print(f"[IMAGE] ERROR: {e}")

    # IMAGE-FIRST LOGIC:
    # 1. If image is VERY confident (>75%), we use it regardless of text (prevent misleading captions)
    # 2. If image is moderately confident, and text matches it, we boost confidence.
    # 3. If image detection is low confidence, we trust text classification.
    
    final = "UNCATEGORISED"
    final_conf = 0.0
    source = "none"

    if image_cat != "UNCATEGORISED" and image_conf > 0.75:
        # High confidence image detection wins over text
        final, final_conf, source = image_cat, image_conf, "image_dominant"
    elif text_cat != "UNCATEGORISED":
        # Text detection is solid, check for image agreement
        if image_cat == text_cat:
            final, final_conf, source = text_cat, max(image_conf, 0.85), "multi_modal_match"
        else:
            final, final_conf, source = text_cat, 0.70, "text_primary"
    elif image_cat != "UNCATEGORISED" and image_conf >= 0.35:
        # No text keywords found, falling back to image classification
        final, final_conf, source = image_cat, image_conf, "image_fallback"
    
    priority = calculate_priority(final, text_input)

    print(f"[RESULT] source={source} → {final} ({final_conf:.2%}) | Priority: {priority}")
    return final, round(final_conf * 100, 1), priority

# ── PYDANTIC MODELS ─────────────────────────────────────────────────────────
class CategorizeRequest(BaseModel):
    text_input: str
    image_url: str = None
    lat: float = 0.0
    lon: float = 0.0

# ── ENDPOINTS ───────────────────────────────────────────────────────────────
@app.get("/health")
@app.get("/")
async def health():
    return {"status": "ok", "message": "DRISHTI AI Backend is live", "categories": list(DEPARTMENT_MAP.keys())}

@app.post("/complaint")
async def complaint(file: UploadFile, lat: float = Form(...), lon: float = Form(...), text_input: str = Form(None)):
    """Citizen app: direct image upload + optional text → category + confidence."""
    try:
        content = await file.read()
        image = Image.open(io.BytesIO(content)).convert("RGB")
        final_cat, conf, priority = analyze_issue(text_input or "", None)
        image_cat, image_conf = predict_image(image)

        # Override with image if confident
        if image_cat != "UNCATEGORISED" and image_conf >= 0.40:
            final_cat = image_cat
            conf = round(image_conf * 100, 1)
            priority = calculate_priority(final_cat, text_input or "")

        return {
            "category": final_cat,
            "department": DEPARTMENT_MAP.get(final_cat, "General Admin"),
            "confidence": conf,
            "priority": priority,
            "status": "success"
        }
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500)

@app.post("/categorize")
async def categorize(req: CategorizeRequest):
    """Admin AUTO-SORT: image URL + text → category + confidence score + priority."""
    try:
        print(f"[/categorize] text='{req.text_input}' | image={'YES' if req.image_url else 'NO'}")
        final_cat, conf, priority = analyze_issue(req.text_input, req.image_url)
        print(f"[/categorize] → {final_cat} ({conf}%) | {priority}")
        return {"category": final_cat, "confidence": conf, "priority": priority, "status": "success"}
    except Exception as e:
        print(f"[/categorize] EXCEPTION: {e}")
        return JSONResponse({"error": str(e)}, status_code=500)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
