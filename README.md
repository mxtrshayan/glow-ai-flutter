# Glow AI

Flutter beauty consultations and offline photo makeup previews for Android 7+
(API 24+) and iOS 15.5+. Phone portrait/landscape and tablet layouts are supported.

## Dashboard & settings

Home leads with a generated HD makeup animation and two direct actions: AI
recommendations (primary) and virtual makeup. The bottom bar has Home, AI looks,
a central **+ / Add photo**, Makeup, and Settings. The +
flow asks whether to try virtual makeup or get AI suggestions, then opens the
camera or photo library. Cancelling leaves the current session intact.

The eight-second GIF is 1080 × 1350 and approximately 3 MB. It has a pause/play
control, uses a matching still for reduced motion, and stops playing when Home is
inactive. This is labelled as an illustrative demo. Artwork prompts and assembly
instructions are in [the animation notes](docs/DASHBOARD_ANIMATION.md).

Light mode is the default. Settings saves the dark-mode preference across app
restarts and links to the privacy policy. **Clear my data** asks for confirmation,
clears the current portrait reference, consultation choices and recommendation,
and resets the saved theme to light. Original and downloaded photos are retained
in their existing locations. System navigation insets are respected in both themes.

## Local makeup

The studio uses a bundled MediaPipe FaceMesh-V2 model with 478 landmarks through
`mediapipe_face_mesh` 3.1.0, pinned for this repository's Flutter 3.32 / Dart 3.8
SDK. Native inference runs in a worker isolate. ML Kit remains a legacy-runtime
fallback. Python or a server is not needed for makeup: selecting a local image,
face detection, shade changes and compositing all work without an internet
connection. Photos are not uploaded to Gemini.

Lipstick follows smoothed inner/outer lip boundaries. Eyeshadow follows eyelid
creases; eyeliner and mascara follow upper lids. Blush and highlighter are blended
on separate cosmetic layers with protected eye, brow and mouth regions. All six
makeup categories have intensity controls. “Try this look” loads the recommended
lip, cheek and eye colours. Pinch to zoom and toggle “Show makeup” to compare.

Use one clear frontal or moderate three-quarter portrait. Severe profiles and
unusable/group images request another photo. Lighting, existing makeup, hair,
occlusions, glasses and camera/display colour affect results. The preview is a
simulation, not an exact prediction of physical cosmetics. Live video is not implemented. Current preferences and portraits last for the app session.

## Run

```sh
flutter pub get
flutter run
```

The consultation creates nine recommendation sections from supplied preferences.
Without Gemini configuration, or when all configured keys are unavailable, it
uses the local catalogue. It does not analyse skin tone from photos.

## Colour controls and saving a look

Every makeup category supports the full RGB palette: open “Choose any … colour”,
use the hue/saturation/brightness controls, or enter a six-digit colour code.
Choosing a colour enables that category; adjusting intensity returns to makeup
view. Controls show Off or their current percentage. Recommendations enable liner,
mascara and highlighter when those steps are present in the recommendation.

“Download look” renders a PNG from the source image and the selected makeup
settings, without the surrounding controls or zoom crop. Android opens its native
save dialog (Downloads is available); iOS opens Save to Files. Cancellation leaves
the preview unchanged, and temporary export files are cleaned up. No additional
storage/gallery permission is required for choosing a file destination.

Consultation choices use dropdowns, and outfit colour opens the same palette.
Primary actions share a 56 dp minimum height; paired photo buttons match heights.
Reading screens and the studio respect system safe areas for gesture and
three-button navigation, including side insets in landscape.

## Smaller Android download

For installing on a modern ARM64 Android phone, build an optimized APK:

```sh
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

Output: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
The universal debug APK includes multiple CPU architectures, a debugging engine,
and Dart debug data, so it is much larger. The release build compiles Dart ahead
of time, shrinks code/resources, and includes only the selected architecture.
Offline face models remain bundled. These local testing builds use the repository's
existing debug signing configuration; store distribution needs production signing.

## Recommendation experience

Results start with three makeup essentials: Lips, Eyes, and Base & blush. Each
card shows one short recommendation; tapping reveals additional details.
“Try this look” is the primary action. “See more categories” opens optional
outfit, accessories, hair, product, contact-lens and skin-preference ideas.
Those categories remain collapsed until selected.

## Gemini configuration and failover

Copy `.env.example` to the ignored `.env` file. Keep the existing `GEMINI_API_KEY`
and add up to six optional keys as `GEMINI_API_KEY_1` through `GEMINI_API_KEY_6`,
or set `GEMINI_API_KEYS` to a comma-separated list. Duplicate/empty keys are ignored.

```sh
flutter run --dart-define-from-file=.env
```

The default model is `gemini-3.5-flash-lite`. `GEMINI_MODEL` and `GEMINI_API_URL`
can override it. `.env` is not bundled as a Flutter asset; ordinary `flutter run`
uses local recommendations.

Quota (429), credential errors and temporary server failures try the next
available key without showing an error dialog. Quota cooldowns honor `Retry-After`
and Gemini `RetryInfo`; the healthy key is preferred for subsequent requests.
Each attempt is limited to 8 seconds, with a 20-second total request budget.
Connectivity failures and exhausted keys fall back locally.

[Google quotas apply per project, not per key](https://ai.google.dev/gemini-api/docs/rate-limits).
Several keys from the same project do not add quota. Live multi-key testing needs
the additional keys; automated tests simulate quota exhaustion without burning
provider quota. Development build definitions are extractable from binaries;
production credentials belong behind an authenticated backend.

## Verification

```sh
flutter analyze
flutter test
flutter build apk --debug
flutter test integration_test/app_test.dart -d <android-emulator-id>
flutter test integration_test/portrait_suite_test.dart -d <android-emulator-id>
```

Unit and widget tests generate temporary synthetic images and remove them after
testing; no real test portraits or comparison screenshots are bundled.

For native detection tests, supply your own local portrait on iOS:

```sh
flutter test integration_test/app_test.dart -d <simulator-id> \
  --dart-define=TEST_PORTRAIT_PATH="/absolute/path/to/portrait.png"
```

The public portrait suite downloads seven listed Unsplash portraits when no
`TEST_PORTRAIT_DIRECTORY` is supplied. For iOS, that definition can point at a host
directory containing `portrait-1.jpg` through `portrait-7.jpg`. Downloads require
internet; detection and rendering do not. Native comparison artifacts are written
to `/tmp/glow-portrait-review` on iOS and the app's temporary directory on Android.

Native test downloads and comparison outputs stay in temporary directories and
are not checked into Git. Physical camera, permission and OS-specific behaviour
still need device validation. Font licenses are in `assets/fonts`.
