import React, { useState } from "react";
import { Image, View, Modal, Pressable } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { Button, Card, Copy, Notice } from "./ui";
import { pickPhoto } from "../features/camera/photos";
import { useLook } from "../store/LookContext";
import { theme as t } from "../theme";
export function PhotoPicker({ local = false }: { local?: boolean }) {
  const { photo, setPhoto } = useLook();
  const [open, setOpen] = useState(false);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  async function pick(camera: boolean) {
    setOpen(false);
    setError("");
    setBusy(true);
    try {
      const next = await pickPhoto(camera);
      if (next) setPhoto(next);
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : "This photo could not be opened. Try another portrait.",
      );
    } finally {
      setBusy(false);
    }
  }
  return (
    <View style={{ gap: 14 }}>
      {photo ? (
        <Image
          source={{ uri: photo.uri }}
          accessibilityLabel="Your selected portrait"
          style={{ width: "100%", height: 280, borderRadius: 24 }}
          resizeMode="contain"
        />
      ) : (
        <Card
          style={{
            alignItems: "center",
            paddingVertical: 36,
            backgroundColor: t.colors.soft,
          }}
        >
          <Ionicons name="scan-outline" size={48} color={t.colors.primary} />
          <Copy title style={{ fontSize: 24 }}>
            A little more you.
          </Copy>
          <Copy style={{ textAlign: "center" }}>
            Choose a clear, front-facing portrait
            {local
              ? " to explore your shades."
              : ", or start with your preferences."}
          </Copy>
        </Card>
      )}
      <Button
        label={
          busy
            ? "Preparing your photo…"
            : photo
              ? "Replace photo"
              : "Add your portrait"
        }
        icon="camera-outline"
        disabled={busy}
        onPress={() => setOpen(true)}
      />
      {photo && (
        <Button
          secondary
          label="Remove photo"
          icon="close-outline"
          onPress={() => setPhoto()}
        />
      )}
      <Notice
        message={
          local
            ? "Your portrait stays on this device. Virtual makeup works without AI or an internet connection."
            : "When you tap Create my look, your photo and preferences are sent to GlowAI and Google Gemini for analysis. A photo is optional."
        }
      />
      {!!error && <Notice message={error} error />}
      <Modal
        transparent
        visible={open}
        animationType="slide"
        onRequestClose={() => setOpen(false)}
      >
        <View
          style={{
            flex: 1,
            justifyContent: "flex-end",
            backgroundColor: "#2D1B2670",
          }}
        >
          <Pressable
            accessibilityLabel="Close photo options"
            onPress={() => setOpen(false)}
            style={{ flex: 1 }}
          />
          <Card
            style={{
              borderBottomLeftRadius: 0,
              borderBottomRightRadius: 0,
              paddingBottom: 40,
            }}
          >
            <Copy title>Your portrait</Copy>
            <Copy>Natural light. One face. Beautifully you.</Copy>
            <Button
              label="Take photo"
              icon="camera-outline"
              onPress={() => void pick(true)}
            />
            <Button
              secondary
              label="Choose from gallery"
              icon="images-outline"
              onPress={() => void pick(false)}
            />
            <Button
              secondary
              label="Cancel"
              icon="close-outline"
              onPress={() => setOpen(false)}
            />
          </Card>
        </View>
      </Modal>
    </View>
  );
}
