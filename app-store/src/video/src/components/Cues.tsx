import type React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import type { View } from "../timeline/Stage";
import { clamp, enter, exit, font } from "../theme";
import { gold } from "../theme";

// White speech bubbles stand out against the cream menu. Their gold rim
// and glow match the beams and capture frame in the Glass feature images.
// Every bubble uses one text style; a step card only adds its keys.
// Gold marks (target, hover, capture) get a white rim for the same reason:
//   step card  – one line on why and one on what to do, beside the spot that
//                is about to change. Appears on a still frame before anything
//                moves.
//   label      – a short follow-up action in the same step.
// Targets, clicks, hovers and the capture flash share the same gold.
// The camera only moves when no cue is appearing.

// A view for scenes without a recording: output pixels map to themselves.
export const useStaticView = (): View => {
  const frame = useCurrentFrame();
  return { frame, scale: 1, map: (x, y) => ({ x, y }) };
};

const card = "#f8fbff";

export const cueSurface: React.CSSProperties = {
  background: `linear-gradient(180deg, #ffffff, ${card})`,
  border: `1.5px solid ${gold.base}`,
};

// The glow and shadow wrap the bubble and its pointer as one shape.
export const bubbleGlow = `drop-shadow(0 0 12px ${gold.glow}) drop-shadow(0 8px 14px rgba(16, 41, 93, 0.14))`;

export const text: React.CSSProperties = {
  fontFamily: font,
  fontSize: 34,
  fontWeight: 600,
  letterSpacing: -0.4,
  lineHeight: 1.15,
  color: "#2c2c2e",
};

// White rim under gold marks, so they hold on cream.
const rim = "0 0 0 2px #ffffff";

type Side = "above" | "below" | "left" | "right";

export const show = (f: number, from: number, to: number) =>
  interpolate(f, [from, from + 8], [0, 1], { ...clamp, easing: enter }) *
  interpolate(f, [to, to + 6], [1, 0], { ...clamp, easing: exit });

// Offset a box from an anchor so it never covers the anchor itself.
const offset = (side: Side, gap: number) => {
  switch (side) {
    case "above":
      return {
        translate: `-50% calc(-100% - ${gap}px)`,
        origin: "center bottom",
      };
    case "below":
      return { translate: `-50% ${gap}px`, origin: "center top" };
    case "left":
      return {
        translate: `calc(-100% - ${gap}px) -50%`,
        origin: "right center",
      };
    case "right":
      return { translate: `${gap}px -50%`, origin: "left center" };
  }
};

// Small pointer on the edge facing the anchor.
const Pointer: React.FC<{ readonly side: Side }> = ({ side }) => {
  const s = 16;
  const common: React.CSSProperties = {
    position: "absolute",
    width: s,
    height: s,
    background: card,
    borderRight: `1.5px solid ${gold.base}`,
    borderBottom: `1.5px solid ${gold.base}`,
  };
  switch (side) {
    case "above":
      return (
        <div
          style={{
            ...common,
            left: "50%",
            bottom: -s / 2 - 1,
            translate: "-50% 0px",
            rotate: "45deg",
          }}
        />
      );
    case "below":
      return (
        <div
          style={{
            ...common,
            left: "50%",
            top: -s / 2 - 1,
            translate: "-50% 0px",
            rotate: "225deg",
          }}
        />
      );
    case "left":
      return (
        <div
          style={{
            ...common,
            top: "50%",
            right: -s / 2 - 1,
            translate: "0px -50%",
            rotate: "-45deg",
          }}
        />
      );
    case "right":
      return (
        <div
          style={{
            ...common,
            top: "50%",
            left: -s / 2 - 1,
            translate: "0px -50%",
            rotate: "135deg",
          }}
        />
      );
  }
};

type At = { x: number; y: number };

type LabelProps = {
  readonly view: View;
  readonly anchor: At;
  readonly side: Side;
  readonly from: number;
  readonly to: number;
  readonly children: React.ReactNode;
};

