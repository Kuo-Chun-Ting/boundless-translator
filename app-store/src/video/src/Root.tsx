import { Composition } from "remotion";
import { FPS, HEIGHT, WIDTH } from "./theme";
import { PREVIEW_TOTAL_FRAMES, Preview } from "./scenes/Preview";

// Final: the screenshot translation cards use the card-slide "咻".
// Kept for comparison: the same video with the "woo" card sound.
export const RemotionRoot: React.FC = () => (
  <>
    <Composition id="PreviewShoo" component={Preview} defaultProps={{ cardSound: "sfx/kenney/card-shoo.wav", cardLead: 3 }} durationInFrames={PREVIEW_TOTAL_FRAMES} fps={FPS} width={WIDTH} height={HEIGHT} />
    <Composition id="PreviewWoo" component={Preview} defaultProps={{ cardSound: "sfx/kenney/card-woo.wav", cardLead: 0 }} durationInFrames={PREVIEW_TOTAL_FRAMES} fps={FPS} width={WIDTH} height={HEIGHT} />
  </>
);
