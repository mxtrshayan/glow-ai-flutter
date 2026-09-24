import React, { type PropsWithChildren, useEffect } from "react";
import {
  Text,
  View,
  Pressable,
  ScrollView,
  StyleSheet,
  ActivityIndicator,
  type TextStyle,
  type StyleProp,
  type ViewStyle,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import Animated, {
  FadeInDown,
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withRepeat,
  withSequence,
  useReducedMotion,
} from "react-native-reanimated";
import { SafeAreaView } from "react-native-safe-area-context";
import { theme as t } from "../theme";
export function Copy({
  children,
  style,
  title = false,
}: PropsWithChildren<{ style?: StyleProp<TextStyle>; title?: boolean }>) {
  return (
    <Text style={[title ? styles.title : styles.copy, style]}>{children}</Text>
  );
}
export function Eyebrow({ children }: PropsWithChildren) {
  return <Copy style={styles.eyebrow}>{children}</Copy>;
}
export function Screen({
  children,
  scroll = true,
}: PropsWithChildren<{ scroll?: boolean }>) {
  return (
    <SafeAreaView style={styles.screen} edges={["top", "bottom"]}>
      {scroll ? (
        <ScrollView
          keyboardShouldPersistTaps="handled"
          contentContainerStyle={styles.content}
        >
          {children}
        </ScrollView>
      ) : (
        children
      )}
    </SafeAreaView>
  );
}
export function Card({
  children,
  style,
}: PropsWithChildren<{ style?: StyleProp<ViewStyle> }>) {
  return <View style={[styles.card, style]}>{children}</View>;
}
export function Entrance({ children }: PropsWithChildren) {
  const reduced = useReducedMotion();
  return (
    <Animated.View
      entering={reduced ? undefined : FadeInDown.duration(t.motion.entrance)}
    >
      {children}
    </Animated.View>
  );
}
export function Button({
  label,
  onPress,
  secondary,
  icon = "arrow-forward",
  disabled = false,
}: {
  label: string;
  onPress: () => void;
  secondary?: boolean;
  icon?: keyof typeof Ionicons.glyphMap;
  disabled?: boolean;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ disabled }}
      disabled={disabled}
      onPress={() => {
        void Haptics.selectionAsync().catch(() => {});
        onPress();
      }}
      style={({ pressed }) => [
        {
          opacity: disabled ? 0.45 : 1,
          transform: [{ scale: pressed ? 0.98 : 1 }],
        },
      ]}
    >
      <LinearGradient
        colors={
          secondary ? [t.colors.surface, t.colors.surface] : t.gradients.button
        }
        style={[styles.button, secondary && styles.secondary]}
      >
        <Text
          style={[styles.buttonText, secondary && { color: t.colors.primary }]}
        >
          {label}
        </Text>
        <Ionicons
          name={icon}
          color={secondary ? t.colors.primary : "white"}
          size={20}
        />
      </LinearGradient>
    </Pressable>
  );
}
export function Choices({
  options,
  value,
  onChange,
}: {
  options: (string | string[])[];
  value: string;
  onChange: (value: string) => void;
}) {
  return (
    <View style={styles.wrap}>
      {options.map((option) => {
        const [key, label] =
          typeof option === "string" ? [option, option] : option;
        return (
          <Pressable
            key={key}
            accessibilityRole="radio"
            accessibilityState={{ selected: value === key }}
            onPress={() => onChange(key)}
            style={[styles.chip, value === key && styles.selected]}
          >
            <Copy
              style={
                value === key
                  ? { color: "white", fontFamily: t.fonts.medium }
                  : undefined
              }
            >
              {label}
            </Copy>
          </Pressable>
        );
      })}
    </View>
  );
}
export function Notice({
  message,
  error = false,
}: {
  message: string;
  error?: boolean;
}) {
  return (
    <View
      accessibilityLiveRegion="polite"
      style={[styles.notice, error && { backgroundColor: "#FBE8EC" }]}
    >
      <Ionicons
        name={error ? "alert-circle-outline" : "shield-checkmark-outline"}
        size={20}
        color={error ? t.colors.error : t.colors.primary}
      />
      <Copy style={{ flex: 1, fontSize: 12, lineHeight: 20 }}>{message}</Copy>
    </View>
  );
}
export function Glow({ label }: { label: string }) {
  const scale = useSharedValue(1);
  const reduced = useReducedMotion();
  useEffect(() => {
    if (!reduced)
      scale.value = withRepeat(
        withSequence(
          withTiming(1.08, { duration: 1300 }),
          withTiming(1, { duration: 1300 }),
        ),
        -1,
      );
  }, [reduced, scale]);
  const style = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));
  return (
    <View style={{ alignItems: "center", gap: 24, paddingVertical: 40 }}>
      <Animated.View style={[styles.orb, style]}>
        <Ionicons name="sparkles-outline" size={48} color={t.colors.primary} />
      </Animated.View>
      <Copy title style={{ fontSize: 26, textAlign: "center" }}>
        {label}
      </Copy>
      <ActivityIndicator color={t.colors.primary} />
    </View>
  );
}
export const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: t.colors.bg },
  content: { padding: 22, paddingBottom: 36, gap: 20 },
  title: {
    fontFamily: t.fonts.title,
    fontSize: 32,
    lineHeight: 41,
    color: t.colors.ink,
  },
  copy: {
    fontFamily: t.fonts.body,
    fontSize: 14,
    lineHeight: 23,
    color: t.colors.muted,
  },
  eyebrow: {
    fontFamily: t.fonts.medium,
    fontSize: 10,
    letterSpacing: 2.4,
    color: t.colors.primary,
    textTransform: "uppercase",
  },
  card: {
    backgroundColor: t.colors.surface,
    borderRadius: t.radius.card,
    padding: 22,
    gap: 14,
    borderWidth: 1,
    borderColor: t.colors.border,
    ...t.shadow,
  },
  button: {
    minHeight: 56,
    borderRadius: 18,
    paddingHorizontal: 22,
    paddingVertical: 14,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 12,
  },
  buttonText: {
    fontFamily: t.fonts.medium,
    fontSize: 14,
    color: "white",
    flexShrink: 1,
  },
  secondary: { borderWidth: 1, borderColor: t.colors.border },
  wrap: { flexDirection: "row", flexWrap: "wrap", gap: 10 },
  chip: {
    minHeight: 48,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 16,
    backgroundColor: "white",
    borderWidth: 1,
    borderColor: t.colors.border,
  },
  selected: {
    backgroundColor: t.colors.primary,
    borderColor: t.colors.primary,
  },
  notice: {
    padding: 16,
    borderRadius: 16,
    backgroundColor: t.colors.soft,
    flexDirection: "row",
    gap: 10,
    alignItems: "flex-start",
  },
  orb: {
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: "#F2D0DC",
    borderWidth: 12,
    borderColor: "#F9EEF2",
    alignItems: "center",
    justifyContent: "center",
  },
  input: {
    fontFamily: t.fonts.body,
    fontSize: 15,
    color: t.colors.ink,
    backgroundColor: "white",
    borderColor: t.colors.border,
    borderWidth: 1,
    borderRadius: 16,
    padding: 16,
    minHeight: 54,
  },
});
