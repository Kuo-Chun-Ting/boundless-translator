import { Audio } from "@remotion/media";
import type React from "react";
import { staticFile } from "remotion";
import { SceneFade } from "../components/Glass";
import { outFrame, Stage } from "../timeline/Stage";
import { type CamPos, timeline } from "../timeline/beats";
import {
  GoldCapture,
  GoldCard,
  GoldClick,
  GoldHover,
  GoldLabel,
  GoldTarget,
  KEY_STAGGER,
} from "../components/Cues";
import { STAGE } from "../theme";
import { NOTE, DictionaryVeil } from "../components/DictionaryVeil";
import { holdFor, readChars, readTime, FADE } from "../timeline/read";
import { AfterTitle, FeatureTitle, TITLE_HOLD } from "../components/FeatureTitle";

// assets/recording/screenshot-translation.mov as media/menu-screenshot.mp4
// (30 fps). Source events (frames):
//   24 ⌘⇧2 (crosshair at 25) · 63–115 drag the capture area
//   116 screenshot window opens · 192 hover card on 野菜 · 232 hover card on カレー
//   285–307 select the description · 333 sentence translation shown
//   386 hover card on 香ばしく · 431 click the book
//   434 Mac dictionary starts to pop up · 436 fully shown
// Cameras stay below y = 180: the menu bar and Safari's address bar show
// other apps' icons and a local file path.
const WIDE: CamPos = { x: 1512, y: 1032, w: 3024 };
const MENU: CamPos = { x: 2070, y: 1010, w: 1900 };
// The whole screenshot window, kept for every step inside it, including the
// dictionary that opens over its top-left corner.
const WINDOW: CamPos = { x: 1512, y: 990, w: 2300 };

const TITLE = "Screenshot Translation";
const SHOT = "Take a screenshot to translate";
const HOVER = "Hover to translate";
const SENTENCE = "Select to translate";
const LOOKUP = "Open dictionary";
const RESULT = "香氣十足的烤蔬菜和慢燉咖哩。附有沙拉和湯。";

// No extra instruction or reading hold while travelling to the capture area.
const TRAVEL = 18;

const T = timeline(WIDE, [
  { id: "title", at: 18, dur: TITLE_HOLD, freeze: true },
  // The first key goes down as the press segment starts (the last key lands on
  // the real ⌘⇧2 at 24), so the hold alone carries the reading time.
  { id: "card-shot", at: 18, dur: holdFor(SHOT, 1, 0), freeze: true },
  { id: "press", at: 18, dur: 10 }, // ⌘⇧2 at 24 and the crosshair at real speed
  { id: "travel", at: 28, dur: TRAVEL, rate: 35 / TRAVEL, move: MENU },
  { id: "drag", at: 63, dur: 25, rate: 2 },
  { id: "window", at: 113, dur: 16, rate: 21 / 16, move: WINDOW },
  { id: "cue-hover", at: 134, dur: holdFor(HOVER), freeze: true },
  // Cut the first hover on 焼き (frames 135–191).
  { id: "hover", at: 192, dur: 40, rate: 2.25 }, // 野菜, then カレー
  { id: "card-sentence", at: 281, dur: holdFor(SENTENCE), freeze: true }, // also reads 咖哩
  { id: "select", at: 285, dur: 23 },
  { at: 308, dur: 10, rate: 2.6 }, // translation arrives
  { at: 334, dur: readChars(RESULT), freeze: true }, // read the translation
  // One cue covers the whole lookup: approach the word, reveal its card,
  // then click the book. Keep the recorded hover instead of jumping to it.
  { id: "card-dict", at: 375, dur: holdFor(LOOKUP), freeze: true },
  { id: "dict-hover", at: 375, dur: 19 },
  { id: "to-book", at: 394, dur: 14, rate: 2 },
  { id: "click", at: 422, dur: 16 }, // click at 431
  // The note fades in at frame 436, 2 output frames before this hold.
  { at: 438, dur: FADE + readTime(NOTE.join(" ")) - 2, freeze: true },
]);

export const MENU_FRAMES = T.total;
export const MENU_TIMELINE = T;

const DRAG_START = { x: 1806, y: 730 };
const SENTENCE_START = { x: 620, y: 1100 }; // drag over the description
const BOOK = { x: 958, y: 962 };

// A sound each time a translation card shows its result: the hover cards on
// 野菜 (198), カレー (239) and 香ばしく (394), and the sentence card (333).
const CARD_RESULTS = [198, 239, 333, 394];

