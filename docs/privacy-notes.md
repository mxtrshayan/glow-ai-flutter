# Privacy architecture

- Studio portraits are normalized in the app cache, analyzed for geometry by bundled MediaPipe Tasks Vision on Android, and rendered locally. No identity recognition and no implicit server fallback. The bundled model requires no runtime download.
- AI submission is a separate explicit action. The consultation notice explains that the chosen image and preferences are sent to FastAPI and Google Gemini. Photo-free consultation is supported. Provider data handling terms apply; do not promise that Google retains nothing.
- Backend photo processing is in memory, with upload/pixel limits and EXIF normalization. No raw image, base64, prompt or secret logging. Health endpoint returns configuration booleans only.
- Weather is opt-in: request foreground location only, call backend then WeatherAPI. Denial never blocks consultation. No location history retained.
- No account, analytics, identity database or persistent portrait store. Session state is in memory. App-created portrait/export cache files are deleted on replacement/removal or at next launch. Gallery exports remain under user control.
- Request camera only on capture and media permission only on export. Android system photo picker limits access to selected photos. No audio recording permission.
- Configure HTTPS for deployed APIs; emulator HTTP is development-only. Keep all private keys in backend/.env. Only the public base URL belongs in mobile environment.
