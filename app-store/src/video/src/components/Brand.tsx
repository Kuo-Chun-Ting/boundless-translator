import type React from "react";
import { AbsoluteFill, Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { SceneFade } from "./Glass";
import { clamp, colors, enter, font } from "../theme";

const rise = (frame: number, delay: number, distance: number) => ({
  opacity: interpolate(frame, [delay, delay + 12], [0, 1], { ...clamp, easing: enter }),
  translate: `0px ${interpolate(frame, [delay, delay + 16], [distance, 0], { ...clamp, easing: enter })}px`,
});

// Closing brand card for the preview.
export const BrandCard: React.FC<{
  readonly tagline: string;
  // The end card carries the music credit and holds to the last frame.
  readonly end?: boolean;
}> = ({ tagline, end = false }) => {
  const frame = useCurrentFrame();
  return (
    <SceneFade fadeIn={end ? 8 : 1} fadeOut={end ? 1 : 8}>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", fontFamily: font, color: colors.ink }}>
        <Img
          src={staticFile("brand-sprite.png")}
          style={{ width: 220, height: 220, ...rise(frame, 0, 24), rotate: `${Math.sin(frame / 14) * 1.5}deg` }}
        />
        <div style={{ marginTop: 20, fontSize: 88, fontWeight: 600, letterSpacing: -3, ...rise(frame, 4, 20) }}>
          Boundless Translator
        </div>
        <div
          style={{
            marginTop: 12,
            fontSize: 36,
            fontWeight: 400,
            letterSpacing: -0.5,
            color: colors.sub,
            ...rise(frame, 8, 16),
          }}
        >
          {tagline}
        </div>
      </AbsoluteFill>
      {end ? (
        <div
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            bottom: 28,
            textAlign: "center",
            fontFamily: font,
            fontSize: 18,
            color: colors.sub,
            opacity: interpolate(frame, [10, 22], [0, 0.85], clamp),
          }}
        >
          Music: “Easy Lemon” by Kevin MacLeod (incompetech.com), licensed under CC BY 4.0
        </div>
      ) : null}
    </SceneFade>
  );
};