export const ScreenshotDemo: React.FC<{
  readonly cardSound: string;
  // Frames between the sound's start and its main hit, so the hit lands on
  // the card (card-slide-4 swishes for 3 frames before the card lands).
  readonly cardLead: number;
}> = ({ cardSound, cardLead }) => {
  const { start, end } = T;
  const PRESS = outFrame(T.segments, 24) - KEY_STAGGER * 2;
  const RELEASE = outFrame(T.segments, 115);
  const WINDOW_OPENS = outFrame(T.segments, 116);
  // Each hover outline marks the word whose card is on screen: it starts when
  // the card appears and ends when the next step starts.
  const VEGETABLES_CARD = outFrame(T.segments, 192);
  const CURRY_CARD = outFrame(T.segments, 232);
  const FRAGRANT_CARD = outFrame(T.segments, 386);
  const CLICK = outFrame(T.segments, 431);
  // Everything at the book is gone, and the definitions are covered, from the
  // first frame of the dictionary's pop-up animation.
  const DICTIONARY_OPENS = outFrame(T.segments, 434);
  const DICTIONARY_SETTLED = outFrame(T.segments, 437) + 1;
  return (
    <SceneFade fadeIn={8} fadeOut={6}>
      <FeatureTitle>{TITLE}</FeatureTitle>
      <AfterTitle>
        <Stage
          src="menu-screenshot"
          segments={T.segments}
          cams={T.cams}
          stage={STAGE}
          overlay={(view) => (
            <>
              <GoldCard
                view={view}
                anchor={{ x: DRAG_START.x + 20, y: DRAG_START.y - 40 }}
                side="above"
                from={start("card-shot")}
                to={end("press") - 2}
                title={SHOT}
                keys={["⌘", "⇧", "2"]}
                press={PRESS}
              />
              <GoldTarget
                view={view}
                at={DRAG_START}
                from={outFrame(T.segments, 25)}
                to={start("drag")}
              />
              <GoldCapture
                view={view}
                rect={{ x0: 1806, y0: 730, x1: 2764, y1: 1280 }}
                frame={RELEASE}
                until={WINDOW_OPENS}
              />

              <GoldLabel
                view={view}
                anchor={{ x: 1300, y: 900 }}
                side="below"
                from={start("cue-hover")}
                to={end("hover")}
              >
                {HOVER}
              </GoldLabel>
              <GoldHover
                view={view}
                rect={{ x0: 1130, y0: 630, x1: 1698, y1: 885 }}
                from={VEGETABLES_CARD}
                to={CURRY_CARD - 6}
              />
              <GoldHover
                view={view}
                rect={{ x0: 1690, y0: 630, x1: 2430, y1: 885 }}
                from={CURRY_CARD}
                to={start("card-sentence") - 6}
              />

              <GoldTarget
                view={view}
                at={SENTENCE_START}
                from={start("card-sentence")}
                to={start("select")}
              />
              {/* Between the headline and the first line, above where the drag starts. */}
              <GoldCard
                view={view}
                anchor={{ x: 640, y: 1072 }}
                side="above"
                from={start("card-sentence")}
                to={end("select") - 2}
                title={SENTENCE}
              />

              <GoldHover
                view={view}
                rect={{ x0: 592, y0: 1070, x1: 1056, y1: 1188 }}
                from={FRAGRANT_CARD}
                to={DICTIONARY_OPENS - 6}
              />
              <GoldTarget
                view={view}
                at={BOOK}
                from={start("to-book")}
                to={DICTIONARY_OPENS - 6}
              />
              {/* Right of the hover card, between the headline and the description. */}
              <GoldCard
                view={view}
                anchor={{ x: 1035, y: 962 }}
                side="right"
                from={start("card-dict")}
                to={DICTIONARY_OPENS - 6}
                title={LOOKUP}
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
                rect={{ x0: 505, y0: 380, x1: 1255, y1: 1155 }}
                from={DICTIONARY_OPENS}
                to={DICTIONARY_SETTLED - 1}
                fadeIn={1}
                note={false}
                seed={119}
              />
              <DictionaryVeil
                view={view}
                rect={{ x0: 584, y0: 486, x1: 1214, y1: 778 }}
                from={DICTIONARY_OPENS}
                fadeIn={1}
                seed={19}
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
        name="Key 2"
        from={PRESS + KEY_STAGGER * 2}
        src={staticFile("sfx/ui/key-3.wav")}
        volume={0.75}
      />
      <Audio
        name="Screenshot"
        from={RELEASE}
        src={staticFile("sfx/ui/shutter-cc0.wav")}
        volume={0.8}
      />
      {/* click.wav starts at sample 0; its 76 ms silence is between press and release. */}
      <Audio
        name="Click book"
        from={CLICK}
        src={staticFile("sfx/ui/click.wav")}
        volume={0.85}
      />
      {CARD_RESULTS.map((src) => (
        <Audio
          key={src}
          name={`Card ${src}`}
          from={outFrame(T.segments, src) - cardLead}
          src={staticFile(cardSound)}
        />
      ))}
    </SceneFade>
  );
};
