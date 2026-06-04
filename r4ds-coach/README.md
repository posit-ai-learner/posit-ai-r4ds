# R4DS Coach (local)

A self-learning companion for *R for Data Science* (https://r4ds.hadley.nz/):
a zero-install R sandbox (WebR) plus a Socratic hint engine that makes you think
before it answers. Built to be handed to **Claude Code** to finish and extend.

## Hand it to Claude Code
From this folder:
```
claude
```
Then, for example:
> Read CLAUDE.md and SPEC.md. Verify the core loop runs, then implement the
> exercise registry and progress model from the build order.

`CLAUDE.md` is read automatically and contains the architecture + the one rule
that must not be broken (the tiered, gated hints).

## Run it yourself
```
cp .env.example .env          # then paste your Anthropic API key into .env
npm install
npm run dev                   # open the printed localhost URL
```
First boot downloads the WebR runtime and installs dplyr in the background; base R
works immediately.

## What's here
| path | what |
|------|------|
| `CLAUDE.md` | steering doc for Claude Code (read first) |
| `SPEC.md` | full feature spec + roadmap |
| `reference/prototype.html` | the working core-loop prototype, for reference |
| `prompts/*.md` | the hint + feedback system prompts (edit these to tune behavior) |
| `src/` | frontend (Vite, vanilla JS) |
| `vite.config.js` | dev server + the `/api/claude` proxy that hides your key |

## Security
Your Anthropic key stays server-side (in the Vite dev middleware, read from `.env`).
Never move Anthropic calls into client code.
