# api/routes/weather.py
# ── Weather route ─────────────────────────────────────────────
from fastapi import APIRouter, Query
from api.services.weather_service import get_weather

router = APIRouter()


@router.get("/weather")
async def weather_endpoint(
    lat: float = Query(..., ge=-90, le=90, description="Latitude"),
    lon: float = Query(..., ge=-180, le=180, description="Longitude"),
):
    """Return current weather data for given coordinates."""
    return await get_weather(lat, lon)
