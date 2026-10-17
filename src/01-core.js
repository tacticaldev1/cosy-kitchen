const TAU = Math.PI * 2, W = 400, H = 640, CX = 200, CY = 330, PLUM = '#3B2340';
const $ = id => document.getElementById(id);
const cv = $('game'), ctx = cv.getContext('2d');
const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
const R = Math.random;
let clock = 0;

// ================= shading engine =================
// Every path remembers its bounds, so any outlined shape can get soft anime shading automatically.
const GFX = {shade: true};
(() => {
  const P = CanvasRenderingContext2D.prototype;
  const add = (g, x, y) => { const b = g._bb; if (!b){ g._bb = {x0: x, y0: y, x1: x, y1: y}; return; } if (x < b.x0) b.x0 = x; else if (x > b.x1) b.x1 = x; if (y < b.y0) b.y0 = y; else if (y > b.y1) b.y1 = y; };
  const wrap = (name, hook) => { const orig = P[name]; P[name] = function(){ hook(this, arguments); return orig.apply(this, arguments); }; };
  wrap('beginPath', g => { g._bb = null; });
  wrap('moveTo', (g, a) => add(g, a[0], a[1]));
  wrap('lineTo', (g, a) => add(g, a[0], a[1]));
  wrap('quadraticCurveTo', (g, a) => { add(g, a[0], a[1]); add(g, a[2], a[3]); });
  wrap('bezierCurveTo', (g, a) => { add(g, a[0], a[1]); add(g, a[2], a[3]); add(g, a[4], a[5]); });
  wrap('arcTo', (g, a) => { add(g, a[0], a[1]); add(g, a[2], a[3]); });
  wrap('arc', (g, a) => { add(g, a[0] - a[2], a[1] - a[2]); add(g, a[0] + a[2], a[1] + a[2]); });
  wrap('ellipse', (g, a) => { const m = Math.max(a[2], a[3]); add(g, a[0] - m, a[1] - m); add(g, a[0] + m, a[1] + m); });
  wrap('rect', (g, a) => { add(g, a[0], a[1]); add(g, a[0] + a[2], a[1] + a[3]); });
})();
function shadeFill(g, color){
  g.fillStyle = color; g.fill();
  const b = g._bb; if (!GFX.shade || !b || typeof color !== 'string' || color[0] !== '#') return;
  const w = b.x1 - b.x0, h = b.y1 - b.y0; if (w < 6 || h < 6) return;
  let lx = -.5, ly = -.86;
  if (g.getTransform){ const m = g.getTransform(), det = m.a * m.d - m.b * m.c; if (det){ const ux = (m.d * lx - m.c * ly) / det, uy = (-m.b * lx + m.a * ly) / det, n = Math.hypot(ux, uy) || 1; lx = ux / n; ly = uy / n; } }
  const cx = (b.x0 + b.x1) / 2, cy = (b.y0 + b.y1) / 2, Rr = Math.hypot(w, h) * .5;
  g.save(); g.clip();
  const gr = g.createRadialGradient(cx + lx * Rr * .5, cy + ly * Rr * .5, 0, cx + lx * Rr * .32, cy + ly * Rr * .32, Rr * 1.28);
  gr.addColorStop(0, 'rgba(255,252,246,.46)'); gr.addColorStop(.32, 'rgba(255,252,246,0)'); gr.addColorStop(.6, 'rgba(78,32,104,0)'); gr.addColorStop(.7, 'rgba(78,32,104,.12)'); gr.addColorStop(1, 'rgba(78,32,104,.3)');
  g.fillStyle = gr; g.fillRect(b.x0 - 1, b.y0 - 1, w + 2, h + 2);
  if (Rr > 9){ const sx = cx + lx * Rr * .46, sy = cy + ly * Rr * .46, sr = Rr * .2, sg = g.createRadialGradient(sx, sy, 0, sx, sy, sr); sg.addColorStop(0, 'rgba(255,255,255,.7)'); sg.addColorStop(1, 'rgba(255,255,255,0)'); g.fillStyle = sg; g.fillRect(sx - sr, sy - sr, sr * 2, sr * 2); }
  const bx = cx - lx * Rr * .62, by = cy - ly * Rr * .62, br = Rr * .5, bg = g.createRadialGradient(bx, by, 0, bx, by, br); bg.addColorStop(0, 'rgba(255,190,220,.16)'); bg.addColorStop(1, 'rgba(255,190,220,0)'); g.fillStyle = bg; g.fillRect(bx - br, by - br, br * 2, br * 2);
  g.restore();
}

