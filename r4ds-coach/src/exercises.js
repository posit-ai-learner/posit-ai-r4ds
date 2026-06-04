// Exercise registry. Claude Code: add more following this schema (see SPEC.md).
// setupR is prepended to every run so the data always exists.

export const exercises = [
  {
    id: 'transform-heaviest-species',
    chapter: 3,
    chapterTitle: 'Data transformation',
    title: 'Heaviest species first',
    promptHtml: `
      <p>A small <code class="inline">penguins</code> data frame has been created for
      you (run the code to peek at it). Your task:</p>
      <p><strong>For each <code class="inline">species</code>, compute the mean
      <code class="inline">body_mass_g</code>, then sort so the heaviest species is on top.</strong></p>
      <p style="font-size:15px;color:var(--ink-soft)">Solve it however you like — base R
      works immediately, and <code class="inline">dplyr</code> loads in the background.</p>`,
    setupR: `penguins <- data.frame(
  species = c("Adelie","Adelie","Adelie","Gentoo","Gentoo","Chinstrap","Chinstrap","Gentoo","Adelie","Chinstrap"),
  body_mass_g = c(3750,3800,3250,5000,5150,3500,3700,4900,3900,3650),
  flipper_length_mm = c(181,186,195,210,215,192,196,212,190,193),
  stringsAsFactors = FALSE
)`,
    starterR: `# peek first — then transform
head(penguins)

# your answer below:
`,
    setupNote:
      '# prepended for you each run:  penguins <- data.frame(species=…, body_mass_g=…, flipper_length_mm=…)',
    expected:
      'a per-species mean of body_mass_g, sorted descending (Gentoo ~4762, Adelie ~3675, Chinstrap ~3617)',
    concepts: ['group-wise summary', 'sorting'],
    prereqs: [],
  },
];

export function getExercise(id) {
  return exercises.find((e) => e.id === id) || exercises[0];
}
