import { Audio } from "@remotion/media";
import type React from "react";
import { interpolate, staticFile, useCurrentFrame, useVideoConfig } from "remotion";

// Easy Lemon under the interface sounds; its peaks stay well below theirs.
const MUSIC_VOLUME = 0.25;

export const Music: React.FC = () => {
  const frame = useCurrentFrame();
  const { durationInFrames, fps } = useVideoConfig();
  return (
    <Audio
      name="Music: Easy Lemon"
      src={staticFile("audio/easy-lemon.mp3")}
      durationInFrames={durationInFrames}
      volume={
        MUSIC_VOLUME *
        interpolate(frame, [0, 0.6 * fps], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }) *
        interpolate(frame, [durationInFrames - 1.5 * fps, durationInFrames], [1, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        })
      }
    />
  );
};
