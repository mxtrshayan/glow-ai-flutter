import io
from PIL import Image
from fastapi.testclient import TestClient
from api.index import app
from api.services.image_service import preprocess_image
import base64

client = TestClient(app)

def test_health_and_no_secret_disclosure():
    assert client.get('/health').json()['status'] == 'ok'
    assert set(client.get('/test-gemini').json()) == {'ok', 'configured'}

def test_invalid_weather_coordinates():
    assert client.get('/weather?lat=100&lon=0').status_code == 422

def test_corrupt_photo_is_friendly():
    response = client.post('/analyze', files={'image': ('photo.jpg', b'not an image', 'image/jpeg')})
    assert response.status_code == 400
    assert 'photo' in response.json()['detail']

def test_exif_normalization():
    image = Image.new('RGB', (80, 40), 'red')
    exif = Image.Exif(); exif[274] = 6
    buffer = io.BytesIO(); image.save(buffer, 'JPEG', exif=exif)
    normalized = Image.open(io.BytesIO(base64.b64decode(preprocess_image(buffer.getvalue()))))
    assert normalized.size == (40, 80)
    assert not normalized.getexif().get(274)

def test_model_error_is_honestly_labeled(monkeypatch):
    async def unavailable(*args):
        raise RuntimeError('private provider detail')
    monkeypatch.setattr('api.routes.analyze.call_gemini', unavailable)
    response = client.post('/analyze', data={'skin_tone':'medium','event':'eid','hijab':'yes'})
    data=response.json()
    assert data['status'] == 'fallback'
    assert 'private provider detail' not in response.text
    assert data['inputs_received']['hijab'] == 'yes'
    assert all(key in data for key in ['face','eyes','lips','outfit','hair_hijab','brands','accessories','lens'])