// Gold action label: what to do, right where it happens.
export const GoldLabel: React.FC<LabelProps> = ({
  view,
  anchor,
  side,
  from,
  to,
  children,
}) => {
  const f = view.frame;
  if (f < from || f > to + 6) {
    return null;
  }
  const v = show(f, from, to);
  const p = view.map(anchor.x, anchor.y);
  const o = offset(side, 26);
  return (
    <div
      style={{
        position: "absolute",
        left: p.x,
        top: p.y,
        translate: o.translate,
        filter: bubbleGlow,
      }}
    >
      <div
        style={{
          position: "relative",
          padding: "14px 22px 15px",
          borderRadius: 14,
          ...text,
          whiteSpace: "nowrap",
          ...cueSurface,
          opacity: v,
          scale: String(0.94 + 0.06 * v),
          transformOrigin: o.origin,
        }}
      >
        {children}
        <Pointer side={side} />
      </div>
    </div>
  );
};

export const KEY_STAGGER = 3;

// One keycap; it sinks and fills with gold while pressed.
const Keycap: React.FC<{ readonly label: string; readonly down: number }> = ({
  label,
  down,
}) => (
  <div
    style={{
      width: 60,
      height: 60,
      borderRadius: 14,
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      ...text,
      fontSize: 31,
      color: text.color,
      background:
        down > 0
          ? `linear-gradient(180deg, ${gold.mid}, ${gold.base})`
          : "linear-gradient(180deg, #ffffff, #f7f3ec)",
      border: `1.5px solid ${down > 0 ? gold.deep : "rgba(188, 130, 36, 0.45)"}`,
      boxShadow: `0 ${4 - 3 * down}px 0 rgba(120, 80, 20, ${0.35 - 0.15 * down})${
        down > 0 ? `, 0 0 ${18 * down}px ${gold.glow}` : ""
      }`,
      translate: `0px ${3 * down}px`,
    }}
  >
    {label}
  </div>
);

type CardProps = {
  readonly view: View;
  readonly anchor: At;
  readonly side: Side;
  readonly from: number;
  readonly to: number;
  // What this step is for.
  readonly title: string;
  // The shortcut keys, if this step is a key press.
  readonly keys?: string[];
  // Frame the first key goes down.
  readonly press?: number;
};

// Gold step card: what this step is for, and its keys if any, placed beside
// the spot that is about to change. It appears on a still frame, stays while
// the action happens, and leaves once the result is on screen.
export const GoldCard: React.FC<CardProps> = ({
  view,
  anchor,
  side,
  from,
  to,
  title,
  keys,
  press = 0,
}) => {
  const f = view.frame;
  if (f < from || f > to + 6) {
    return null;
  }
  const v = show(f, from, to);
  const p = view.map(anchor.x, anchor.y);
  const o = offset(side, 24);
  return (
    <div
      style={{
        position: "absolute",
        left: p.x,
        top: p.y,
        translate: o.translate,
        filter: bubbleGlow,
      }}
    >
      <div
        style={{
          position: "relative",
          padding: "16px 24px 18px",
          borderRadius: 20,
          display: "flex",
          flexDirection: "column",
          gap: 12,
          whiteSpace: "nowrap",
          ...cueSurface,
          opacity: v,
          scale: String(0.94 + 0.06 * v),
          transformOrigin: o.origin,
        }}
      >
        <div style={text}>{title}</div>
        {keys ? (
          <div style={{ display: "flex", gap: 10 }}>
            {keys.map((k, i) => {
              const at = press + i * KEY_STAGGER;
              return (
                <Keycap
                  key={k}
                  label={k}
                  down={interpolate(
                    f,
                    [at - 1, at, at + 6],
                    [0, 1, 0.7],
                    clamp,
                  )}
                />
              );
            })}
          </div>
        ) : null}
        <Pointer side={side} />
      </div>
    </div>
  );
};

// Before every press that starts an action (a click, or the start of a drag):
// a gold ring on the spot, from the step's cue until the press. Hovers use
// GoldHover and key presses have no pointer, so neither gets a ring.
export const GoldTarget: React.FC<{
  readonly view: View;
  readonly at: At;
  readonly from: number;
  readonly to: number;
}> = ({ view, at, from, to }) => {
  const f = view.frame;
  if (f < from || f > to + 6) {
    return null;
  }
  const v = show(f, from, to);
  const p = view.map(at.x, at.y);
  const pulse = 1 + 0.1 * Math.sin(((f - from) / 24) * Math.PI * 2);
  const r = 30 * pulse;
  return (
    <div style={{ position: "absolute", left: p.x, top: p.y, opacity: v }}>
      <div
        style={{
          position: "absolute",
          left: -r,
          top: -r,
          width: r * 2,
          height: r * 2,
          borderRadius: "50%",
          border: `3px solid ${gold.base}`,
          boxShadow: `${rim}, inset ${rim}, 0 0 18px ${gold.glow}`,
        }}
      />
    </div>
  );
};

