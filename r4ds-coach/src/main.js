import { bootWebR, runR, isDplyrReady } from './webr.js';
import { getExercise } from './exercises.js';
import hintSystemTpl from '../prompts/hint-system.md?raw';
import feedbackSystemTpl from '../prompts/feedback-system.md?raw';

/* ---------- elements ---------- */
const $ = (id) => document.getElementById(id);
const codeEl = $('code'),
  outEl = $('out'),
  coachEl = $('coach');
const runBtn = $('run'),
  hintBtn = $('hint'),
  checkBtn = $('check');
const rDot = $('r-dot'),
  rStatus = $('r-status'),
  dDot = $('d-dot'),
  dStatus = $('d-status');
const attemptsEl = $('attempts'),
  ladder = $('ladder');

/* ---------- exercise + learner state (in-memory) ---------- */
const ex = getExercise();
let attempts = 0; // Run clicks
let hintTier = 0; // 0..4
let lastOutput = ''; // most recent captured output

const LEVEL_BRIEF = {
  1: 'a single conceptual nudge — name the KIND of operation needed, no functions, no code.',
  2: 'point to the specific verbs/functions and the order to apply them — still NO complete code.',
  3: 'a code skeleton with the key parts left as blanks/comments — not a runnable answer.',
  4: 'the full, runnable, idiomatic solution WITH a short explanation of each step.',
};

/* ---------- render the exercise ---------- */
$('ex-kicker').textContent = `Chapter ${ex.chapter} · ${ex.chapterTitle}`;
$('ex-title').textContent = ex.title;
$('ex-prompt').innerHTML = ex.promptHtml;
$('setup-note').textContent = ex.setupNote || '';
codeEl.value = ex.starterR;

/* ---------- editor niceties ---------- */
codeEl.addEventListener('keydown', (e) => {
  if (e.key === 'Tab') {
    e.preventDefault();
    const s = codeEl.selectionStart,
      en = codeEl.selectionEnd;
    codeEl.value = codeEl.value.slice(0, s) + '  ' + codeEl.value.slice(en);
    codeEl.selectionStart = codeEl.selectionEnd = s + 2;
  }
});

const setAttempts = () =>
  (attemptsEl.textContent = attempts + (attempts === 1 ? ' run' : ' runs'));
const paintLadder = () =>
  [...ladder.children].forEach((b, i) => b.classList.toggle('on', i < hintTier));

/* ---------- boot WebR ---------- */
runBtn.disabled = true;
bootWebR((evt) => {
  if (evt === 'r-ready') {
    rDot.className = 'dot ok';
    rStatus.textContent = 'R ready — runs in your browser';
    runBtn.disabled = false;
    dDot.className = 'dot work';
    dStatus.textContent = 'dplyr: installing…';
  } else if (evt === 'dplyr-ready') {
    dDot.className = 'dot ok';
    dStatus.textContent = 'dplyr: ready';
  } else if (evt === 'dplyr-fail') {
    dDot.className = 'dot bad';
    dStatus.textContent = 'dplyr: unavailable (use base R)';
  }
}).catch((err) => {
  rDot.className = 'dot bad';
  rStatus.textContent = 'R failed to boot — see console';
  console.error(err);
});

/* ---------- run R ---------- */
async function doRun() {
  attempts++;
  setAttempts();
  outEl.textContent = 'running…';
  const full = ex.setupR + '\n\n' + codeEl.value;
  try {
    const output = await runR(full);
    lastOutput = output.map((o) => o.data).join('\n');
    outEl.innerHTML = '';
    if (!output.length) {
      outEl.textContent = '(ran with no printed output)';
    } else {
      output.forEach((o) => {
        const span = document.createElement('span');
        if (o.type === 'stderr') span.className = 'err';
        span.textContent = o.data + '\n';
        outEl.appendChild(span);
      });
    }
  } catch (err) {
    lastOutput = 'ERROR: ' + (err.message || err);
    outEl.innerHTML = `<span class="err">${escapeHtml(String(err.message || err))}</span>`;
  }
}

/* ---------- Claude proxy ---------- */
async function askClaude(system, userText) {
  const r = await fetch('/api/claude', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      max_tokens: 1024,
      system,
      messages: [{ role: 'user', content: userText }],
    }),
  });
  const data = await r.json();
  if (data.error) throw new Error(data.error.message || JSON.stringify(data.error));
  return (data.content || [])
    .filter((b) => b.type === 'text')
    .map((b) => b.text)
    .join('\n')
    .trim();
}

