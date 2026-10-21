import { Easing } from "remotion";

// Glass palette from app-store/src/image/glass/*.html.
export const colors = {
  page: "#f3f8ff",
  ink: "#10295d",
  sub: "#465e81",
  blue: "#1765ef",
  sky: "#149ff5",
  cyan: "#45d9eb",
};

export const font =
  '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Helvetica Neue", sans-serif';

export const SOURCE = { w: 3024, h: 1964 };

export const clamp = {
  extrapolateLeft: "clamp",
  extrapolateRight: "clamp",
} as const;

// One signature curve for entrances, one for exits, one for camera moves.
export const enter = Easing.bezier(0.2, 0, 0, 1);
export const exit = Easing.bezier(0.3, 0, 1, 1);
export const glide = Easing.bezier(0.4, 0, 0.2, 1);

export const glassPanel: React.CSSProperties = {
  background: "rgba(255, 255, 255, 0.82)",
  backdropFilter: "blur(18px) saturate(1.4)",
  border: "1.5px solid rgba(255, 255, 255, 0.95)",
  boxShadow:
    "0 0 0 1px rgba(23, 101, 239, 0.16), 0 14px 34px rgba(16, 41, 93, 0.22)",
};

export const windowShadow =
  "0 28px 70px rgba(20, 40, 60, 0.22), 0 4px 14px rgba(20, 40, 60, 0.10)";

// Mac App Store app preview: 1920 × 1080, 15–30 s, ≤ 30 fps.
export const WIDTH = 1920;
export const HEIGHT = 1080;
export const FPS = 30;

// The recording window.
export const STAGE = { x: 80, y: 44, w: 1760, h: 992 };

// Warm gold used for every action cue, as in the Glass feature images
// (app-store/src/image/components/beams.js, selected-text-arrow.js, the capture frame).
export const gold = {
  light: "#ffeac0",
  mid: "#f4ce85",
  base: "#e8b255",
  deep: "#bc8224",
  glow: "rgba(232, 178, 85, 0.55)",
};

// Small action labels use the Glass graphite, not the title blue.
export const graphite = "#555354";

export const cueSurface: React.CSSProperties = {
  background: "linear-gradient(180deg, rgba(255, 252, 244, 0.97), rgba(255, 244, 222, 0.95))",
  border: `1.5px solid ${gold.base}`,
  boxShadow: `0 0 0 4px rgba(232, 178, 85, 0.18), 0 0 26px ${gold.glow}, 0 10px 24px rgba(60, 40, 10, 0.18)`,
};

// Step-card titles: a warm near-black that reads on the cream card and stays
// clear of the selection blue.
export const ink = "#3a2a10";
