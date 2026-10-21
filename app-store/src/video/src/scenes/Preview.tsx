import type React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { GlassBackground } from "../components/Glass";
import { Music } from "../components/Music";
import { BrandCard } from "../components/Brand";
import { MENU_FRAMES, ScreenshotDemo } from "./ScreenshotDemo";
import { PREVIEW_FRAMES, SelectedTextDemo } from "./SelectedTextDemo";

// No opening brand card: each demo opens on its feature name, and the brand
// closes the preview.
const ENDING = 45;

const SELECTED_FROM = 0;
const SCREENSHOT_FROM = SELECTED_FROM + PREVIEW_FRAMES;
const ENDING_FROM = SCREENSHOT_FROM + MENU_FRAMES;

export const PREVIEW_TOTAL_FRAMES = ENDING_FROM + ENDING;

// Both demos share the background and music; each screenshot translation
// card plays the selected sound.
export const Preview: React.FC<{
  readonly cardSound: string;
  readonly cardLead: number;
}> = ({ cardSound, cardLead }) => (
  <AbsoluteFill>
    <GlassBackground />
    <Sequence
      name="Selected text"
      from={SELECTED_FROM}
      durationInFrames={PREVIEW_FRAMES}
    >
      <SelectedTextDemo />
    </Sequence>
    <Sequence
      name="Screenshot"
      from={SCREENSHOT_FROM}
      durationInFrames={MENU_FRAMES}
    >
      <ScreenshotDemo cardSound={cardSound} cardLead={cardLead} />
    </Sequence>
    <Sequence name="Ending" from={ENDING_FROM} durationInFrames={ENDING}>
      <BrandCard tagline="Translate in any app or website." end />
    </Sequence>
    <Music />
  </AbsoluteFill>
);
