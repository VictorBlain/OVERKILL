import React, { useCallback, useMemo, useRef, useState } from "react";
import {
  PanResponder,
  Platform,
  useColorScheme,
  View,
  type LayoutChangeEvent,
} from "react-native";
import { G, Line, Path, Svg, Text as SvgText } from "react-native-svg";
import type { GraphFunction } from "@/context/AppContext";

interface Viewport {
  xMin: number;
  xMax: number;
  yMin: number;
  yMax: number;
}

interface Props {
  functions: GraphFunction[];
}

const SAMPLE_COUNT = 400;
const DEFAULT_VIEWPORT: Viewport = {
  xMin: -10,
  xMax: 10,
  yMin: -10,
  yMax: 10,
};

function niceStep(range: number, targetLines = 8): number {
  const rough = range / targetLines;
  const mag = Math.pow(10, Math.floor(Math.log10(Math.abs(rough) || 1)));
  const n = rough / mag;
  if (n <= 1) return mag;
  if (n <= 2) return 2 * mag;
  if (n <= 5) return 5 * mag;
  return 10 * mag;
}

function safeEval(expr: string, x: number): number | null {
  try {
    const js = expr
      .replace(/\^/g, "**")
      .replace(/\be\b/g, String(Math.E))
      .replace(/\bpi\b/g, String(Math.PI))
      .replace(/\bPI\b/g, String(Math.PI))
      .replace(/\bE\b/g, String(Math.E))
      .replace(/\bsin\s*\(/g, "Math.sin(")
      .replace(/\bcos\s*\(/g, "Math.cos(")
      .replace(/\btan\s*\(/g, "Math.tan(")
      .replace(/\basin\s*\(/g, "Math.asin(")
      .replace(/\bacos\s*\(/g, "Math.acos(")
      .replace(/\batan\s*\(/g, "Math.atan(")
      .replace(/\bexp\s*\(/g, "Math.exp(")
      .replace(/\bsqrt\s*\(/g, "Math.sqrt(")
      .replace(/\babs\s*\(/g, "Math.abs(")
      .replace(/\bceil\s*\(/g, "Math.ceil(")
      .replace(/\bfloor\s*\(/g, "Math.floor(")
      .replace(/\blog\s*\(/g, "Math.log(")
      .replace(/\bln\s*\(/g, "Math.log(")
      .replace(/\blog10\s*\(/g, "Math.log10(")
      .replace(/\blog2\s*\(/g, "Math.log2(")
      .replace(/\bpow\s*\(/g, "Math.pow(")
      .replace(/\bsign\s*\(/g, "Math.sign(")
      .replace(/\bmax\s*\(/g, "Math.max(")
      .replace(/\bmin\s*\(/g, "Math.min(");

    // eslint-disable-next-line no-new-func
    const fn = new Function("x", `"use strict"; return (${js});`);
    const result = fn(x);
    if (typeof result !== "number" || !isFinite(result) || isNaN(result)) return null;
    return result;
  } catch {
    return null;
  }
}

function buildPath(
  expr: string,
  vp: Viewport,
  w: number,
  h: number
): string {
  const { xMin, xMax, yMin, yMax } = vp;
  const xRange = xMax - xMin;
  const yRange = yMax - yMin;

  const toSX = (x: number) => ((x - xMin) / xRange) * w;
  const toSY = (y: number) => h - ((y - yMin) / yRange) * h;

  let d = "";
  let prevY: number | null = null;
  let penDown = false;

  for (let i = 0; i <= SAMPLE_COUNT; i++) {
    const x = xMin + (i / SAMPLE_COUNT) * xRange;
    const y = safeEval(expr, x);

    if (y === null || y < yMin - yRange * 2 || y > yMax + yRange * 2) {
      penDown = false;
      prevY = null;
      continue;
    }

    const big = prevY !== null && Math.abs(y - prevY) > yRange * 5;
    if (big) {
      penDown = false;
    }

    const sx = toSX(x).toFixed(2);
    const sy = toSY(y).toFixed(2);

    if (!penDown) {
      d += `M${sx} ${sy} `;
      penDown = true;
    } else {
      d += `L${sx} ${sy} `;
    }
    prevY = y;
  }
  return d;
}

export default function GraphCanvas({ functions }: Props) {
  const [viewport, setViewport] = useState<Viewport>(DEFAULT_VIEWPORT);
  const [size, setSize] = useState({ width: 0, height: 0 });
  const colorScheme = useColorScheme() ?? "dark";
  const isDark = colorScheme === "dark";

  const vpRef = useRef(viewport);
  vpRef.current = viewport;
  const sizeRef = useRef(size);
  sizeRef.current = size;

  const gestureRef = useRef({
    prevX: 0,
    prevY: 0,
    prevDist: 0,
    pinching: false,
    pinchCenterMathX: 0,
    pinchCenterMathY: 0,
  });

  const onLayout = useCallback((e: LayoutChangeEvent) => {
    const { width, height } = e.nativeEvent.layout;
    if (width > 0 && height > 0) setSize({ width, height });
  }, []);

  const panResponder = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: () => true,
        onPanResponderGrant: (evt) => {
          const touches = evt.nativeEvent.touches;
          const g = gestureRef.current;
          if (touches.length >= 2) {
            const t0 = touches[0];
            const t1 = touches[1];
            const dx = t1.pageX - t0.pageX;
            const dy = t1.pageY - t0.pageY;
            g.prevDist = Math.sqrt(dx * dx + dy * dy);
            g.pinching = true;
            const w = sizeRef.current.width || 1;
            const h = sizeRef.current.height || 1;
            const cxScreen = (t0.pageX + t1.pageX) / 2;
            const cyScreen = (t0.pageY + t1.pageY) / 2;
            const vp = vpRef.current;
            g.pinchCenterMathX = vp.xMin + (cxScreen / w) * (vp.xMax - vp.xMin);
            g.pinchCenterMathY = vp.yMax - (cyScreen / h) * (vp.yMax - vp.yMin);
          } else if (touches.length === 1) {
            g.prevX = touches[0].pageX;
            g.prevY = touches[0].pageY;
            g.pinching = false;
          }
        },
        onPanResponderMove: (evt) => {
          const touches = evt.nativeEvent.touches;
          const g = gestureRef.current;
          const w = sizeRef.current.width || 1;
          const h = sizeRef.current.height || 1;

          if (touches.length >= 2 && g.pinching) {
            const t0 = touches[0];
            const t1 = touches[1];
            const dx = t1.pageX - t0.pageX;
            const dy = t1.pageY - t0.pageY;
            const dist = Math.sqrt(dx * dx + dy * dy);
            if (g.prevDist === 0) { g.prevDist = dist; return; }
            const scale = g.prevDist / dist;
            g.prevDist = dist;
            const cx = g.pinchCenterMathX;
            const cy = g.pinchCenterMathY;
            setViewport((prev) => {
              const halfW = Math.min(Math.max(((prev.xMax - prev.xMin) / 2) * scale, 0.001), 1e5);
              const halfH = Math.min(Math.max(((prev.yMax - prev.yMin) / 2) * scale, 0.001), 1e5);
              return { xMin: cx - halfW, xMax: cx + halfW, yMin: cy - halfH, yMax: cy + halfH };
            });
          } else if (touches.length === 1 && !g.pinching) {
            const touch = touches[0];
            const dsx = touch.pageX - g.prevX;
            const dsy = touch.pageY - g.prevY;
            g.prevX = touch.pageX;
            g.prevY = touch.pageY;
            setViewport((prev) => {
              const dmx = -(dsx / w) * (prev.xMax - prev.xMin);
              const dmy = (dsy / h) * (prev.yMax - prev.yMin);
              return { xMin: prev.xMin + dmx, xMax: prev.xMax + dmx, yMin: prev.yMin + dmy, yMax: prev.yMax + dmy };
            });
          }
        },
        onPanResponderRelease: () => { gestureRef.current.pinching = false; },
        onPanResponderTerminate: () => { gestureRef.current.pinching = false; },
      }),
    []
  );

  const { width, height } = size;

  const gridColor = isDark ? "#2C2C2E" : "#D1D1D6";
  const axisColor = isDark ? "#48484A" : "#AEAEB2";
  const labelColor = isDark ? "#8E8E93" : "#636366";
  const bgColor = isDark ? "#000000" : "#F2F2F7";

  const xRange = viewport.xMax - viewport.xMin;
  const yRange = viewport.yMax - viewport.yMin;
  const xStep = niceStep(xRange);
  const yStep = niceStep(yRange);

  const toSX = (x: number) => ((x - viewport.xMin) / xRange) * width;
  const toSY = (y: number) => height - ((y - viewport.yMin) / yRange) * height;

  const xStart = Math.ceil(viewport.xMin / xStep) * xStep;
  const yStart = Math.ceil(viewport.yMin / yStep) * yStep;

  const vertLines: number[] = [];
  for (let x = xStart; x <= viewport.xMax + 1e-9; x += xStep) vertLines.push(x);
  const horizLines: number[] = [];
  for (let y = yStart; y <= viewport.yMax + 1e-9; y += yStep) horizLines.push(y);

  const paths = useMemo(() => {
    if (width === 0 || height === 0) return [];
    return functions
      .filter((f) => f.visible && f.expression.trim())
      .map((f) => ({
        id: f.id,
        color: f.color,
        d: buildPath(f.expression, viewport, width, height),
      }));
  }, [functions, viewport, width, height]);

  const axisX = toSX(0);
  const axisY = toSY(0);

  return (
    <View style={{ flex: 1, backgroundColor: bgColor }} onLayout={onLayout} {...panResponder.panHandlers}>
      {width > 0 && height > 0 && (
        <Svg width={width} height={height}>
          {vertLines.map((x, i) => {
            const sx = toSX(x);
            const isAxis = Math.abs(x) < xStep * 0.01;
            const label = x % 1 === 0 ? x.toFixed(0) : x.toPrecision(2);
            return (
              <G key={`v${i}`}>
                <Line x1={sx} y1={0} x2={sx} y2={height} stroke={isAxis ? axisColor : gridColor} strokeWidth={isAxis ? 1.5 : 0.5} />
                {!isAxis && (
                  <SvgText x={sx + 3} y={Math.min(Math.max(axisY + 14, 14), height - 4)} fill={labelColor} fontSize={9}>{label}</SvgText>
                )}
              </G>
            );
          })}
          {horizLines.map((y, i) => {
            const sy = toSY(y);
            const isAxis = Math.abs(y) < yStep * 0.01;
            const label = y % 1 === 0 ? y.toFixed(0) : y.toPrecision(2);
            return (
              <G key={`h${i}`}>
                <Line x1={0} y1={sy} x2={width} y2={sy} stroke={isAxis ? axisColor : gridColor} strokeWidth={isAxis ? 1.5 : 0.5} />
                {!isAxis && (
                  <SvgText x={Math.min(Math.max(axisX + 4, 4), width - 28)} y={sy - 3} fill={labelColor} fontSize={9}>{label}</SvgText>
                )}
              </G>
            );
          })}
          {paths.map((p) =>
            p.d ? (
              <Path key={p.id} d={p.d} stroke={p.color} strokeWidth={2.5} fill="none" strokeLinecap="round" strokeLinejoin="round" />
            ) : null
          )}
        </Svg>
      )}
    </View>
  );
}
