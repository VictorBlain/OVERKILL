import React, { useState } from "react";
import {
  Keyboard,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
  useColorScheme,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import Svg, { Rect, Text as SvgText, Line } from "react-native-svg";
import { useColors } from "@/hooks/useColors";

const SAMPLE_DATASETS = [
  "2, 4, 4, 4, 5, 5, 7, 9",
  "1, 3, 5, 7, 9, 11, 13, 15, 17, 19",
  "85, 90, 78, 92, 88, 76, 95, 82, 89, 91",
  "10, 20, 20, 30, 40, 50, 50, 60, 70, 80",
];

interface Stats {
  count: number;
  mean: number;
  median: number;
  mode: number[];
  std: number;
  variance: number;
  min: number;
  max: number;
  range: number;
  q1: number;
  q3: number;
  iqr: number;
}

function computeStats(data: number[]): Stats {
  const sorted = [...data].sort((a, b) => a - b);
  const n = data.length;
  const mean = data.reduce((s, v) => s + v, 0) / n;
  const median =
    n % 2 === 0
      ? (sorted[n / 2 - 1] + sorted[n / 2]) / 2
      : sorted[Math.floor(n / 2)];
  const freq = new Map<number, number>();
  data.forEach((v) => freq.set(v, (freq.get(v) ?? 0) + 1));
  const maxFreq = Math.max(...freq.values());
  const mode = [...freq.entries()]
    .filter(([, c]) => c === maxFreq)
    .map(([v]) => v);
  const variance = data.reduce((s, v) => s + (v - mean) ** 2, 0) / n;
  const std = Math.sqrt(variance);
  const min = sorted[0];
  const max = sorted[n - 1];
  const q1 = sorted[Math.floor(n / 4)];
  const q3 = sorted[Math.floor((3 * n) / 4)];
  return { count: n, mean, median, mode, std, variance, min, max, range: max - min, q1, q3, iqr: q3 - q1 };
}

function MiniBarChart({ data, colors }: { data: number[]; colors: ReturnType<typeof import("@/hooks/useColors").useColors> }) {
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";
  const w = 300;
  const h = 100;
  const pad = 6;
  const max = Math.max(...data);
  const min = Math.min(...data);
  const range = max - min || 1;
  const barW = (w - pad * (data.length + 1)) / data.length;

  return (
    <Svg width={w} height={h + 20} style={{ alignSelf: "center" }}>
      <Line x1={0} y1={h} x2={w} y2={h} stroke={isDark ? "#2C2C2E" : "#C6C6C8"} strokeWidth={1} />
      {data.map((v, i) => {
        const barH = ((v - min) / range) * (h - 10) + 10;
        const x = pad + i * (barW + pad);
        const y = h - barH;
        return (
          <React.Fragment key={i}>
            <Rect x={x} y={y} width={barW} height={barH} rx={3} fill={colors.primary} opacity={0.8} />
            {data.length <= 12 && (
              <SvgText x={x + barW / 2} y={h + 14} textAnchor="middle" fill={isDark ? "#8E8E93" : "#8E8E93"} fontSize={9}>
                {v}
              </SvgText>
            )}
          </React.Fragment>
        );
      })}
    </Svg>
  );
}

function StatRow({ label, value, colors, sectionBg }: { label: string; value: string; colors: any; sectionBg: string }) {
  return (
    <View style={[statStyles.row, { borderBottomColor: colors.border }]}>
      <Text style={[statStyles.rowLabel, { color: colors.mutedForeground }]}>{label}</Text>
      <Text style={[statStyles.rowValue, { color: colors.foreground }]}>{value}</Text>
    </View>
  );
}

const statStyles = StyleSheet.create({
  row: { flexDirection: "row", justifyContent: "space-between", paddingVertical: 10, borderBottomWidth: StyleSheet.hairlineWidth },
  rowLabel: { fontSize: 14, fontFamily: "Inter_400Regular" },
  rowValue: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
});

export default function StatsScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";

  const [input, setInput] = useState("2, 4, 4, 4, 5, 5, 7, 9");
  const [stats, setStats] = useState<Stats | null>(null);
  const [parsedData, setParsedData] = useState<number[]>([]);

  const topPad = Platform.OS === "web" ? 67 : insets.top;
  const cardBg = isDark ? "#111111" : "#FFFFFF";
  const sectionBg = isDark ? "#1C1C1E" : "#F2F2F7";

  const compute = () => {
    Keyboard.dismiss();
    const data = input
      .split(/[\s,;]+/)
      .map((s) => parseFloat(s.trim()))
      .filter((v) => !isNaN(v));
    if (data.length < 2) return;
    setParsedData(data);
    setStats(computeStats(data));
  };

  return (
    <ScrollView
      style={[styles.root, { backgroundColor: isDark ? "#000" : "#F2F2F7" }]}
      contentContainerStyle={[styles.content, { paddingTop: topPad + 8 }]}
      keyboardShouldPersistTaps="handled"
    >
      <Text style={[styles.pageTitle, { color: colors.foreground }]}>Statistics</Text>

      <View style={[styles.card, { backgroundColor: cardBg }]}>
        <Text style={[styles.label, { color: colors.mutedForeground }]}>DATA SET</Text>
        <TextInput
          style={[styles.dataInput, { color: colors.foreground, borderColor: colors.border }]}
          value={input}
          onChangeText={setInput}
          placeholder="Enter numbers separated by commas"
          placeholderTextColor={colors.mutedForeground}
          multiline
          autoCapitalize="none"
          autoCorrect={false}
        />
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginTop: 10 }}>
          {SAMPLE_DATASETS.map((d, i) => (
            <Pressable
              key={i}
              onPress={() => setInput(d)}
              style={({ pressed }) => [
                styles.sampleBtn,
                { backgroundColor: sectionBg, borderColor: colors.border, opacity: pressed ? 0.7 : 1 },
              ]}
            >
              <Text style={[styles.sampleBtnText, { color: colors.mutedForeground }]}>
                Sample {i + 1}
              </Text>
            </Pressable>
          ))}
        </ScrollView>
        <Pressable
          onPress={compute}
          style={({ pressed }) => [
            styles.computeBtn,
            { backgroundColor: colors.primary, opacity: pressed ? 0.8 : 1, marginTop: 14 },
          ]}
        >
          <Text style={styles.computeBtnText}>Analyze</Text>
        </Pressable>
      </View>

      {stats && parsedData.length > 0 && (
        <>
          <View style={[styles.card, { backgroundColor: cardBg }]}>
            <Text style={[styles.label, { color: colors.mutedForeground }]}>
              DISTRIBUTION ({parsedData.length} values)
            </Text>
            <MiniBarChart data={parsedData} colors={colors} />
          </View>

          <View style={[styles.card, { backgroundColor: cardBg }]}>
            <Text style={[styles.label, { color: colors.mutedForeground }]}>DESCRIPTIVE STATISTICS</Text>
            <StatRow label="Count" value={stats.count.toString()} colors={colors} sectionBg={sectionBg} />
            <StatRow label="Mean" value={stats.mean.toFixed(4)} colors={colors} sectionBg={sectionBg} />
            <StatRow label="Median" value={stats.median.toFixed(4)} colors={colors} sectionBg={sectionBg} />
            <StatRow label="Mode" value={stats.mode.join(", ")} colors={colors} sectionBg={sectionBg} />
            <StatRow label="Std Deviation" value={stats.std.toFixed(4)} colors={colors} sectionBg={sectionBg} />
            <StatRow label="Variance" value={stats.variance.toFixed(4)} colors={colors} sectionBg={sectionBg} />
            <StatRow label="Min" value={stats.min.toString()} colors={colors} sectionBg={sectionBg} />
            <StatRow label="Max" value={stats.max.toString()} colors={colors} sectionBg={sectionBg} />
            <StatRow label="Range" value={stats.range.toString()} colors={colors} sectionBg={sectionBg} />
            <StatRow label="Q1" value={stats.q1.toFixed(4)} colors={colors} sectionBg={sectionBg} />
            <StatRow label="Q3" value={stats.q3.toFixed(4)} colors={colors} sectionBg={sectionBg} />
            <StatRow label="IQR" value={stats.iqr.toFixed(4)} colors={colors} sectionBg={sectionBg} />
          </View>
        </>
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
  dataInput: { fontSize: 15, fontFamily: "Inter_400Regular", borderWidth: 1, borderRadius: 10, padding: 12, minHeight: 70 },
  sampleBtn: { marginRight: 8, paddingHorizontal: 14, paddingVertical: 7, borderRadius: 20, borderWidth: 1 },
  sampleBtnText: { fontSize: 12, fontFamily: "Inter_400Regular" },
  computeBtn: { borderRadius: 12, paddingVertical: 14, alignItems: "center" },
  computeBtnText: { color: "#FFF", fontSize: 16, fontFamily: "Inter_600SemiBold" },
});
