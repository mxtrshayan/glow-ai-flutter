import { z } from "zod";
export type Photo = { uri: string; width: number; height: number };
const section = z
  .record(z.string(), z.string())
  .refine(
    (v) => Object.values(v).some((s) => s.trim()),
    "Empty recommendation",
  );
export const recommendationSchema = z.object({
  status: z.enum(["success", "fallback"]),
  skin_analysis: section,
  face: section,
  eyes: section,
  lips: section,
  outfit: section,
  accessories: section,
  brands: section,
  lens: section,
  hair_hijab: section,
  weather_tip: z.string().optional(),
  overall_tip: z.string(),
  inputs_received: z.record(z.string(), z.string()).optional(),
});
export type GlowAIRecommendation = z.infer<typeof recommendationSchema>;
export type SkinAnalysis = GlowAIRecommendation["skin_analysis"];
export type FaceRecommendation = GlowAIRecommendation["face"];
export type EyeRecommendation = GlowAIRecommendation["eyes"];
export type LipRecommendation = GlowAIRecommendation["lips"];
export type OutfitRecommendation = GlowAIRecommendation["outfit"];
export type AccessoryRecommendation = GlowAIRecommendation["accessories"];
export type BrandRecommendation = GlowAIRecommendation["brands"];
export type LensRecommendation = GlowAIRecommendation["lens"];
export type HairHijabRecommendation = GlowAIRecommendation["hair_hijab"];
export const weatherSchema = z.object({
  condition: z.string(),
  temp_c: z.number(),
  humidity: z.number(),
  category: z.string(),
  city: z.string(),
  country: z.string().optional(),
});
export type WeatherData = z.infer<typeof weatherSchema>;
export type UserProfileInput = {
  skin_tone: string;
  undertone: string;
  skin_type: string;
  event: string;
  time_of_day: string;
  outfit_color: string;
  hijab: "yes" | "no";
  style_preference: "traditional" | "both" | "western";
  owned_items: string;
};
export type RootStackParamList = {
  Home: undefined;
  Consultation: undefined;
  Results: undefined;
  Studio: undefined;
  Privacy: undefined;
};
