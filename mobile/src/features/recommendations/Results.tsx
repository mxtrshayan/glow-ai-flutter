import React, { useState } from "react";
import { View, Pressable } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import type { RootStackParamList, GlowAIRecommendation } from "../../types";
import {
  Button,
  Card,
  Copy,
  Entrance,
  Eyebrow,
  Notice,
  Screen,
} from "../../components/ui";
import { useLook } from "../../store/LookContext";
import { theme as t } from "../../theme";
import { normalizeHex } from "../../utils/color";
type SectionKey =
  | "skin_analysis"
  | "face"
  | "eyes"
  | "lips"
  | "outfit"
  | "accessories"
  | "brands"
  | "lens"
  | "hair_hijab";
const sections: [SectionKey, string, keyof typeof Ionicons.glyphMap][] = [
  ["skin_analysis", "Your skin story", "sunny-outline"],
  ["face", "Face & base", "happy-outline"],
  ["eyes", "Eyes", "eye-outline"],
  ["lips", "Lips", "heart-outline"],
  ["outfit", "Your outfit", "shirt-outline"],
  ["accessories", "The finishing touches", "diamond-outline"],
  ["brands", "Your beauty shelf", "bag-handle-outline"],
  ["lens", "Contact lenses", "eye-outline"],
  ["hair_hijab", "Hair & hijab", "flower-outline"],
];
function Section({
  title,
  icon,
  data,
}: {
  title: string;
  icon: keyof typeof Ionicons.glyphMap;
  data: Record<string, string>;
}) {
  const [open, setOpen] = useState(true);
  return (
    <Card>
      <Pressable
        accessibilityRole="button"
        accessibilityState={{ expanded: open }}
        onPress={() => setOpen(!open)}
        style={{
          flexDirection: "row",
          alignItems: "center",
          gap: 12,
          minHeight: 44,
        }}
      >
        <Ionicons name={icon} size={24} color={t.colors.primary} />
        <Copy title style={{ fontSize: 24, flex: 1 }}>
          {title}
        </Copy>
        <Ionicons
          name={open ? "chevron-up" : "chevron-down"}
          color={t.colors.muted}
          size={18}
        />
      </Pressable>
      {open &&
        Object.entries(data)
          .filter(
            ([key, value]) =>
              !key.endsWith("hex") && value && value.toLowerCase() !== "n/a",
          )
          .map(([key, value]) => (
            <View key={key} style={{ gap: 4 }}>
              <Copy
                style={{
                  fontSize: 10,
                  fontFamily: t.fonts.bold,
                  textTransform: "uppercase",
                  letterSpacing: 1.1,
                  color: t.colors.primary,
                }}
              >
                {key
                  .replaceAll("_", " ")
                  .replace("brand suggestion", "Suggested brand")}
              </Copy>
              <Copy>{value}</Copy>
            </View>
          ))}
      {open && (
        <View style={{ flexDirection: "row", gap: 8 }}>
          {Object.entries(data)
            .filter(
              ([key, value]) => key.endsWith("hex") && normalizeHex(value),
            )
            .map(([key, value]) => (
              <View
                key={key}
                accessibilityLabel={`${key}: ${value}`}
                style={{
                  width: 34,
                  height: 34,
                  borderRadius: 17,
                  backgroundColor: value,
                  borderWidth: 1,
                  borderColor: t.colors.border,
                }}
              />
            ))}
        </View>
      )}
    </Card>
  );
}
export function Results({
  navigation,
}: NativeStackScreenProps<RootStackParamList, "Results">) {
  const { result } = useLook();
  if (!result)
    return (
      <Screen>
        <Copy title>Your next look awaits.</Copy>
        <Button
          label="Create my look"
          onPress={() => navigation.navigate("Consultation")}
        />
      </Screen>
    );
  return (
    <Screen>
      <Entrance>
        <View style={{ gap: 20 }}>
          <Eyebrow>YOUR PERSONAL BEAUTY EDIT</Eyebrow>
          <Copy title>A look that feels{"\n"}like you.</Copy>
          <Copy>{result.overall_tip}</Copy>
          {result.status === "fallback" && (
            <Notice message="AI is unavailable. These are curated suggestions based on your preferences; your photo has not been analysed." />
          )}
          <Button
            label="Try this look"
            icon="color-wand-outline"
            onPress={() => navigation.navigate("Studio")}
          />
          {sections.map(([key, title, icon]) => (
            <Section
              key={key}
              title={
                key === "hair_hijab"
                  ? result.inputs_received?.hijab === "yes"
                    ? "Your hijab style"
                    : "Your hairstyle"
                  : title
              }
              icon={icon}
              data={
                result[key as keyof GlowAIRecommendation] as Record<
                  string,
                  string
                >
              }
            />
          ))}
          {result.weather_tip && <Notice message={result.weather_tip} />}
          <Button
            secondary
            label="Create another look"
            onPress={() => navigation.navigate("Consultation")}
          />
        </View>
      </Entrance>
    </Screen>
  );
}
