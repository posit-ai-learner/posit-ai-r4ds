library(shiny)
library(bslib)
library(ellmer)
library(evaluate)
library(jsonlite)

# Load helpers ----------------------------------------------------------------
source("R/exercises.R")
source("R/progress.R")
source("R/retrieval.R")
source("R/run_code.R")
source("R/hints.R")

# Null-coalescing: return b if a is NULL or empty string
`%||%` <- function(a, b) {
  if (!is.null(a) && nchar(trimws(as.character(a))) > 0) a else b
}

# ── Shared JS (tab-key indent + set_editor custom message handler) ────────────
tab_js <- tags$script(HTML(
  '
  $(document).on("keydown", "#code_editor", function(e) {
    if (e.key === "Tab") {
      e.preventDefault();
      var el = this, s = el.selectionStart, end = el.selectionEnd;
      el.value = el.value.slice(0, s) + "  " + el.value.slice(end);
      el.selectionStart = el.selectionEnd = s + 2;
      Shiny.setInputValue("code_editor", el.value, {priority: "event"});
    }
  });
  Shiny.addCustomMessageHandler("set_editor", function(val) {
    var el = document.getElementById("code_editor");
    if (el) {
      el.value = val;
      Shiny.setInputValue("code_editor", val, {priority: "event"});
    }
  });
'
))

# ── Chapter/exercise nav sidebar (rendered server-side so dots update) ────────
render_nav <- function(all_progress, current_id, review_due = 0) {
  groups <- exercises_by_chapter()

  chapter_names <- c(
    "1" = "Chapter 1 · Visualisation",
    "3" = "Chapter 3 · Transformation",
    "5" = "Chapter 5 · Tidy data"
  )

  nav_items <- lapply(names(groups), function(ch_key) {
    exs <- groups[[ch_key]]
    ch_label <- chapter_names[ch_key]
    n_cleared <- sum(vapply(
      exs,
      function(ex) {
        identical(get_progress(ex$id, all_progress)$status, "cleared")
      },
      logical(1)
    ))

    ex_links <- lapply(exs, function(ex) {
      p <- get_progress(ex$id, all_progress)
      colour <- status_colour(p$status)
      active <- identical(ex$id, current_id)

      tags$div(
        class = paste("nav-ex", if (active) "nav-ex-active"),
        style = if (active) "background:#e9ecef;" else "",
        tags$span(
          class = "status-dot",
          style = paste0("background:", colour, ";")
        ),
        actionLink(
          inputId = paste0("nav_", gsub("-", "_", ex$id)),
          label = ex$title,
          style = "font-size:13px; padding:0; border:none; background:none; text-align:left; color:inherit;"
        )
      )
    })

    tagList(
      tags$div(
        class = "nav-chapter",
        tags$span(ch_label, class = "nav-chapter-label"),
        tags$span(
          paste0(n_cleared, "/", length(exs)),
          class = "nav-chapter-count"
        )
      ),
      tagList(ex_links)
    )
  })

  review_banner <- if (review_due > 0) {
    tags$div(
      class = "review-banner",
      tags$span(
        "\u23f0 ",
        review_due,
        " review",
        if (review_due > 1) "s" else "",
        " due"
      ),
      actionLink(
        "show_review",
        "Start review \u2192",
        style = "font-weight:600; color:var(--bs-success);"
      )
    )
  }

  tagList(review_banner, tagList(nav_items))
}

# ── Coach message HTML (hint or feedback) ─────────────────────────────────────
coach_card <- function(label, sublabel = NULL, md_text, is_feedback = FALSE) {
  border_colour <- if (is_feedback) "var(--bs-success)" else "var(--bs-warning)"
  bg_colour <- if (is_feedback) "#d1e7dd" else "#fff3cd"
  lbl_colour <- if (is_feedback) "var(--bs-success)" else "var(--bs-secondary)"

  html_body <- md_to_html(md_text)

  tags$div(
    style = paste0(
      "border-left:3px solid ",
      border_colour,
      "; background:",
      bg_colour,
      "; ",
      "border-radius:0 10px 10px 0; padding:14px 18px; margin-top:14px;"
    ),
    tags$div(
      style = paste0(
        "font-family:monospace; font-size:11px; text-transform:uppercase; ",
        "letter-spacing:.12em; color:",
        lbl_colour,
        "; margin-bottom:5px; ",
        "display:flex; justify-content:space-between;"
      ),
      tags$span(label),
      if (!is.null(sublabel)) tags$span(sublabel)
    ),
    HTML(html_body)
  )
}

