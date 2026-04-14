# backend_app.py
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from PIL import Image
import requests
import io
import torch
from torchvision import transforms
from torchvision.transforms import functional as F
from transformers import CLIPProcessor, CLIPModel
import numpy as np
from math import radians, sin, cos, sqrt, atan2

# -----------------------------
# Labels, Departments, Urgency
# -----------------------------
labels = ["StreetLight Broken", "Water leak", "garbage dump", "pothole", "other"]
department_map = {
    'StreetLight Broken': 'Electricity/Streetlights Dept',
    'Water leak': 'Water Supply Dept',
    'garbage dump': 'Sanitation Dept',
    'pothole': 'Roads Dept',
    'Bridge Damage': 'Roads Dept',
    'Bridge Collapse': 'Roads Dept',
    'Landslide': 'Disaster Management Dept',
    'Flooding': 'Disaster Management Dept',
    'Possible epidemic': 'Health Dept',
    'Stray animals': 'Animal Control Dept',
    'sinkhole': 'Roads Dept',
    'wildlife sighting': 'Animal Control Dept',
    'animal attack': 'Animal Control Dept',
    'broken traffic signal': 'Traffic Management Dept',
    'missing road sign': 'Traffic Management Dept',
    'other': 'Unrelated/Other'
}
urgency_labels = ["Low", "Medium", "High", "Very High"]
priority_order = {"Very High": 4, "High": 3, "Medium": 2, "Low": 1, "N/A": 0}

# -----------------------------
# Device and Model
# -----------------------------
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32").to(device)
processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")

# -----------------------------
# Image transforms and TTA
# -----------------------------
transform = transforms.Compose([transforms.Resize((224, 224))])

def apply_tta(image):
    return [image, F.hflip(image), F.vflip(image), F.rotate(image, 15), F.rotate(image, -15)]

def is_blank_image(image, threshold=10):
    arr = np.array(image.convert("L"))
    return arr.std() < threshold

# -----------------------------
# Haversine distance
# -----------------------------
def haversine(lat1, lon1, lat2, lon2):
    R = 6371000
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = sin(dlat/2)**2 + cos(radians(lat1))*cos(radians(lat2))*sin(dlon/2)**2
    c = 2 * atan2(sqrt(a), sqrt(1-a))
    return R * c

# -----------------------------
# Grouping & Human verification
# -----------------------------
complaints = []
human_verification = []
group_counter = 1

def max_priority(p1, p2):
    return p1 if priority_order[p1] >= priority_order[p2] else p2

def add_complaint(lat, lon, category, dept, confidence, priority, radius=100):
    global group_counter
    lat, lon = round(lat,5), round(lon,5)
    if category == "other" or confidence < 0.5:
        human_verification.append((lat, lon, category, dept, confidence, group_counter, priority))
    if category == "other":
        return None
    for i, (clat, clon, ccat, cdept, count, gid, cprio) in enumerate(complaints):
        if ccat == category and haversine(lat, lon, clat, clon) <= radius:
            max_prio = urgency_labels[max(priority_order.get(priority,0), priority_order.get(cprio,0))-1] if priority in urgency_labels else cprio
            complaints[i] = (clat, clon, ccat, cdept, count+1, gid, max_prio)
            return gid
    gid = group_counter
    complaints.append((lat, lon, category, dept, 1, gid, priority))
    group_counter += 1
    return gid

# -----------------------------
# Prediction functions
# -----------------------------
def predict_image(image, confidence_threshold=0.5):
    image = transform(image)
    if is_blank_image(image):
        return "other", department_map["other"], 0.0, "⚠ Blank or uniform image. Marked as Other"
    probs_list = []
    for img in apply_tta(image):
        inputs = processor(text=labels, images=img, return_tensors="pt", padding=True)
        inputs = {k:v.to(device) for k,v in inputs.items()}
        with torch.no_grad():
            outputs = model(**inputs)
            logits = outputs.logits_per_image
            probs_list.append(torch.softmax(logits, dim=1).cpu())
    avg_probs = torch.stack(probs_list).mean(dim=0)
    confidence, pred_idx_tensor = torch.max(avg_probs, dim=1)
    pred_idx = int(pred_idx_tensor.item())
    confidence = float(confidence.item())
    category = labels[pred_idx]
    department = department_map[category]
    warning = ""
    if confidence < confidence_threshold:
        category = "other"
        department = department_map[category]
        warning = "⚠ Low confidence. Marked as Other"
    return category, department, confidence, warning

def detect_urgency(image, text_input=None):
    inputs = processor(text=[f"{u} urgency" for u in urgency_labels], images=image, return_tensors="pt", padding=True, truncation=True)
    inputs = {k:v.to(device) for k,v in inputs.items()}
    with torch.no_grad():
        outputs = model(**inputs)
        probs = outputs.logits_per_image.softmax(dim=1)
    img_conf, img_idx = torch.max(probs, dim=1)
    priority = urgency_labels[img_idx.item()]
    confidence = img_conf.item()
    return priority, confidence

# -----------------------------
# FastAPI setup
# -----------------------------
app = FastAPI(title="Civic Complaint Categorizer API")

# Pydantic model for JSON input
class ComplaintRequest(BaseModel):
    image_url: str
    description: str = ""
    lat: float = 0.0
    lon: float = 0.0

@app.post("/complaint")
async def categorize_complaint(req: ComplaintRequest):
    try:
        # Download image from URL
        response = requests.get(req.image_url)
        image = Image.open(io.BytesIO(response.content)).convert("RGB")
        
        # Predict category and department
        img_cat, img_dept, img_conf, warning = predict_image(image)
        
        # Determine priority
        priority, _ = detect_urgency(image)
        
        # Add to grouping
        gid = add_complaint(req.lat, req.lon, img_cat, img_dept, img_conf, priority)
        
        return JSONResponse({
            "group_id": gid,
            "category": img_cat,
            "department": img_dept,
            "priority": priority,
            "location": {"lat": req.lat, "lon": req.lon},
            "warning": warning
        })
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500)

@app.get("/complaints_summary")
def complaints_summary():
    return {"complaints": complaints, "human_verification": human_verification}
