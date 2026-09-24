import React, {
  createContext,
  useContext,
  useState,
  type PropsWithChildren,
} from "react";
import type {
  GlowAIRecommendation,
  Photo,
  UserProfileInput,
  WeatherData,
} from "../types";
import { removePhoto } from "../features/camera/photos";
export const initialProfile: UserProfileInput = {
  skin_tone: "",
  undertone: "",
  skin_type: "",
  event: "",
  time_of_day: "day",
  outfit_color: "#D4A0C0",
  hijab: "no",
  style_preference: "both",
  owned_items: "",
};
function useLookState() {
  const [photo, setPhotoState] = useState<Photo>();
  const [profile, setProfile] = useState(initialProfile);
  const [result, setResult] = useState<GlowAIRecommendation>();
  const [weather, setWeather] = useState<WeatherData>();
  function setPhoto(next?: Photo) {
    setPhotoState((previous) => {
      if (previous?.uri !== next?.uri) removePhoto(previous);
      return next;
    });
  }
  function clear() {
    setPhoto();
    setResult(undefined);
    setWeather(undefined);
    setProfile(initialProfile);
  }
  return {
    photo,
    setPhoto,
    profile,
    setProfile,
    result,
    setResult,
    weather,
    setWeather,
    clear,
  };
}
const LookContext = createContext<ReturnType<typeof useLookState> | null>(null);
export function LookProvider({ children }: PropsWithChildren) {
  const value = useLookState();
  return <LookContext.Provider value={value}>{children}</LookContext.Provider>;
}
export function useLook() {
  const value = useContext(LookContext);
  if (!value) throw new Error("LookProvider missing");
  return value;
}
