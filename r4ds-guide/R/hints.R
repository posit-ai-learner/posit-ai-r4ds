# LLM integration via ellmer.
# Hints, feedback, and retrieval feedback all go through this module.
# Provider defaults to Anthropic; swap chat_anthropic() for any ellmer provider.

LEVEL_BRIEF <- c(
  "1" = "a single conceptual nudge — name the KIND of operation needed, no functions, no code.",
  "2" = "point to the specific tidyverse verbs/functions and the order to apply them — still NO complete code.",
  "3" = "a code skeleton with the key parts left as blanks or comments — not a runnable answer.",
  "4" = "the full, runnable, idiomatic solution WITH a short explanation of each step."
)

#' Read a prompt file from the prompts/ directory (relative to app.R).
read_prompt <- function(name) {
  path <- file.path("prompts", paste0(name, ".md"))
  if (!file.exists(path)) {
    stop("Prompt file not found: ", path)
  }
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

#' Return an ellmer Chat configured for hints.
#' Change this function to swap the LLM provider.
make_chat <- function(system_prompt) {
  ellmer::chat_openai(
    system_prompt = system_prompt,
    model         = Sys.getenv("R4DS_MODEL", unset = "gpt-4.1-mini")
  )
}

#' Get a tiered Socratic hint.
#'
#' @param exercise    Exercise list (from exercises.R).
#' @param level       Integer 1–4.
#' @param learner_code Current code in the editor.
#' @param last_output  Text output from the last run (or "").
#' @return Character string (the hint text, markdown).
get_hint <- function(exercise, level, learner_code, last_output = "") {
  system_tpl <- read_prompt("hint-system")
  system_prompt <- gsub(
    "\\{\\{LEVEL\\}\\}",
    level,
    gsub(
      "\\{\\{LEVEL_BRIEF\\}\\}",
      LEVEL_BRIEF[as.character(level)],
      system_tpl
    )
  )

  user_msg <- paste0(
    "EXERCISE: ",
    strip_html(exercise$prompt),
    "\n\n",
    "LEARNER'S CURRENT CODE:\n```r\n",
    learner_code,
    "\n```\n\n",
    "THEIR LAST RUN OUTPUT:\n",
    if (nchar(trimws(last_output)) == 0) {
      "(they haven't run anything yet)"
    } else {
      last_output
    },
    "\n\nGive the level ",
    level,
    " hint now."
  )

  chat <- make_chat(system_prompt)
  chat$chat(user_msg)
}

#' Get idiomatic feedback on a learner's answer.
#'
#' @param exercise     Exercise list.
#' @param learner_code Code submitted.
#' @param last_output  Captured output from running the code.
#' @param hint_unlocked Logical — whether L4 was already shown.
#' @return Character string (feedback, markdown).
get_feedback <- function(
  exercise,
  learner_code,
  last_output,
  hint_unlocked = FALSE
) {
  system_tpl <- read_prompt("feedback-system")

  giveaway <- if (hint_unlocked) {
    "They have already seen the full solution, so you may show corrected code if helpful."
  } else {
    paste0(
      "IMPORTANT: if the answer is WRONG, do NOT give corrected code — ",
      "give one pointed nudge and suggest they use the hint button. ",
      "Only confirm and praise if correct."
    )
  }

  system_prompt <- gsub("\\{\\{GIVEAWAY_POLICY\\}\\}", giveaway, system_tpl)

  user_msg <- paste0(
    "EXERCISE: ",
    strip_html(exercise$prompt),
    "\n\n",
    "LEARNER CODE:\n```r\n",
    learner_code,
    "\n```\n\n",
    "CAPTURED OUTPUT:\n",
    last_output,
    "\n\n",
    "Expected: ",
    exercise$expected,
    ". Give your feedback."
  )

  chat <- make_chat(system_prompt)
  chat$chat(user_msg)
}

#' Get retrieval-session feedback (no solution revealed, regardless of hint history).
#'
#' @param exercise     Exercise list.
#' @param learner_code Code submitted.
#' @param last_output  Captured output.
#' @return Character string (feedback, markdown).
get_retrieval_feedback <- function(exercise, learner_code, last_output) {
  system_prompt <- read_prompt("retrieval-system")

  user_msg <- paste0(
    "EXERCISE: ",
    strip_html(exercise$prompt),
    "\n\n",
    "LEARNER CODE:\n```r\n",
    learner_code,
    "\n```\n\n",
    "CAPTURED OUTPUT:\n",
    last_output
  )

  chat <- make_chat(system_prompt)
  chat$chat(user_msg)
}

#' Strip HTML tags from a string (for sending plain text to the LLM).
strip_html <- function(s) {
  gsub("<[^>]+>", " ", s) |> gsub("\\s+", " ", x = _) |> trimws()
}
