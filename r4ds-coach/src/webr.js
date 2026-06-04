import { WebR, ChannelType } from 'webr';

let webR = null;
let dplyrReady = false;

export function isDplyrReady() {
  return dplyrReady;
}

// Boots WebR (PostMessage channel — no special server headers needed) and then
// installs dplyr in the background. onStatus is called with: 'r-ready',
// 'dplyr-ready', 'dplyr-fail'.
export async function bootWebR(onStatus) {
  webR = new WebR({ channelType: ChannelType.PostMessage });
  await webR.init();
  onStatus('r-ready');
  try {
    await webR.installPackages(['dplyr']);
    dplyrReady = true;
    onStatus('dplyr-ready');
  } catch (e) {
    onStatus('dplyr-fail');
  }
}

// Runs R code and returns an array of { type: 'stdout'|'stderr', data: string }.
// Throws on an R evaluation error (message contains the R error text).
export async function runR(code) {
  if (!webR) throw new Error('R runtime not booted yet');
  const shelter = await new webR.Shelter();
  try {
    const res = await shelter.captureR(code, {
      withAutoprint: true,
      captureStreams: true,
      captureConditions: false,
    });
    return res.output;
  } finally {
    shelter.purge();
  }
}