function rngFor(seed){ let a = seed >>> 0; return () => { a |= 0; a = a + 0x6D2B79F5 | 0; let t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
function rr(g, x, y, w, h, r){
  if (typeof r === 'number') r = [r, r, r, r];
  const m = Math.min(Math.abs(w), Math.abs(h)) / 2, [a, b, c, d] = r.map(v => Math.max(0, Math.min(v, m)));
  g.beginPath(); g.moveTo(x + a, y); g.arcTo(x + w, y, x + w, y + h, b); g.arcTo(x + w, y + h, x, y + h, c); g.arcTo(x, y + h, x, y, d); g.arcTo(x, y, x + w, y, a); g.closePath();
}
function disc(g, x, y, r, f){ g.beginPath(); g.arc(x, y, Math.max(0, r), 0, TAU); if (r >= 14 && typeof f === 'string' && f[0] === '#') shadeFill(g, f); else { g.fillStyle = f; g.fill(); } }
function ring(g, x, y, r, w = 2.5, c = PLUM){ g.beginPath(); g.arc(x, y, Math.max(0, r), 0, TAU); g.lineWidth = w; g.strokeStyle = c; g.stroke(); }
function ell(g, x, y, rx, ry, f, stroke, rot = 0){ g.beginPath(); g.ellipse(x, y, Math.max(0, rx), Math.max(0, ry), rot, 0, TAU); if (f){ if (stroke) shadeFill(g, f); else { g.fillStyle = f; g.fill(); } } if (stroke){ g.lineWidth = stroke; g.strokeStyle = PLUM; g.stroke(); } }
function line(g, w = 2.5, c = PLUM){ g.lineWidth = w; g.strokeStyle = c; g.stroke(); }
function fillLine(g, f, w = 2.5){ shadeFill(g, f); line(g, w); }
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const ease = k => 1 - Math.pow(1 - clamp(k, 0, 1), 3);
const easeBack = k => { k = clamp(k, 0, 1); const c1 = 1.70158, c3 = c1 + 1; return 1 + c3 * Math.pow(k - 1, 3) + c1 * Math.pow(k - 1, 2); };
function bounce(k){ k = clamp(k, 0, 1); const n = 7.5625, d = 2.75; if (k < 1/d) return n*k*k; if (k < 2/d) return n*(k-=1.5/d)*k+.75; if (k < 2.5/d) return n*(k-=2.25/d)*k+.9375; return n*(k-=2.625/d)*k+.984375; }
function buzz(ms){ try { navigator.vibrate && navigator.vibrate(ms); } catch (e) {} }
function hex(c){ const n = parseInt(c.slice(1), 16); return [n >> 16 & 255, n >> 8 & 255, n & 255]; }
function lerpC(a, b, t){ const A = hex(a), B = hex(b); t = clamp(t, 0, 1); return '#' + A.map((v, i) => Math.round(v + (B[i] - v) * t).toString(16).padStart(2, '0')).join(''); }
function mixC(list){ let s = [0, 0, 0], w = 0; for (const [c, k] of list){ const v = hex(c); s = s.map((x, i) => x + v[i] * k); w += k; } if (!w) return '#F2E6D8'; return '#' + s.map(x => Math.round(x / w).toString(16).padStart(2, '0')).join(''); }
const lighten = (c, t) => lerpC(c, '#FFFFFF', t), darken = (c, t) => lerpC(c, '#2A1608', t);
function zoneScore(v, a, b){ if (v >= a && v <= b) return 1; const d = v < a ? a - v : v - b; return clamp(1 - d / .3, .2, 1); }
function star4(g, x, y, r, rot = 0){ g.save(); g.translate(x, y); g.rotate(rot); g.beginPath(); for (let i = 0; i < 8; i++){ const a = i * Math.PI / 4, d = i % 2 ? r * .28 : r; g.lineTo(Math.cos(a) * d, Math.sin(a) * d); } g.closePath(); g.restore(); }
function star5(g, x, y, r){ g.beginPath(); for (let j = 0; j < 10; j++){ const a = -Math.PI / 2 + j * Math.PI / 5, d = j % 2 ? r * .45 : r; g.lineTo(x + Math.cos(a) * d, y + Math.sin(a) * d); } g.closePath(); }
function face(g, x, y, s, mood){
  g.save(); g.strokeStyle = PLUM; g.fillStyle = PLUM; g.lineWidth = 2.2 * s; g.lineCap = 'round';
  const blink = (clock % 3.7) < .12 && mood === 'idle';
  for (const k of [-1, 1]){
    const ex = x + k * 11 * s, ey = y;
    if (mood === 'happy'){ g.beginPath(); g.arc(ex, ey + 2 * s, 4 * s, Math.PI * 1.15, Math.PI * 1.85); g.stroke(); }
    else if (mood === 'focus'){ g.beginPath(); g.moveTo(ex - 4 * s * k, ey - 4 * s); g.lineTo(ex + 3 * s * k, ey); g.lineTo(ex - 4 * s * k, ey + 4 * s); g.stroke(); }
    else if (mood === 'sleepy' || blink){ g.beginPath(); g.moveTo(ex - 4 * s, ey); g.lineTo(ex + 4 * s, ey); g.stroke(); }
    else if (mood === 'wow'){ ell(g, ex, ey, 4.4 * s, 5.4 * s, PLUM); g.fillStyle = '#FFFFFF'; star4(g, ex, ey - .4 * s, 3.6 * s); g.fill(); g.fillStyle = PLUM; }
    else { const ew = 3.8 * s, eh = 5.2 * s; ell(g, ex, ey, ew, eh, PLUM);
      const ig = g.createLinearGradient(0, ey - eh, 0, ey + eh); ig.addColorStop(.3, 'rgba(200,110,180,0)'); ig.addColorStop(1, 'rgba(236,140,205,.95)'); ell(g, ex, ey + .4 * s, ew * .78, eh * .82, ig);
      disc(g, ex - 1.3 * s, ey - 2.1 * s, 1.7 * s, '#FFFFFF'); disc(g, ex + 1.5 * s, ey + 2.3 * s, .8 * s, '#FFFFFF'); }
  }
  for (const k of [-1, 1]){ const bx = x + k * 19 * s, by = y + 6 * s, br = 6.5 * s, bgr = g.createRadialGradient(bx, by, 0, bx, by, br); bgr.addColorStop(0, 'rgba(255,105,150,.62)'); bgr.addColorStop(1, 'rgba(255,105,150,0)'); g.fillStyle = bgr; g.fillRect(bx - br, by - br, br * 2, br * 2);
    if (s > .6){ g.strokeStyle = 'rgba(255,255,255,.75)'; g.lineWidth = 1.1 * s; for (let j = 0; j < 2; j++){ g.beginPath(); g.moveTo(bx - 1.5 * s + j * 3 * s, by - 1.6 * s); g.lineTo(bx - 2.6 * s + j * 3 * s, by + 1.6 * s); g.stroke(); } } }
  g.strokeStyle = PLUM; g.fillStyle = PLUM; g.lineWidth = 2.2 * s;
  g.beginPath();
  if (mood === 'happy' || mood === 'focus'){ g.arc(x, y + 5 * s, 4 * s, .1 * Math.PI, .9 * Math.PI); g.fillStyle = '#C2415E'; g.fill(); g.stroke(); }
  else if (mood === 'wow'){ ell(g, x, y + 7 * s, 3 * s, 3.6 * s, '#C2415E'); }
  else if (mood === 'yuck'){ g.moveTo(x - 5 * s, y + 7 * s); for (let i = 1; i <= 4; i++) g.lineTo(x - 5 * s + i * 2.5 * s, y + (i % 2 ? 5 : 7) * s); g.stroke(); }
  else { g.arc(x, y + 5 * s, 2.6 * s, .15 * Math.PI, .85 * Math.PI); g.stroke(); }
  g.restore();
}

// ================= audio (all synthesized) =================
let AC = null, master, verb, noiseBuf, ambGain, sfxOn = true, ambOn = true;
function initAudio(){
  if (AC){ if (AC.state === 'suspended') AC.resume(); return; }
  try { AC = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) { AC = null; return; }
  master = AC.createGain(); master.gain.value = .9; master.connect(AC.destination);
  const len = AC.sampleRate * 1.8, imp = AC.createBuffer(2, len, AC.sampleRate);
  for (let c = 0; c < 2; c++){ const d = imp.getChannelData(c); for (let i = 0; i < len; i++) d[i] = (R() * 2 - 1) * Math.pow(1 - i / len, 3); }
  const conv = AC.createConvolver(); conv.buffer = imp; verb = AC.createGain(); verb.gain.value = .5; verb.connect(conv); conv.connect(master);
  noiseBuf = AC.createBuffer(1, AC.sampleRate * 2, AC.sampleRate);
  const nd = noiseBuf.getChannelData(0); for (let i = 0; i < nd.length; i++) nd[i] = R() * 2 - 1;
  const bl = AC.sampleRate * 4, bb = AC.createBuffer(1, bl, AC.sampleRate), bd = bb.getChannelData(0); let last = 0;
  for (let i = 0; i < bl; i++){ last = (last + .02 * (R() * 2 - 1)) / 1.02; bd[i] = last * 3.2; }
  ambGain = AC.createGain(); ambGain.gain.value = 0; ambGain.connect(master);
  const brown = AC.createBufferSource(); brown.buffer = bb; brown.loop = true;
  const lp = AC.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 420;
  const bg = AC.createGain(); bg.gain.value = .5; brown.connect(lp).connect(bg).connect(ambGain); brown.start();
  const hiss = AC.createBufferSource(); hiss.buffer = noiseBuf; hiss.loop = true;
  const bp = AC.createBiquadFilter(); bp.type = 'bandpass'; bp.frequency.value = 2600; bp.Q.value = .4;
  const hg = AC.createGain(); hg.gain.value = .05; hiss.connect(bp).connect(hg).connect(ambGain); hiss.start();
  setAmb();
}
function setAmb(){ if (!AC) return; ambGain.gain.cancelScheduledValues(AC.currentTime); ambGain.gain.linearRampToValueAtTime(ambOn ? .22 : 0, AC.currentTime + .8); }
function send(node, wet){ node.connect(master); if (wet){ const s = AC.createGain(); s.gain.value = wet; node.connect(s); s.connect(verb); } }
function noise({dur = .1, type = 'bandpass', f0 = 1000, f1 = f0, q = 1, vol = .1, at = 0, wet = .15}){
  if (!AC || !sfxOn) return;
  const t = AC.currentTime + at, src = AC.createBufferSource(); src.buffer = noiseBuf;
  const f = AC.createBiquadFilter(); f.type = type; f.Q.value = q;
  f.frequency.setValueAtTime(f0, t); f.frequency.exponentialRampToValueAtTime(Math.max(20, f1), t + dur);
  const g = AC.createGain(); g.gain.setValueAtTime(.0001, t); g.gain.linearRampToValueAtTime(vol, t + Math.min(.012, dur * .2)); g.gain.exponentialRampToValueAtTime(.0001, t + dur);
  src.connect(f).connect(g); send(g, wet); src.start(t, R() * 1.5, dur + .05);
}
function tone({f0 = 440, f1 = f0, dur = .2, vol = .1, type = 'sine', at = 0, wet = .2}){
  if (!AC || !sfxOn) return;
  const t = AC.currentTime + at, o = AC.createOscillator(); o.type = type;
  o.frequency.setValueAtTime(f0, t); o.frequency.exponentialRampToValueAtTime(Math.max(20, f1), t + dur * .8);
  const g = AC.createGain(); g.gain.setValueAtTime(.0001, t); g.gain.linearRampToValueAtTime(vol, t + .006); g.gain.exponentialRampToValueAtTime(.0001, t + dur);
  o.connect(g); send(g, wet); o.start(t); o.stop(t + dur + .05);
}
const SND = {
  fwip(){ noise({dur: .32, f0: 500, f1: 3800, q: 1.4, vol: .16}); noise({dur: .12, type: 'lowpass', f0: 600, f1: 200, vol: .08, at: .26}); },
  pat(){ tone({f0: 190, f1: 95, dur: .16, vol: .2, wet: .1}); noise({dur: .05, type: 'lowpass', f0: 1400, f1: 400, q: .7, vol: .12, wet: .05}); },
  click(){ noise({dur: .03, f0: 2600, f1: 2100, q: 7, vol: .22, wet: .1}); tone({f0: 1150, f1: 950, dur: .035, vol: .04, type: 'triangle', wet: 0}); },
  chop(){ noise({dur: .05, type: 'highpass', f0: 4500, f1: 3000, q: .7, vol: .18, wet: .1}); noise({dur: .07, f0: 900, f1: 500, q: 2, vol: .14, wet: 0}); tone({f0: 150, f1: 70, dur: .11, vol: .3, at: .02, wet: .08}); },
  pop(i = 0){ tone({f0: 520 + i * 60, f1: 980 + i * 90, dur: .1, vol: .1, wet: .25}); },
  sparkle(){ for (let i = 0; i < 3; i++) tone({f0: 2100 + R() * 1400, dur: .25, vol: .025, at: i * .05, wet: .6}); },
  chime(){ [1046.5, 1318.5, 1568, 2093].forEach((f, i) => tone({f0: f, dur: 1.6, vol: .055, at: i * .07, wet: .7})); },
  stamp(){ tone({f0: 160, f1: 80, dur: .18, vol: .3, wet: .2}); [1568, 2093, 2637].forEach((f, i) => tone({f0: f, dur: .5, vol: .04, at: .15 + i * .08, wet: .6})); },
  sad(){ tone({f0: 440, f1: 330, dur: .5, vol: .07, type: 'triangle', wet: .4}); },
  plunk(){ tone({f0: 280, f1: 120, dur: .14, vol: .18, wet: .15}); noise({dur: .05, type: 'lowpass', f0: 1200, f1: 300, vol: .1}); },
  glug(){ for (let i = 0; i < 4; i++){ const f = 260 + R() * 280; tone({f0: f, f1: f * 1.7, dur: .07, vol: .12, at: i * .085, wet: .25}); } },
  poof(){ noise({dur: .4, type: 'lowpass', f0: 1200, f1: 250, q: .5, vol: .14, wet: .2}); },
  clink(){ for (let i = 0; i < 3; i++) tone({f0: 2400 + R() * 1200, dur: .12, vol: .04, at: i * .06, wet: .4, type: 'triangle'}); },
  crack(){ noise({dur: .05, type: 'highpass', f0: 3800, f1: 2400, q: .8, vol: .3, wet: .1}); tone({f0: 1800, f1: 1200, dur: .03, vol: .06, type: 'triangle'}); },
  plop(){ tone({f0: 260, f1: 100, dur: .22, vol: .22, wet: .2}); noise({dur: .1, f0: 600, f1: 300, q: 1.2, vol: .1, at: .02}); },
  swish(v){ noise({dur: .09, f0: 2400 + R() * 1200, q: 1.6, vol: .03 + .09 * v, wet: .05}); if (R() < .18) tone({f0: 3000 + R() * 800, dur: .06, vol: .025, type: 'triangle', wet: .3}); },
  flip(){ noise({dur: .3, f0: 350, f1: 1600, q: 1.2, vol: .14}); tone({f0: 190, f1: 90, dur: .16, vol: .22, at: .5, wet: .1}); },
  ding(){ tone({f0: 1760, dur: 1.6, vol: .08, wet: .7}); tone({f0: 2637, dur: 1.2, vol: .04, at: .01, wet: .7}); },
  beep(){ for (let i = 0; i < 3; i++) tone({f0: 1900, dur: .11, vol: .045, type: 'square', at: i * .22, wet: .1}); },
  key(){ tone({f0: 1400, dur: .045, vol: .04, type: 'square', wet: .05}); },
  clunk(){ tone({f0: 110, f1: 60, dur: .14, vol: .28, wet: .1}); noise({dur: .06, type: 'lowpass', f0: 700, f1: 200, vol: .15}); },
  tick(){ noise({dur: .016, f0: 3200, q: 8, vol: .14, wet: 0}); },
  kernel(){ const f = 900 + R() * 1500; noise({dur: .035, f0: f, f1: f * .7, q: 2.5, vol: .18 + R() * .12, wet: .15}); tone({f0: 520 + R() * 300, f1: 300, dur: .03, vol: .05, type: 'triangle', wet: 0}); },
  crackle(){ noise({dur: .02, type: 'highpass', f0: 5000, f1: 4000, vol: .05 + R() * .07, wet: 0}); },
  bloop(){ const f = 180 + R() * 220; tone({f0: f, f1: f * 2.2, dur: .09, vol: .07, wet: .3}); },
  frost(){ noise({dur: .06, type: 'highpass', f0: 6000, f1: 5000, vol: .06, wet: .4}); if (R() < .3) tone({f0: 3500 + R() * 1500, dur: .2, vol: .015, wet: .8}); },
  spinDown(){ tone({f0: 190, f1: 50, dur: .5, vol: .05, type: 'sawtooth', wet: .05}); },
  nom(){ for (let i = 0; i < 3; i++){ noise({dur: .07, type: 'lowpass', f0: 900, f1: 300, q: 1, vol: .16, at: i * .2, wet: .05}); tone({f0: 220, f1: 140, dur: .06, vol: .06, at: i * .2 + .03}); } },
  yay(){ [784, 988, 1175, 1568].forEach((f, i) => tone({f0: f, dur: .25, vol: .07, at: i * .07, type: 'triangle', wet: .4})); },
  trash(){ noise({dur: .25, f0: 1800, f1: 400, q: .8, vol: .14}); tone({f0: 300, f1: 120, dur: .15, vol: .12, at: .1}); },
};
function loopSnd(kind){
  const nul = {set(){}, stop(){}};
  if (!AC || !sfxOn) return nul;
  const out = AC.createGain(); out.gain.value = 0; send(out, .12);
  const nodes = [], t = AC.currentTime;
  const nz = () => { const s = AC.createBufferSource(); s.buffer = noiseBuf; s.loop = true; s.start(); nodes.push(s); return s; };
  const osc = (type, f) => { const o = AC.createOscillator(); o.type = type; o.frequency.value = f; o.start(); nodes.push(o); return o; };
  const filt = (type, f, q = 1) => { const b = AC.createBiquadFilter(); b.type = type; b.frequency.value = f; b.Q.value = q; return b; };
  const gain = v => { const g = AC.createGain(); g.gain.value = v; return g; };
  const api = {set(){}}; let level = .1;
  if (kind === 'blender'){
    const o = osc('sawtooth', 80), lp = filt('lowpass', 600, 2), bp = filt('bandpass', 1500, .8);
    o.connect(lp).connect(out); nz().connect(bp).connect(gain(.7)).connect(out); level = .09;
    api.set = v => { const n = AC.currentTime; o.frequency.setTargetAtTime(80 + v * 110, n, .05); lp.frequency.setTargetAtTime(500 + v * 1400, n, .05); bp.frequency.setTargetAtTime(1200 + v * 1800, n, .05); };
  } else if (kind === 'sizzle'){ nz().connect(filt('highpass', 3200, .7)).connect(out); level = .05; }
  else if (kind === 'boil'){ nz().connect(filt('lowpass', 500, 1)).connect(out); level = .09; }
  else if (kind === 'hum'){ const lp = filt('lowpass', 380); osc('triangle', 100).connect(lp); osc('sine', 200).connect(lp); lp.connect(out); nz().connect(filt('lowpass', 240)).connect(gain(.8)).connect(out); level = .07; }
  else if (kind === 'cold'){ nz().connect(filt('bandpass', 5200, 3)).connect(gain(.5)).connect(out); osc('sine', 62).connect(gain(.6)).connect(out); level = .06; }
  out.gain.linearRampToValueAtTime(level, t + .08);
  api.stop = () => { const n = AC.currentTime; out.gain.cancelScheduledValues(n); out.gain.setValueAtTime(out.gain.value, n); out.gain.linearRampToValueAtTime(0, n + .25); nodes.forEach(x => { try { x.stop(n + .3); } catch (e) {} }); };
  return api;
}
