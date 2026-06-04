# Safe(ish) R code execution using evaluate::evaluate().
# Captures text output, warnings, messages, errors, and plots.
# Runs in a child of the global environment so packages are accessible,
# but assignments don't pollute the global env.

#' Run user-submitted code (with optional setup prefix) and return a result list.
#'
#' @param code      Character string of learner code.
#' @param setup_r   Character string prepended to code (data/package setup).
#' @return A list:
#'   $text     — captured text output as a single string (may include warnings/errors)
#'   $plot_file — path to a saved PNG if a plot was produced, else NULL
#'   $has_error — logical
run_code <- function(code, setup_r = "") {
  full_code <- if (nchar(trimws(setup_r)) > 0) {
    paste(setup_r, code, sep = "\n\n")
  } else {
    code
  }

  env       <- new.env(parent = globalenv())
  text_out  <- character(0)
  has_error <- FALSE
  plot_file <- NULL
  tmp_png   <- tempfile(fileext = ".png")

  results <- tryCatch(
    evaluate::evaluate(full_code, envir = env, new_device = TRUE, stop_on_error = 0L),
    error = function(e) list(simpleError(conditionMessage(e)))
  )

  for (item in results) {
    if (is.character(item)) {
      text_out <- c(text_out, item)

    } else if (inherits(item, "recordedplot")) {
      tryCatch({
        grDevices::png(tmp_png, width = 720, height = 450, res = 110)
        grDevices::replayPlot(item)
        grDevices::dev.off()
        plot_file <- tmp_png
      }, error = function(e) {
        try(grDevices::dev.off(), silent = TRUE)
      })

    } else if (inherits(item, "warning")) {
      text_out <- c(text_out, paste0("Warning: ", conditionMessage(item), "\n"))

    } else if (inherits(item, "message")) {
      # Suppress routine package startup messages from setup_r
      msg <- conditionMessage(item)
      if (!grepl("^Attaching|^The following", msg)) {
        text_out <- c(text_out, msg)
      }

    } else if (inherits(item, "error")) {
      has_error <- TRUE
      text_out  <- c(text_out, paste0("Error: ", conditionMessage(item), "\n"))
    }
  }

  list(
    text      = paste(text_out, collapse = ""),
    plot_file = plot_file,
    has_error = has_error
  )
}
