import { Feather } from "@expo/vector-icons";
import React, { useState } from "react";
import {
  Keyboard,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  useColorScheme,
  View,
} from "react-native";
import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

export default function FunctionPanel() {
  const colors = useColors();
  const { functions, addFunction, removeFunction, toggleFunction } = useApp();
  const [input, setInput] = useState("");
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";

  const handleAdd = () => {
    const expr = input.trim();
    if (!expr) return;
    addFunction(expr);
    setInput("");
    Keyboard.dismiss();
  };

  return (
    <View
      style={[
        styles.container,
        {
          backgroundColor: isDark ? "#111111" : "#FFFFFF",
          borderTopColor: colors.border,
        },
      ]}
    >
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={styles.chips}
        contentContainerStyle={styles.chipsContent}
      >
        {functions.map((f) => (
          <View
            key={f.id}
            style={[
              styles.chip,
              {
                backgroundColor: isDark ? "#1C1C1E" : "#F2F2F7",
                borderColor: f.color,
                borderWidth: 1.5,
                opacity: f.visible ? 1 : 0.4,
              },
            ]}
          >
            <TouchableOpacity onPress={() => toggleFunction(f.id)}>
              <View style={[styles.dot, { backgroundColor: f.color }]} />
            </TouchableOpacity>
            <Text
              style={[styles.chipText, { color: colors.foreground }]}
              numberOfLines={1}
            >
              {f.expression}
            </Text>
            <TouchableOpacity onPress={() => removeFunction(f.id)}>
              <Feather name="x" size={14} color={colors.mutedForeground} />
            </TouchableOpacity>
          </View>
        ))}
      </ScrollView>

      <View
        style={[
          styles.inputRow,
          { borderTopColor: isDark ? "#2C2C2E" : "#E5E5EA" },
        ]}
      >
        <Text style={[styles.prefix, { color: colors.mutedForeground }]}>
          f(x) =
        </Text>
        <TextInput
          style={[styles.input, { color: colors.foreground }]}
          value={input}
          onChangeText={setInput}
          placeholder="sin(x), x^2, e^x..."
          placeholderTextColor={colors.mutedForeground}
          autoCapitalize="none"
          autoCorrect={false}
          returnKeyType="done"
          onSubmitEditing={handleAdd}
        />
        <Pressable
          onPress={handleAdd}
          style={({ pressed }) => [
            styles.addBtn,
            { backgroundColor: colors.primary, opacity: pressed ? 0.8 : 1 },
          ]}
        >
          <Feather name="plus" size={18} color="#FFF" />
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    borderTopWidth: StyleSheet.hairlineWidth,
  },
  chips: {
    maxHeight: 48,
  },
  chipsContent: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    gap: 8,
    flexDirection: "row",
    alignItems: "center",
  },
  chip: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 20,
    gap: 6,
    maxWidth: 160,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  chipText: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    flexShrink: 1,
  },
  inputRow: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 16,
    paddingVertical: 10,
    gap: 10,
    borderTopWidth: StyleSheet.hairlineWidth,
  },
  prefix: {
    fontSize: 15,
    fontFamily: "Inter_500Medium",
  },
  input: {
    flex: 1,
    fontSize: 16,
    fontFamily: "Inter_400Regular",
    padding: 0,
  },
  addBtn: {
    width: 34,
    height: 34,
    borderRadius: 17,
    alignItems: "center",
    justifyContent: "center",
  },
});