// The click: a gold flash and expanding ring, synced to the click sound.
export const GoldClick: React.FC<{
  readonly view: View;
  readonly at: At;
  readonly frame: number;
  // Output frame the click's result covers the spot (e.g. a popup); the ring
  // is gone by then instead of drawing over it.
  readonly until?: number;
}> = ({ view, at, frame, until }) => {
  const f = view.frame - frame;
  if (f < 0 || f > 18 || (until !== undefined && view.frame >= until)) {
    return null;
  }
  const p = view.map(at.x, at.y);
  const r = interpolate(f, [0, 18], [16, 70], { ...clamp, easing: enter });
  return (
    <div style={{ position: "absolute", left: p.x, top: p.y }}>
      <div
        style={{
          position: "absolute",
          left: -18,
          top: -18,
          width: 36,
          height: 36,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${gold.light}, ${gold.base})`,
          opacity: interpolate(f, [0, 2, 10], [0, 0.85, 0], clamp),
        }}
      />
      <div
        style={{
          position: "absolute",
          left: -r,
          top: -r,
          width: r * 2,
          height: r * 2,
          borderRadius: "50%",
          border: `4px solid ${gold.base}`,
          boxShadow: `${rim}, 0 0 16px ${gold.glow}`,
          opacity: interpolate(f, [0, 18], [1, 0], clamp),
        }}
      />
    </div>
  );
};

type Rect = { x0: number; y0: number; x1: number; y1: number };

// Hover: a steady, softly breathing gold outline. No ripple and no sound.
export const GoldHover: React.FC<{
  readonly view: View;
  readonly rect: Rect;
  readonly from: number;
  readonly to: number;
}> = ({ view, rect, from, to }) => {
  const f = view.frame;
  if (f < from || f > to + 6) {
    return null;
  }
  const a = view.map(rect.x0, rect.y0);
  const b = view.map(rect.x1, rect.y1);
  const breathe = 0.7 + 0.3 * Math.sin(((f - from) / 36) * Math.PI * 2);
  return (
    <div
      style={{
        position: "absolute",
        left: a.x - 8,
        top: a.y - 8,
        width: b.x - a.x + 16,
        height: b.y - a.y + 16,
        borderRadius: 14,
        border: `2.5px dashed ${gold.base}`,
        boxShadow: `${rim}, 0 0 ${20 * breathe}px ${gold.glow}`,
        opacity: show(f, from, to),
      }}
    />
  );
};

// Screenshot taken: a gold frame with glowing corner dots, like the capture
// frame in the Glass images. Ends before the screenshot window appears.
export const GoldCapture: React.FC<{
  readonly view: View;
  readonly rect: Rect;
  readonly frame: number;
  readonly until: number;
}> = ({ view, rect, frame, until }) => {
  const f = view.frame - frame;
  if (f < 0 || view.frame >= until) {
    return null;
  }
  const a = view.map(rect.x0, rect.y0);
  const b = view.map(rect.x1, rect.y1);
  const v = interpolate(f, [0, 2], [0, 1], clamp);
  const dot: React.CSSProperties = {
    position: "absolute",
    width: 14,
    height: 14,
    borderRadius: "50%",
    background: `radial-gradient(circle, #fff, ${gold.base})`,
    boxShadow: `0 0 14px ${gold.base}`,
  };
  return (
    <div
      style={{
        position: "absolute",
        left: a.x,
        top: a.y,
        width: b.x - a.x,
        height: b.y - a.y,
        border: `3px solid ${gold.base}`,
        borderRadius: 6,
        boxShadow: `${rim}, 0 0 22px ${gold.glow}`,
        background: `rgba(255, 244, 222, ${interpolate(f, [0, 2, 8], [0, 0.5, 0], clamp)})`,
        opacity: v,
      }}
    >
      <div style={{ ...dot, left: -8, top: -8 }} />
      <div style={{ ...dot, right: -8, top: -8 }} />
      <div style={{ ...dot, left: -8, bottom: -8 }} />
      <div style={{ ...dot, right: -8, bottom: -8 }} />
    </div>
  );
};
