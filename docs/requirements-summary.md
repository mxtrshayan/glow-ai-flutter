# GlowAI Android requirements

## Sources and precedence
The two user-provided master and premium UI specifications are authoritative, followed by any project report, then https://github.com/mxtrshayan/glow-ai. Workspace was empty. No project report was present in the workspace or repository; no report requirements have been invented. Reference source remains unchanged in `reference-web/`.

## Product and parity
React Native, strict TypeScript, current installed Expo SDK, Android development build (`com.glowai.app`). Preserve FastAPI `/analyze`, `/weather`, `/tryon`, Gemini prompts, all recommendation fields, and Python MediaPipe/OpenCV reference algorithms. Secrets belong only in backend environment. No login required.

Seven consultation steps: optional gallery/camera photo; ten skin tones, four undertones and five skin types (AI estimates with photo); thirteen occasions; four times, traditional/both/western, hijab yes/no; all 24 outfit colour presets and custom hex; owned items; optional permission-aware weather. Multipart API fields must match existing routes. Results include skin, face, eyes, lips, outfit, accessories, brands, lenses, hair/hijab, weather and overall advice. Label curated fallback honestly. Map four recommended hex colours to studio.

## Design
Preserve website rose #E8A0B4, deeper rose #C9748F, ivory #FDF6F9, plum #2D1B26 and gold #C9A96E. Use shared theme, editorial serif titles, readable sans typography, gradients, generous spacing, rounded cards, icons, animated splash/entrances/progress, pressed feedback, accessible labels and targets. Native stack navigation, Home, guided consultation, results, studio, current look and privacy. Loading, empty, error and retry states are real flows.

## Local makeup phases and verification gates
A: Normalize EXIF, detect one face with MediaPipe Tasks Vision Kotlin Expo module, return dimensions and normalized geometry, verify debug overlay alignment before rendering features.
B: Lipstick outer mask minus inner mouth, feathering, intensity, satin/matte/gloss, preserve texture.
C: Face-relative bilateral diffuse blush.
D: Bilateral eyelid shadow excluding eyeballs.
E: Bilateral upper lash liner with geometry-relative classic/winged styles.
Skia GPU preview, detection once per image. Original/makeup/split comparison aligned to same image. Export useful resolution to gallery or share, permission-aware and temporary-file cleanup. No hidden network fallback or identity recognition.

## Validation and acceptance
Test parsing, form validation, hex normalization, makeup config, landmark transforms and recommendation mapping. Run backend tests/startup, TypeScript, ESLint, Expo doctor, Android build and emulator launch. Visually inspect each screen and phase before marking verified. Test multiple sizes/orientations and error cases. Clearly document external-key and device limitations; never substitute mock production AI or fake rendering. Keep status current. README must include versions, setup, emulator 10.0.2.2 and physical LAN host, builds/APK paths, troubleshooting and privacy.
