import type React from "react";
import { useMemo } from "react";
import { interpolate } from "remotion";
import type { View } from "../timeline/Stage";
import { clamp, enter, font } from "../theme";
export const NOTE = ["See definitions in your", "Mac’s built-in dictionary."];

// The Mac dictionary is third-party content, so its definitions are hidden
// under the same gold dust as the Glass dictionary image
// (app-store/src/image/glass/dictionary-blur-options.html, #option-2-dust): a blur, a
// light mist, seeded motes in the wizard's beam colours, and a note in the
// page ink.
// Same text colour and weight as the action cues.
const INK = "#2c2c2e";
const MOTES = [
  "255, 241, 207",
  "244, 206, 133",
  "228, 172, 74",
  "255, 236, 195",
];

type Rect = { x0: number; y0: number; x1: number; y1: number };

const rng = (seed: number) => () => {
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};

const gauss = (r: () => number) =>
  Math.sqrt(-2 * Math.log(1 - r())) * Math.cos(2 * Math.PI * r());

// Motes in source pixels: dense near the centre, thinning toward the edges.
const useMotes = (w: number, h: number, seed: number) =>
  useMemo(() => {
    const r = rng(seed);
    const count = Math.round((w * h) / 260);
    const motes = [];
    for (let i = 0; i < count; i++) {
      const x = w / 2 + gauss(r) * w * 0.3;
      const y = h / 2 + gauss(r) * h * 0.26;
      if (x < 4 || y < 4 || x > w - 4 || y > h - 4) {
        continue;
      }
      const glow = r() < 0.1;
      motes.push({
        x,
        y,
        size: 0.7 + Math.pow(r(), 3) * 3.2 + (glow ? 1 : 0),
        colour: MOTES[Math.floor(r() * MOTES.length)],
        alpha: Math.min(1, 0.25 + r() * 0.6 + (glow ? 0.3 : 0)),
        glow,
        phase: r() * Math.PI * 2,
      });
    }
    return motes;
  }, [w, h, seed]);

const Sparkle: React.FC<{ readonly size: number }> = ({ size }) => (
  <svg
    width={size}
    height={size}
    viewBox="-10 -10 20 20"
    aria-hidden="true"
    style={{ flex: "none" }}
  >
    <defs>
      <radialGradient id="veil-spark">
        <stop offset="0" stopColor="#fff6dc" />
        <stop offset=".55" stopColor="#f4ce85" />
        <stop offset="1" stopColor="#e4ac4a" />
      </radialGradient>
    </defs>
    <path
      d="M0 -9 C1 -2 2 -1 9 0 C2 1 1 2 0 9 C-1 2 -2 1 -9 0 C-2 -1 -1 -2 0 -9Z"
      fill="url(#veil-spark)"
      style={{ filter: "drop-shadow(0 0 1.6px #efc26c)" }}
    />
  </svg>
);

export const DictionaryVeil: React.FC<{
  readonly view: View;
  // Definitions only, in source pixels; the dictionary name and headword stay clear.
  readonly rect: Rect;
  // Output frame the dictionary is on screen.
  readonly from: number;
  readonly seed: number;
  // Frames to reach full cover. Use 1 when `from` is the first frame of the
  // popup's own animation, so no definition is ever readable.
  readonly fadeIn?: number;
  // Last output frame to draw, for a cover that only bridges the popup's
  // grow animation; and whether to show the note (off for such a cover).
  readonly to?: number;
  readonly note?: boolean;
}> = ({ view, rect, from, seed, fadeIn = 8, to, note = true }) => {
  const w = rect.x1 - rect.x0;
  const h = rect.y1 - rect.y0;
  const motes = useMotes(w, h, seed);
  const f = view.frame;
  if (f < from || (to !== undefined && f > to)) {
    return null;
  }
  const a = view.map(rect.x0, rect.y0);
  const s = view.scale;
  const feather = `linear-gradient(90deg, transparent, #000 ${14 * s}px, #000 calc(100% - ${14 * s}px), transparent)`;
  return (
    <div
      style={{
        position: "absolute",
        left: a.x,
        top: a.y,
        width: w * s,
        height: h * s,
        borderRadius: 8 * s,
        overflow: "hidden",
        backdropFilter: `blur(${22 * s}px)`,
        background: "rgba(255, 252, 246, 0.55)",
        maskImage: feather,
        opacity: interpolate(f, [from, from + fadeIn], [0, 1], {
          ...clamp,
          easing: enter,
        }),
      }}
    >
      <svg
        viewBox={`0 0 ${w} ${h}`}
        preserveAspectRatio="none"
        style={{
          position: "absolute",
          inset: 0,
          width: "100%",
          height: "100%",
        }}
      >
        <defs>
          <radialGradient id={`veil-mist-${seed}`} cx="50%" cy="50%" r="55%">
            <stop offset="0" stopColor="rgb(255, 248, 232)" stopOpacity=".72" />
            <stop
              offset=".55"
              stopColor="rgb(255, 242, 214)"
              stopOpacity=".3"
            />
            <stop offset="1" stopColor="rgb(255, 242, 214)" stopOpacity="0" />
          </radialGradient>
        </defs>
        <rect width={w} height={h} fill={`url(#veil-mist-${seed})`} />
        {motes.map((m, i) => (
          <circle
            key={i}
            cx={m.x}
            cy={m.y}
            r={m.size}
            fill={`rgba(${m.colour}, ${(m.alpha * (0.75 + 0.25 * Math.sin(f / 9 + m.phase))).toFixed(3)})`}
            style={
              m.glow
                ? { filter: "drop-shadow(0 0 4px rgba(237, 171, 63, 0.75))" }
                : undefined
            }
          />
        ))}
      </svg>
      {note ? (
        <div
          style={{
            position: "absolute",
            inset: 0,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 12 * s,
            fontFamily: font,
            fontSize: 30 * s,
            lineHeight: 1.36,
            fontWeight: 600,
            letterSpacing: -0.2,
            color: INK,
            textAlign: "center",
          }}
        >
          <Sparkle size={30 * s} />
          <div>
            {NOTE[0]}
            <br />
            {NOTE[1]}
          </div>
        </div>
      ) : null}
    </div>
  );
};
