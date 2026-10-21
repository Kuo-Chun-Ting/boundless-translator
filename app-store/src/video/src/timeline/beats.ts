import { type Cam, place, type Placed, type Segment } from "./Stage";

export type CamPos = Omit<Cam, "f">;

// One beat of a demo: a piece of the recording, plus an optional camera move
// that happens during this beat and nowhere else. Beats that cues refer to
// carry an `id`, so the long and short cuts can share the same cue layout.
export type Beat = Segment & { readonly move?: CamPos; readonly id?: string };

export const timeline = (initial: CamPos, beats: Beat[]) => {
  const segments: Placed[] = place(beats);
  const cams: Cam[] = [{ f: 0, ...initial }];
  let current = initial;
  segments.forEach((s, i) => {
    const target = beats[i].move;
    if (!target) {
      return;
    }
    if (cams[cams.length - 1].f < s.start) {
      cams.push({ f: s.start, ...current });
    }
    current = target;
    cams.push({ f: s.start + s.dur, ...current });
  });
  const find = (id: string) => {
    const i = beats.findIndex((b) => b.id === id);
    if (i < 0) {
      throw new Error(`No beat "${id}"`);
    }
    return segments[i];
  };
  // Start and end frame of a named beat.
  const start = (id: string) => find(id).start;
  const end = (id: string) => find(id).start + find(id).dur;
  const total = segments.reduce((sum, s) => sum + s.dur, 0);
  return { segments, cams, start, end, total };
};
