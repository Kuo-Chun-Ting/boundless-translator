import { Audio } from "@remotion/media";
import type React from "react";
import { staticFile } from "remotion";
import { SceneFade } from "../components/Glass";
import { outFrame, Stage } from "../timeline/Stage";
import { type CamPos, timeline } from "../timeline/beats";
import { GoldCard, GoldClick, GoldTarget, KEY_STAGGER } from "../components/Cues";
import { STAGE } from "../theme";
import { NOTE, DictionaryVeil } from "../components/DictionaryVeil";
import { holdFor, readChars, readTime, FADE } from "../timeline/read";
import { AfterTitle, FeatureTitle, TITLE_HOLD } from "../components/FeatureTitle";

// assets/recording/selected-text-translation.mov as media/preview-selected.mp4
// (30 fps). Source events (frames):
//   56–68 drag-select the sentence · 93 ⌘⇧1 · 96 translation window opens
//   117 translation shown · 171 double-click "shortcut" · 204 click the book
//   206 Mac dictionary starts to pop up · 208 fully shown
// Inset past the recorded window border, including its rounded corners.
// Remove 8 source pixels on each side and start 4 pixels below the white edge.
const PAGE: CamPos = {
  x: 1512,
  y: 70 + (STAGE.h * 3008) / (2 * STAGE.w),
  w: 3008,
};
// The end of the selected sentence with the translation window, then the
// window with its dictionary, so each result stays next to where it came from.
const TRANSLATION: CamPos = { x: 1660, y: 740, w: 1700 };
const DICTIONARY: CamPos = { x: 1813, y: 1040, w: 1900 };

const TITLE = "Selected Text Translation";
const SELECT = "Select text to translate";
const LOOKUP = "Open dictionary";
const RESULT = "選擇一個句子，然後按快捷鍵進行翻譯。";

// Every cue gets the reading time of read.ts before its action: a still
// hold, minus the frames the next segment plays before the action (the last
// argument). Results hold for their character count. Only pointer travel
// between actions is cut or sped up.
const T = timeline(PAGE, [
  { id: "title", at: 52, dur: TITLE_HOLD, freeze: true },
  { id: "card-select", at: 52, dur: holdFor(SELECT, 1, 4), freeze: true },
  { id: "drag", at: 52, dur: 17 }, // drag starts at 56
  // Keep 0.6 seconds of the recorded pause after selecting, before the shortcut.
  { id: "selection-pause", at: 69, dur: 18 },
  { id: "press", at: 88, dur: 9 }, // ⌘⇧1 at 93
  { at: 97, dur: 14, rate: 1.43, move: TRANSLATION }, // translation arrives while the camera follows
  { at: 117, dur: readChars(RESULT), freeze: true }, // read the translation
  // Cut the pointer travelling to "shortcut" (frames 118–159).
  { id: "card-dict", at: 160, dur: holdFor(LOOKUP, 0, 11), freeze: true },
  { id: "select-word", at: 160, dur: 15 }, // double-click at 171
  { id: "to-book", at: 175, dur: 12, rate: 1.67, move: DICTIONARY },
  { id: "click", at: 195, dur: 17 }, // click at 204
  // The note fades in at frame 208, 4 output frames before this hold.
  { at: 212, dur: FADE + readTime(NOTE.join(" ")) - 4, freeze: true },
]);

export const PREVIEW_FRAMES = T.total;
export const PREVIEW_TIMELINE = T;

const DRAG_START = { x: 280, y: 442 };
const WORD = { x: 1690, y: 735 }; // double-click on "shortcut"
const BOOK = { x: 1708, y: 682 };

export const SelectedTextDemo: React.FC = () => {
  const { start } = T;
  // The final key completes the chord at the real shortcut trigger.
  const PRESS = outFrame(T.segments, 93) - KEY_STAGGER * 2;
  const WINDOW_OPENS = outFrame(T.segments, 96);
  const DOUBLE_CLICK = outFrame(T.segments, 171);
  const CLICK = outFrame(T.segments, 204);
  // Everything at the book is gone, and the definitions are covered, from the
  // first frame of the dictionary's pop-up animation.
  const DICTIONARY_OPENS = outFrame(T.segments, 206);
  const DICTIONARY_SETTLED = outFrame(T.segments, 210);
  return (
    <SceneFade fadeIn={8} fadeOut={6}>
      <FeatureTitle>{TITLE}</FeatureTitle>
      <AfterTitle>
        <Stage
          src="preview-selected"
          segments={T.segments}
          cams={T.cams}
          stage={STAGE}
          overlay={(view) => (
            <>
              <GoldTarget
                view={view}
                at={DRAG_START}
                from={start("card-select")}
                to={outFrame(T.segments, 56)}
              />
              <GoldCard
                view={view}
                anchor={{ x: 700, y: 480 }}
                side="below"
                from={start("card-select")}
                to={WINDOW_OPENS}
                title={SELECT}
                keys={["⌘", "⇧", "1"]}
                press={PRESS}
              />

              <GoldCard
                view={view}
                anchor={{ x: 1709, y: 770 }}
                side="below"
                from={start("card-dict")}
                to={DICTIONARY_OPENS - 6}
                title={LOOKUP}
              />
              <GoldTarget
                view={view}
                at={WORD}
                from={start("card-dict")}
                to={DOUBLE_CLICK}
              />
              <GoldTarget
                view={view}
                at={BOOK}
                from={start("to-book")}
                to={DICTIONARY_OPENS - 6}
              />
              <GoldClick
                view={view}
                at={BOOK}
                frame={CLICK}
                until={DICTIONARY_OPENS}
              />

              {/* While the popup grows it is not yet where the definitions veil sits:
                  cover the whole popup until it has settled. */}
              <DictionaryVeil
                view={view}
                rect={{ x0: 1370, y0: 770, x1: 2048, y1: 1475 }}
                from={DICTIONARY_OPENS}
                to={DICTIONARY_SETTLED - 1}
                fadeIn={1}
                note={false}
                seed={107}
              />
              <DictionaryVeil
                view={view}
                rect={{ x0: 1380, y0: 918, x1: 2030, y1: 1164 }}
                from={DICTIONARY_OPENS}
                fadeIn={1}
                seed={7}
              />
            </>
          )}
        />
      </AfterTitle>
      <Audio
        name="Key ⌘"
        from={PRESS}
        src={staticFile("sfx/ui/key-1.wav")}
        volume={0.75}
      />
      <Audio
        name="Key ⇧"
        from={PRESS + KEY_STAGGER}
        src={staticFile("sfx/ui/key-2.wav")}
        volume={0.7}
      />
      <Audio
        name="Key 1"
        from={PRESS + KEY_STAGGER * 2}
        src={staticFile("sfx/ui/key-3.wav")}
        volume={0.75}
      />
      {/* click.wav starts at sample 0; its 76 ms silence is between press and release. */}
      <Audio
        name="Click book"
        from={CLICK}
        src={staticFile("sfx/ui/click.wav")}
        volume={0.85}
      />
    </SceneFade>
  );
};