# ── Tiny Markdown → HTML (code blocks + inline code + paragraphs) ─────────────
md_to_html <- function(md) {
  # Fenced code blocks
  parts <- strsplit(md, "```(?:r|R)?\\n?", perl = TRUE)[[1]]
  html <- ""
  in_code <- FALSE
  for (p in parts) {
    if (in_code) {
      html <- paste0(
        html,
        "<pre style='background:#212529;color:#dee2e6;padding:12px;",
        "border-radius:8px;overflow:auto;font-family:monospace;font-size:13px;",
        "margin:8px 0'>",
        htmltools::htmlEscape(sub("\\n$", "", p)),
        "</pre>"
      )
    } else {
      paras <- strsplit(trimws(p), "\\n{2,}")[[1]]
      for (para in paras) {
        para <- trimws(para)
        if (nchar(para) == 0) {
          next
        }
        # Inline code
        para <- gsub(
          "`([^`]+)`",
          "<code style='font-family:monospace;font-size:.85em;background:#f8f9fa;border:1px solid #dee2e6;padding:1px 5px;border-radius:4px'>\\1</code>",
          para
        )
        html <- paste0(html, "<p style='margin:0 0 8px'>", para, "</p>")
      }
    }
    in_code <- !in_code
  }
  if (nchar(html) == 0) {
    paste0("<p>", htmltools::htmlEscape(md), "</p>")
  } else {
    html
  }
}

# ═════════════════════════════════════════════════════════════════════════════
# UI
# ═════════════════════════════════════════════════════════════════════════════

