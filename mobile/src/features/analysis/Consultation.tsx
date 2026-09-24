import React, { useEffect, useRef, useState } from "react";
import {
  View,
  TextInput,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
} from "react-native";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from "react-native-reanimated";
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import type { RootStackParamList, UserProfileInput } from "../../types";
import {
  Button,
  Card,
  Choices,
  Copy,
  Entrance,
  Eyebrow,
  Glow,
  Notice,
  styles,
} from "../../components/ui";
import { ShadePicker } from "../../components/ShadePicker";
import { PhotoPicker } from "../../components/PhotoPicker";
import { useLook } from "../../store/LookContext";
import {
  skinTones,
  skinColors,
  occasions,
  outfitColors,
} from "../../constants/options";
import { theme as t } from "../../theme";
import { validateProfile } from "./validation";
import { analyze } from "../../services/api";
import { normalizeHex } from "../../utils/color";
const titles = [
  "Let’s start with you.",
  "Your skin, understood.",
  "What’s the occasion?",
  "Make it your style.",
  "A colour story.",
  "Shop your own collection.",
  "A little atmosphere.",
];
const subtitles = [
  "A portrait helps us personalise your consultation.",
  "Tell us what you know. We’ll take it from here.",
  "From everyday rituals to unforgettable celebrations.",
  "The details that make this look yours.",
  "We’ll find the shades that belong together.",
  "A beautiful look can begin with what you already own.",
  "Make your look work with the weather.",
];
const loading = [
  "Understanding your features…",
  "Finding your best shades…",
  "Matching your look to the occasion…",
  "Creating your GlowAI look…",
];
export function Consultation({
  navigation,
}: NativeStackScreenProps<RootStackParamList, "Consultation">) {
  const look = useLook();
  const [step, setStep] = useState(0);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [weatherBusy, setWeatherBusy] = useState(false);
  const [weatherMessage, setWeatherMessage] = useState("");
  const [message, setMessage] = useState(0);
  const scroll = useRef<ScrollView>(null);
  const weatherRequest = useRef(0);
  const progress = useSharedValue(1 / 7);
  useEffect(() => {
    progress.value = withTiming((step + 1) / 7);
    scroll.current?.scrollTo({ y: 0, animated: false });
  }, [step, progress]);
  const progressStyle = useAnimatedStyle(() => ({
    width: `${progress.value * 100}%`,
  }));
  useEffect(() => {
    if (!busy) return;
    const timer = setInterval(
      () => setMessage((v) => (v + 1) % loading.length),
      2800,
    );
    return () => clearInterval(timer);
  }, [busy]);
  function update<K extends keyof UserProfileInput>(
    key: K,
    value: UserProfileInput[K],
  ) {
    look.setProfile({ ...look.profile, [key]: value });
    setError("");
  }
  async function weather() {
    weatherRequest.current++;
    setWeatherBusy(true);
    setWeatherMessage("");
    await new Promise((resolve) => setTimeout(resolve, 250));
    setWeatherMessage("Weather is unavailable offline. Your look can continue without it.");
    setWeatherBusy(false);
  }
  async function next() {
    setError("");
    if (step === 1 && !look.photo && !look.profile.skin_tone) {
      setError("Choose a skin tone, or go back and add a photo.");
      return;
    }
    if (step === 2 && !look.profile.event) {
      setError("Choose an occasion to continue.");
      return;
    }
    if (step === 4 && !normalizeHex(look.profile.outfit_color)) {
      setError("Enter a valid HEX colour, such as #D4A0C0.");
      return;
    }
    if (step < 6) {
      setStep(step + 1);
      return;
    }
    const invalid = validateProfile(look.profile, !!look.photo);
    if (invalid) {
      setError(invalid);
      return;
    }
    setBusy(true);
    try {
      look.setResult(
        await analyze(
          {
            ...look.profile,
            outfit_color: normalizeHex(look.profile.outfit_color)!,
          },
          look.photo,
          look.weather,
        ),
      );
      navigation.replace("Results");
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : "Your look could not be created. Please try again.",
      );
    } finally {
      setBusy(false);
    }
  }
  if (busy)
    return (
      <View
        style={{
          flex: 1,
          justifyContent: "center",
          padding: 28,
          backgroundColor: t.colors.bg,
        }}
      >
        <Eyebrow>YOUR PERSONAL BEAUTY CONSULTATION</Eyebrow>
        <Glow label={loading[message]} />
        <Copy style={{ textAlign: "center" }}>
          A considered look, created around you. This may take a moment.
        </Copy>
      </View>
    );
  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: t.colors.bg }}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <ScrollView
        ref={scroll}
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={styles.content}
      >
        <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
          <Eyebrow>YOUR BEAUTY CONSULTATION</Eyebrow>
          <Copy>{String(step + 1).padStart(2, "0")} / 07</Copy>
        </View>
        <View
          style={{
            height: 4,
            backgroundColor: t.colors.border,
            borderRadius: 4,
          }}
        >
          <Animated.View
            style={[
              { height: 4, backgroundColor: t.colors.primary, borderRadius: 4 },
              progressStyle,
            ]}
          />
        </View>
        <Entrance key={step}>
          <View style={{ gap: 20 }}>
            <Copy title>{titles[step]}</Copy>
            <Copy>{subtitles[step]}</Copy>
            {step === 0 && <PhotoPicker />}
            {step === 1 && (
              <>
                <Notice
                  message={
                    look.photo
                      ? "Your portrait stays on this device. These choices are optional."
                      : "Choose your skin tone for a consultation without a photo."
                  }
                />
                <View style={styles.wrap}>
                  {skinTones.map((tone, i) => (
                    <Pressable
                      key={tone}
                      accessibilityRole="radio"
                      accessibilityLabel={tone}
                      accessibilityState={{
                        selected: look.profile.skin_tone === tone.toLowerCase(),
                      }}
                      onPress={() => update("skin_tone", tone.toLowerCase())}
                      style={{
                        width: "30%",
                        alignItems: "center",
                        paddingVertical: 10,
                        gap: 8,
                        borderRadius: 16,
                        borderWidth:
                          look.profile.skin_tone === tone.toLowerCase() ? 2 : 1,
                        borderColor:
                          look.profile.skin_tone === tone.toLowerCase()
                            ? t.colors.primary
                            : t.colors.border,
                        backgroundColor: "white",
                      }}
                    >
                      <View
                        style={{
                          width: 44,
                          height: 44,
                          borderRadius: 22,
                          backgroundColor: skinColors[i],
                        }}
                      />
                      <Copy style={{ fontSize: 11, textAlign: "center" }}>
                        {tone}
                      </Copy>
                    </Pressable>
                  ))}
                </View>
                <Eyebrow>UNDERTONE</Eyebrow>
                <Choices
                  options={["Warm", "Cool", "Neutral", "Olive"]}
                  value={look.profile.undertone}
                  onChange={(v) => update("undertone", v)}
                />
                <Eyebrow>SKIN TYPE</Eyebrow>
                <Choices
                  options={[
                    "Oily",
                    "Dry",
                    "Combination",
                    "Sensitive",
                    "Normal",
                  ]}
                  value={look.profile.skin_type}
                  onChange={(v) => update("skin_type", v)}
                />
              </>
            )}
            {step === 2 && (
              <Choices
                options={occasions}
                value={look.profile.event}
                onChange={(v) => update("event", v)}
              />
            )}
            {step === 3 && (
              <>
                <Eyebrow>TIME OF DAY</Eyebrow>
                <Choices
                  options={[
                    ["morning", "Morning"],
                    ["day", "Daytime"],
                    ["evening", "Evening"],
                    ["night", "Night"],
                  ]}
                  value={look.profile.time_of_day}
                  onChange={(v) => update("time_of_day", v)}
                />
                <Eyebrow>STYLE PREFERENCE</Eyebrow>
                <Choices
                  options={[
                    ["traditional", "Traditional Pakistani"],
                    ["both", "A little of both"],
                    ["western", "Western"],
                  ]}
                  value={look.profile.style_preference}
                  onChange={(v) =>
                    update(
                      "style_preference",
                      v as UserProfileInput["style_preference"],
                    )
                  }
                />
                <Eyebrow>DO YOU WEAR HIJAB?</Eyebrow>
                <Choices
                  options={[
                    ["yes", "Yes · hijab styling"],
                    ["no", "No · hair styling"],
                  ]}
                  value={look.profile.hijab}
                  onChange={(v) => update("hijab", v as "yes" | "no")}
                />
              </>
            )}
            {step === 4 && (
              <>
                <View style={styles.wrap}>
                  {outfitColors.map(([name, color]) => (
                    <Pressable
                      key={name}
                      accessibilityRole="radio"
                      accessibilityLabel={name}
                      accessibilityState={{
                        selected: look.profile.outfit_color === color,
                      }}
                      onPress={() => update("outfit_color", color)}
                      style={{
                        width: "22%",
                        alignItems: "center",
                        gap: 6,
                        paddingVertical: 8,
                        borderRadius: 12,
                        backgroundColor:
                          look.profile.outfit_color === color
                            ? t.colors.border
                            : "transparent",
                      }}
                    >
                      <View
                        style={{
                          backgroundColor: color,
                          width: 42,
                          height: 42,
                          borderRadius: 21,
                          borderWidth: 1,
                          borderColor: t.colors.border,
                        }}
                      />
                      <Copy style={{ fontSize: 10, textAlign: "center" }}>
                        {name}
                      </Copy>
                    </Pressable>
                  ))}
                </View>
                <ShadePicker
                  value={normalizeHex(look.profile.outfit_color) ?? "#D4A0C0"}
                  onChange={(v) => update("outfit_color", v)}
                />
                <Eyebrow>CUSTOM HEX COLOUR</Eyebrow>
                <TextInput
                  accessibilityLabel="Custom outfit HEX colour"
                  autoCapitalize="characters"
                  maxLength={7}
                  value={look.profile.outfit_color}
                  onChangeText={(v) => update("outfit_color", v)}
                  style={styles.input}
                />
                <View
                  style={{
                    height: 48,
                    borderRadius: 14,
                    backgroundColor:
                      normalizeHex(look.profile.outfit_color) ?? t.colors.soft,
                  }}
                />
              </>
            )}
            {step === 5 && (
              <>
                <TextInput
                  accessibilityLabel="Items you already own"
                  placeholder="My favourite rose lipstick, gold jhumkas, an emerald kurta…"
                  placeholderTextColor={t.colors.muted}
                  multiline
                  maxLength={2000}
                  value={look.profile.owned_items}
                  onChangeText={(v) => update("owned_items", v)}
                  style={[
                    styles.input,
                    { height: 180, textAlignVertical: "top" },
                  ]}
                />
                <Copy style={{ fontSize: 12 }}>
                  Optional · We’ll prioritise the pieces you love.
                </Copy>
              </>
            )}
            {step === 6 && (
              <>
                <Card>
                  <Copy title style={{ fontSize: 24 }}>
                    Ready for your day.
                  </Copy>
                  <Copy>
                    Humidity, sunshine or cooler evenings — let your makeup
                    adapt.
                  </Copy>
                  <Button
                    label={
                      weatherBusy
                        ? "Finding your weather…"
                        : "Weather unavailable offline"
                    }
                    disabled={weatherBusy}
                    icon="partly-sunny-outline"
                    onPress={() => void weather()}
                  />
                  <Button
                    secondary
                    label="Continue without weather"
                    icon="close-outline"
                    onPress={() => {
                      weatherRequest.current++;
                      setWeatherBusy(false);
                      look.setWeather(undefined);
                      setWeatherMessage("Weather is off.");
                    }}
                  />
                  {look.weather && (
                    <Copy>
                      {look.weather.city} · {look.weather.temp_c}°C ·{" "}
                      {look.weather.condition}
                    </Copy>
                  )}
                  {!!weatherMessage && <Notice message={weatherMessage} />}
                </Card>
                <Notice
                  message={
                    look.photo
                      ? "Your portrait and preferences stay on this device. Local studio editing never uploads your portrait."
                      : "Your preferences stay on this device. No photo will be uploaded."
                  }
                />
              </>
            )}
          </View>
        </Entrance>
        {!!error && <Notice error message={error} />}
        <Button
          label={
            step === 6
              ? "Create my look"
              : step === 0 && !look.photo
                ? "Continue without photo"
                : "Continue"
          }
          onPress={() => void next()}
        />
        {step > 0 && (
          <Button
            secondary
            label="Back"
            icon="arrow-back"
            onPress={() => {
              setError("");
              setStep(step - 1);
            }}
          />
        )}
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
