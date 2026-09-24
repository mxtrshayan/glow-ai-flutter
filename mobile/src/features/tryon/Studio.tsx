import React, { useState } from "react";
import { View, Image, Switch, useWindowDimensions } from "react-native";
import { Canvas, Circle } from "@shopify/react-native-skia";
import { PhotoPicker } from "../../components/PhotoPicker";
import { Card, Copy, Glow, Notice, Screen } from "../../components/ui";
import { useLook } from "../../store/LookContext";
import type { Photo } from "../../types";
import { theme as t } from "../../theme";
import { useFace } from "./useFace";
export function Studio() {
  const { photo } = useLook();
  return (
    <Screen>
      <Copy title>The makeup studio</Copy>
      <Copy>Local face landmark verification</Copy>
      <PhotoPicker local />
      {photo && <Portrait key={photo.uri} photo={photo} />}
    </Screen>
  );
}
function Portrait({ photo }: { photo: Photo }) {
  const { width } = useWindowDimensions();
  const { face, busy, error } = useFace(photo.uri);
  const [debug, setDebug] = useState(true);
  const w = width - 88;
  const h = (w * photo.height) / photo.width;
  return (
    <>
      {busy && <Glow label="Detecting facial features…" />}
      {!!error && <Notice error message={error} />}{" "}
      {face?.status === "success" && (
        <Card>
          <View style={{ width: w, height: h }}>
            <Image
              source={{ uri: photo.uri }}
              style={{ position: "absolute", width: w, height: h }}
            />
            {debug && (
              <Canvas style={{ width: w, height: h }}>
                {face.landmarks.map((p, i) => (
                  <Circle
                    key={i}
                    cx={p.x * w}
                    cy={p.y * h}
                    r={1.3}
                    color="#00FFAA"
                  />
                ))}
              </Canvas>
            )}
          </View>
          <Copy>
            {face.landmarks.length} facial landmarks detected on device
          </Copy>
          <View
            style={{
              flexDirection: "row",
              justifyContent: "space-between",
              alignItems: "center",
            }}
          >
            <Copy>Landmark overlay</Copy>
            <Switch
              accessibilityLabel="Landmark overlay"
              value={debug}
              onValueChange={setDebug}
              trackColor={{ true: t.colors.primary }}
            />
          </View>
        </Card>
      )}
    </>
  );
}
