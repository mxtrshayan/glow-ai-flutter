# Dashboard makeup animation

The dashboard uses an illustrative generated adult portrait, not a user photo or a recorded app result. The original artwork and makeup-only keyframe were created with the built-in image_gen tool using the imagegen skill. FFmpeg assembles those keyframes into a continuous loop, blending only within a soft face region so the background remains stable.

## Shipped assets

- `assets/dashboard/makeup-preview-hd.gif`: 1080 × 1350, 80 frames, 10 fps, 8 seconds, infinite loop, approximately 3 MB.
- `assets/dashboard/makeup-poster.jpg`: matching still frame for reduced motion, paused preview and inactive Home tab.
- `tools/build_dashboard_gif.sh`: reproducible assembly command accepting the two generated keyframe paths.

The dashboard labels this “Virtual makeup demo”. It prioritises AI recommendations and offers virtual makeup immediately below the visual. The two features have dedicated bottom destinations, AI looks and Makeup. Plus continues to offer photo import for either feature. Pausing switches to the matching still; system reduced-motion preferences do the same. Home stops decoding animated frames while another tab is active.

## Generation mode and exact prompt set

Mode: built-in image_gen, not API/CLI fallback.

### Before keyframe

Use case: photorealistic-natural.
Asset type: high-resolution portrait keyframe for a looping virtual-makeup demonstration in the Glow AI mobile dashboard.
Primary request: a beautiful adult South Asian woman in her late twenties with warm medium skin, expressive brown eyes and dark brown hair neatly tucked behind both ears, looking straight into the camera, a soft confident closed-mouth smile. Natural bare face with NO lipstick, blush, eyeshadow, eyeliner or mascara. Clean healthy real skin with visible fine pores, natural lip pigmentation, believable subtle asymmetry.
Scene/backdrop: seamless warm blush-beige studio background; elegant rose-toned beauty editorial, ivory top with modest neckline.
Composition/framing: portrait 4:5, at least 1080x1350 pixels, head and upper shoulders fully visible, centered, symmetrical straight-on face, hair contained within frame, face takes about two thirds of frame height. Camera locked, eye-level, 85mm beauty photography.
Lighting/mood: soft flattering diffused studio light with natural skin texture; premium calm beauty app aesthetic.
Constraints: ONE woman, adult, photorealistic, no text, no typography, no interface, no watermark, no brushes or hands or props, no facial ornaments, no artificial plastic skin, no collage. This will be the before frame; preserve clear eyes, lips, and cheek geometry for a subsequent makeup-only edit.

### Makeup keyframe edit

Use case: identity-preserve. Asset type: after keyframe for the exact same locked-camera virtual-makeup animation.
Edit target: the referenced bare-face portrait.
Primary request: apply elegant visible makeup ONLY to this woman's face: rich rose-pink satin lipstick following her existing lips exactly, soft dusty-rose blush on cheek apples blending toward temples, champagne highlighter on high points, refined warm taupe eyeshadow on upper lids, thin dark brown winged eyeliner, naturally defined mascara. A harmonious wearable rose look, premium beauty editorial.
Absolute invariants: preserve the EXACT woman's facial identity, head position, eye gaze, expression, facial proportions, lip shape, cheek geometry, hair strands, ivory top, background, camera crop, resolution and lighting. Do not move anything. No beauty reshaping or skin airbrushing. Her mouth stays closed and smile unchanged. Preserve real skin pores and all visible features. Cosmetic pigments and subtle cosmetic sheen are the only edits. No text, watermarks, hands, brushes or interface. Output the same 4:5 portrait composition at high resolution.
