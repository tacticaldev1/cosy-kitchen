// Renders every sound of the web version's Web Audio synth into WAV files for Godot,
// using the browser's OfflineAudioContext (your installed Chrome or Edge via Playwright).
// Also composes three lo-fi music tracks with the same synth toolkit.
//
//   node godot/tools/audio/render_audio.mjs            (from cosy-kitchen-project/)
//
// Output: godot/assets/audio/{sfx,loops,music}/*.wav
import { chromium } from 'playwright';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const godot = join(here, '..', '..');
const src = join(godot, '..', 'src');
const core = readFileSync(join(src, '01-core.js'), 'utf8');
const shop = readFileSync(join(src, '06-shop.js'), 'utf8');

// Pull the synth straight out of the web game so both versions sound identical.
const cut = (text, start, end) => { const a = text.indexOf(start); const b = text.indexOf(end, a); if (a < 0 || b < 0) throw new Error('missing ' + start); return text.slice(a, b); };
const helpers = cut(core, 'function send(', 'const SND = {');
const sndObj = cut(core, 'const SND = {', 'function loopSnd(');
const loopFn = cut(core, 'function loopSnd(', '\n}\n') + '\n}\n';
const extra = shop.split('\n').filter(l => /^SND\.\w+ = /.test(l)).join('\n');

