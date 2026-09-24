"""GlowAI API, shared with the Android client."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.routes import analyze, weather, test, tryon

app = FastAPI(title="GlowAI API", version="2.1.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=False,
                   allow_methods=["GET", "POST"], allow_headers=["*"])
for router in (analyze.router, weather.router, tryon.router, test.router):
    app.include_router(router)

@app.get("/health")
async def health():
    return {"status": "ok", "service": "GlowAI"}
