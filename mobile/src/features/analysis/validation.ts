import { z } from "zod";
import { normalizeHex } from "../../utils/color";
import { occasions } from "../../constants/options";
export const profileSchema = z.object({
  skin_tone: z.string(),
  undertone: z.string(),
  skin_type: z.string(),
  event: z
    .string()
    .refine((v) => occasions.some(([id]) => id === v), "Choose an occasion."),
  time_of_day: z.enum(["morning", "day", "evening", "night"]),
  outfit_color: z
    .string()
    .refine(
      (v) => normalizeHex(v) !== null,
      "Enter a valid colour, such as #D4A0C0.",
    ),
  hijab: z.enum(["yes", "no"]),
  style_preference: z.enum(["traditional", "both", "western"]),
  owned_items: z.string().max(2000),
});
export function validateProfile(
  value: unknown,
  hasPhoto: boolean,
): string | null {
  const result = profileSchema.safeParse(value);
  if (!result.success) return result.error.issues[0].message;
  if (!hasPhoto && !result.data.skin_tone)
    return "Choose your skin tone, or add a photo for AI estimation.";
  return null;
}
