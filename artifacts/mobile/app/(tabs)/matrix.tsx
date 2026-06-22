import React, { useState } from "react";
import {
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

type Size = 2 | 3 | 4;
type MatOp = "det" | "inv" | "transpose" | "multiply" | "eigenvalues";

const OP_LABELS: Record<MatOp, string> = {
  det: "Determinant",
  inv: "Inverse",
  transpose: "Transpose",
  multiply: "A × A",
  eigenvalues: "Eigenvalues",
};

function makeEmpty(size: Size): string[][] {
  return Array.from({ length: size }, () => Array(size).fill(""));
}

function parseMatrix(cells: string[][]): number[][] {
  return cells.map((row) =>
    row.map((c) => {
      const v = parseFloat(c);
      return isNaN(v) ? 0 : v;
    })
  );
}

function formatMatrix(m: number[][]): string {
  return m
    .map((row) => "[ " + row.map((v) => v.toFixed(4)).join("  ") + " ]")
    .join("\n");
}

function formatNum(n: number | { re: number; im: number }): string {
  if (typeof n === "object" && "re" in n) {
    const { re, im } = n;
    if (Math.abs(im) < 1e-10) return re.toFixed(4);
    return `${re.toFixed(3)} + ${im.toFixed(3)}i`;
  }
  return (n as number).toFixed(4);
}

async function runMatOp(
  cells: string[][],
  op: MatOp,
  math: typeof import("mathjs")
): Promise<string> {
  const A = parseMatrix(cells);
  const m = math.matrix(A);

  switch (op) {
    case "det": {
      const d = math.det(m);
      return typeof d === "number" ? d.toFixed(6) : String(d);
    }
    case "inv": {
      try {
        const inv = math.inv(m) as number[][];
        return formatMatrix(inv);
      } catch {
        return "Matrix is singular (not invertible)";
      }
    }
    case "transpose": {
      const t = math.transpose(m) as { toArray: () => number[][] };
      return formatMatrix(t.toArray());
    }
    case "multiply": {
      const res = math.multiply(m, m) as { toArray: () => number[][] };
      return formatMatrix(res.toArray());
    }
    case "eigenvalues": {
      try {
        const { values } = math.eigs(m);
        const arr = (values as { toArray?: () => any[] }).toArray
          ? (values as any).toArray()
          : values;
        return (arr as any[]).map(formatNum).join("\n");
      } catch (e: any) {
        return `Error: ${e.message}`;
      }
    }
  }
}

export default function MatrixScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";

  const [size, setSize] = useState<Size>(3);
  const [cells, setCells] = useState<string[][]>(makeEmpty(3));
  const [operation, setOperation] = useState<MatOp>("det");
  const [result, setResult] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const topPad = Platform.OS === "web" ? 67 : insets.top;
  const cardBg = isDark ? "#111111" : "#FFFFFF";
  const sectionBg = isDark ? "#1C1C1E" : "#F2F2F7";

  const changeSize = (s: Size) => {
    setSize(s);
    setCells(makeEmpty(s));
    setResult(null);
  };

  const setCell = (row: number, col: number, val: string) => {
    setCells((prev) => {
      const next = prev.map((r) => [...r]);
      next[row][col] = val;
      return next;
    });
  };

  const fillIdentity = () => {
    setCells(
      Array.from({ length: size }, (_, i) =>
        Array.from({ length: size }, (_, j) => (i === j ? "1" : "0"))
      )
    );
  };

  const fillRandom = () => {
    setCells(
      Array.from({ length: size }, () =>
        Array.from({ length: size }, () =>
          (Math.floor(Math.random() * 19) - 9).toString()
        )
      )
    );
  };

  const compute = async () => {
    setLoading(true);
    try {
      const math = await import("mathjs");
      const out = await runMatOp(cells, operation, math);
      setResult(out);
    } catch (e: any) {
      setResult(`Error: ${e.message}`);
    }
    setLoading(false);
  };

  const cellSize = Math.min(60, (320 - (size - 1) * 8) / size);

  return (
    <ScrollView
      style={[styles.root, { backgroundColor: isDark ? "#000" : "#F2F2F7" }]}
      contentContainerStyle={[styles.content, { paddingTop: topPad + 8 }]}
      keyboardShouldPersistTaps="handled"
    >
      <Text style={[styles.pageTitle, { color: colors.foreground }]}>Matrix</Text>

      <View style={[styles.card, { backgroundColor: cardBg }]}>
        <Text style={[styles.label, { color: colors.mutedForeground }]}>SIZE</Text>
        <View style={styles.sizeRow}>
          {([2, 3, 4] as Size[]).map((s) => (
            <Pressable
              key={s}
              onPress={() => changeSize(s)}
              style={({ pressed }) => [
                styles.sizeBtn,
                {
                  backgroundColor: size === s ? colors.primary : sectionBg,
                  borderColor: size === s ? colors.primary : colors.border,
                  opacity: pressed ? 0.7 : 1,
                },
              ]}
            >
              <Text
                style={[
                  styles.sizeBtnText,
                  { color: size === s ? "#FFF" : colors.foreground },
                ]}
              >
                {s}×{s}
              </Text>
            </Pressable>
          ))}
          <View style={{ flex: 1 }} />
          <TouchableOpacity
            onPress={fillIdentity}
            style={[styles.fillBtn, { backgroundColor: sectionBg, borderColor: colors.border }]}
          >
            <Text style={[styles.fillBtnText, { color: colors.foreground }]}>I</Text>
          </TouchableOpacity>
          <TouchableOpacity
            onPress={fillRandom}
            style={[styles.fillBtn, { backgroundColor: sectionBg, borderColor: colors.border }]}
          >
            <Text style={[styles.fillBtnText, { color: colors.foreground }]}>?</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.matrixGrid}>
          {cells.map((row, ri) => (
            <View key={ri} style={styles.matrixRow}>
              {row.map((val, ci) => (
                <TextInput
                  key={ci}
                  style={[
                    styles.cell,
                    {
                      width: cellSize,
                      height: cellSize,
                      backgroundColor: sectionBg,
                      color: colors.foreground,
                      borderColor: colors.border,
                    },
                  ]}
                  value={val}
                  onChangeText={(v) => setCell(ri, ci, v)}
                  keyboardType="numbers-and-punctuation"
                  textAlign="center"
                  selectTextOnFocus
                />
              ))}
            </View>
          ))}
        </View>
      </View>

      <View style={[styles.card, { backgroundColor: cardBg }]}>
        <Text style={[styles.label, { color: colors.mutedForeground }]}>OPERATION</Text>
        <View style={styles.opsGrid}>
          {(Object.keys(OP_LABELS) as MatOp[]).map((op) => (
            <Pressable
              key={op}
              onPress={() => setOperation(op)}
              style={({ pressed }) => [
                styles.opBtn,
                {
                  backgroundColor: operation === op ? colors.primary : sectionBg,
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
          <Text style={styles.computeBtnText}>
            {loading ? "Computing…" : "Compute"}
          </Text>
        </Pressable>
      </View>

      {result !== null && (
        <View style={[styles.card, { backgroundColor: cardBg }]}>
          <Text style={[styles.label, { color: colors.mutedForeground }]}>
            {OP_LABELS[operation].toUpperCase()}
          </Text>
          <View style={[styles.resultBox, { backgroundColor: sectionBg }]}>
            <Text
              style={[
                styles.resultText,
                { color: colors.foreground, fontFamily: "Inter_400Regular" },
              ]}
            >
              {result}
            </Text>
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
  pageTitle: { fontSize: 28, fontFamily: "Inter_700Bold", marginBottom: 4, letterSpacing: -0.5 },
  card: { borderRadius: 16, padding: 16, shadowColor: "#000", shadowOpacity: 0.06, shadowRadius: 8, shadowOffset: { width: 0, height: 2 }, elevation: 2 },
  label: { fontSize: 11, fontFamily: "Inter_600SemiBold", letterSpacing: 1.2, marginBottom: 10 },
  sizeRow: { flexDirection: "row", alignItems: "center", gap: 8, marginBottom: 16 },
  sizeBtn: { paddingHorizontal: 18, paddingVertical: 9, borderRadius: 10, borderWidth: 1 },
  sizeBtnText: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
  fillBtn: { paddingHorizontal: 14, paddingVertical: 9, borderRadius: 10, borderWidth: 1 },
  fillBtnText: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
  matrixGrid: { gap: 8, alignSelf: "center" },
  matrixRow: { flexDirection: "row", gap: 8 },
  cell: { borderRadius: 8, borderWidth: 1, fontSize: 16, fontFamily: "Inter_500Medium" },
  opsGrid: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  opBtn: { paddingHorizontal: 14, paddingVertical: 9, borderRadius: 10, borderWidth: 1 },
  opBtnText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  computeBtn: { borderRadius: 12, paddingVertical: 14, alignItems: "center" },
  computeBtnText: { color: "#FFF", fontSize: 16, fontFamily: "Inter_600SemiBold" },
  resultBox: { borderRadius: 12, padding: 14 },
  resultText: { fontSize: 15, lineHeight: 24 },
});
