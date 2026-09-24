"""Configuration health; never disclose secrets or spend tokens on a health check."""
from fastapi import APIRouter
from api.config import GEMINI_API_KEY
router = APIRouter()
@router.get("/test-gemini")
async def test_gemini():
    return {"ok": bool(GEMINI_API_KEY), "configured": bool(GEMINI_API_KEY)}
