# CLAUDE.md — instructions for building R4DS Coach

You are building **R4DS Coach**: a local web app that helps a self-learner work
through *R for Data Science* (https://r4ds.hadley.nz/). Read `SPEC.md` for the
full feature design and `reference/prototype.html` for a working reference of the
core loop (it ran as a browser artifact; you are porting and extending it).

## The one rule that must never be broken
This tool teaches **by protecting productive struggle**. The AI must NOT do the
thinking for the learner.

- Hints are **tiered** (1→4). Each request escalates by exactly one level.
- Level 4 (the full solution) is **gated**: it does not unlock until the learner
  has actually run code at least twice.
- "Check my answer" gives idiomatic feedback but **withholds the corrected code**
  when the answer is wrong, unless level 4 was already unlocked.

If any change would let a learner get a complete answer without trying, it is wrong.
Treat this as a hard invariant, like a security property.

## Architecture (already scaffolded — keep this shape)
- **Frontend**: Vite + vanilla JS (no framework needed). Entry `index.html` → `src/main.js`.
- **R runtime**: WebR (R compiled to WebAssembly) via the `webr` npm package,
  `PostMessage` channel (no special headers required). See `src/webr.js`.
- **LLM calls**: the browser calls `POST /api/claude` ONLY. The Anthropic API key
  lives server-side in a Vite dev middleware (`vite.config.js`) read from `.env`.
  **Never** put the API key in client code or expose it to the browser.
- **Prompts** live as editable Markdown in `prompts/*.md`, imported with Vite `?raw`.

## Setup
1. `cp .env.example .env` and add the user's `ANTHROPIC_API_KEY`.
2. `npm install`
3. `npm run dev` → open the printed localhost URL.

WebR downloads its WASM payload on first run and installs `dplyr` in the
background; base R works immediately. Expect a few seconds on first boot.

## Build order (the core loop already works — extend in this order)
1. **Verify the core loop** runs end to end (run R, tiered hints, check answer).
2. **Exercise registry**: move the single hard-coded exercise into
   `src/exercises.js` as a list following the schema in SPEC.md; add 3–4 more
   from R4DS chapters 1, 3, 5.
3. **Progress model**: persist per-exercise status + the hint level reached, in
   `localStorage` (this is local, so localStorage is fine here — unlike the
   artifact). Surface a simple progress strip.
4. **Spaced retrieval**: generate short retrieval questions from cleared
   exercises; schedule with FSRS (or SM-2 to start). See SPEC.md §Roadmap.
5. **Bring-your-own-data** and **concept graph**: later; specced but not required
   for a first usable version.

## Conventions
- Keep it dependency-light. Vanilla JS + Vite. Do not add React unless the
  progress UI genuinely needs it.
- Default model is `claude-sonnet-4-6` (set in `vite.config.js`, override via
  `CLAUDE_MODEL` in `.env`). The user can change it.
- Prefer tidyverse idioms in hints, but accept base R as valid.
- Edit prompt behavior by editing `prompts/*.md`, not by hard-coding strings in JS.
