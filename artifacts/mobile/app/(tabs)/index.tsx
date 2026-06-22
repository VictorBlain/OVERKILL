import { Feather } from "@expo/vector-icons";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import React from "react";
import {
  Platform,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  useColorScheme,
} from "react-native";
import GraphCanvas from "@/components/GraphCanvas";
import FunctionPanel from "@/components/FunctionPanel";
import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

export default function GraphScreen() {
  const { functions } = useApp();
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";

  const topPad = Platform.OS === "web" ? 67 : insets.top;

  return (
    <View style={[styles.container, { backgroundColor: isDark ? "#000" : "#F2F2F7" }]}>
      <View style={[styles.header, { paddingTop: topPad + 8, backgroundColor: isDark ? "#000000CC" : "#F2F2F7CC" }]}>
        <Text style={[styles.title, { color: colors.foreground }]}>OVERKILL</Text>
        <Text style={[styles.subtitle, { color: colors.primary }]}>
          {functions.filter((f) => f.visible).length} active
        </Text>
      </View>

      <GraphCanvas functions={functions} />
      <FunctionPanel />

      {Platform.OS === "web" && <View style={{ height: 34 }} />}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    zIndex: 10,
    flexDirection: "row",
    alignItems: "flex-end",
    paddingHorizontal: 20,
    paddingBottom: 10,
  },
  title: {
    fontSize: 15,
    fontFamily: "Inter_700Bold",
    letterSpacing: 3,
    flex: 1,
  },
  subtitle: {
    fontSize: 12,
    fontFamily: "Inter_500Medium",
    letterSpacing: 1,
  },
});
