import React from "react";
import { View, StyleSheet } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import type { RootStackParamList } from "../types";
import { Button, Card, Copy, Entrance, Eyebrow, Screen } from "./ui";
import { theme as t } from "../theme";
import { useLook } from "../store/LookContext";
export function Home({
  navigation,
}: NativeStackScreenProps<RootStackParamList, "Home">) {
  const { result, weather } = useLook();
  return (
    <Screen>
      <Entrance>
        <View style={{ gap: 24 }}>
          <View
            style={{
              flexDirection: "row",
              justifyContent: "space-between",
              alignItems: "center",
            }}
          >
            <Copy title style={{ fontSize: 29 }}>
              Glow
              <TextAI />
            </Copy>
            <View style={s.badge}>
              <Ionicons name="sparkles" size={13} color={t.colors.primary} />
              <Copy style={{ fontSize: 10 }}>MADE FOR YOU</Copy>
            </View>
          </View>
          <LinearGradient colors={t.gradients.hero} style={s.hero}>
            <View style={s.halo} />
            <Eyebrow>YOUR EVERYDAY BEAUTY RITUAL</Eyebrow>
            <Copy title style={{ fontSize: 43, lineHeight: 53, marginTop: 16 }}>
              Your beauty.{"\n"}
              <Copy
                title
                style={{
                  fontFamily: t.fonts.italic,
                  fontSize: 43,
                  lineHeight: 53,
                  color: t.colors.primary,
                }}
              >
                Your kind of glow.
              </Copy>
            </Copy>
            <Copy style={{ marginTop: 16, maxWidth: 265 }}>
              A personal makeup artist and style advisor, inspired by everything
              that makes you, you.
            </Copy>
            <View style={s.palette}>
              {["#8D2947", "#D68B99", "#D6A777", "#705043", "#3D2633"].map(
                (color, i) => (
                  <View
                    key={color}
                    style={[
                      s.swatch,
                      {
                        backgroundColor: color,
                        transform: [{ rotate: `${(i - 2) * 8}deg` }],
                      },
                    ]}
                  />
                ),
              )}
            </View>
            <Button
              label="Create my look"
              onPress={() => navigation.navigate("Consultation")}
            />
            <Copy style={{ fontSize: 10, textAlign: "center", marginTop: 12 }}>
              PERSONALISED SHADES · THOUGHTFUL STYLE
            </Copy>
          </LinearGradient>
          <View>
            <Eyebrow>THE GLOWAI STUDIO</Eyebrow>
            <Copy title style={{ fontSize: 27, marginTop: 6 }}>
              Try a little possibility.
            </Copy>
          </View>
          <Card
            style={{
              backgroundColor: t.colors.plum,
              borderColor: t.colors.plum,
            }}
          >
            <View
              style={{ flexDirection: "row", gap: 16, alignItems: "center" }}
            >
              <View style={s.studioIcon}>
                <Ionicons
                  name="color-palette-outline"
                  size={30}
                  color={t.colors.rose}
                />
              </View>
              <View style={{ flex: 1 }}>
                <Copy title style={{ fontSize: 23, color: "white" }}>
                  Virtual makeup
                </Copy>
                <Copy style={{ fontSize: 12, color: "#EAD4DE" }}>
                  Your portrait. Endless shades.
                </Copy>
              </View>
            </View>
            <Copy style={{ color: "#EAD4DE", fontSize: 13 }}>
              Explore lipstick, soft blush and expressive eyes — right on your
              photo.
            </Copy>
            <Button
              secondary
              label="Enter the studio"
              icon="color-wand-outline"
              onPress={() => navigation.navigate("Studio")}
            />
          </Card>
          {result && (
            <Button
              secondary
              label="Revisit my current look"
              icon="heart-outline"
              onPress={() => navigation.navigate("Results")}
            />
          )}
          {weather && (
            <Copy>
              {weather.city} · {weather.temp_c}°C · {weather.condition}
            </Copy>
          )}
          <View style={{ flexDirection: "row", gap: 12, padding: 4 }}>
            <Ionicons
              name="shield-checkmark-outline"
              size={21}
              color={t.colors.primary}
            />
            <Copy style={{ flex: 1, fontSize: 12 }}>
              You’re in control. AI consultations use your shared photo. Virtual
              makeup stays on your device.
            </Copy>
          </View>
          <Button
            secondary
            label="Privacy & about GlowAI"
            icon="information-circle-outline"
            onPress={() => navigation.navigate("Privacy")}
          />
        </View>
      </Entrance>
    </Screen>
  );
}
function TextAI() {
  return (
    <Copy title style={{ fontSize: 29, color: t.colors.primary }}>
      AI
    </Copy>
  );
}
const s = StyleSheet.create({
  badge: {
    flexDirection: "row",
    gap: 6,
    alignItems: "center",
    backgroundColor: t.colors.soft,
    borderRadius: 100,
    padding: 10,
  },
  hero: {
    padding: 25,
    borderRadius: 30,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: t.colors.border,
  },
  halo: {
    position: "absolute",
    width: 240,
    height: 240,
    borderRadius: 120,
    borderWidth: 1,
    borderColor: "#C9A96E55",
    top: -75,
    right: -110,
  },
  palette: {
    flexDirection: "row",
    justifyContent: "center",
    paddingVertical: 32,
    gap: 9,
  },
  swatch: {
    width: 42,
    height: 66,
    borderRadius: 24,
    borderWidth: 3,
    borderColor: "#FFFFFFAA",
  },
  studioIcon: {
    width: 58,
    height: 58,
    borderRadius: 20,
    backgroundColor: "#FFFFFF12",
    alignItems: "center",
    justifyContent: "center",
  },
});
