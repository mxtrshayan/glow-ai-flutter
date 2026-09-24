import React, { useState } from "react";
import { View, Pressable, TextInput, Modal } from "react-native";
import Slider from "@react-native-community/slider";
import { Button, Card, Copy, Eyebrow, styles } from "./ui";
import { normalizeHex } from "../utils/color";
import { theme as t } from "../theme";
const shades = [
  "#C8385A",
  "#9E2449",
  "#7A284B",
  "#D38B8D",
  "#B66B60",
  "#E07A7A",
  "#C0724A",
  "#8B5A2B",
  "#B8916F",
  "#8D628D",
  "#5F4149",
  "#1A1A1A",
];
export function ShadePicker({
  value,
  onChange,
}: {
  value: string;
  onChange: (color: string) => void;
}) {
  const [open, setOpen] = useState(false);
  return (
    <View style={{ gap: 14 }}>
      <View style={styles.wrap}>
        {shades.map((color) => (
          <Pressable
            key={color}
            accessibilityLabel={`Shade ${color}`}
            accessibilityRole="radio"
            accessibilityState={{ selected: value.toUpperCase() === color }}
            onPress={() => onChange(color)}
            style={{
              width: 46,
              height: 46,
              padding: 4,
              borderRadius: 23,
              borderWidth: 2,
              borderColor:
                value.toUpperCase() === color
                  ? t.colors.primary
                  : "transparent",
            }}
          >
            <View
              style={{ flex: 1, backgroundColor: color, borderRadius: 20 }}
            />
          </Pressable>
        ))}
      </View>
      <Button
        secondary
        label={`Custom colour · ${value}`}
        icon="color-palette-outline"
        onPress={() => setOpen(true)}
      />
      <Modal
        transparent
        visible={open}
        animationType="slide"
        onRequestClose={() => setOpen(false)}
      >
        <View
          style={{
            flex: 1,
            backgroundColor: "#2D1B2670",
            justifyContent: "flex-end",
          }}
        >
          <Pressable
            accessibilityLabel="Close colour picker"
            style={{ flex: 1 }}
            onPress={() => setOpen(false)}
          />
          <CustomColor
            key={open ? "open" : "closed"}
            value={value}
            onDone={(color) => {
              onChange(color);
              setOpen(false);
            }}
          />
        </View>
      </Modal>
    </View>
  );
}
export function CustomColor({
  value,
  onDone,
}: {
  value: string;
  onDone: (color: string) => void;
}) {
  const [hex, setHex] = useState(value);
  const valid = normalizeHex(hex);
  const color = valid ?? value;
  const rgb = [1, 3, 5].map((i) => parseInt(color.slice(i, i + 2), 16));
  function channel(index: number, v: number) {
    const next = [...rgb];
    next[index] = Math.round(v);
    setHex(
      "#" +
        next
          .map((n) => n.toString(16).padStart(2, "0"))
          .join("")
          .toUpperCase(),
    );
  }
  return (
    <Card
      style={{
        paddingBottom: 36,
        borderBottomLeftRadius: 0,
        borderBottomRightRadius: 0,
      }}
    >
      <Eyebrow>FIND YOUR SHADE</Eyebrow>
      <Copy title style={{ fontSize: 26 }}>
        Make it personal.
      </Copy>
      <View style={{ height: 56, borderRadius: 16, backgroundColor: color }} />
      <TextInput
        accessibilityLabel="Custom colour HEX"
        autoCapitalize="characters"
        value={hex}
        onChangeText={setHex}
        maxLength={7}
        style={styles.input}
      />
      {["Red", "Green", "Blue"].map((name, i) => (
        <View key={name}>
          <Copy style={{ fontSize: 12 }}>
            {name} · {rgb[i]}
          </Copy>
          <Slider
            accessibilityLabel={`${name} colour channel`}
            minimumValue={0}
            maximumValue={255}
            step={1}
            value={rgb[i]}
            onValueChange={(v) => channel(i, v)}
            minimumTrackTintColor={t.colors.primary}
            thumbTintColor={t.colors.primary}
          />
        </View>
      ))}
      <Button
        label="Use this shade"
        disabled={!valid}
        icon="checkmark"
        onPress={() => {
          if (valid) onDone(valid);
        }}
      />
    </Card>
  );
}
