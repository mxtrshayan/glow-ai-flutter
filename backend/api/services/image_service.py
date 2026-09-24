"""Bounded, orientation-normalized in-memory image processing."""
import io
import base64
from PIL import Image, ImageOps, UnidentifiedImageError
from fastapi import HTTPException

MAX_UPLOAD_BYTES = 12 * 1024 * 1024
Image.MAX_IMAGE_PIXELS = 25_000_000

def preprocess_image(file_bytes: bytes) -> str:
    if len(file_bytes) > MAX_UPLOAD_BYTES:
        raise HTTPException(413, "Choose a photo smaller than 12 MB.")
    try:
        with Image.open(io.BytesIO(file_bytes)) as source:
            img = ImageOps.exif_transpose(source).convert("RGB")
            img.thumbnail((1200, 1200), Image.Resampling.LANCZOS)
            buffer = io.BytesIO()
            img.save(buffer, format="JPEG", quality=85)
            return base64.b64encode(buffer.getvalue()).decode("ascii")
    except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError) as exc:
        raise HTTPException(400, "This photo could not be opened. Choose a JPG or PNG portrait.") from exc
