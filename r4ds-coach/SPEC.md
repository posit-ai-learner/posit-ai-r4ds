# R4DS Coach — Specification

## Purpose
Help a self-learner actually *finish* and *retain* *R for Data Science*
(https://r4ds.hadley.nz/, CC BY-NC-ND 3.0). The book teaches by doing: every
chapter ends in exercises, and it deliberately ships without answers. Coach fills
the gaps that make self-learners quit — setup friction and the absence of a
feedback loop — **without** removing the struggle that produces learning.

## Design philosophy (non-negotiable)
> Remove the friction that makes self-learners quit; protect the difficulty that
> makes them learn.

Every feature is one or the other. The failure mode to design against is
over-reliance: a learner who feels productive because the AI keeps unblocking
them but has outsourced the cognition. Success is measured by what the learner
can do with the AI turned off.

## Core loop (v1 — implemented in the reference prototype)
1. **Zero-install R sandbox.** WebR runs real R in the browser. The learner reads,
   writes code, and runs it inline. No R/RStudio install.
2. **Tiered Socratic hints.** One button. Each press escalates one level:
   - L1 — a conceptual nudge (name the *kind* of operation; no functions, no code)
   - L2 — point to the specific verbs/functions and the order; still no full code
   - L3 — a code skeleton with the key parts left as blanks
   - L4 — the full, runnable, idiomatic solution **with** a step-by-step explanation
   L4 is gated behind ≥2 runs. Levels never skip; the model is told the exact level
   and forbidden to exceed it.
3. **Idiomatic feedback ("Check my answer").** Runs the learner's code, judges
   correctness AND style (base R vs dplyr, tidy vs not). If wrong and L4 not yet
   unlocked, it gives one pointed nudge, not the fix.

## Exercise schema (v2)
```js
{
  id: "transform-heaviest-species",
  chapter: 3,
  chapterTitle: "Data transformation",
  title: "Heaviest species first",
  prompt: "For each species, compute the mean body_mass_g, then sort descending.",
  setupR: "penguins <- data.frame(...)",     // prepended to every run
  starterR: "head(penguins)\n\n# your answer:\n",
  // used by the feedback grader to know what 'correct' looks like:
  expected: "per-species mean of body_mass_g, sorted desc (Gentoo>Adelie>Chinstrap)",
  concepts: ["group-wise summary", "sorting"],  // for the concept graph
  prereqs: []                                    // exercise ids
}
```
Seed with exercises from chapters 1 (visualize), 3 (transform), 5 (tidy).

## Roadmap (v3+)
- **Progress model.** Per-exercise: status (untouched / attempted / cleared) and
  the *highest hint level reached*. Persist in `localStorage`. "Cleared at L1" vs
  "needed L4 three times" is the key signal for review. Show a compact progress
  strip across the chapter.
- **Spaced retrieval.** From cleared exercises, generate short *retrieval-practice*
  questions ("write the code to…"), schedule with FSRS (fall back to SM-2).
  Interleave concepts across chapters (mix a dplyr and a ggplot question) — proven
  better than blocked practice. Questions are retrieval, never multiple choice.
- **Bring-your-own-data.** Learner uploads a CSV; Coach scaffolds applying the
  current chapter's skills to *their* data, same Socratic restraint. WebR can read
  an uploaded file via its virtual filesystem (`webR.FS`).
- **Concept-dependency graph.** Model R4DS prerequisites (joins lean on logical
  vectors; EDA needs visualize + transform). When a learner struggles, point back
  to the unmet prerequisite rather than treating chapters as isolated.
- **Closed-book mode.** Occasionally have the learner solve something cold with
  hints disabled, so both they and the system see whether it's actually sticking.

## Technical notes / gotchas
- **WebR channel.** `PostMessage` needs no special headers and is used by default.
  The faster `SharedArrayBuffer` channel requires COOP/COEP headers
  (`Cross-Origin-Opener-Policy: same-origin`, `Cross-Origin-Embedder-Policy:
  require-corp`) on the dev server AND CORS/CORP-friendly loading of any CDN assets.
  Only switch if performance demands it.
- **dplyr install** happens at runtime via `webR.installPackages(['dplyr'])` and
  pulls several deps — slow on first boot. Keep base R working while it loads.
- **Plots.** ggplot output needs a canvas device and is more involved over the
  PostMessage channel; the v1 exercises are transform-only on purpose. Add plotting
  exercises only after wiring `webR` graphics capture.
- **API key.** Server-side only. The included Vite middleware proxies `/api/claude`
  → Anthropic `/v1/messages`. For a deployed (non-dev) version, replace it with a
  real serverless function or small backend; the dev middleware is dev-only.
- **License.** The R4DS text is CC BY-NC-ND. Link to chapters; do not copy or ship
  a modified version of the prose inside the app.
