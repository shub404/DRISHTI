from fastapi import FastAPI, UploadFile, Form
from fastapi.responses import JSONResponse
from test import process_single_complaint, complaints, human_verification

app = FastAPI()

@app.post("/complaint")
async def complaint(
    file: UploadFile,
    lat: float = Form(...),
    lon: float = Form(...),
    text_input: str = Form(None),
    use_voice: bool = Form(False)
):
    # Save uploaded file temporarily
    img_path = f"temp_{file.filename}"
    with open(img_path, "wb") as f:
        f.write(await file.read())

    # Run the processing
    process_single_complaint(img_path, lat, lon, text_input=text_input, use_voice=use_voice)

    # Return results as JSON
    return JSONResponse({
        "complaints": complaints,               # grouped complaints
        "human_verification": human_verification  # low-confidence cases
    })

@app.get("/")
async def root():
    return {"message": "🚀 Backend is running!"}