/* ---------- tiered hints (the pedagogical heart) ---------- */
async function getHint() {
  hintBtn.disabled = true;
  let target = Math.min(hintTier + 1, 4);
  if (target === 4 && attempts < 2) target = 3; // gate the full answer
  hintTier = target;
  paintLadder();

  const note = document.createElement('div');
  note.className = 'hint';
  note.innerHTML = `<div class="lvl"><span>hint · level ${target} of 4</span><span>thinking…</span></div><p>…</p>`;
  coachEl.prepend(note);

  const system = hintSystemTpl
    .replaceAll('{{LEVEL}}', String(target))
    .replaceAll('{{LEVEL_BRIEF}}', LEVEL_BRIEF[target]);

  const user =
    `EXERCISE: ${ex.promptHtml.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim()}\n\n` +
    `LEARNER'S CURRENT CODE:\n\`\`\`r\n${codeEl.value}\n\`\`\`\n\n` +
    `THEIR LAST RUN OUTPUT:\n${lastOutput || '(they haven\'t run anything yet)'}\n\n` +
    `dplyr available: ${isDplyrReady() ? 'yes' : 'no (suggest base R like aggregate()/order())'}.\n` +
    `Give the level ${target} hint now.`;

  try {
    const ans = await askClaude(system, user);
    note.innerHTML =
      `<div class="lvl"><span>hint · level ${target} of 4</span><span>${target < 4 ? 'try it, then ask for more' : 'full solution'}</span></div>` +
      mdToHtml(ans);
  } catch (err) {
    note.innerHTML = `<div class="lvl"><span>hint · level ${target}</span></div><p class="err">Hint service error: ${escapeHtml(String(err.message || err))}</p>`;
  } finally {
    hintBtn.disabled = false;
    hintBtn.textContent = hintTier >= 4 ? 'Solution shown' : 'A little more help';
  }
}

/* ---------- check answer ---------- */
async function checkAnswer() {
  if (lastOutput === '') await doRun();
  checkBtn.disabled = true;
  const note = document.createElement('div');
  note.className = 'hint feedback';
  note.innerHTML =
    '<div class="lvl"><span>feedback</span><span>checking…</span></div><p>…</p>';
  coachEl.prepend(note);

  const unlocked = hintTier >= 4;
  const giveaway = unlocked
    ? 'They have already unlocked the full solution, so you may show corrected code if helpful.'
    : 'IMPORTANT: if the answer is WRONG, do NOT give corrected code — give one pointed nudge and suggest the hint button. Only confirm + praise if correct.';
  const system = feedbackSystemTpl.replaceAll('{{GIVEAWAY_POLICY}}', giveaway);

  const user =
    `EXERCISE: ${ex.promptHtml.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim()}\n\n` +
    `LEARNER CODE:\n\`\`\`r\n${codeEl.value}\n\`\`\`\n\n` +
    `CAPTURED OUTPUT:\n${lastOutput}\n\n` +
    `Expected: ${ex.expected}. Give your feedback.`;

  try {
    const ans = await askClaude(system, user);
    note.innerHTML = '<div class="lvl"><span>feedback</span></div>' + mdToHtml(ans);
  } catch (err) {
    note.innerHTML = `<div class="lvl"><span>feedback</span></div><p class="err">Feedback service error: ${escapeHtml(String(err.message || err))}</p>`;
  } finally {
    checkBtn.disabled = false;
  }
}

/* ---------- tiny markdown ---------- */
function escapeHtml(s) {
  return s.replace(/[&<>]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));
}
function mdToHtml(md) {
  const parts = md.split(/```(?:r|R)?\n?/);
  let html = '',
    code = false;
  for (const p of parts) {
    if (code) {
      html += '<pre>' + escapeHtml(p.replace(/\n$/, '')) + '</pre>';
    } else {
      p.split(/\n{2,}/).forEach((par) => {
        const t = par.trim();
        if (!t) return;
        html +=
          '<p>' +
          escapeHtml(t).replace(/`([^`]+)`/g, '<code class="inline">$1</code>') +
          '</p>';
      });
    }
    code = !code;
  }
  return html || '<p>' + escapeHtml(md) + '</p>';
}

runBtn.addEventListener('click', doRun);
hintBtn.addEventListener('click', getHint);
checkBtn.addEventListener('click', checkAnswer);
setAttempts();
paintLadder();
