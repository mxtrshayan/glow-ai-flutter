# Glow AI

Glow AI is a Flutter beauty consultation and virtual makeup studio for Android
and iOS. It provides:

- A guided consultation with local recommendation fallbacks.
- Optional Gemini-powered recommendations through `GEMINI_API_KEY`.
- Face-aware virtual makeup previews using on-device ML Kit detection.
- Selectable lipstick, blush, and eyeshadow shades with intensity controls.
- Local-only fallback recommendations when AI is unavailable.

## Configuration

Copy `.env.example` to `.env` and add a Gemini key if desired:

```dotenv
GEMINI_API_KEY=your_key_here
```

The app does not wait indefinitely for Gemini. Missing or unreachable AI
configuration immediately uses the local recommendation catalogue.

## Run

```bash
flutter pub get
flutter run
```

After cloning this repository, run the commands from the repository root.
The Dart package identifier is `glow_ai`.