const harness = `
var AC, master, verb, noiseBuf, sfxOn = true, R, ambOn = true;
var _seed = 1;
function seedR(s){ _seed = s >>> 0 || 1; R = () => { _seed = (_seed * 16807) % 2147483647; return (_seed - 1) / 2147483646; }; }
function setup(ac, seed){
  AC = ac; seedR(seed);
  master = AC.createGain(); master.gain.value = .9; master.connect(AC.destination);
  const len = Math.floor(AC.sampleRate * 1.8), imp = AC.createBuffer(2, len, AC.sampleRate);
  for (let c = 0; c < 2; c++){ const d = imp.getChannelData(c); for (let i = 0; i < len; i++) d[i] = (R() * 2 - 1) * Math.pow(1 - i / len, 3); }
  const conv = AC.createConvolver(); conv.buffer = imp; verb = AC.createGain(); verb.gain.value = .5; verb.connect(conv); conv.connect(master);
  noiseBuf = AC.createBuffer(1, AC.sampleRate * 2, AC.sampleRate);
  const nd = noiseBuf.getChannelData(0); for (let i = 0; i < nd.length; i++) nd[i] = R() * 2 - 1;
}
${helpers}
${sndObj}
${extra}
${loopFn}

function encodeWav(chs, sr){
  const n = chs[0].length, nc = chs.length, buf = new ArrayBuffer(44 + n * nc * 2), v = new DataView(buf);
  const w = (o, s) => { for (let i = 0; i < s.length; i++) v.setUint8(o + i, s.charCodeAt(i)); };
  w(0, 'RIFF'); v.setUint32(4, 36 + n * nc * 2, true); w(8, 'WAVE'); w(12, 'fmt '); v.setUint32(16, 16, true); v.setUint16(20, 1, true);
  v.setUint16(22, nc, true); v.setUint32(24, sr, true); v.setUint32(28, sr * nc * 2, true); v.setUint16(32, nc * 2, true); v.setUint16(34, 16, true);
  w(36, 'data'); v.setUint32(40, n * nc * 2, true);
  let o = 44; for (let i = 0; i < n; i++) for (let c = 0; c < nc; c++){ const x = Math.max(-1, Math.min(1, chs[c][i])); v.setInt16(o, x < 0 ? x * 0x8000 : x * 0x7FFF, true); o += 2; }
  let s = ''; const b = new Uint8Array(buf); for (let i = 0; i < b.length; i += 0x8000) s += String.fromCharCode.apply(null, b.subarray(i, i + 0x8000));
  return btoa(s);
}
function trim(chs, sr, thresh = 0.0008){
  let end = chs[0].length;
  while (end > 1 && chs.every(c => Math.abs(c[end - 1]) < thresh)) end--;
  end = Math.min(chs[0].length, end + Math.floor(sr * 0.03));
  const fade = Math.floor(sr * 0.02);
  return chs.map(c => { const o = c.slice(0, end); for (let i = 0; i < fade && i < o.length; i++) o[o.length - 1 - i] *= i / fade; return o; });
}
function normalize(chs, peak){ let m = 0; for (const c of chs) for (const x of c) m = Math.max(m, Math.abs(x)); if (m < 1e-6) return chs; const k = Math.min(peak / m, 4.0); return chs.map(c => c.map(x => x * k)); }
// seamless loop: drop the fade-in, then crossfade the tail into the head
function loopify(chs, sr, skip = 0.25, xf = 0.8){
  const s = Math.floor(sr * skip), F = Math.floor(sr * xf);
  return chs.map(c => { const x = c.slice(s); const L = x.length - F; const y = new Float32Array(L);
    for (let i = 0; i < L; i++) y[i] = i < F ? x[i] * Math.sqrt(i / F) + x[L + i] * Math.sqrt(1 - i / F) : x[i];
    return y; });
}
async function renderSfx(name, seed, args){
  const sr = 32000, ac = new OfflineAudioContext(2, sr * 3, sr);
  setup(ac, seed);
  SND[name](...args);
  const b = await ac.startRendering();
  let chs = [b.getChannelData(0), b.getChannelData(1)];
  chs = trim(chs, sr).map(c => c.map(x => x * GAIN));
  return encodeWav(chs, sr);
}
// one shared gain keeps the web version's mix between one-shots and loops
var GAIN = 2.5;
async function renderLoop(kind, seed, secs){
  const sr = 32000, ac = new OfflineAudioContext(2, sr * secs, sr);
  setup(ac, seed);
  if (kind === 'rain'){
    const bl = ac.sampleRate * 4, bb = ac.createBuffer(1, bl, ac.sampleRate), bd = bb.getChannelData(0); let last = 0;
    for (let i = 0; i < bl; i++){ last = (last + .02 * (R() * 2 - 1)) / 1.02; bd[i] = last * 3.2; }
    const g = ac.createGain(); g.gain.value = .9; g.connect(master);
    const brown = ac.createBufferSource(); brown.buffer = bb; brown.loop = true;
    const lp = ac.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 420;
    const bg = ac.createGain(); bg.gain.value = .5; brown.connect(lp).connect(bg).connect(g); brown.start();
    const hiss = ac.createBufferSource(); hiss.buffer = noiseBuf; hiss.loop = true;
    const bp = ac.createBiquadFilter(); bp.type = 'bandpass'; bp.frequency.value = 2600; bp.Q.value = .4;
    const hg = ac.createGain(); hg.gain.value = .05; hiss.connect(bp).connect(hg).connect(g); hiss.start();
    // occasional drips on the window
    for (let t = 0.3; t < secs - 0.5; t += 0.18 + R() * 0.7){ const o = ac.createOscillator(); const f = 1400 + R() * 2200; o.frequency.setValueAtTime(f, t); o.frequency.exponentialRampToValueAtTime(f * 0.6, t + 0.05); const og = ac.createGain(); og.gain.setValueAtTime(0.0001, t); og.gain.linearRampToValueAtTime(0.012 + R() * 0.02, t + 0.004); og.gain.exponentialRampToValueAtTime(0.0001, t + 0.08); o.connect(og).connect(g); o.start(t); o.stop(t + 0.1); }
  } else {
    const api = loopSnd(kind);
    if (kind === 'blender') api.set(0.45);
  }
  const b = await ac.startRendering();
  let chs = [b.getChannelData(0), b.getChannelData(1)];
  chs = loopify(chs, sr);
  chs = kind === 'rain' ? normalize(chs, 0.5) : chs.map(c => c.map(x => x * GAIN));
  return encodeWav(chs, sr);
}

// ---------------------------------------------------------------- lo-fi music
const mtof = m => 440 * Math.pow(2, (m - 69) / 12);
function rhodes(ac, out, t, m, dur, vel){
  const f = mtof(m), car = ac.createOscillator(), mod = ac.createOscillator(), mg = ac.createGain(), g = ac.createGain();
  car.frequency.value = f; mod.frequency.value = f; car.detune.value = (R() - .5) * 8;
  mg.gain.setValueAtTime(f * 1.4 * vel, t); mg.gain.exponentialRampToValueAtTime(f * 0.12, t + 0.6);
  mod.connect(mg).connect(car.frequency);
  const tine = ac.createOscillator(), tg = ac.createGain(); tine.frequency.value = f * 7.02;
  tg.gain.setValueAtTime(0.0001, t); tg.gain.linearRampToValueAtTime(0.025 * vel, t + 0.003); tg.gain.exponentialRampToValueAtTime(0.0001, t + 0.18);
  tine.connect(tg).connect(out);
  g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(0.13 * vel, t + 0.008); g.gain.exponentialRampToValueAtTime(0.07 * vel, t + 0.5);
  g.gain.setValueAtTime(0.07 * vel, t + dur); g.gain.exponentialRampToValueAtTime(0.0001, t + dur + 0.6);
  car.connect(g).connect(out);
  for (const o of [car, mod, tine]){ o.start(t); o.stop(t + dur + 0.7); }
}
function bass(ac, out, t, m, dur){
  const f = mtof(m), o = ac.createOscillator(), o2 = ac.createOscillator(), lp = ac.createBiquadFilter(), g = ac.createGain();
  o.type = 'sine'; o2.type = 'triangle'; o.frequency.value = f; o2.frequency.value = f;
  lp.type = 'lowpass'; lp.frequency.value = 520;
  g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(0.32, t + 0.02); g.gain.exponentialRampToValueAtTime(0.18, t + dur * 0.6); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
  const g2 = ac.createGain(); g2.gain.value = 0.25; o2.connect(g2).connect(lp); o.connect(lp); lp.connect(g).connect(out);
  o.start(t); o2.start(t); o.stop(t + dur + 0.05); o2.stop(t + dur + 0.05);
}
function kick(ac, out, t, v){
  const o = ac.createOscillator(), g = ac.createGain();
  o.frequency.setValueAtTime(115, t); o.frequency.exponentialRampToValueAtTime(42, t + 0.14);
  g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(0.75 * v, t + 0.004); g.gain.exponentialRampToValueAtTime(0.0001, t + 0.38);
  o.connect(g).connect(out); o.start(t); o.stop(t + 0.4);
}
function snare(ac, out, t, v){
  const s = ac.createBufferSource(); s.buffer = noiseBuf; const bp = ac.createBiquadFilter(); bp.type = 'bandpass'; bp.frequency.value = 1700; bp.Q.value = 0.7;
  const g = ac.createGain(); g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(0.16 * v, t + 0.004); g.gain.exponentialRampToValueAtTime(0.0001, t + 0.2);
  s.connect(bp).connect(g).connect(out); s.start(t, R(), 0.25);
  const o = ac.createOscillator(), og = ac.createGain(); o.frequency.setValueAtTime(190, t); o.frequency.exponentialRampToValueAtTime(140, t + 0.08);
  og.gain.setValueAtTime(0.0001, t); og.gain.linearRampToValueAtTime(0.08 * v, t + 0.003); og.gain.exponentialRampToValueAtTime(0.0001, t + 0.1);
  o.connect(og).connect(out); o.start(t); o.stop(t + 0.12);
}
function hat(ac, out, t, v, open){
  const s = ac.createBufferSource(); s.buffer = noiseBuf; const hp = ac.createBiquadFilter(); hp.type = 'highpass'; hp.frequency.value = 7200;
  const g = ac.createGain(); g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(0.05 * v, t + 0.002); g.gain.exponentialRampToValueAtTime(0.0001, t + (open ? 0.22 : 0.045));
  s.connect(hp).connect(g).connect(out); s.start(t, R(), 0.3);
}
function kalimba(ac, out, t, m, v){
  const f = mtof(m), o = ac.createOscillator(), o2 = ac.createOscillator(), g = ac.createGain(), g2 = ac.createGain();
  o.frequency.value = f; o2.frequency.value = f * 5.4;
  g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(0.09 * v, t + 0.004); g.gain.exponentialRampToValueAtTime(0.0001, t + 1.4);
  g2.gain.setValueAtTime(0.0001, t); g2.gain.linearRampToValueAtTime(0.02 * v, t + 0.002); g2.gain.exponentialRampToValueAtTime(0.0001, t + 0.15);
  o.connect(g).connect(out); o2.connect(g2).connect(out); o.start(t); o2.start(t); o.stop(t + 1.5); o2.stop(t + 0.2);
}
async function renderMusic(track){
  const sr = 32000, spb = 60 / track.bpm, bar = spb * 4, bars = track.form.length;
  const secs = bars * bar + 3;
  const ac = new OfflineAudioContext(2, Math.floor(sr * secs), sr);
  setup(ac, track.seed);
  const bus = ac.createGain(); bus.gain.value = 0.9;
  const lp = ac.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 6200; lp.Q.value = 0.4;
  const comp = ac.createDynamicsCompressor(); comp.threshold.value = -20; comp.ratio.value = 3; comp.attack.value = 0.01; comp.release.value = 0.25;
  bus.connect(lp).connect(comp).connect(master);
  const pan = (p) => { const n = ac.createStereoPanner(); n.pan.value = p; n.connect(bus); return n; };
  const keys = pan(-0.15), drums = pan(0.0), hats = pan(0.35), mel = pan(-0.35), low = pan(0);
  const rv = ac.createGain(); rv.gain.value = 0.28; rv.connect(verb); keys.connect(rv); mel.connect(rv);
  // vinyl: soft hiss + random crackles across the whole track
  const hiss = ac.createBufferSource(); hiss.buffer = noiseBuf; hiss.loop = true; const hb = ac.createBiquadFilter(); hb.type = 'bandpass'; hb.frequency.value = 3200; hb.Q.value = 0.3;
  const hg = ac.createGain(); hg.gain.value = 0.012; hiss.connect(hb).connect(hg).connect(bus); hiss.start();
  for (let t = 0.1; t < secs - 1; t += 0.03 + R() * 0.35){ const s = ac.createBufferSource(); s.buffer = noiseBuf; const hp = ac.createBiquadFilter(); hp.type = 'highpass'; hp.frequency.value = 3000;
    const g = ac.createGain(); const a = 0.01 + R() * 0.04; g.gain.setValueAtTime(a, t); g.gain.exponentialRampToValueAtTime(0.0001, t + 0.012); s.connect(hp).connect(g).connect(bus); s.start(t, R(), 0.02); }
  const swing = (i) => (i % 2 ? spb * 0.5 * 0.16 : 0);
  let t0 = 1.0;
  for (let b = 0; b < bars; b++){
    const sec = track.form[b];             // 'i' intro, 'A', 'B', 'o' outro
    const ch = track.chords[(sec === 'B' ? track.bchords : track.chords) === track.chords ? b % track.chords.length : b % track.bchords.length];
    const chord = sec === 'B' ? track.bchords[b % track.bchords.length] : ch;
    const tb = t0 + b * bar;
    // chords: a stab on 1 and a push on the "and" of 2
    const vel = sec === 'i' || sec === 'o' ? 0.7 : 1.0;
    for (const m of chord.v) rhodes(ac, keys, tb + (R() * 0.012), m, bar * 0.55, vel * (0.8 + R() * 0.2));
    if (sec !== 'i') for (const m of chord.v) rhodes(ac, keys, tb + spb * 2.5 + swing(1), m, bar * 0.35, 0.6 * vel);
    if (sec !== 'i') { bass(ac, low, tb, chord.b, spb * 1.6); bass(ac, low, tb + spb * 2.5 + swing(1), chord.b + (R() < .4 ? 7 : 0), spb * 1.2); }
    if (sec === 'A' || sec === 'B'){
      for (let i = 0; i < 8; i++){
        const tt = tb + i * spb * 0.5 + swing(i);
        hat(ac, hats, tt, (i % 2 ? 0.6 : 1.0) * (0.7 + R() * 0.3), i === 7 && R() < 0.3);
        if (i === 0 || (i === 5 && R() < 0.6) || (i === 3 && R() < 0.25)) kick(ac, drums, tt, i === 0 ? 1.0 : 0.7);
        if (i === 2 || i === 6) snare(ac, drums, tt, 0.9);
      }
    }
    // melody on the B section and second A: sparse pentatonic phrases
    if ((sec === 'B' || (sec === 'A' && b > track.form.indexOf('B'))) && R() < 0.85){
      let idx = Math.floor(R() * track.scale.length);
      const n = 2 + Math.floor(R() * 4);
      for (let k = 0; k < n; k++){
        idx = Math.max(0, Math.min(track.scale.length - 1, idx + Math.floor(R() * 5) - 2));
        const pos = Math.floor(R() * 8);
        kalimba(ac, mel, tb + pos * spb * 0.5 + swing(pos), track.scale[idx], 0.7 + R() * 0.3);
      }
    }
  }
  const b = await ac.startRendering();
  let chs = [b.getChannelData(0), b.getChannelData(1)];
  chs = normalize(chs, 0.8);
  chs = trim(chs, sr, 0.002);
  return encodeWav(chs, sr);
}
`;

