import React, { useState } from "react";
import { Button, Card, Copy, Notice, Screen } from "./ui";
import { useLook } from "../store/LookContext";
export function Privacy() {
  const { clear } = useLook();
  const [cleared, setCleared] = useState(false);
  return (
    <Screen>
      <Copy title>Beauty, on your terms.</Copy>
      <Card>
        <Copy title style={{ fontSize: 24 }}>
          Your photos
        </Copy>
        <Copy>
          Virtual makeup uses face geometry on this Android device. It does not
          identify you, and it does not send your studio portrait to a server.
        </Copy>
        <Copy>
          When you create an AI look, the photo you choose and your preferences
          are sent to the GlowAI backend and Google Gemini. You can create a
          look without a photo. GlowAI processes uploads in memory and does not
          store them on its server. Google’s service terms and data handling
          policies apply to AI requests.
        </Copy>
      </Card>
      <Card>
        <Copy title style={{ fontSize: 24 }}>
          Your choices
        </Copy>
        <Copy>
          Location is requested only when you choose weather. Coordinates are
          sent through the backend to WeatherAPI. Camera and gallery saving
          permissions are requested when needed. Android’s photo picker lets you
          choose specific images.
        </Copy>
        <Copy>
          Your current portrait and consultation are held for this app session.
          Temporary portraits are cleared when replaced, removed or at the next
          launch. Exported photos remain in your gallery until you delete them.
        </Copy>
        <Button
          secondary
          label="Clear my current session"
          icon="trash-outline"
          onPress={() => {
            clear();
            setCleared(true);
          }}
        />
        {cleared && (
          <Notice message="Your current portrait and consultation have been cleared." />
        )}
      </Card>
      <Copy>
        GlowAI · Your personal makeup artist and style advisor. Inspired by the
        original GlowAI website.
      </Copy>
    </Screen>
  );
}
