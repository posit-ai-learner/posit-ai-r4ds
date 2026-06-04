# Spaced retrieval scheduler using SM-2.
#
# SM-2 state per item:
#   interval    : days until next review (starts at 1)
#   ease_factor : multiplier for interval growth (starts at 2.5, min 1.3)
#   repetitions : number of successful reviews in a row
#   due_at      : Unix timestamp (seconds) when the item is next due
#
# Quality ratings mapped to SM-2 q (0–5):
#   "Got it"  → q = 5
#   "Almost"  → q = 3
#   "Forgot"  → q = 1

retrieval_path <- function() {
  path <- file.path(Sys.getenv("HOME"), ".r4ds-guide", "retrieval.json")
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  path
}

read_retrieval <- function() {
  p <- retrieval_path()
  if (!file.exists(p)) return(list())
  tryCatch(
    jsonlite::read_json(p, simplifyVector = FALSE),
    error = function(e) list()
  )
}

write_retrieval <- function(schedule) {
  jsonlite::write_json(schedule, retrieval_path(), auto_unbox = TRUE, pretty = TRUE)
}

#' Schedule an exercise for retrieval practice (call when first cleared).
schedule_retrieval <- function(id) {
  schedule <- read_retrieval()
  if (!is.null(schedule[[id]])) return(invisible(schedule))  # already scheduled
  schedule[[id]] <- list(
    interval    = 1,
    ease_factor = 2.5,
    repetitions = 0L,
    due_at      = as.numeric(Sys.time()) + 86400  # due in 1 day
  )
  write_retrieval(schedule)
  invisible(schedule)
}

#' Update the SM-2 schedule after a retrieval attempt.
#' rating: one of "Got it", "Almost", "Forgot"
update_retrieval <- function(id, rating) {
  q <- switch(rating, "Got it" = 5, "Almost" = 3, "Forgot" = 1, 3)

  schedule <- read_retrieval()
  item <- schedule[[id]]
  if (is.null(item)) return(invisible(schedule))

  ef  <- max(1.3, item$ease_factor + 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
  rep <- item$repetitions

  if (q >= 3) {
    interval <- switch(
      as.character(rep),
      "0" = 1,
      "1" = 6,
      ceiling(item$interval * ef)
    )
    rep <- rep + 1L
  } else {
    interval <- 1
    rep      <- 0L
  }

  schedule[[id]] <- list(
    interval    = interval,
    ease_factor = ef,
    repetitions = rep,
    due_at      = as.numeric(Sys.time()) + interval * 86400
  )
  write_retrieval(schedule)
  invisible(schedule)
}

#' Return ids of exercises that are due for retrieval right now.
due_items <- function() {
  schedule <- read_retrieval()
  now <- as.numeric(Sys.time())
  Filter(function(id) schedule[[id]]$due_at <= now, names(schedule))
}

#' Number of items currently due.
n_due <- function() length(due_items())