// sounds and how many random variations to render
const SFX = { fwip: 2, pat: 2, click: 3, chop: 4, pop: 1, sparkle: 3, chime: 1, stamp: 1, sad: 1, plunk: 3, glug: 2, poof: 2, clink: 2, crack: 2, plop: 2, swish: 4,
  flip: 2, ding: 1, beep: 1, key: 2, clunk: 2, tick: 2, kernel: 5, crackle: 4, bloop: 4, frost: 3, spinDown: 1, nom: 2, yay: 1, trash: 2, coin: 3, bell: 1, note: 2, sigh: 1 };
const ARGS = { swish: [0.7], pop: [2] };
const LOOPS = { blender: 6, sizzle: 6, boil: 6, hum: 6, cold: 6, rain: 14 };
const s = (n) => n; // readability
const TRACKS = [
  { name: 'rainy_window', bpm: 74, seed: 11, form: ['i','i','A','A','A','A','B','B','B','B','A','A','A','A','B','B','B','B','A','A','A','A','o','o'],
    chords: [{b: 41, v: [57, 60, 64, 67]}, {b: 40, v: [55, 59, 62, 64]}, {b: 38, v: [53, 57, 60, 64]}, {b: 36, v: [52, 55, 59, 62]}],
    bchords: [{b: 46, v: [57, 62, 65, 69]}, {b: 45, v: [55, 60, 64, 67]}, {b: 43, v: [53, 58, 62, 65]}, {b: 36, v: [52, 58, 62, 65]}],
    scale: [65, 67, 69, 72, 74, 77, 79, 81] },
  { name: 'matcha_morning', bpm: 80, seed: 23, form: ['i','A','A','A','A','B','B','B','B','A','A','A','A','B','B','B','B','A','A','o','o'],
    chords: [{b: 43, v: [54, 59, 62, 66]}, {b: 47, v: [57, 59, 62, 66]}, {b: 40, v: [55, 59, 62, 66]}, {b: 36, v: [55, 59, 62, 64]}],
    bchords: [{b: 45, v: [55, 60, 64, 67]}, {b: 38, v: [54, 57, 60, 64]}, {b: 43, v: [54, 59, 62, 66]}, {b: 40, v: [55, 59, 62, 67]}],
    scale: [67, 69, 71, 74, 76, 79, 81, 83] },
  { name: 'moonlit_ramen', bpm: 70, seed: 37, form: ['i','i','A','A','A','A','B','B','B','B','A','A','A','A','B','B','B','B','o','o'],
    chords: [{b: 45, v: [55, 60, 64, 67, 71]}, {b: 41, v: [57, 60, 64, 65]}, {b: 36, v: [55, 59, 62, 64]}, {b: 43, v: [53, 57, 59, 64]}],
    bchords: [{b: 38, v: [53, 57, 60, 64]}, {b: 40, v: [55, 59, 62, 68]}, {b: 45, v: [55, 60, 64, 67]}, {b: 41, v: [57, 60, 64, 67]}],
    scale: [69, 72, 74, 76, 79, 81, 84] },
];

