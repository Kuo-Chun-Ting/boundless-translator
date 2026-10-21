import type React from "react";
import {
  AbsoluteFill,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { clamp, colors, enter, exit } from "../theme";

// Ambient layer shared by every scene: the slanted glass plane and blue beam
// from the Glass feature images, drifting slowly for the whole video.
export const GlassBackground: React.FC = () => {
  const frame = useCurrentFrame();
  const { durationInFrames, width, height } = useVideoConfig();
  const drift = interpolate(frame, [0, durationInFrames], [0, -48]);
  return (
    <AbsoluteFill style={{ background: colors.page }}>
      <svg
        width={width}
        height={height}
        viewBox="0 0 1600 1000"
        preserveAspectRatio="xMidYMid slice"
        // The shapes run past the right edge of the view box; let them show
        // there so the drift never uncovers a strip of page colour.
        overflow="visible"
        style={{ position: "absolute", translate: `${drift}px 0px` }}
      >
        <defs>
          <linearGradient id="v2-blue" x1="0" y1="0" x2="1" y2=".7">
            <stop stopColor={colors.blue} />
            <stop offset=".58" stopColor={colors.sky} />
            <stop offset="1" stopColor={colors.cyan} />
          </linearGradient>
          <linearGradient id="v2-glass-fill" x1="0" y1="0" x2="1" y2="1">
            <stop stopColor="#ffffff" stopOpacity=".65" />
            <stop offset=".45" stopColor="#d5eeff" stopOpacity=".6" />
            <stop offset="1" stopColor="#7fdcf4" stopOpacity=".75" />
          </linearGradient>
          <linearGradient id="v2-glass-edge" x1="0" y1="0" x2="1" y2="1">
            <stop stopColor="#ffffff" />
            <stop offset=".42" stopColor="#b2edff" />
            <stop offset="1" stopColor="#229ce9" />
          </linearGradient>
          <filter id="v2-pane-shadow" x="-30%" y="-30%" width="160%" height="160%">
            <feGaussianBlur stdDeviation="16" />
          </filter>
        </defs>
        <path d="M280 1050 L1700 600 L1700 1100 Z" fill="url(#v2-blue)" opacity=".66" />
        <path
          d="M562 422 L1712 122 L1712 1072 L562 1372 Z"
          fill="#1262b7"
          opacity=".13"
          filter="url(#v2-pane-shadow)"
        />
        <path
          d="M550 410 L1700 110 L1700 1060 L550 1360 Z"
          fill="url(#v2-glass-fill)"
          stroke="url(#v2-glass-edge)"
          strokeWidth="3"
        />
        <path
          d="M556 1000 L556 415 L1700 117"
          fill="none"
          stroke="#ffffff"
          strokeOpacity=".88"
          strokeWidth="1.5"
        />
      </svg>
    </AbsoluteFill>
  );
};

// Fades a whole scene in and out over the shared background.
export const SceneFade: React.FC<{
  readonly children: React.ReactNode;
  readonly fadeIn?: number;
  readonly fadeOut?: number;
}> = ({ children, fadeIn = 10, fadeOut = 8 }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  return (
    <AbsoluteFill
      style={{
        opacity:
          interpolate(frame, [0, fadeIn], [0, 1], { ...clamp, easing: enter }) *
          interpolate(frame, [durationInFrames - fadeOut, durationInFrames], [1, 0], {
            ...clamp,
            easing: exit,
          }),
      }}
    >
      {children}
    </AbsoluteFill>
  );
};

