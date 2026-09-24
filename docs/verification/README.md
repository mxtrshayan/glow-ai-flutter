# Verification evidence

Public test portrait: https://storage.googleapis.com/mediapipe-assets/portrait.jpg (Google MediaPipe test asset; used only in emulator tests, not bundled in the app).

Phase A must pass native Android detection and overlay inspection before adding colour rendering. All mobile rendering uses normalized source coordinates and one portrait aspect ratio; EXIF is normalized before detection. Transform unit tests cover letterboxed portrait and landscape viewports.

Backend test run: 9 passed, including original engine tests and mobile contract/privacy/orientation checks. MediaPipe 1.0.1 crashed inside its Metal service initialization on this Mac; pinned 0.10.32 passes. Android native API dependency is separately versioned.

Expo Doctor: 21/21 passed. TypeScript and ESLint pass for the consultation + landmark prototype. Six meaningful mobile tests cover response parsing, actual curated contract, input validation, colour handling, configuration and letterbox transforms. npm audit reports 12 moderate advisories through Expo's tooling/xcode/uuid chain, no high/critical; its suggested fix would downgrade Expo to SDK 46 and was not applied.