const out = (dir) => { const p = join(godot, 'assets', 'audio', dir); mkdirSync(p, { recursive: true }); return p; };
const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || 'chrome' }).catch(() => chromium.launch({ channel: 'msedge' }));
const page = await browser.newPage();
await page.evaluate(code => { (0, eval)(code); }, harness);
let n = 0;
for (const [name, count] of Object.entries(SFX)){
  for (let i = 0; i < count; i++){
    const b64 = await page.evaluate(([nm, seed, args]) => renderSfx(nm, seed, args), [name, 101 + i * 977 + name.length * 13, ARGS[name] || []]);
    writeFileSync(join(out('sfx'), `${name}_${i + 1}.wav`), Buffer.from(b64, 'base64')); n++;
  }
}
console.log(`rendered ${n} one-shots`);
for (const [kind, secs] of Object.entries(LOOPS)){
  const b64 = await page.evaluate(([k, s]) => renderLoop(k, 7, s), [kind, secs]);
  writeFileSync(join(out('loops'), `${kind}.wav`), Buffer.from(b64, 'base64'));
}
console.log(`rendered ${Object.keys(LOOPS).length} loops`);
if (!process.argv.includes('--no-music')){
  for (const tr of TRACKS){
    const b64 = await page.evaluate(t => renderMusic(t), tr);
    writeFileSync(join(out('music'), `${tr.name}.wav`), Buffer.from(b64, 'base64'));
    console.log('composed', tr.name);
  }
}
await browser.close();