ui <- page_sidebar(
  title = tags$span(
    class = "fw-bold",
    "R4DS ",
    tags$em("Guide", class = "text-primary")
  ),
  theme = bs_theme(
    bootswatch = "litera",
    code_font = font_google("JetBrains Mono")
  ),

  # ── Sidebar ──────────────────────────────────────────────────────────────
  sidebar = sidebar(
    width = 240,
    style = "font-size:13px; padding:12px 10px;",
    uiOutput("nav_sidebar")
  ),

  # ── Main content ──────────────────────────────────────────────────────────
  tags$head(
    tab_js,
    tags$style(HTML(
      "
      .nav-chapter       { margin:14px 0 4px; }
      .nav-chapter-label { font-size:11px; font-weight:700; text-transform:uppercase;
                           letter-spacing:.12em; color:var(--bs-secondary); }
      .nav-chapter-count { float:right; font-size:11px; color:var(--bs-success); font-weight:700; }
      .nav-ex            { display:flex; align-items:center; gap:7px;
                           padding:4px 6px; border-radius:6px; cursor:pointer; }
      .nav-ex:hover      { background:var(--bs-light); }
      .nav-ex-active     { background:#e9ecef; }
      .status-dot        { width:9px; height:9px; border-radius:50%; flex:none; }
      .review-banner     { background:#d1e7dd; border:1px solid var(--bs-success); border-radius:8px;
                           padding:8px 10px; margin-bottom:10px; font-size:12px; color:#0a3622; }
      .kicker            { font-family:monospace; font-size:11px; letter-spacing:.18em;
                           text-transform:uppercase; color:var(--bs-secondary); margin:0 0 6px; }
      .hint-ladder       { display:flex; gap:5px; margin-top:6px; }
      .hint-bar          { height:4px; flex:1; border-radius:2px; background:#dee2e6; }
      .hint-bar-on       { background:var(--bs-warning); }
      #code_editor       { width:100%; min-height:160px; font-family:'JetBrains Mono',monospace;
                           font-size:13.5px; line-height:1.6; padding:14px;
                           background:#f8f9fa; border:1px solid #dee2e6; border-radius:8px;
                           resize:vertical; tab-size:2; }
      .console-out       { background:#212529; color:#dee2e6; font-family:monospace;
                           font-size:13px; padding:12px 16px; border-radius:8px;
                           min-height:44px; white-space:pre-wrap; border:1px solid #000; }
      .attempts-badge    { font-family:monospace; font-size:12px; color:var(--bs-secondary); }
    "
    ))
  ),

  # ── Exercise card ──────────────────────────────────────────────────────
  card(
    card_header(
      uiOutput("ex_kicker"),
      uiOutput("ex_title")
    ),
    card_body(
      uiOutput("ex_prompt"),

      # Code editor
      tags$div(
        style = "margin-top:12px;",
        tags$label("Your code", style = "font-weight:600; font-size:14px;"),
        tags$textarea(
          id = "code_editor",
          placeholder = "# write your R code here"
        )
      ),
      uiOutput("setup_note_ui"),

      # Action buttons
      tags$div(
        style = "display:flex; gap:10px; flex-wrap:wrap; align-items:center; margin-top:12px;",
        actionButton("run_btn", "\u25b7 Run", class = "btn btn-success"),
        actionButton(
          "hint_btn",
          "Need a hint",
          class = "btn btn-outline-warning"
        ),
        actionButton("check_btn", "Check my answer", class = "btn btn-dark"),
        uiOutput("attempts_badge")
      ),

      # Hint ladder
      uiOutput("hint_ladder"),

      # Output console
      tags$div(
        style = "margin-top:12px;",
        tags$div(
          id = "console_out",
          class = "console-out",
          uiOutput("run_output_text")
        )
      ),

      # Plot output (hidden when no plot)
      uiOutput("plot_area"),

      # Coach messages (hints + feedback)
      tags$div(id = "coach_msgs", uiOutput("coach_messages"))
    )
  ),
)

# ═════════════════════════════════════════════════════════════════════════════
# Server
# ═════════════════════════════════════════════════════════════════════════════

server <- function(input, output, session) {
  # ── Reactive state ─────────────────────────────────────────────────────────
  current_id <- reactiveVal(exercises[[1]]$id)
  attempts <- reactiveVal(0L)
  hint_tier <- reactiveVal(0L)
  last_output <- reactiveVal("")
  run_result <- reactiveVal(list(
    text = "",
    plot_file = NULL,
    has_error = FALSE
  ))
  coach_msgs <- reactiveVal(list()) # list of tagLists, newest first
  all_progress <- reactiveVal(read_progress())
  review_mode <- reactiveVal(FALSE)
  review_id <- reactiveVal(NULL)
  review_run_result <- reactiveVal(list(
    text = "",
    plot_file = NULL,
    has_error = FALSE
  ))
  review_feedback <- reactiveVal(NULL)

  current_ex <- reactive(get_exercise(current_id()))

  # ── Sidebar navigation ──────────────────────────────────────────────────────
  output$nav_sidebar <- renderUI({
    render_nav(all_progress(), current_id(), n_due())
  })

  # Wire up each nav link dynamically
  observe({
    lapply(exercises, function(ex) {
      local({
        eid <- ex$id
        input_id <- paste0("nav_", gsub("-", "_", eid))
        observeEvent(
          input[[input_id]],
          {
            load_exercise(eid)
          },
          ignoreInit = TRUE
        )
      })
    })
  })

  # ── Load exercise (reset session state) ────────────────────────────────────
  load_exercise <- function(id) {
    ex <- get_exercise(id)
    current_id(id)
    attempts(0L)
    hint_tier(0L)
    last_output("")
    run_result(list(text = "", plot_file = NULL, has_error = FALSE))
    coach_msgs(list())
    review_mode(FALSE)
    # Update editor content via JS
    session$sendCustomMessage("set_editor", ex$starter_r)
  }

  # Initialise editor with first exercise starter code
  observe({
    session$sendCustomMessage("set_editor", exercises[[1]]$starter_r)
  })

  # ── Exercise UI ─────────────────────────────────────────────────────────────
  output$ex_kicker <- renderUI({
    ex <- current_ex()
    tags$p(
      class = "kicker",
      paste0("Chapter ", ex$chapter, " \u00b7 ", ex$chapter_title)
    )
  })

  output$ex_title <- renderUI({
    tags$h3(current_ex()$title, style = "margin:0 0 8px; font-weight:700;")
  })

  output$ex_prompt <- renderUI({
    HTML(current_ex()$prompt)
  })

  output$setup_note_ui <- renderUI({
    note <- current_ex()$setup_note
    if (!is.null(note) && nchar(trimws(note)) > 0) {
      tags$pre(
        note,
        style = "font-size:11.5px; color:var(--bs-secondary); background:#f8f9fa;
                        border-top:1px dashed #dee2e6; padding:8px 12px;
                        border-radius:0 0 8px 8px; margin-top:-2px;"
      )
    }
  })

  output$attempts_badge <- renderUI({
    n <- attempts()
    tags$span(class = "attempts-badge", paste(n, if (n == 1) "run" else "runs"))
  })

  output$hint_ladder <- renderUI({
    tier <- hint_tier()
    bars <- lapply(1:4, function(i) {
      cls <- if (i <= tier) "hint-bar hint-bar-on" else "hint-bar"
      tags$div(class = cls)
    })
    tags$div(class = "hint-ladder", bars)
  })

  # ── Run button ──────────────────────────────────────────────────────────────
  observeEvent(input$run_btn, {
    code <- input$code_editor %||% ""
    ex <- current_ex()

    withProgress(message = "Running\u2026", value = 0.5, {
      result <- run_code(code, ex$setup_r)
    })

    run_result(result)
    last_output(result$text)
    attempts(attempts() + 1L)
    all_progress(record_attempt(ex$id, all_progress()))
  })

  output$run_output_text <- renderUI({
    res <- run_result()
    if (nchar(res$text) == 0 && is.null(res$plot_file)) {
      tags$span(
        style = "color:#6b655a; font-style:italic;",
        "output appears here after you run."
      )
    } else {
      style <- if (res$has_error) "color:#e8896f;" else ""
      tags$span(style = style, res$text)
    }
  })

  output$plot_area <- renderUI({
    res <- run_result()
    if (!is.null(res$plot_file) && file.exists(res$plot_file)) {
      tags$div(
        style = "margin-top:10px;",
        tags$img(
          src = knitr::image_uri(res$plot_file),
          style = "max-width:100%; border-radius:8px;"
        )
      )
    }
  })

  # ── Hint button ─────────────────────────────────────────────────────────────
  observeEvent(input$hint_btn, {
    ex <- current_ex()
    target <- min(hint_tier() + 1L, 4L)

    # Gate L4 until >= 2 runs
    if (target == 4L && attempts() < 2L) {
      showNotification(
        "Run your code at least twice before the full solution unlocks.",
        type = "warning",
        duration = 4
      )
      return()
    }

    hint_tier(target)
    all_progress(record_hint(ex$id, target, all_progress()))

    sublabel <- if (target < 4L) {
      "try it, then ask for more"
    } else {
      "full solution"
    }

    # Placeholder card while fetching
    placeholder_id <- paste0("hint_", target, "_", as.integer(Sys.time()))
    msgs <- coach_msgs()
    msgs <- c(
      list(coach_card(
        paste0("hint \u00b7 level ", target, " of 4"),
        "\u2026thinking\u2026",
        "_Fetching hint\u2026_"
      )),
      msgs
    )
    coach_msgs(msgs)

    withProgress(
      message = paste("Generating level", target, "hint\u2026"),
      value = 0.5,
      {
        text <- tryCatch(
          get_hint(ex, target, input$code_editor %||% "", last_output()),
          error = function(e) paste0("**Hint service error:** ", e$message)
        )
      }
    )

    msgs <- coach_msgs()
    msgs[[1]] <- coach_card(
      paste0("hint \u00b7 level ", target, " of 4"),
      sublabel,
      text
    )
    coach_msgs(msgs)

    # Update hint button label
    updateActionButton(
      session,
      "hint_btn",
      label = if (target >= 4L) "Solution shown" else "A little more help"
    )
  })

  # ── Check answer button ──────────────────────────────────────────────────────
  observeEvent(input$check_btn, {
    ex <- current_ex()

    # Auto-run if not yet run
    if (attempts() == 0L) {
      code <- input$code_editor %||% ""
      result <- run_code(code, ex$setup_r)
      run_result(result)
      last_output(result$text)
      attempts(1L)
      all_progress(record_attempt(ex$id, all_progress()))
    }

    # Placeholder
    msgs <- coach_msgs()
    msgs <- c(
      list(coach_card(
        "feedback",
        "\u2026checking\u2026",
        "_Checking your answer\u2026_",
        is_feedback = TRUE
      )),
      msgs
    )
    coach_msgs(msgs)

    withProgress(message = "Checking your answer\u2026", value = 0.5, {
      feedback_text <- tryCatch(
        get_feedback(
          ex,
          input$code_editor %||% "",
          last_output(),
          hint_tier() >= 4L
        ),
        error = function(e) paste0("**Feedback service error:** ", e$message)
      )
    })

    msgs <- coach_msgs()
    msgs[[1]] <- coach_card("feedback", NULL, feedback_text, is_feedback = TRUE)
    coach_msgs(msgs)

    # If correct, mark cleared and schedule retrieval
    if (grepl("^CORRECT", trimws(feedback_text), ignore.case = TRUE)) {
      all_progress(record_cleared(ex$id, all_progress()))
      schedule_retrieval(ex$id)
      showNotification(
        "\u2705 Exercise cleared!",
        type = "message",
        duration = 3
      )
    }
  })

  # ── Coach messages render ────────────────────────────────────────────────────
  output$coach_messages <- renderUI({
    msgs <- coach_msgs()
    if (length(msgs) == 0) {
      return(NULL)
    }
    tagList(msgs)
  })

  # ── Review mode ──────────────────────────────────────────────────────────────
  observeEvent(input$show_review, {
    due <- due_items()
    if (length(due) == 0) {
      return()
    }

    rid <- due[[1]]
    review_id(rid)
    review_mode(TRUE)
    review_feedback(NULL)
    review_run_result(list(text = "", plot_file = NULL, has_error = FALSE))

    ex <- get_exercise(rid)
    showModal(modalDialog(
      title = tags$span("\u23f0 Retrieval practice: ", ex$title),
      easyClose = FALSE,
      footer = NULL,

      tags$p(
        style = "font-style:italic; color:var(--bs-secondary); font-size:13px;",
        "You cleared this exercise before. Can you reconstruct it from memory?"
      ),
      HTML(ex$prompt),
      tags$div(
        style = "margin-top:12px;",
        tags$textarea(
          id = "review_code",
          style = paste0(
            "width:100%; min-height:140px; font-family:monospace; font-size:13px; ",
            "padding:12px; background:#f8f9fa; border:1px solid #dee2e6; border-radius:8px;"
          ),
          placeholder = "# your answer from memory:"
        )
      ),
      tags$div(
        style = "display:flex; gap:10px; margin-top:10px;",
        actionButton(
          "review_run",
          "\u25b7 Run",
          class = "btn btn-success btn-sm"
        ),
        actionButton(
          "review_check",
          "Check my answer",
          class = "btn btn-dark btn-sm"
        )
      ),
      uiOutput("review_output"),
      uiOutput("review_feedback_ui"),
      tags$div(
        style = "margin-top:14px; border-top:1px solid #dee2e6; padding-top:12px;",
        tags$strong("How did that feel?"),
        tags$div(
          style = "display:flex; gap:8px; margin-top:6px;",
          actionButton(
            "rate_gotit",
            "\u2713 Got it",
            class = "btn btn-outline-success btn-sm"
          ),
          actionButton(
            "rate_almost",
            "\u223c Almost",
            class = "btn btn-outline-warning btn-sm"
          ),
          actionButton(
            "rate_forgot",
            "\u2717 Forgot",
            class = "btn btn-outline-danger btn-sm"
          )
        )
      )
    ))
  })

  observeEvent(input$review_run, {
    ex <- get_exercise(review_id())
    code <- input$review_code %||% ""
    result <- run_code(code, ex$setup_r)
    review_run_result(result)
  })

  output$review_output <- renderUI({
    res <- review_run_result()
    if (nchar(res$text) == 0 && is.null(res$plot_file)) {
      return(NULL)
    }
    tags$pre(
      res$text,
      style = "background:#212529; color:#dee2e6; padding:10px;
                      border-radius:6px; font-size:12px; margin-top:8px;"
    )
  })

  observeEvent(input$review_check, {
    ex <- get_exercise(review_id())
    code <- input$review_code %||% ""
    res <- review_run_result()
    if (nchar(trimws(res$text)) == 0) {
      result <- run_code(code, ex$setup_r)
      review_run_result(result)
      res <- result
    }
    withProgress(message = "Checking\u2026", value = 0.5, {
      fb <- tryCatch(
        get_retrieval_feedback(ex, code, res$text),
        error = function(e) paste0("**Error:** ", e$message)
      )
    })
    review_feedback(fb)
  })

  output$review_feedback_ui <- renderUI({
    fb <- review_feedback()
    if (is.null(fb)) {
      return(NULL)
    }
    coach_card("retrieval feedback", NULL, fb, is_feedback = TRUE)
  })

  # Rating buttons close modal and update SM-2
  for (btn in c("rate_gotit", "rate_almost", "rate_forgot")) {
    local({
      b <- btn
      rat <- switch(
        b,
        rate_gotit = "Got it",
        rate_almost = "Almost",
        rate_forgot = "Forgot"
      )
      observeEvent(
        input[[b]],
        {
          update_retrieval(review_id(), rat)
          removeModal()
          review_mode(FALSE)
          review_feedback(NULL)
          review_run_result(list(
            text = "",
            plot_file = NULL,
            has_error = FALSE
          ))
        },
        ignoreInit = TRUE
      )
    })
  }
}

shinyApp(ui, server)
