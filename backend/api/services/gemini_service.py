"""Gemini recommendations using the supported SDK; same prompts and API contract."""
import asyncio
import base64
from google import genai
from google.genai import types
from api.config import GEMINI_API_KEY, GEMINI_MODEL

async def call_gemini(prompt: str, image_b64: str | None) -> str:
    if not GEMINI_API_KEY:
        raise ValueError("Gemini is not configured")
    parts = [types.Part.from_text(text=prompt)]
    if image_b64:
        parts.append(types.Part.from_bytes(data=base64.b64decode(image_b64), mime_type="image/jpeg"))
    async with genai.Client(api_key=GEMINI_API_KEY, http_options=types.HttpOptions(timeout=60000)).aio as client:
        response = await asyncio.wait_for(client.models.generate_content(
            model=GEMINI_MODEL, contents=types.Content(role="user", parts=parts),
            config=types.GenerateContentConfig(response_mime_type="application/json")), timeout=70)
        if not response.text:
            raise ValueError("No recommendation returned")
        return response.text
