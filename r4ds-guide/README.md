# R4DS Guide

A Positron-native self-learning companion for [*R for Data Science*](https://r4ds.hadley.nz/).

R runs natively in your existing R session (no WebR, no browser sandbox). The
AI tutor gives tiered Socratic hints and never hands you the answer until
you've genuinely tried.

## Quick start

### 1. Install dependencies

```r
install.packages(c("shiny", "bslib", "ellmer", "evaluate", "jsonlite", "knitr"))
```

### 2. Set your API key

Add this line to your `~/.Renviron` (run `usethis::edit_r_environ()` to open it):

```
ANTHROPIC_API_KEY=sk-ant-...
```

Restart R after saving. The key is read once at startup and never exposed in the app.

**Alternative providers** — swap `chat_anthropic()` in `R/hints.R` for any
[`ellmer` provider](https://ellmer.tidyverse.org/reference/index.html):

| Provider | Function | Env var |
|----------|----------|---------|
| Anthropic (default) | `chat_anthropic()` | `ANTHROPIC_API_KEY` |
| OpenAI | `chat_openai()` | `OPENAI_API_KEY` |
| Ollama (free, local) | `chat_ollama()` | *(none)* |
| OpenRouter | `chat_openrouter()` | `OPENROUTER_API_KEY` |

### 3. Launch

From the Positron R console, with your working directory set to this folder:

```r
shiny::runApp("r4ds-guide/")
```

The app opens in Positron's Viewer pane.

---

## How it works

### The one rule

> Remove the friction that makes self-learners quit; protect the difficulty that
> makes them learn.

The AI never does your thinking for you:

- **Tiered hints (L1–L4).** One button. Each press escalates exactly one level:
  - L1 — names the *kind* of operation (no functions, no code)
  - L2 — names the specific functions and order (no complete code)
  - L3 — a code skeleton with key parts left as blanks
  - L4 — the full, runnable solution with step-by-step explanation
  - **L4 is gated** until you've run your code at least twice.
- **Check my answer.** Grades correctness *and* style. If wrong and L4 not yet
  unlocked, gives one nudge — not the fix.

### Spaced retrieval

When you clear an exercise, it's scheduled for retrieval practice using SM-2.
A badge in the sidebar tells you how many reviews are due. The review card
gives you the prompt cold — hints are disabled — and three self-rating buttons
update the schedule.

### Progress

Saved to `~/.r4ds-guide/` as JSON files. Clearing an exercise is permanent
(status never regresses). The sidebar shows a colour-coded dot per exercise:

- ⚫ Grey = untouched
- 🟠 Amber = attempted (ran code but not yet correct)
- 🟢 Green = cleared

---

## Customising the tutor

Prompt behaviour lives in `prompts/*.md` — edit those files to tune tone,
strictness, or tidyverse/base R preferences. No R code changes needed.

To change the model:

```r
# In R/hints.R, swap:
ellmer::chat_anthropic(model = "claude-sonnet-4-5", ...)
# for any other ellmer provider/model
```

Or set `R4DS_MODEL` in your `.Renviron` to override the default model name.

---

## Exercises

| Chapter | Exercise | Concepts |
|---------|----------|----------|
| 1 · Visualisation | Your first scatter plot | `geom_point`, aesthetics |
| 1 · Visualisation | Color by vehicle class | color aesthetic, categorical mapping |
| 1 · Visualisation | Highway MPG by drive type | `geom_boxplot`, distributions |
| 3 · Transformation | Four-cylinder cars only | `filter`, `select` |
| 3 · Transformation | Heaviest species first | `group_by`, `summarise`, `arrange` |
| 3 · Transformation | Add a km-per-litre column | `mutate`, arithmetic |
| 3 · Transformation | Penguin count by species and island | `count`, grouped counting |
| 3 · Transformation | Mean flipper length by species | `summarise`, `n()` |
| 5 · Tidy data | Scores from wide to long | `pivot_longer` |
| 5 · Tidy data | Measurements from long to wide | `pivot_wider` |
| 5 · Tidy data | Split a date column | `separate` |

---

## Adding exercises

Add entries to `R/exercises.R` following the existing schema:

```r
list(
  id            = "unique-kebab-id",
  chapter       = 3,
  chapter_title = "Data transformation",
  title         = "Short display title",
  prompt        = "<p>HTML prompt shown to the learner.</p>",
  setup_r       = "library(dplyr)\n# data setup code",
  starter_r     = "# starter code shown in the editor\n",
  setup_note    = "# brief note shown below the editor",
  expected      = "plain-English description for the feedback grader",
  concepts      = c("concept1", "concept2"),
  prereqs       = c("other-exercise-id")  # or character(0)
)
```

The R4DS text is CC BY-NC-ND. Link to chapters; do not copy or ship a
modified version of the book's prose inside this app.
