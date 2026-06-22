import { Feather } from "@expo/vector-icons";
import React, { useState } from "react";
import {
  Alert,
  Keyboard,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  useColorScheme,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useColors } from "@/hooks/useColors";
import { useApp } from "@/context/AppContext";

type Operation =
  | "evaluate"
  | "derivative"
  | "integral"
  | "simplify"
  | "expand";

interface Result {
  op: Operation;
  input: string;
  output: string;
  detail?: string;
}

const OP_LABELS: Record<Operation, string> = {
  evaluate: "Evaluate",
  derivative: "d/dx",
  integral: "∫ dx",
  simplify: "Simplify",
  expand: "Expand",
};

const QUICK_EXPRS = [
  "x^2 + 3*x + 2",
  "sin(x)^2 + cos(x)^2",
  "e^x",
  "log(x^2)",
  "tan(x)",
  "1/(1+x^2)",
];

async function runOperation(
  expr: string,
  op: Operation,
  math: typeof import("mathjs")
): Promise<{ output: string; detail?: string }> {
  const e = expr.trim();
  switch (op) {
    case "evaluate": {
      try {
        const res = math.evaluate(e);
        return { output: typeof res === "object" ? res.toString() : String(res) };
      } catch (err: any) {
        return { output: `Error: ${err.message}` };
      }
    }
    case "derivative": {
      try {
        const node = math.parse(e);
        const deriv = math.derivative(node, "x");
        const simplified = math.simplify(deriv);
        return {
          output: simplified.toString(),
          detail: `d/dx[${e}] = ${simplified.toString()}`,
        };
      } catch (err: any) {
        try {
          const h = 1e-7;
          const dVal = (math.evaluate(e, { x: 1 + h }) as number - math.evaluate(e, { x: 1 - h }) as number) / (2 * h);
          return {
            output: `≈ ${dVal.toFixed(6)} at x=1`,
            detail: "Numerical derivative (symbolic not available)",
          };
        } catch {
          return { output: `Error: ${err.message}` };
        }
      }
    }
    case "integral": {
      const a = -5, b = 5, n = 10000;
      try {
        const dx = (b - a) / n;
        let sum = 0;
        for (let i = 0; i <= n; i++) {
          const x = a + i * dx;
          const y = math.evaluate(e, { x }) as number;
          if (!isFinite(y)) continue;
          const w = i === 0 || i === n ? 1 : i % 2 === 0 ? 2 : 4;
          sum += w * y;
        }
        const result = (dx / 3) * sum;
        return {
          output: result.toFixed(6),
          detail: `∫₋₅⁵ (${e}) dx ≈ ${result.toFixed(6)}  [Simpson's rule, n=${n}]`,
        };
      } catch (err: any) {
        return { output: `Error: ${err.message}` };
      }
    }
    case "simplify": {
      try {
        const simplified = math.simplify(e);
        return { output: simplified.toString() };
      } catch (err: any) {
        return { output: `Error: ${err.message}` };
      }
    }
    case "expand": {
      try {
        const expanded = math.expand ? math.expand(e).toString() : math.simplify(e).toString();
        return { output: expanded };
      } catch (err: any) {
        return { output: `Error: ${err.message}` };
      }
    }
  }
}

