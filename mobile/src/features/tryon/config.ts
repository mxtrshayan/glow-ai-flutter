import { z } from "zod";
import type { GlowAIRecommendation } from "../../types";
import { safeHex } from "../../utils/color";
const feature = z.object({
  enabled: z.boolean(),
  color: z.string().regex(/^#[0-9A-Fa-f]{6}$/),
  intensity: z.number().min(0).max(1),
});
export const makeupSchema = z.object({
  lipstick: feature.extend({ finish: z.enum(["satin", "matte", "gloss"]) }),
  blush: feature,
  eyeshadow: feature,
  eyeliner: feature.extend({ style: z.enum(["classic", "winged"]) }),
});
export type MakeupConfig = z.infer<typeof makeupSchema>;
export type MakeupFeature = keyof MakeupConfig;
export function recommendedMakeup(result?: GlowAIRecommendation): MakeupConfig {
  return {
    lipstick: {
      enabled: true,
      color: safeHex(result?.lips.hex, "#C8385A"),
      intensity: 0.7,
      finish: "satin",
    },
    blush: {
      enabled: true,
      color: safeHex(result?.face.blush_hex, "#E07A7A"),
      intensity: 0.35,
    },
    eyeshadow: {
      enabled: true,
      color: safeHex(result?.eyes.eyeshadow_hex, "#8B5A2B"),
      intensity: 0.45,
    },
    eyeliner: {
      enabled: true,
      color: safeHex(result?.eyes.eyeliner_hex, "#1A1A1A"),
      intensity: 0.85,
      style: "classic",
    },
  };
}
