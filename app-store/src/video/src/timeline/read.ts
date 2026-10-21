// One reading rule for every cue: once a cue has fully faded in, it stays
// readable before its action starts for BASE frames plus a fixed time per
// English word, or per character for a Chinese translation result.
//
// A hold is the still frame placed before the action. `lead` is how many
// output frames pass between the end of the hold and the action itself
// (the action is rarely the first frame of the next recording segment), and
// counts toward reading time.
export const FADE = 8;
const BASE = 7;
const PER_WORD = 6;
const PER_CHAR = 2.2;

const words = (text: string, keys: number) => text.trim().split(/\s+/).length + keys;

// Readable frames a cue needs; `keys` counts a row of keycaps as one word.
export const readTime = (text: string, keys = 0) => BASE + PER_WORD * words(text, keys);

// Readable frames a translation result needs, from its character count.
export const readChars = (text: string) => Math.round(BASE + PER_CHAR * [...text.replace(/\s/g, "")].length);

// Still frames to place before an action so the cue gets its reading time.
export const holdFor = (text: string, keys = 0, lead = 0) => Math.max(0, FADE + readTime(text, keys) - lead);