export default function CalculatorScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";
  const { addToHistory } = useApp();

  const [expression, setExpression] = useState("x^2 + 3*x + 2");
  const [operation, setOperation] = useState<Operation>("derivative");
  const [result, setResult] = useState<Result | null>(null);
  const [loading, setLoading] = useState(false);

  const topPad = Platform.OS === "web" ? 67 : insets.top;

  const compute = async () => {
    if (!expression.trim()) return;
    Keyboard.dismiss();
    setLoading(true);
    try {
      const math = await import("mathjs");
      const { output, detail } = await runOperation(expression, operation, math);
      const r: Result = { op: operation, input: expression, output, detail };
      setResult(r);
      addToHistory(`${OP_LABELS[operation]}(${expression}) = ${output}`);
    } catch (e: any) {
      setResult({ op: operation, input: expression, output: `Error: ${e.message}` });
    }
    setLoading(false);
  };

  const cardBg = isDark ? "#111111" : "#FFFFFF";
  const sectionBg = isDark ? "#1C1C1E" : "#F2F2F7";

  return (
    <ScrollView
      style={[styles.root, { backgroundColor: isDark ? "#000" : "#F2F2F7" }]}
      contentContainerStyle={[styles.content, { paddingTop: topPad + 8 }]}
      keyboardShouldPersistTaps="handled"
    >
      <Text style={[styles.pageTitle, { color: colors.foreground }]}>Calculate</Text>

      <View style={[styles.card, { backgroundColor: cardBg }]}>
        <Text style={[styles.label, { color: colors.mutedForeground }]}>EXPRESSION</Text>
        <TextInput
          style={[styles.exprInput, { color: colors.foreground, borderColor: colors.border }]}
          value={expression}
          onChangeText={setExpression}
          autoCapitalize="none"
          autoCorrect={false}
          placeholder="e.g. x^2 + sin(x)"
          placeholderTextColor={colors.mutedForeground}
          multiline
        />

        <Text style={[styles.label, { color: colors.mutedForeground, marginTop: 12 }]}>QUICK EXAMPLES</Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.quickRow}>
          {QUICK_EXPRS.map((q) => (
            <TouchableOpacity
              key={q}
              style={[styles.quickChip, { backgroundColor: sectionBg, borderColor: colors.border }]}
              onPress={() => setExpression(q)}
            >
              <Text style={[styles.quickChipText, { color: colors.foreground }]}>{q}</Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>

      <View style={[styles.card, { backgroundColor: cardBg }]}>
        <Text style={[styles.label, { color: colors.mutedForeground }]}>OPERATION</Text>
        <View style={styles.opsGrid}>
          {(Object.keys(OP_LABELS) as Operation[]).map((op) => (
            <Pressable
              key={op}
              onPress={() => setOperation(op)}
              style={({ pressed }) => [
                styles.opBtn,
                {
                  backgroundColor:
                    operation === op
                      ? colors.primary
                      : sectionBg,
                  borderColor: operation === op ? colors.primary : colors.border,
                  opacity: pressed ? 0.7 : 1,
                },
              ]}
            >
              <Text
                style={[
                  styles.opBtnText,
                  { color: operation === op ? "#FFF" : colors.foreground },
                ]}
              >
                {OP_LABELS[op]}
              </Text>
            </Pressable>
          ))}
        </View>

        <Pressable
          onPress={compute}
          style={({ pressed }) => [
            styles.computeBtn,
            { backgroundColor: colors.primary, opacity: pressed ? 0.8 : 1 },
          ]}
        >
          {loading ? (
            <Text style={styles.computeBtnText}>Computing…</Text>
          ) : (
            <Text style={styles.computeBtnText}>Compute</Text>
          )}
        </Pressable>
      </View>

      {result && (
        <View style={[styles.card, { backgroundColor: cardBg }]}>
          <Text style={[styles.label, { color: colors.mutedForeground }]}>RESULT</Text>
          <View style={[styles.resultBox, { backgroundColor: sectionBg }]}>
            <Text style={[styles.resultOp, { color: colors.primary }]}>
              {OP_LABELS[result.op]}
            </Text>
            <Text style={[styles.resultInput, { color: colors.mutedForeground }]}>
              f(x) = {result.input}
            </Text>
            <Text style={[styles.resultOutput, { color: colors.foreground }]}>
              {result.output}
            </Text>
            {result.detail && (
              <Text style={[styles.resultDetail, { color: colors.mutedForeground }]}>
                {result.detail}
              </Text>
            )}
          </View>
        </View>
      )}

      {Platform.OS === "web" && <View style={{ height: 34 }} />}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  content: { padding: 16, gap: 12, paddingBottom: 40 },
  pageTitle: {
    fontSize: 28,
    fontFamily: "Inter_700Bold",
    marginBottom: 4,
    letterSpacing: -0.5,
  },
  card: {
    borderRadius: 16,
    padding: 16,
    shadowColor: "#000",
    shadowOpacity: 0.06,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },
  label: {
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
    letterSpacing: 1.2,
    marginBottom: 8,
  },
  exprInput: {
    fontSize: 18,
    fontFamily: "Inter_400Regular",
    borderWidth: 1,
    borderRadius: 10,
    padding: 12,
    minHeight: 54,
  },
  quickRow: { marginHorizontal: -4 },
  quickChip: {
    marginHorizontal: 4,
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 20,
    borderWidth: 1,
  },
  quickChipText: { fontSize: 13, fontFamily: "Inter_400Regular" },
  opsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
    marginBottom: 14,
  },
  opBtn: {
    paddingHorizontal: 16,
    paddingVertical: 9,
    borderRadius: 10,
    borderWidth: 1,
  },
  opBtnText: { fontSize: 14, fontFamily: "Inter_500Medium" },
  computeBtn: {
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: "center",
  },
  computeBtnText: {
    color: "#FFF",
    fontSize: 16,
    fontFamily: "Inter_600SemiBold",
  },
  resultBox: {
    borderRadius: 12,
    padding: 14,
    gap: 4,
  },
  resultOp: { fontSize: 11, fontFamily: "Inter_600SemiBold", letterSpacing: 1 },
  resultInput: { fontSize: 13, fontFamily: "Inter_400Regular", marginBottom: 6 },
  resultOutput: { fontSize: 22, fontFamily: "Inter_700Bold", letterSpacing: -0.5 },
  resultDetail: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 6, lineHeight: 18 },
});
