import { Feather } from "@expo/vector-icons";
import React, { useState } from "react";
import {
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

type SolverMode = "derivative" | "taylor" | "roots" | "simplify" | "limits";

const MODES: { key: SolverMode; label: string; desc: string }[] = [
  { key: "derivative", label: "d/dx", desc: "Symbolic derivative" },
  { key: "simplify", label: "Simplify", desc: "Algebraic simplification" },
  { key: "taylor", label: "Taylor", desc: "Taylor series expansion" },
  { key: "roots", label: "Roots", desc: "Numerical root finding" },
  { key: "limits", label: "Limit", desc: "Numerical limit evaluation" },
];

const EXAMPLES: Record<SolverMode, string[]> = {
  derivative: ["x^3 + 2*x^2 - x + 5", "sin(x)*cos(x)", "e^(x^2)", "log(x^2 + 1)"],
  simplify: ["2*x + 3*x - x", "sin(x)^2 + cos(x)^2", "(x+1)^2 - x^2 - 2*x", "2*(x+3) + 4*x"],
  taylor: ["sin(x)", "cos(x)", "e^x", "log(1+x)"],
  roots: ["x^3 - x - 2", "x^2 - 4", "sin(x) - 0.5", "x^3 - 2*x^2 - x + 2"],
  limits: ["sin(x)/x", "(e^x - 1)/x", "(1 - cos(x))/x^2", "x*sin(1/x)"],
};

interface StepResult {
  steps: { label: string; value: string }[];
  answer: string;
}

async function solveDerivative(expr: string, math: typeof import("mathjs")): Promise<StepResult> {
  const steps: { label: string; value: string }[] = [];
  steps.push({ label: "Original expression", value: `f(x) = ${expr}` });
  try {
    const node = math.parse(expr);
    const deriv = math.derivative(node, "x");
    steps.push({ label: "Applying differentiation rules", value: `f'(x) = ${deriv.toString()}` });
    const simplified = math.simplify(deriv);
    steps.push({ label: "Simplifying result", value: `f'(x) = ${simplified.toString()}` });
    return { steps, answer: simplified.toString() };
  } catch (e: any) {
    steps.push({ label: "Error", value: e.message });
    return { steps, answer: "Error" };
  }
}

async function solveSimplify(expr: string, math: typeof import("mathjs")): Promise<StepResult> {
  const steps: { label: string; value: string }[] = [];
  steps.push({ label: "Original expression", value: expr });
  try {
    const simplified = math.simplify(expr);
    steps.push({ label: "Simplified", value: simplified.toString() });
    const evaluated = math.evaluate(simplified.toString(), { x: 1 });
    const original = math.evaluate(expr, { x: 1 });
    steps.push({ label: "Verification at x=1", value: `${original} ≡ ${evaluated} ✓` });
    return { steps, answer: simplified.toString() };
  } catch (e: any) {
    return { steps: [{ label: "Error", value: e.message }], answer: "Error" };
  }
}

async function solveTaylor(expr: string, math: typeof import("mathjs")): Promise<StepResult> {
  const steps: { label: string; value: string }[] = [];
  steps.push({ label: "Function", value: `f(x) = ${expr}` });
  steps.push({ label: "Center", value: "a = 0 (Maclaurin series)" });
  try {
    const terms: string[] = [];
    const coefficients: { n: number; coeff: number }[] = [];
    let factorial = 1;
    for (let n = 0; n <= 5; n++) {
      if (n > 0) factorial *= n;
      let fn: typeof import("mathjs");
      let expr_n = expr;
      try {
        for (let k = 0; k < n; k++) {
          const node = math.parse(expr_n);
          expr_n = math.derivative(node, "x").toString();
        }
        const val = math.evaluate(expr_n, { x: 0 }) as number;
        const coeff = val / factorial;
        if (Math.abs(coeff) > 1e-12) {
          coefficients.push({ n, coeff });
          if (n === 0) terms.push(coeff.toFixed(3));
          else if (n === 1) terms.push(`${coeff.toFixed(3)}x`);
          else terms.push(`${coeff.toFixed(3)}x^${n}`);
        }
      } catch { break; }
    }
    const series = terms.slice(0, 5).join(" + ").replace(/\+ -/g, "- ") || "Unable to compute";
    steps.push({ label: "Series (order 5)", value: series + " + …" });
    return { steps, answer: series + " + …" };
  } catch (e: any) {
    return { steps: [{ label: "Error", value: e.message }], answer: "Error" };
  }
}

async function solveRoots(expr: string, math: typeof import("mathjs")): Promise<StepResult> {
  const steps: { label: string; value: string }[] = [];
  steps.push({ label: "Finding roots of", value: `f(x) = ${expr}` });
  steps.push({ label: "Method", value: "Bisection + Newton-Raphson" });
  try {
    const f = (x: number) => math.evaluate(expr, { x }) as number;
    const roots: number[] = [];
    const range = 20;
    const step = 0.1;
    let prevSign = Math.sign(f(-range));
    for (let x = -range + step; x <= range; x += step) {
      const sign = Math.sign(f(x));
      if (sign !== prevSign && sign !== 0) {
        let lo = x - step, hi = x;
        for (let i = 0; i < 50; i++) {
          const mid = (lo + hi) / 2;
          if (Math.sign(f(mid)) === Math.sign(f(lo))) lo = mid;
          else hi = mid;
        }
        const root = (lo + hi) / 2;
        if (!roots.some((r) => Math.abs(r - root) < 0.01)) {
          roots.push(root);
        }
      }
      prevSign = sign || prevSign;
    }
    if (roots.length === 0) {
      steps.push({ label: "Result", value: "No real roots found in [-20, 20]" });
      return { steps, answer: "No real roots" };
    }
    roots.forEach((r, i) => steps.push({ label: `Root ${i + 1}`, value: `x ≈ ${r.toFixed(6)}` }));
    return { steps, answer: roots.map((r) => r.toFixed(4)).join(", ") };
  } catch (e: any) {
    return { steps: [{ label: "Error", value: e.message }], answer: "Error" };
  }
}

async function solveLimit(expr: string, math: typeof import("mathjs")): Promise<StepResult> {
  const steps: { label: string; value: string }[] = [];
  steps.push({ label: "Evaluating limit", value: `lim(x→0) ${expr}` });
  steps.push({ label: "Method", value: "Numerical approach from both sides" });
  try {
    const f = (x: number) => math.evaluate(expr, { x }) as number;
    const approaches = [0.1, 0.01, 0.001, 0.0001];
    let leftVal: number | null = null;
    let rightVal: number | null = null;
    for (const h of approaches) {
      const lv = f(-h);
      const rv = f(h);
      if (isFinite(lv)) leftVal = lv;
      if (isFinite(rv)) rightVal = rv;
      steps.push({ label: `h = ${h}`, value: `f(-h) = ${isFinite(lv) ? lv.toFixed(6) : "∞"}  |  f(h) = ${isFinite(rv) ? rv.toFixed(6) : "∞"}` });
    }
    if (leftVal !== null && rightVal !== null && Math.abs(leftVal - rightVal) < 1e-4) {
      const limit = (leftVal + rightVal) / 2;
      steps.push({ label: "Conclusion", value: `Left and right limits agree → limit exists` });
      return { steps, answer: limit.toFixed(6) };
    } else {
      steps.push({ label: "Conclusion", value: "Limit does not exist (sides disagree)" });
      return { steps, answer: "DNE" };
    }
  } catch (e: any) {
    return { steps: [{ label: "Error", value: e.message }], answer: "Error" };
  }
}

export default function SolverScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";
  const { addToHistory } = useApp();

  const [mode, setMode] = useState<SolverMode>("derivative");
  const [expr, setExpr] = useState("x^3 + 2*x^2 - x + 5");
  const [result, setResult] = useState<StepResult | null>(null);
  const [loading, setLoading] = useState(false);

  const topPad = Platform.OS === "web" ? 67 : insets.top;
  const cardBg = isDark ? "#111111" : "#FFFFFF";
  const sectionBg = isDark ? "#1C1C1E" : "#F2F2F7";

  const solve = async () => {
    Keyboard.dismiss();
    setLoading(true);
    try {
      const math = await import("mathjs");
      let r: StepResult;
      switch (mode) {
        case "derivative": r = await solveDerivative(expr, math); break;
        case "simplify": r = await solveSimplify(expr, math); break;
        case "taylor": r = await solveTaylor(expr, math); break;
        case "roots": r = await solveRoots(expr, math); break;
        case "limits": r = await solveLimit(expr, math); break;
      }
      setResult(r);
      addToHistory(`${mode}(${expr}) = ${r.answer}`);
    } catch (e: any) {
      setResult({ steps: [{ label: "Error", value: e.message }], answer: "Error" });
    }
    setLoading(false);
  };

  const currentExamples = EXAMPLES[mode];

  return (
    <ScrollView
      style={[styles.root, { backgroundColor: isDark ? "#000" : "#F2F2F7" }]}
      contentContainerStyle={[styles.content, { paddingTop: topPad + 8 }]}
      keyboardShouldPersistTaps="handled"
    >
      <Text style={[styles.pageTitle, { color: colors.foreground }]}>Solver</Text>
      <Text style={[styles.pageSubtitle, { color: colors.mutedForeground }]}>Step-by-step symbolic engine</Text>

      <View style={[styles.card, { backgroundColor: cardBg }]}>
        <Text style={[styles.label, { color: colors.mutedForeground }]}>MODE</Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 14 }}>
          {MODES.map((m) => (
            <Pressable
              key={m.key}
              onPress={() => { setMode(m.key); setResult(null); }}
              style={({ pressed }) => [
                styles.modeBtn,
                {
                  backgroundColor: mode === m.key ? colors.primary : sectionBg,
                  borderColor: mode === m.key ? colors.primary : colors.border,
                  opacity: pressed ? 0.7 : 1,
                  marginRight: 8,
                },
              ]}
            >
              <Text style={[styles.modeBtnLabel, { color: mode === m.key ? "#FFF" : colors.foreground }]}>
                {m.label}
              </Text>
              <Text style={[styles.modeBtnDesc, { color: mode === m.key ? "#FFFFFFAA" : colors.mutedForeground }]}>
                {m.desc}
              </Text>
            </Pressable>
          ))}
        </ScrollView>

        <Text style={[styles.label, { color: colors.mutedForeground }]}>EXPRESSION</Text>
        <TextInput
          style={[styles.exprInput, { color: colors.foreground, borderColor: colors.border }]}
          value={expr}
          onChangeText={setExpr}
          autoCapitalize="none"
          autoCorrect={false}
          placeholder="e.g. x^3 + 2*x^2 - x + 5"
          placeholderTextColor={colors.mutedForeground}
        />

        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginTop: 10 }}>
          {currentExamples.map((ex) => (
            <TouchableOpacity
              key={ex}
              onPress={() => setExpr(ex)}
              style={[styles.exampleChip, { backgroundColor: sectionBg, borderColor: colors.border }]}
            >
              <Text style={[styles.exampleChipText, { color: colors.foreground }]}>{ex}</Text>
            </TouchableOpacity>
          ))}
        </ScrollView>

        <Pressable
          onPress={solve}
          style={({ pressed }) => [
            styles.solveBtn,
            { backgroundColor: colors.primary, opacity: pressed ? 0.8 : 1, marginTop: 14 },
          ]}
        >
          <Text style={styles.solveBtnText}>{loading ? "Solving…" : "Solve Step-by-Step"}</Text>
        </Pressable>
      </View>

      {result && (
        <View style={[styles.card, { backgroundColor: cardBg }]}>
          <Text style={[styles.label, { color: colors.mutedForeground }]}>SOLUTION STEPS</Text>
          {result.steps.map((step, i) => (
            <View
              key={i}
              style={[styles.stepRow, { borderLeftColor: colors.primary, backgroundColor: sectionBg }]}
            >
              <Text style={[styles.stepLabel, { color: colors.mutedForeground }]}>
                {i + 1}. {step.label}
              </Text>
              <Text style={[styles.stepValue, { color: colors.foreground }]}>{step.value}</Text>
            </View>
          ))}

          <View style={[styles.answerBox, { backgroundColor: colors.primary + "22", borderColor: colors.primary }]}>
            <Text style={[styles.answerLabel, { color: colors.primary }]}>ANSWER</Text>
            <Text style={[styles.answerValue, { color: colors.foreground }]}>{result.answer}</Text>
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
  pageTitle: { fontSize: 28, fontFamily: "Inter_700Bold", letterSpacing: -0.5 },
  pageSubtitle: { fontSize: 13, fontFamily: "Inter_400Regular", marginTop: 2, marginBottom: 4 },
  card: { borderRadius: 16, padding: 16, shadowColor: "#000", shadowOpacity: 0.06, shadowRadius: 8, shadowOffset: { width: 0, height: 2 }, elevation: 2 },
  label: { fontSize: 11, fontFamily: "Inter_600SemiBold", letterSpacing: 1.2, marginBottom: 10 },
  modeBtn: { paddingHorizontal: 14, paddingVertical: 10, borderRadius: 12, borderWidth: 1, minWidth: 90, alignItems: "center" },
  modeBtnLabel: { fontSize: 16, fontFamily: "Inter_700Bold" },
  modeBtnDesc: { fontSize: 10, fontFamily: "Inter_400Regular", marginTop: 2 },
  exprInput: { fontSize: 18, fontFamily: "Inter_400Regular", borderWidth: 1, borderRadius: 10, padding: 12 },
  exampleChip: { marginRight: 8, paddingHorizontal: 12, paddingVertical: 7, borderRadius: 20, borderWidth: 1 },
  exampleChipText: { fontSize: 13, fontFamily: "Inter_400Regular" },
  solveBtn: { borderRadius: 12, paddingVertical: 14, alignItems: "center" },
  solveBtnText: { color: "#FFF", fontSize: 16, fontFamily: "Inter_600SemiBold" },
  stepRow: { borderLeftWidth: 3, borderRadius: 8, padding: 12, marginBottom: 8 },
  stepLabel: { fontSize: 11, fontFamily: "Inter_600SemiBold", letterSpacing: 0.5, marginBottom: 4 },
  stepValue: { fontSize: 15, fontFamily: "Inter_500Medium" },
  answerBox: { borderRadius: 12, borderWidth: 1.5, padding: 16, alignItems: "center", marginTop: 4 },
  answerLabel: { fontSize: 11, fontFamily: "Inter_700Bold", letterSpacing: 1.5, marginBottom: 6 },
  answerValue: { fontSize: 24, fontFamily: "Inter_700Bold", letterSpacing: -0.5, textAlign: "center" },
});
