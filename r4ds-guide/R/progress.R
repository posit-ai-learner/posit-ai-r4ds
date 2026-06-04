# Progress persistence — reads/writes ~/.r4ds-guide/progress.json.
# Schema per exercise id:
#   status       : "untouched" | "attempted" | "cleared"
#   max_hint_level: 0..4
#   attempts     : integer (total Run clicks for this exercise)
#   cleared_at   : POSIXct or NA

progress_path <- function() {
  path <- file.path(Sys.getenv("HOME"), ".r4ds-guide", "progress.json")
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  path
}

#' Read the full progress list from disk.
read_progress <- function() {
  p <- progress_path()
  if (!file.exists(p)) {
    return(list())
  }
  tryCatch(
    jsonlite::read_json(p, simplifyVector = FALSE),
    error = function(e) list()
  )
}

#' Write the full progress list to disk.
write_progress <- function(progress) {
  jsonlite::write_json(
    progress,
    progress_path(),
    auto_unbox = TRUE,
    pretty = TRUE
  )
}

#' Get progress for a single exercise id (returns defaults if not recorded).
get_progress <- function(id, progress = NULL) {
  if (is.null(progress)) {
    progress <- read_progress()
  }
  if (!is.null(progress[[id]])) {
    progress[[id]]
  } else {
    list(
      status = "untouched",
      max_hint_level = 0L,
      attempts = 0L,
      cleared_at = NA
    )
  }
}

#' Update progress for a single exercise; merges patch into existing record.
set_progress <- function(id, patch, progress = NULL) {
  if (is.null(progress)) {
    progress <- read_progress()
  }
  existing <- get_progress(id, progress)
  # Merge patch fields; never regress status (cleared stays cleared)
  merged <- utils::modifyList(existing, patch)
  if (identical(existing$status, "cleared")) {
    merged$status <- "cleared"
  }
  progress[[id]] <- merged
  write_progress(progress)
  invisible(progress)
}

#' Convenience: record that the learner ran code for an exercise.
record_attempt <- function(id, progress = NULL) {
  if (is.null(progress)) {
    progress <- read_progress()
  }
  p <- get_progress(id, progress)
  patch <- list(
    attempts = p$attempts + 1L,
    status = if (identical(p$status, "untouched")) "attempted" else p$status
  )
  set_progress(id, patch, progress)
}

#' Convenience: record a hint level reached.
record_hint <- function(id, level, progress = NULL) {
  if (is.null(progress)) {
    progress <- read_progress()
  }
  p <- get_progress(id, progress)
  if (level > p$max_hint_level) {
    set_progress(id, list(max_hint_level = level), progress)
  } else {
    invisible(progress)
  }
}

#' Convenience: mark an exercise as cleared.
record_cleared <- function(id, progress = NULL) {
  if (is.null(progress)) {
    progress <- read_progress()
  }
  p <- get_progress(id, progress)
  if (!identical(p$status, "cleared")) {
    set_progress(
      id,
      list(status = "cleared", cleared_at = as.numeric(Sys.time())),
      progress
    )
  } else {
    invisible(progress)
  }
}

#' Status badge colour for use in the sidebar UI.
status_colour <- function(status) {
  switch(
    status,
    untouched = "#adb5bd",
    attempted = "#fd7e14",
    cleared = "#198754",
    "#adb5bd"
  )
}
