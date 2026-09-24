# api/services/tryon_service.py
# ── Service wrapper for decoding images, processing try-on, and base64 encoding ──
import base64
import io
from PIL import Image, ImageOps, UnidentifiedImageError
import cv2
import numpy as np
from api.virtual_tryon.makeup_engine import apply_virtual_makeup


def process_virtual_tryon(image_bytes: bytes, makeup_config: dict) -> dict:
    """
    Decodes uploaded image bytes, applies virtual makeup, and returns base64 image data.
    """
    if not image_bytes:
        raise ValueError("No image data provided.")

    try:
        with Image.open(io.BytesIO(image_bytes)) as source:
            if source.width * source.height > 25_000_000:
                raise ValueError("Choose a photo smaller than 25 megapixels.")
            normalized = ImageOps.exif_transpose(source).convert("RGB")
            normalized.thumbnail((1600, 1600), Image.Resampling.LANCZOS)
            image_bgr = cv2.cvtColor(np.asarray(normalized), cv2.COLOR_RGB2BGR)
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as exc:
        raise ValueError("This photo could not be opened. Choose a JPG or PNG portrait.") from exc

    h, w, _ = image_bgr.shape
    max_dim = 1600
    if max(h, w) > max_dim:
        scale = max_dim / float(max(h, w))
        image_bgr = cv2.resize(image_bgr, (int(w * scale), int(h * scale)), interpolation=cv2.INTER_AREA)

    # Apply makeup
    output_bgr, applied_features = apply_virtual_makeup(image_bgr, makeup_config)

    # Encode to JPEG in memory
    success, buffer = cv2.imencode(".jpg", output_bgr, [int(cv2.IMWRITE_JPEG_QUALITY), 93])
    if not success:
        raise ValueError("Failed to encode processed image.")

    b64_str = base64.b64encode(buffer).decode("utf-8")
    data_url = f"data:image/jpeg;base64,{b64_str}"

    return {
        "status": "success",
        "image_b64": data_url,
        "applied": applied_features,
    }
