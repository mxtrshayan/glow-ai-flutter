import {
  recommendationSchema,
  type UserProfileInput,
  type WeatherData,
} from "../types";
import { localRecommendation } from "./localRecommendation";
export function parseRecommendation(raw: unknown) {
  const result = recommendationSchema.safeParse(raw);
  if (!result.success)
    throw new Error(
      "Your look arrived incomplete. Please try your consultation again.",
    );
  return result.data;
}
export async function analyze(
  profile: UserProfileInput,
  _photo?: { uri: string; width: number; height: number },
  weather?: WeatherData,
) {
  return parseRecommendation(localRecommendation(profile, weather));
}
