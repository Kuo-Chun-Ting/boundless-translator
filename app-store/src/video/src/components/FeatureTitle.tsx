import type React from "react";
import { AbsoluteFill, Easing, interpolate, useCurrentFrame } from "remotion";
import { colors, font } from "../theme";

// A feature chapter opens on the Glass background alone, like the brand end
// card: the feature name, set as the end card sets "Boundless Translator",
// then the recording window rises in under it. Nothing covers the recording.
//
// Motion: one premium curve. The title rises 18px as it fades in, holds and
// leaves; only then does the window rise in, so the two never overlap. The
// first step cue waits until the window has settled.
const premium = Easing.bezier(0.4, 0, 0.2, 1);
const IN = 12;
const READ = 40;
const OUT = 9;

const TITLE_END = IN + READ + OUT;
const WINDOW_IN = 14;

// Frames from the start of a demo until its first step may begin.
export const TITLE_HOLD = TITLE_END + WINDOW_IN;

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

export const FeatureTitle: React.FC<{ readonly children: string }> = ({
  children,
}) => {
  const f = useCurrentFrame();
  if (f > TITLE_END) {
    return null;
  }
  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
      <div
        style={{
          fontFamily: font,
          fontSize: 88,
          fontWeight: 600,
          letterSpacing: -2,
          lineHeight: 1.05,
          color: colors.ink,
          opacity:
            interpolate(f, [0, IN], [0, 1], { ...clamp, easing: premium }) *
            interpolate(f, [TITLE_END - OUT, TITLE_END], [1, 0], {
              ...clamp,
              easing: premium,
            }),
          translate: `0px ${
            interpolate(f, [0, IN], [18, 0], { ...clamp, easing: premium }) +
            interpolate(f, [TITLE_END - OUT, TITLE_END], [0, -10], {
              ...clamp,
              easing: premium,
            })
          }px`,
        }}
      >
        {children}
      </div>
    </AbsoluteFill>
  );
};

// Holds the recording window back until the title leaves, then lets it rise in.
export const AfterTitle: React.FC<{ readonly children: React.ReactNode }> = ({
  children,
}) => {
  const f = useCurrentFrame();
  const start = TITLE_END;
  return (
    <AbsoluteFill
      style={{
        opacity: interpolate(f, [start, start + WINDOW_IN - 2], [0, 1], {
          ...clamp,
          easing: premium,
        }),
        translate: `0px ${interpolate(f, [start, start + WINDOW_IN], [24, 0], { ...clamp, easing: premium })}px`,
      }}
    >
      {children}
    </AbsoluteFill>
  );
};
