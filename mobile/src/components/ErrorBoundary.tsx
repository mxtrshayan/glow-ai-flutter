import React from "react";
import { View } from "react-native";
import { Button, Copy, Notice } from "./ui";
import { theme } from "../theme";
export class ErrorBoundary extends React.Component<
  React.PropsWithChildren,
  { failed: boolean }
> {
  state = { failed: false };
  static getDerivedStateFromError() {
    return { failed: true };
  }
  render() {
    if (this.state.failed)
      return (
        <View
          style={{
            flex: 1,
            justifyContent: "center",
            padding: 28,
            gap: 20,
            backgroundColor: theme.colors.bg,
          }}
        >
          <Copy title>Let’s try that again.</Copy>
          <Notice
            error
            message="This view could not be prepared. Your original photo has not been changed."
          />
          <Button
            label="Reopen GlowAI"
            onPress={() => this.setState({ failed: false })}
          />
        </View>
      );
    return this.props.children;
  }
}
