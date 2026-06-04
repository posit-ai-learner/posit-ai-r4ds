# Exercise registry for R4DS Guide.
# Each exercise is a named list following the schema from SPEC.md.
# setup_r is prepended to every run so data/packages are always available.

exercises <- list(

  # ── Chapter 1: Data Visualisation ────────────────────────────────────────

  list(
    id            = "viz-scatter-basic",
    chapter       = 1,
    chapter_title = "Data visualisation",
    title         = "Your first scatter plot",
    prompt        = paste0(
      "<p>The <code>mpg</code> data frame (from ggplot2) records fuel economy ",
      "data for 38 car models. Two numeric columns you care about:</p>",
      "<ul><li><code>displ</code> — engine displacement, in litres</li>",
      "<li><code>hwy</code> — highway miles per gallon</li></ul>",
      "<p><strong>Create a scatter plot with <code>displ</code> on the x-axis ",
      "and <code>hwy</code> on the y-axis.</strong></p>"
    ),
    setup_r       = 'suppressPackageStartupMessages(library(ggplot2))',
    starter_r     = '# mpg is available from ggplot2\nhead(mpg)\n\n# your scatter plot:\n',
    setup_note    = "# ggplot2 is loaded for you each run",
    expected      = "a ggplot scatter plot with displ on x and hwy on y using geom_point()",
    concepts      = c("ggplot2 basics", "aesthetics", "geom_point"),
    prereqs       = character(0)
  ),

  list(
    id            = "viz-color-class",
    chapter       = 1,
    chapter_title = "Data visualisation",
    title         = "Color by vehicle class",
    prompt        = paste0(
      "<p>Take the scatter plot from the previous exercise (displ vs hwy) and ",
      "<strong>map the <code>class</code> variable to the color aesthetic</strong> ",
      "so each vehicle class gets a different color.</p>"
    ),
    setup_r       = 'suppressPackageStartupMessages(library(ggplot2))',
    starter_r     = '# build on the previous exercise\n\n# your answer:\n',
    setup_note    = "# ggplot2 is loaded for you each run",
    expected      = "scatter plot of displ vs hwy with color = class mapped",
    concepts      = c("color aesthetic", "categorical mapping"),
    prereqs       = c("viz-scatter-basic")
  ),

  list(
    id            = "viz-boxplot-hwy",
    chapter       = 1,
    chapter_title = "Data visualisation",
    title         = "Highway MPG by drive type",
    prompt        = paste0(
      "<p>Using the <code>mpg</code> dataset, <strong>create a boxplot that shows ",
      "the distribution of <code>hwy</code> (highway MPG) for each drive type ",
      "(<code>drv</code>).</strong></p>",
      "<p style='font-size:14px;color:#666'>Hint: <code>drv</code> goes on one ",
      "axis, <code>hwy</code> on the other.</p>"
    ),
    setup_r       = 'suppressPackageStartupMessages(library(ggplot2))',
    starter_r     = '# your boxplot:\n',
    setup_note    = "# ggplot2 is loaded for you each run",
    expected      = "boxplot with drv on x (or y) and hwy on the other axis using geom_boxplot()",
    concepts      = c("geom_boxplot", "distributions", "categorical x-axis"),
    prereqs       = c("viz-scatter-basic")
  ),

  # ── Chapter 3: Data Transformation ───────────────────────────────────────

  list(
    id            = "transform-filter-engines",
    chapter       = 3,
    chapter_title = "Data transformation",
    title         = "Four-cylinder cars only",
    prompt        = paste0(
      "<p>The built-in <code>mtcars</code> data frame has a column <code>cyl</code> ",
      "for number of cylinders. <strong>Filter it to only rows where <code>cyl == 4</code> ",
      "and show only the <code>mpg</code>, <code>cyl</code>, and <code>hp</code> columns.</strong></p>"
    ),
    setup_r       = 'suppressPackageStartupMessages(library(dplyr))',
    starter_r     = '# mtcars is a built-in R dataset\nhead(mtcars)\n\n# filter and select:\n',
    setup_note    = "# dplyr is loaded; mtcars is always available",
    expected      = "data frame with only cyl == 4 rows and three columns: mpg, cyl, hp",
    concepts      = c("filter", "select", "comparison operators"),
    prereqs       = character(0)
  ),

  list(
    id            = "transform-heaviest-species",
    chapter       = 3,
    chapter_title = "Data transformation",
    title         = "Heaviest species first",
    prompt        = paste0(
      "<p>A small <code>penguins</code> data frame has been created for you ",
      "(run the starter code to peek at it). Your task:</p>",
      "<p><strong>For each <code>species</code>, compute the mean ",
      "<code>body_mass_g</code>, then sort so the heaviest species is on top.</strong></p>"
    ),
    setup_r       = 'suppressPackageStartupMessages(library(dplyr))
penguins <- data.frame(
  species         = c("Adelie","Adelie","Adelie","Gentoo","Gentoo","Chinstrap","Chinstrap","Gentoo","Adelie","Chinstrap"),
  body_mass_g     = c(3750, 3800, 3250, 5000, 5150, 3500, 3700, 4900, 3900, 3650),
  flipper_length_mm = c(181, 186, 195, 210, 215, 192, 196, 212, 190, 193)
)',
    starter_r     = "# peek first\nhead(penguins)\n\n# your answer:\n",
    setup_note    = "# dplyr loaded; penguins data frame created for you each run",
    expected      = "per-species mean of body_mass_g sorted descending (Gentoo ~4683, Adelie ~3675, Chinstrap ~3617)",
    concepts      = c("group_by", "summarise", "arrange", "desc"),
    prereqs       = c("transform-filter-engines")
  ),

  list(
    id            = "transform-mutate-kpl",
    chapter       = 3,
    chapter_title = "Data transformation",
    title         = "Add a km-per-litre column",
    prompt        = paste0(
      "<p><code>mtcars</code> has a <code>mpg</code> column in US miles per gallon. ",
      "1 mpg ≈ 0.4251 km/L. <strong>Use <code>mutate()</code> to add a new column ",
      "<code>kpl</code> that converts <code>mpg</code> to km per litre, then select ",
      "just <code>mpg</code> and <code>kpl</code>.</strong></p>"
    ),
    setup_r       = 'suppressPackageStartupMessages(library(dplyr))',
    starter_r     = '# your answer:\n',
    setup_note    = "# dplyr loaded; mtcars is always available",
    expected      = "data frame with mpg and kpl columns, kpl = mpg * 0.4251",
    concepts      = c("mutate", "arithmetic on columns"),
    prereqs       = c("transform-filter-engines")
  ),

  list(
    id            = "transform-count-species",
    chapter       = 3,
    chapter_title = "Data transformation",
    title         = "Penguin count by species and island",
    prompt        = paste0(
      "<p>Using the <code>penguins</code> data frame (created for you), ",
      "<strong>count the number of penguins for each combination of ",
      "<code>species</code> and <code>island</code>, sorted from most to fewest.</strong></p>"
    ),
    setup_r       = 'suppressPackageStartupMessages(library(dplyr))
penguins <- data.frame(
  species = c("Adelie","Adelie","Adelie","Gentoo","Gentoo","Chinstrap","Chinstrap","Gentoo","Adelie","Chinstrap","Adelie","Adelie"),
  island  = c("Torgersen","Torgersen","Dream","Biscoe","Biscoe","Dream","Dream","Biscoe","Biscoe","Dream","Dream","Biscoe"),
  body_mass_g = c(3750,3800,3250,5000,5150,3500,3700,4900,3100,3650,3400,3550)
)',
    starter_r     = "# your answer:\n",
    setup_note    = "# dplyr loaded; penguins data frame created for you each run",
    expected      = "counts of species+island combinations, sorted descending by n",
    concepts      = c("count", "sort", "grouped counting"),
    prereqs       = c("transform-heaviest-species")
  ),

  list(
    id            = "transform-mean-flipper",
    chapter       = 3,
    chapter_title = "Data transformation",
    title         = "Mean flipper length by species",
    prompt        = paste0(
      "<p>Using the <code>penguins</code> data frame, <strong>compute the mean ",
      "<code>flipper_length_mm</code> for each <code>species</code>. ",
      "Also include <code>n()</code> to show how many penguins are in each group.</strong></p>"
    ),
    setup_r       = 'suppressPackageStartupMessages(library(dplyr))
penguins <- data.frame(
  species           = c("Adelie","Adelie","Adelie","Gentoo","Gentoo","Chinstrap","Chinstrap","Gentoo","Adelie","Chinstrap"),
  body_mass_g       = c(3750,3800,3250,5000,5150,3500,3700,4900,3900,3650),
  flipper_length_mm = c(181,186,195,210,215,192,196,212,190,193)
)',
    starter_r     = "# your answer:\n",
    setup_note    = "# dplyr loaded; penguins data frame created for you each run",
    expected      = "per-species mean flipper_length_mm and count n, three rows (one per species)",
    concepts      = c("group_by", "summarise", "n()", "mean"),
    prereqs       = c("transform-heaviest-species")
  ),

  # ── Chapter 5: Data Tidying ───────────────────────────────────────────────

  list(
    id            = "tidy-pivot-longer",
    chapter       = 5,
    chapter_title = "Data tidying",
    title         = "Scores from wide to long",
    prompt        = paste0(
      "<p>The <code>scores</code> data frame below is in wide format — each ",
      "assessment is a column. That makes it hard to plot or summarise by assessment.</p>",
      "<p><strong>Use <code>pivot_longer()</code> to reshape it so there are three ",
      "columns: <code>student</code>, <code>assessment</code>, and <code>score</code>.</strong></p>"
    ),
    setup_r       = 'suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(dplyr))
scores <- data.frame(
  student  = c("Alice", "Bob", "Carol"),
  midterm  = c(82, 74, 91),
  final    = c(88, 79, 95),
  project  = c(76, 85, 88)
)',
    starter_r     = "# peek first\nscores\n\n# pivot to long format:\n",
    setup_note    = "# tidyr + dplyr loaded; scores data frame created for you",
    expected      = "long data frame with 9 rows and columns: student, assessment, score",
    concepts      = c("pivot_longer", "tidy data", "reshaping"),
    prereqs       = character(0)
  ),

  list(
    id            = "tidy-pivot-wider",
    chapter       = 5,
    chapter_title = "Data tidying",
    title         = "Measurements from long to wide",
    prompt        = paste0(
      "<p>The <code>readings</code> data frame is in long format. ",
      "<strong>Use <code>pivot_wider()</code> to reshape it so each station ",
      "becomes its own column.</strong></p>"
    ),
    setup_r       = 'suppressPackageStartupMessages(library(tidyr))
readings <- data.frame(
  day     = c(1, 1, 2, 2, 3, 3),
  station = c("A", "B", "A", "B", "A", "B"),
  temp    = c(14.2, 15.1, 13.8, 14.9, 15.5, 16.0)
)',
    starter_r     = "# peek first\nreadings\n\n# pivot to wide format:\n",
    setup_note    = "# tidyr loaded; readings data frame created for you",
    expected      = "wide data frame with 3 rows (one per day) and columns: day, A, B",
    concepts      = c("pivot_wider", "tidy data", "reshaping"),
    prereqs       = c("tidy-pivot-longer")
  ),

  list(
    id            = "tidy-separate",
    chapter       = 5,
    chapter_title = "Data tidying",
    title         = "Split a date column",
    prompt        = paste0(
      "<p>The <code>events</code> data frame has a <code>date</code> column ",
      "in <code>YYYY-MM-DD</code> format stored as a character string. ",
      "<strong>Separate it into three columns: <code>year</code>, <code>month</code>, ",
      "and <code>day</code>.</strong></p>"
    ),
    setup_r       = 'suppressPackageStartupMessages(library(tidyr))
events <- data.frame(
  event = c("Conference", "Workshop", "Seminar"),
  date  = c("2025-03-15", "2025-07-22", "2026-01-08"),
  stringsAsFactors = FALSE
)',
    starter_r     = "# peek first\nevents\n\n# separate the date column:\n",
    setup_note    = "# tidyr loaded; events data frame created for you",
    expected      = "data frame with event, year, month, day columns (date split by '-')",
    concepts      = c("separate", "string splitting", "column splitting"),
    prereqs       = c("tidy-pivot-longer")
  )

)

# ── Accessors ─────────────────────────────────────────────────────────────────

#' Get a single exercise by id (returns first if id is NULL/missing).
get_exercise <- function(id = NULL) {
  if (is.null(id)) return(exercises[[1]])
  found <- Filter(function(ex) ex$id == id, exercises)
  if (length(found) == 0) exercises[[1]] else found[[1]]
}

#' Return all exercise ids in order.
exercise_ids <- function() vapply(exercises, `[[`, character(1), "id")

#' Return exercises grouped by chapter as a named list.
exercises_by_chapter <- function() {
  chapters <- vapply(exercises, `[[`, integer(1), "chapter")
  split(exercises, chapters)
}
