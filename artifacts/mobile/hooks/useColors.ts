import { useColorScheme } from "react-native";

import colors from "@/constants/colors";

/**
 * Returns the design tokens for the current color scheme.
 *
 * OVERKILL is a dark-first app. When no system preference is detected
 * (e.g. web preview environments), defaults to dark mode.
 */
export function useColors() {
  const scheme = useColorScheme() ?? "dark";
  const palette =
    scheme === "dark" && "dark" in colors
      ? (colors as Record<string, typeof colors.light>).dark
      : colors.light;
  return { ...palette, radius: colors.radius };
}
