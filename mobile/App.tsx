import React, { useEffect, useState } from "react";
import { View } from "react-native";
import { NavigationContainer } from "@react-navigation/native";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { useFonts } from "expo-font";
import {
  PlayfairDisplay_600SemiBold,
  PlayfairDisplay_400Regular_Italic,
} from "@expo-google-fonts/playfair-display";
import {
  Poppins_400Regular,
  Poppins_500Medium,
  Poppins_600SemiBold,
} from "@expo-google-fonts/poppins";
import { LookProvider } from "./src/store/LookContext";
import { ErrorBoundary } from "./src/components/ErrorBoundary";
import { Home } from "./src/components/Home";
import { Consultation } from "./src/features/analysis/Consultation";
import { Results } from "./src/features/recommendations/Results";
import { Studio } from "./src/features/tryon/Studio";
import { Privacy } from "./src/components/Privacy";
import { Copy, Entrance, Glow } from "./src/components/ui";
import type { RootStackParamList } from "./src/types";
import { theme as t } from "./src/theme";
import { clearOldPhotos } from "./src/features/camera/photos";
const Stack = createNativeStackNavigator<RootStackParamList>();
export default function App() {
  const [fonts, error] = useFonts({
    PlayfairDisplay_600SemiBold,
    PlayfairDisplay_400Regular_Italic,
    Poppins_400Regular,
    Poppins_500Medium,
    Poppins_600SemiBold,
  });
  const [ready, setReady] = useState(false);
  useEffect(() => {
    clearOldPhotos();
    const timer = setTimeout(() => setReady(true), 1400);
    return () => clearTimeout(timer);
  }, []);
  return (
    <SafeAreaProvider>
      <StatusBar style="dark" />
      {(!fonts && !error) || !ready ? (
        <View
          style={{
            flex: 1,
            backgroundColor: t.colors.bg,
            justifyContent: "center",
            padding: 30,
          }}
        >
          <Entrance>
            <Glow label="GlowAI" />
            <Copy style={{ textAlign: "center" }}>
              Your beauty. Your kind of glow.
            </Copy>
          </Entrance>
        </View>
      ) : (
        <ErrorBoundary>
          <LookProvider>
            <NavigationContainer>
              <Stack.Navigator
                screenOptions={{
                  headerStyle: { backgroundColor: t.colors.bg },
                  headerTintColor: t.colors.ink,
                  headerShadowVisible: false,
                  headerTitleStyle: {
                    fontFamily: t.fonts.medium,
                    fontSize: 14,
                  },
                  contentStyle: { backgroundColor: t.colors.bg },
                  animation: "slide_from_right",
                }}
              >
                <Stack.Screen
                  name="Home"
                  component={Home}
                  options={{ title: "", headerShown: false }}
                />
                <Stack.Screen
                  name="Consultation"
                  component={Consultation}
                  options={{ title: "Create your look" }}
                />
                <Stack.Screen
                  name="Results"
                  component={Results}
                  options={{ title: "Your beauty edit" }}
                />
                <Stack.Screen
                  name="Studio"
                  component={Studio}
                  options={{ title: "Virtual makeup" }}
                />
                <Stack.Screen
                  name="Privacy"
                  component={Privacy}
                  options={{ title: "Privacy & about" }}
                />
              </Stack.Navigator>
            </NavigationContainer>
          </LookProvider>
        </ErrorBoundary>
      )}
    </SafeAreaProvider>
  );
}
