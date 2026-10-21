import { Video } from "@remotion/media";
import type React from "react";
import {
  AbsoluteFill,
  Freeze,
  interpolate,
  Sequence,
  staticFile,
  useCurrentFrame,
} from "remotion";
import { clamp, glide, SOURCE, STAGE, windowShadow } from "../theme";

// A piece of the recording placed on the scene timeline. `at` is a source
// frame (30 fps proxy). A playing segment shows `dur` output frames starting
// at `at`, advancing `rate` source frames per output frame; a frozen segment
// holds frame `at` for `dur` output frames.
export type Segment = {
  readonly at: number;
  readonly dur: number;
  readonly rate?: number;
  readonly freeze?: boolean;
};

export type Placed = Segment & { readonly start: number };

export const place = (segments: Segment[]): Placed[] => {
  let start = 0;
  return segments.map((s) => {
    const p = { ...s, start };
    start += s.dur;
    return p;
  });
};

export const totalFrames = (segments: Segment[]) =>
  segments.reduce((sum, s) => sum + s.dur, 0);

// Output frame at which source frame `src` is on screen during playback.
export const outFrame = (placed: Placed[], src: number): number => {
  for (const p of placed) {
    if (p.freeze) {
      continue;
    }
    const rate = p.rate ?? 1;
    const end = p.at + p.dur * rate;
    if (src >= p.at && src < end) {
      return p.start + Math.round((src - p.at) / rate);
    }
  }
  throw new Error(`Source frame ${src} is not played in this scene`);
};

// Camera keyframe in scene frames: centre (x, y) and width w in source pixels.
export type Cam = { readonly f: number; readonly x: number; readonly y: number; readonly w: number };

export type View = {
  readonly frame: number;
  // Source pixel → output pixel.
  readonly map: (x: number, y: number) => { x: number; y: number };
  readonly scale: number;
};

const track = (frame: number, cams: Cam[], pick: (c: Cam) => number) =>
  interpolate(frame, cams.map((c) => c.f), cams.map(pick), { ...clamp, easing: glide });

export type StageRect = { readonly x: number; readonly y: number; readonly w: number; readonly h: number };

export const useCamera = (cams: Cam[], stage: StageRect = STAGE): View & { x0: number; y0: number } => {
  const frame = useCurrentFrame();
  const cx = track(frame, cams, (c) => c.x);
  const cy = track(frame, cams, (c) => c.y);
  // Zoom in log space so push-ins feel even.
  const w = Math.exp(track(frame, cams, (c) => Math.log(c.w)));
  const scale = stage.w / w;
  const x0 = cx - w / 2;
  const y0 = cy - stage.h / scale / 2;
  return {
    frame,
    scale,
    x0,
    y0,
    map: (x, y) => ({ x: stage.x + (x - x0) * scale, y: stage.y + (y - y0) * scale }),
  };
};

type StageProps = {
  readonly src: string;
  readonly segments: Placed[];
  readonly cams: Cam[];
  readonly overlay?: (view: View) => React.ReactNode;
  readonly stage?: StageRect;
};

// The recording in a rounded window with the camera applied. Overlays are
// clipped to the same window so hints never spill onto the headline.
export const Stage: React.FC<StageProps> = ({ src, segments, cams, overlay, stage = STAGE }) => {
  const view = useCamera(cams, stage);
  const appear = interpolate(view.frame, [0, 14], [0.965, 1], { ...clamp, easing: glide });
  return (
    <AbsoluteFill>
      <div
        style={{
          position: "absolute",
          left: stage.x,
          top: stage.y,
          width: stage.w,
          height: stage.h,
          borderRadius: 22,
          overflow: "hidden",
          background: "#ffffff",
          boxShadow: windowShadow,
          scale: String(appear),
        }}
      >
        <div
          style={{
            position: "absolute",
            left: 0,
            top: 0,
            width: SOURCE.w,
            height: SOURCE.h,
            transformOrigin: "0 0",
            translate: `${-view.x0 * view.scale}px ${-view.y0 * view.scale}px`,
            scale: String(view.scale),
          }}
        >
          {/* One template renders every segment; the segment list is the
              single source of truth for the scene's timing. */}
          {segments.map((s) => (
            <Sequence
              key={s.start}
              name={`${s.freeze ? "hold" : "play"} @${s.at}`}
              from={s.start}
              durationInFrames={s.dur}
            >
              {s.freeze ? (
                <Freeze frame={0}>
                  <Video
                    src={staticFile(`media/${src}.mp4`)}
                    trimBefore={s.at}
                    muted
                    style={{ width: SOURCE.w, height: SOURCE.h }}
                  />
                </Freeze>
              ) : (
                <Video
                  src={staticFile(`media/${src}.mp4`)}
                  trimBefore={s.at}
                  playbackRate={s.rate ?? 1}
                  muted
                  style={{ width: SOURCE.w, height: SOURCE.h }}
                />
              )}
            </Sequence>
          ))}
        </div>
        <div
          style={{
            position: "absolute",
            left: -stage.x,
            top: -stage.y,
            width: stage.x * 2 + stage.w,
            height: stage.y * 2 + stage.h,
          }}
        >
          {overlay?.(view)}
        </div>
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: 22,
            boxShadow: "inset 0 0 0 1.5px rgba(16, 41, 93, 0.10)",
          }}
        />
      </div>
    </AbsoluteFill>
  );
};
