// ================= kitchen state =================
const kit = {counter: [], open: 'board', eating: null};
const CAP_COUNTER = 8;
const ST = {};
let fx = [], floats = [], petals = [];
const pointer = {down: false, x: 0, y: 0, sx: 0, sy: 0, lastT: 0};
function burst(x, y, n, cols){ if (reduced) n = Math.min(n, 3); for (let i = 0; i < n; i++){ const a = R() * TAU, s = 60 + R() * 140; fx.push({x, y, vx: Math.cos(a) * s, vy: Math.sin(a) * s - 40, life: .6 + R() * .5, r: 4 + R() * 5, c: cols[i % cols.length], rot: R() * 3}); } }
function puff(x, y){ for (let i = 0; i < 10; i++){ const a = R() * TAU, s = 20 + R() * 60; fx.push({x, y, vx: Math.cos(a) * s, vy: Math.sin(a) * s - 30, life: .7, r: 8 + R() * 8, cloud: true}); } }
function floatText(txt, x, y){ floats.push({txt, x, y, life: 1.4}); }
const flyers = [];
function drawFood(g, f, x, y, s){ if (f.flyUntil > clock) return; drawArt(g, foodSpec(f), x, y, s); }
function produce(food, x = CX, y = CY){
  const st = ST[kit.open];
  if (kit.counter.length >= CAP_COUNTER){ st.items.push(food); toast('The counter is full, so it stays here'); }
  else { kit.counter.push(food); food.arrive = clock + .45; food.flyUntil = clock + .5; flyers.push({f: food, x0: x, y0: y, s0: .8, t: clock, dur: .5, to: 'counter'}); }
  burst(x, y, 10, ['#FFFFFF', '#FF7EA6', '#FFE27A']);
  if (food.recipe != null){ const r = RECIPES[food.recipe]; floatText(r.n + '!', 200, 210); SND.sparkle(); toast(`That's ${r.n}!`); }
  else if (food.q === 'burnt') floatText('Oops, burnt!', 200, 210);
  else if (food.q === 'perfect') floatText('Perfect!', 200, 210);
  uiDirty = true;
}
function allFoods(){ return kit.counter.concat(...Object.values(ST).map(s => s.items)); }

function mk(def){ return Object.assign({items: [], cap: 4, back: 'counter', busy(){ return false; }, hint(){ return ''; }, btn(){ return null; }, meter(){ return null; }}, def); }
function slots(n){ return n <= 1 ? [[200, 330]] : n === 2 ? [[125, 330], [275, 330]] : n === 3 ? [[110, 280], [290, 280], [200, 410]] : [[120, 250], [280, 250], [120, 410], [280, 410]]; }
const slotScale = n => n <= 1 ? 1.2 : n === 2 ? .95 : .82;

// ---------- board (chop) ----------
ST.board = mk({key: 'board', name: 'Board', cap: 4, back: 'board', chops: new Map(), knife: null, swiped: new Set(),
  hint(){ return this.items.length ? 'Tap or swipe across food to chop it' : 'Chop things here. Tap food on the counter, or grab some from the Fridge.'; },
  pos(i){ return slots(Math.max(1, this.items.length))[i]; },
  hit(p){ return this.items.findIndex((f, i) => { const [x, y] = this.pos(i); return Math.hypot(p.x - x, p.y - y) < 72; }); },
  down(p){ this.swiped = new Set(); const i = this.hit(p); if (i >= 0) this.chop(i); },
  move(p){ const i = this.hit(p); if (i >= 0 && !this.swiped.has(this.items[i].uid)) this.chop(i); },
  chop(i){
    const f = this.items[i]; this.swiped.add(f.uid);
    if (f.hist[f.hist.length - 1] === 'chop'){ toast('That is already chopped'); return; }
    const n = (this.chops.get(f.uid) || 0) + 1; this.chops.set(f.uid, n);
    const [x, y] = this.pos(i); this.knife = {x, y, t: clock}; SND.chop(); buzz(12); burst(x, y, 5, [ING[f.comps[0].ing].c2, '#FFFFFF']);
    if (n >= 3){ this.items.splice(i, 1); this.chops.delete(f.uid); applyProc(f, 'chop'); produce(f, x, y); }
  },
  auto(){ const f = this.items.find(f => f.hist[f.hist.length - 1] !== 'chop'); if (!f) return; for (let k = 0; k < 4; k++){ const i = this.items.indexOf(f); if (i < 0) break; this.swiped = new Set(); this.chop(i); } },
  draw(g){
    const n = this.items.length, sc = slotScale(n);
    this.items.forEach((f, i) => { const [x, y] = this.pos(i), c = this.chops.get(f.uid) || 0;
      g.save(); g.translate(x, y); if (this.knife && clock - this.knife.t < .15 && this.knife.x === x && this.knife.y === y) g.scale(1.04, .96); drawFood(g, f, 0, 0, sc);
      for (let k = 1; k <= c; k++){ const lx = (-36 + k * 18) * sc; g.beginPath(); g.moveTo(lx, -40 * sc); g.lineTo(lx + 4, 40 * sc); line(g, 4, '#FFFFFF'); g.beginPath(); g.moveTo(lx, -40 * sc); g.lineTo(lx + 4, 40 * sc); line(g, 1.2, 'rgba(59,35,64,.5)'); }
      g.restore(); });
    if (this.knife && clock - this.knife.t < .25){ const k = (clock - this.knife.t) / .25; drawKnife(g, this.knife.x + 30, this.knife.y - 60 + Math.sin(k * Math.PI) * 40); }
    else if (n && !pointer.down){ const [x, y] = this.pos(0); drawKnife(g, x + 40, y - 70 + Math.sin(clock * 3) * 6, .5); }
    if (!n) emptyHint(g, 'Chopping board', 'Tap food on the counter below');
  }});
function drawKnife(g, x, y, a = 1){
  g.save(); g.globalAlpha = a; g.translate(x, y);
  g.beginPath(); g.moveTo(-3, -40); g.lineTo(14, -40); g.quadraticCurveTo(16, 10, 0, 34); g.lineTo(-3, 34); g.closePath(); fillLine(g, '#E9EEF8', 2.2);
  g.beginPath(); g.moveTo(9, -34); g.quadraticCurveTo(10, 0, 3, 24); line(g, 2, 'rgba(255,255,255,.95)');
  rr(g, -4, -84, 14, 46, 6); fillLine(g, '#FF9EBB', 2.2); disc(g, 3, -70, 2, PLUM); disc(g, 3, -54, 2, PLUM);
  g.restore();
}
function emptyHint(g, title, sub){
  g.save(); g.textAlign = 'center'; g.fillStyle = 'rgba(59,35,64,.55)'; g.font = '16px "Mochiy Pop One", sans-serif'; g.fillText(title, 200, 316);
  g.font = '700 12px "M PLUS Rounded 1c", sans-serif'; g.fillText(sub, 200, 340); g.restore();
}

// ---------- bowl (mix) ----------
ST.bowl = mk({key: 'bowl', name: 'Bowl', cap: 6, m: 0, lastA: null, swirl: 0, sndT: 0,
  hint(){ return this.items.length ? 'Stir in circles to mix it all together' : 'Mix things here: batters, salads, drinks…'; },
  meter(){ return this.items.length ? {v: this.m} : null; },
  down(p){ this.lastA = Math.atan2(p.y - CY, p.x - CX); },
  move(p){ if (!this.items.length) return; const a = Math.atan2(p.y - CY, p.x - CX);
    if (this.lastA != null && Math.hypot(p.x - CX, p.y - CY) > 20){ let d = a - this.lastA; if (d > Math.PI) d -= TAU; if (d < -Math.PI) d += TAU; this.m += Math.abs(d) / (2 * TAU); this.swirl += d;
      const now = performance.now(); if (now - this.sndT > 60){ this.sndT = now; SND.swish(clamp(Math.abs(d) * 4, 0, 1)); } if (this.m >= 1) this.finish(); }
    this.lastA = a; },
  up(){ this.lastA = null; },
  finish(){ const f = mergeFoods(this.items, 'mix'); this.items = []; this.m = 0; produce(f); },
  auto(){ if (!this.items.length) return; this.m += .35; this.swirl += 2; SND.swish(.7); if (this.m >= 1) this.finish(); },
  draw(g){
    const r0 = 150, m = clamp(this.m, 0, 1), comps = compsOf(this.items), mix = comps.length ? mixOf(comps) : '#E8F0FF';
    disc(g, CX + 4, CY + 8, r0, 'rgba(59,35,64,.18)'); disc(g, CX, CY, r0, '#A9C8FF'); ring(g, CX, CY, r0, 3);
    disc(g, CX, CY, r0 - 16, '#E8F0FF'); ring(g, CX, CY, r0 - 16);
    g.save(); g.beginPath(); g.arc(CX, CY, r0 - 20, 0, TAU); g.clip();
    if (m > .05) disc(g, CX, CY, (r0 - 30) * clamp(m * 1.5, 0, 1), mix);
    comps.forEach((c, i) => { const d = (.25 + .55 * ((i * .37) % 1)) * (r0 - 50) * (1 - m * .6), a = i * 2.4 + this.swirl * (1 - d / 200);
      g.globalAlpha = 1 - m * .9; const x = CX + Math.cos(a) * d, y = CY + Math.sin(a) * d; if (m < .15) drawIng(g, c.ing, x, y, 26); else ell(g, x, y, 26 + m * 20, 20 + m * 14, lerpC(compColor(c), mix, m)); });
    g.globalAlpha = 1;
    if (m > .3){ g.strokeStyle = `rgba(255,255,255,${.25 + .3 * m})`; g.lineWidth = 3; for (let i = 0; i < 4; i++){ g.beginPath(); for (let k = 0; k < 50; k++){ const t = k / 50, a = this.swirl + i * Math.PI / 2 + t * 4, d = t * (r0 - 40); const x = CX + Math.cos(a) * d, y = CY + Math.sin(a) * d; k ? g.lineTo(x, y) : g.moveTo(x, y); } g.stroke(); } }
    g.restore();
    face(g, CX, CY + r0 - 6, .8, this.items.length ? 'happy' : 'sleepy');
    if (this.items.length){ const wx = pointer.down ? pointer.x : CX + Math.cos(clock * 2.5) * 70, wy = pointer.down ? pointer.y : CY + Math.sin(clock * 2.5) * 70; g.globalAlpha = pointer.down ? 1 : .7; drawWhisk(g, wx, wy + 20, .25); g.globalAlpha = 1; }
    else emptyHint(g, 'Mixing bowl', 'Add ingredients to mix');
  }});
function drawWhisk(g, x, y, rot){ g.save(); g.translate(x, y); g.rotate(rot); rr(g, -6, -110, 12, 54, 6); fillLine(g, '#FF9EBB'); for (const w of [8, 16, 24]){ g.beginPath(); g.ellipse(0, -28, w * .7, 30, 0, 0, TAU); line(g, 2, '#7E86A8'); } g.restore(); }

// ---------- blender ----------
const JUG = {cx: 200, top: 200, bot: 420, tw: 176, bw: 124};
function jugPath(g){ g.beginPath(); g.moveTo(JUG.cx - JUG.tw / 2, JUG.top); g.lineTo(JUG.cx + JUG.tw / 2, JUG.top); g.lineTo(JUG.cx + JUG.bw / 2, JUG.bot); g.lineTo(JUG.cx - JUG.bw / 2, JUG.bot); g.closePath(); }
ST.blender = mk({key: 'blender', name: 'Blender', cap: 5, p: 0, hold: false, snd: null,
  hint(){ return this.items.length ? (this.hold ? 'Whirrrr… keep holding' : 'Hold anywhere to blend') : 'Blend fruit, milk or anything into a drink'; },
  meter(){ return this.items.length ? {v: clamp(this.p, 0, 1)} : null; },
  busy(){ return this.hold; },
  down(){ if (!this.items.length) return; this.hold = true; this.snd = loopSnd('blender'); },
  up(){ if (!this.hold) return; this.hold = false; this.snd?.stop(); SND.spinDown(); },
  update(dt){ if (this.hold){ this.p += dt * .34; this.snd?.set(clamp(this.p, 0, 1)); if (R() < dt * 6) buzz(6); if (this.p >= 1) this.finish(); } },
  finish(){ if (this.hold){ this.hold = false; this.snd?.stop(); SND.spinDown(); } const f = mergeFoods(this.items, 'blend'); this.items = []; this.p = 0; produce(f, 200, 300); },
  auto(){ if (this.items.length) this.finish(); },
  draw(g){
    const spin = this.hold, shake = spin ? Math.sin(clock * 60) * 1.5 : 0, comps = compsOf(this.items), p = clamp(this.p, 0, 1), mix = comps.length ? lighten(mixOf(comps), .08) : '#FFFFFF';
    g.save(); g.translate(shake, 0);
    rr(g, 128, 420, 144, 82, 22); fillLine(g, '#C8B6FF', 3); rr(g, 138, 426, 124, 10, 5); g.fillStyle = 'rgba(255,255,255,.45)'; g.fill();
    face(g, 186, 456, .9, spin ? 'focus' : comps.length ? 'idle' : 'sleepy');
    disc(g, 246, 478, 12, spin ? '#FF5C8D' : '#FF9EBB'); ring(g, 246, 478, 12);
    g.save(); jugPath(g); g.clip();
    let y = JUG.bot; const hs = comps.map(c => 26 * Math.max(.45, ING[c.ing].w)), tot = hs.reduce((a, b) => a + b, 0), sc = Math.min(1, 190 / Math.max(1, tot));
    comps.forEach((c, i) => { const h = hs[i] * sc; g.fillStyle = lerpC(compColor(c), mix, p * 1.6); g.fillRect(0, y - h, W, h + 1);
      if (p < .3){ g.save(); g.globalAlpha = 1 - p * 3; drawIng(g, c.ing, 170 + (i % 3) * 30, y - h / 2, Math.min(18, h * .6)); g.restore(); } y -= h; });
    if (tot){ ell(g, 200, y, 90, 7, 'rgba(255,255,255,.35)'); if (spin){ g.strokeStyle = 'rgba(255,255,255,.55)'; g.lineWidth = 3; for (let i = 0; i < 5; i++){ const a = clock * 14 + i * 1.3; g.beginPath(); g.ellipse(200, y + (JUG.bot - y) * (.3 + i * .14), 50 - i * 6, 10, 0, a, a + 2.2); g.stroke(); } } }
    g.restore();
    g.save(); g.translate(200, 410); g.rotate(spin ? clock * 40 : 0); g.fillStyle = '#9AA0B8'; g.fillRect(-30, -2, 60, 4); g.restore();
    jugPath(g); shadeFill(g, 'rgba(220,240,255,.18)'); line(g, 3);
    g.beginPath(); g.moveTo(JUG.cx - JUG.tw / 2 + 16, JUG.top + 24); g.lineTo(JUG.cx - JUG.bw / 2 + 12, JUG.bot - 24); line(g, 5, 'rgba(255,255,255,.75)');
    for (let i = 1; i <= 4; i++){ const yy = JUG.bot - i * 40; g.beginPath(); g.moveTo(JUG.cx + 30, yy); g.lineTo(JUG.cx + 44, yy); line(g, 2, 'rgba(59,35,64,.35)'); }
    g.beginPath(); g.moveTo(JUG.cx + JUG.tw / 2 - 4, JUG.top + 30); g.bezierCurveTo(JUG.cx + JUG.tw / 2 + 44, JUG.top + 40, JUG.cx + JUG.tw / 2 + 30, JUG.top + 150, JUG.cx + JUG.bw / 2 + 4, JUG.top + 170); line(g, 9); g.strokeStyle = '#C8B6FF'; g.lineWidth = 4; g.stroke();
    rr(g, 108, 180, 184, 26, 10); fillLine(g, '#FF9EBB', 3); rr(g, 182, 168, 36, 16, 6); fillLine(g, '#FF7EA6');
    g.restore();
  }});

// ---------- bamboo mat (roll) ----------
const MAT = {x: 56, y: 160, w: 288, h: 350}, NORI = {x: 75, y: 185, w: 250, h: 300};
function drawMatBg(g, clipY = H){
  g.save(); g.beginPath(); g.rect(0, 0, W, clipY); g.clip();
  rr(g, MAT.x + 2, MAT.y + 5, MAT.w, MAT.h, 6); g.fillStyle = 'rgba(120,80,40,.25)'; g.fill();
  for (let y = MAT.y, i = 0; y < MAT.y + MAT.h; y += 10, i++){ rr(g, MAT.x, y, MAT.w, 9, 4); g.fillStyle = i % 2 ? '#DDB874' : '#D3AB63'; g.fill(); g.fillStyle = 'rgba(255,255,255,.35)'; g.fillRect(MAT.x + 6, y + 1.5, MAT.w - 12, 1.5); }
  g.strokeStyle = '#8E6A35'; g.lineWidth = 1.5; for (const x of [MAT.x + 30, MAT.x + MAT.w - 30]){ g.beginPath(); g.moveTo(x, MAT.y); g.lineTo(x, MAT.y + MAT.h); g.stroke(); }
  rr(g, MAT.x, MAT.y, MAT.w, MAT.h, 6); line(g); g.restore();
}
function drawLogCapsule(g, x0, x1, y, Rr, bamboo, phase){
  const grd = g.createLinearGradient(0, y - Rr, 0, y + Rr);
  if (bamboo){ grd.addColorStop(0, '#B78845'); grd.addColorStop(.3, '#EAC786'); grd.addColorStop(1, '#966A30'); } else { grd.addColorStop(0, '#1A2620'); grd.addColorStop(.28, '#3F5E4C'); grd.addColorStop(.5, '#22332A'); grd.addColorStop(1, '#141E19'); }
  rr(g, x0, y - Rr, x1 - x0, Rr * 2, Rr); g.fillStyle = grd; g.fill();
  if (bamboo){ g.save(); rr(g, x0, y - Rr, x1 - x0, Rr * 2, Rr); g.clip(); g.strokeStyle = 'rgba(110,75,30,.6)'; g.lineWidth = 1.2; for (let i = 0; i < 12; i++){ const a = (i / 12 * TAU + phase) % TAU; if (Math.cos(a) < 0) continue; const yy = y + Math.sin(a) * Rr; g.beginPath(); g.moveTo(x0, yy); g.lineTo(x1, yy); g.stroke(); } g.restore(); }
  rr(g, x0, y - Rr, x1 - x0, Rr * 2, Rr); line(g);
}
ST.mat = mk({key: 'mat', name: 'Mat', cap: 5, back: 'board', p: 0, clickAt: 0,
  hint(){ return this.items.length ? 'Push up on the mat to roll it tight' : 'Roll sushi here: nori, cooked rice and fillings'; },
  meter(){ return this.items.length ? {v: this.p} : null; },
  move(p, q){ if (this.items.length && q.y > p.y) this.push(q.y - p.y); },
  push(d){ this.p = Math.min(1, this.p + d / 320); while (this.p >= this.clickAt + .045){ this.clickAt += .045; SND.click(); buzz(4); } if (this.p >= 1){ SND.fwip(); const f = mergeFoods(this.items, 'roll'); this.items = []; this.p = 0; this.clickAt = 0; produce(f, 200, 300); } },
  auto(){ if (this.items.length) this.push(400); },
  draw(g){
    const yb = NORI.y + NORI.h - this.p * (NORI.h - 30), Rr = 16 + this.p * 16;
    drawMatBg(g, this.p > 0 ? yb : H);
    if (!this.items.length){ emptyHint(g, 'Bamboo mat', 'Lay nori, rice and fillings here'); return; }
    g.save(); g.beginPath(); g.rect(0, 0, W, yb); g.clip();
    const nori = this.items.find(f => f.comps.length === 1 && f.comps[0].ing === 'nori' && !f.hist.length);
    if (nori){ rr(g, NORI.x, NORI.y, NORI.w, NORI.h, 3); fillLine(g, '#1F2C25'); }
    const others = this.items.filter(f => f !== nori);
    others.forEach((f, i) => { const rice = f.comps.some(c => c.ing === 'rice'); if (rice){ rr(g, NORI.x + 6, NORI.y + 44, NORI.w - 12, NORI.h - 52, 6); g.fillStyle = '#FDFAF3'; g.fill(); for (let k = 0; k < 60; k++) ell(g, NORI.x + 14 + (k * 37 % 222), NORI.y + 52 + (k * 53 % 230), 3, 1.6, '#E8E1D3'); }
      else drawFood(g, f, 200 + (i % 2 ? 50 : -50), 400 - Math.floor(i / 2) * 60, .55); });
    g.restore();
    if (this.p > 0) drawLogCapsule(g, MAT.x - 2, MAT.x + MAT.w + 2, yb, Rr, true, this.p * 22);
    else if (!pointer.down){ const a = .5 + .5 * Math.sin(clock * 4), ay = 540 - a * 10; g.globalAlpha = a; g.beginPath(); g.moveTo(200, ay - 16); g.lineTo(216, ay); g.lineTo(206, ay); g.lineTo(206, ay + 16); g.lineTo(194, ay + 16); g.lineTo(194, ay); g.lineTo(184, ay); g.closePath(); fillLine(g, '#FF7EA6'); g.globalAlpha = 1; }
  }});

// ---------- heat stations share this ----------
function heatStation(def){
  return mk(Object.assign({run: false, cook: 0, snd: null, crackT: 0,
    meter(){ return this.items.length && this.run ? {v: clamp(this.cook / 1.4, 0, 1), zone: [.62 / 1.4, 1 / 1.4]} : null; },
    busy(){ return this.run; },
    start(){ if (!this.items.length || this.run) return; this.run = true; this.cook = 0; this.snd = loopSnd(this.loop); SND.clunk(); this.onStart?.(); },
    take(){ if (!this.run) return; this.run = false; this.snd?.stop(); SND.clunk(); const f = mergeFoods(this.items, this.proc, this.cook); this.items = []; const c = this.cook; this.cook = 0; this.onTake?.(); produce(f); return c; },
    btn(){ if (!this.items.length) return null; return this.run ? {label: 'Take out', enabled: this.cook >= .25, ready: this.cook >= .62 && this.cook <= 1} : {label: this.verb, enabled: this.canStart ? this.canStart() : true}; },
    onBtn(){ this.run ? this.take() : this.start(); },
    auto(){ if (!this.items.length) return; if (!this.run){ this.prep?.(); this.start(); } else { this.cook = .8; this.take(); } },
    stateHint(){ return !this.run ? null : this.cook < .62 ? this.cooking : this.cook <= 1 ? 'Ready! Take it out now' : 'Careful, it is starting to burn!'; },
    preview(){ return genericSpec(compsOf(this.items), [...new Set(this.items.flatMap(f => f.hist)), this.proc], {q: cookQ(this.cook), cook: this.cook, hot: clock + 1}); },
    tick(dt){ if (!this.run) return; this.cook += dt * this.rate * (this.rateMul ? this.rateMul() : 1); if (this.cook > 1.7) this.take(); },
  }, def));
}
function previewOrRaw(st, g, x, y, s){
  if (st.run && st.cook > .12){ const sp = st.preview(); sp.burnt = st.cook > 1.18; drawArt(g, sp, x, y, s); }
  else { const n = st.items.length, pos = n === 1 ? [[0, 0]] : [[-45, 0], [45, 0], [0, -30], [0, 30]]; st.items.forEach((f, i) => drawFood(g, f, x + pos[i % 4][0] * s, y + pos[i % 4][1] * s, s * (n === 1 ? 1 : .6))); }
}
// ---------- pot (boil) ----------
ST.pot = heatStation({key: 'pot', name: 'Pot', cap: 6, back: 'stove', proc: 'boil', verb: 'Boil', loop: 'boil', rate: .12, cooking: 'Bubbling away… stir if you like', lastA: null, sndT: 0,
  hint(){ return this.stateHint() || (this.items.length ? 'Press Boil to heat the water' : 'Boil rice, noodles, soups and drinks here'); },
  down(p){ this.lastA = Math.atan2(p.y - 330, p.x - 200); },
  move(p){ if (!this.run) return; const a = Math.atan2(p.y - 330, p.x - 200); if (this.lastA != null){ let d = a - this.lastA; if (d > Math.PI) d -= TAU; if (d < -Math.PI) d += TAU; this.swirl = (this.swirl || 0) + d; const now = performance.now(); if (now - this.sndT > 70){ this.sndT = now; SND.swish(clamp(Math.abs(d) * 3, 0, .8)); } } this.lastA = a; },
  up(){ this.lastA = null; },
  update(dt){ this.tick(dt); if (this.run){ if (R() < dt * 5) SND.bloop(); if (R() < dt * 3) buzz(3); } },
  draw(g){
    const comps = compsOf(this.items), water = comps.length ? lerpC('#BFE3F2', mixOf(comps), clamp(this.cook, 0, 1) * .75) : '#BFE3F2';
    if (this.run) for (let i = 0; i < 5; i++){ const x = 120 + i * 40; g.beginPath(); g.moveTo(x - 8, 480); g.quadraticCurveTo(x, 448 - Math.sin(clock * 12 + i) * 6, x + 8, 480); g.fillStyle = i % 2 ? '#7FD3F7' : '#FFB86A'; g.fill(); }
    rr(g, 50, 300, 30, 18, 8); fillLine(g, '#8E96B8'); rr(g, 320, 300, 30, 18, 8); fillLine(g, '#8E96B8');
    rr(g, 72, 290, 256, 180, [10, 10, 40, 40]); fillLine(g, '#C5CCE6', 3); rr(g, 80, 360, 240, 10, 5); g.fillStyle = 'rgba(255,255,255,.4)'; g.fill();
    face(g, 200, 410, 1.1, this.run ? (this.cook > 1.18 ? 'yuck' : 'happy') : this.items.length ? 'idle' : 'sleepy');
    ell(g, 200, 290, 128, 34, '#9AA3C6', 3); g.save(); g.beginPath(); g.ellipse(200, 292, 116, 27, 0, 0, TAU); g.clip(); const wgr = g.createLinearGradient(0, 264, 0, 320); wgr.addColorStop(0, lighten(water, .35)); wgr.addColorStop(1, darken(water, .14)); g.fillStyle = wgr; g.fillRect(70, 260, 260, 70); for (let i = 0; i < 3; i++){ g.beginPath(); g.ellipse(200 + Math.sin(clock * .8 + i * 2) * 12, 292, 92 - i * 26, 19 - i * 5, 0, Math.PI * 1.08, Math.PI * 1.55); line(g, 2, 'rgba(255,255,255,.55)'); }
    const sw = this.swirl || 0;
    this.items.forEach((f, i) => { const a = i * 2.1 + sw * .5 + clock * (this.run ? .6 : 0), x = 200 + Math.cos(a) * 60, y = 292 + Math.sin(a) * 12 + Math.sin(clock * 3 + i) * 2; g.save(); g.translate(x, y); g.scale(1, .7); drawFood(g, f, 0, -8, .4); g.restore(); });
    if (this.run) for (let i = 0; i < 9; i++){ const t = (clock * .9 + i / 9) % 1, x = 100 + ((i * 53) % 200); g.globalAlpha = 1 - t; ring(g, x, 300 - t * 14, 3 + t * 5, 1.5, 'rgba(255,255,255,.9)'); } g.globalAlpha = 1;
    g.restore(); g.beginPath(); g.ellipse(200, 292, 116, 27, 0, 0, TAU); line(g, 2.5);
    if (this.run) steamAt(g, 200, 250, this.cook > 1.18);
    if (!this.items.length) emptyHint(g, '', 'Add food, then press Boil');
  }});
function steamAt(g, x, y, smoke){ const col = smoke ? '110,96,110' : '255,255,255';
  for (let i = 0; i < 5; i++){ const t = (clock * .4 + i / 5) % 1, a = Math.sin(t * Math.PI), px = x - 48 + i * 24 + Math.sin(t * 4 + i) * 10, py = y - t * 92, r = 14 + t * 28;
    const gr = g.createRadialGradient(px, py, 0, px, py, r); gr.addColorStop(0, `rgba(${col},${(smoke ? .65 : .5) * a})`); gr.addColorStop(1, `rgba(${col},0)`); g.fillStyle = gr; g.fillRect(px - r, py - r, r * 2, r * 2); } }
// ---------- pan (fry) ----------
const PAN = {x: 190, y: 310, r: 122};
ST.pan = heatStation({key: 'pan', name: 'Pan', cap: 4, back: 'stove', proc: 'fry', verb: 'Fry', loop: 'sizzle', rate: .14, cooking: 'Sizzling… swipe up to flip', flipT: -1, flipped: false,
  hint(){ return this.stateHint() || (this.items.length ? 'Press Fry to heat the pan' : 'Fry eggs, pancakes, chips and more'); },
  down(){ this.flipped = false; },
  move(p){ if (this.run && !this.flipped && pointer.sy - p.y > 60){ this.flipped = true; this.flipT = clock; SND.flip(); buzz(10); this.cook += .02; } },
  update(dt){ this.tick(dt); if (this.run){ this.crackT -= dt; if (this.crackT <= 0){ this.crackT = .04 + R() * .18; SND.crackle(); } } },
  draw(g){
    const {x, y, r} = PAN;
    if (this.run){ g.beginPath(); g.arc(x, y, r + 10, 0, TAU); g.strokeStyle = `rgba(255,120,80,${.35 + .2 * Math.sin(clock * 6)})`; g.lineWidth = 10; g.stroke(); }
    rr(g, x + r - 10, y - 12, 140, 24, 12); fillLine(g, '#A8734A');
    disc(g, x, y, r, '#2A2A38'); ring(g, x, y, r, 3);
    const gr = g.createRadialGradient(x - 30, y - 30, 10, x, y, r - 10); gr.addColorStop(0, '#6A6A84'); gr.addColorStop(1, '#3E3E54'); disc(g, x, y, r - 12, gr);
    g.beginPath(); g.arc(x, y, r - 30, Math.PI * 1.15, Math.PI * 1.45); line(g, 5, 'rgba(255,255,255,.28)'); g.beginPath(); g.arc(x, y, r - 4, Math.PI * 1.1, Math.PI * 1.5); line(g, 3, 'rgba(255,255,255,.4)'); if (this.run){ const oil = g.createRadialGradient(x + 20, y + 20, 10, x, y, r - 14); oil.addColorStop(0, 'rgba(255,214,120,.18)'); oil.addColorStop(1, 'rgba(255,214,120,0)'); g.fillStyle = oil; g.fillRect(x - r, y - r, r * 2, r * 2); }
    face(g, x + r + 60, y, .7, this.run ? 'focus' : 'idle');
    let up = 0, sy = 1; if (this.flipT >= 0 && clock - this.flipT < .6){ const k = (clock - this.flipT) / .6; up = Math.sin(k * Math.PI) * 90; sy = Math.cos(k * TAU); }
    g.save(); g.translate(x, y - up); g.scale(1, Math.max(.08, Math.abs(sy))); previewOrRaw(this, g, 0, 0, .95); g.restore();
    if (this.run) steamAt(g, x, y - 60, this.cook > 1.18);
    if (!this.items.length) emptyHint(g, '', 'Add food, then press Fry');
  }});
// ---------- oven (bake) ----------
const OVEN = {x: 56, y: 150, w: 288, h: 310};
ST.oven = heatStation({key: 'oven', name: 'Oven', cap: 4, proc: 'bake', verb: 'Bake', loop: 'hum', rate: .1, cooking: 'Baking… peek through the window', temp: 180, drag: false, lastTick: 180, dinged: false,
  rateMul(){ return this.temp / 180; }, canStart(){ return this.temp >= 120; },
  hint(){ return this.stateHint() || (this.items.length ? 'Set the dial (about 180°) and press Bake' : 'Bake cakes, cookies, pizza and toast'); },
  onStart(){ this.dinged = false; }, prep(){ this.temp = 180; },
  down(p){ if (Math.hypot(p.x - (OVEN.x + 240), p.y - (OVEN.y + 51)) < 60){ this.drag = true; this.setFrom(p); } else if (this.run && p.y > OVEN.y + 90 && p.y < OVEN.y + OVEN.h && this.cook >= .25) this.take(); },
  move(p){ if (this.drag) this.setFrom(p); }, up(){ this.drag = false; },
  setFrom(p){ let a = Math.atan2(p.y - (OVEN.y + 51), p.x - (OVEN.x + 240)) + Math.PI / 2; if (a > Math.PI) a -= TAU; a = clamp(a, -Math.PI * .75, Math.PI * .75);
    this.temp = Math.round((50 + (a + Math.PI * .75) / (Math.PI * 1.5) * 200) / 5) * 5; if (Math.abs(this.temp - this.lastTick) >= 10){ this.lastTick = this.temp; SND.tick(); buzz(3); } },
  update(dt){ this.tick(dt); if (this.run){ if (Math.floor(clock * 2) !== Math.floor((clock - dt) * 2)) SND.tick(); if (this.cook >= .62 && !this.dinged){ this.dinged = true; SND.ding(); buzz(20); } } },
  draw(g){
    const {x, y, w, h} = OVEN, mood = this.run ? (this.cook > 1.18 ? 'yuck' : this.cook >= .62 ? 'happy' : 'focus') : this.items.length ? 'idle' : 'sleepy';
    rr(g, x + 20, y + h - 4, 24, 16, 4); g.fillStyle = PLUM; g.fill(); rr(g, x + w - 44, y + h - 4, 24, 16, 4); g.fill();
    rr(g, x, y, w, h, 26); fillLine(g, '#FFB9A6', 3); rr(g, x + 10, y + 8, w - 20, 8, 4); g.fillStyle = 'rgba(255,255,255,.5)'; g.fill();
    rr(g, x + 14, y + 20, w - 28, 62, 16); fillLine(g, '#FFE3D8');
    face(g, x + 62, y + 50, 1, mood);
    rr(g, x + 112, y + 34, 82, 34, 8); fillLine(g, '#2E2A40');
    g.fillStyle = this.run ? '#8FF0C8' : '#FFE27A'; g.font = '18px "Mochiy Pop One", sans-serif'; g.textAlign = 'center'; g.fillText(Math.round(this.temp) + '°', x + 153, y + 58);
    const kx = x + 240, ky = y + 51; disc(g, kx, ky, 24, '#FFF6F0'); ring(g, kx, ky, 24);
    for (let i = 0; i <= 8; i++){ const a = -Math.PI * .75 + i / 8 * Math.PI * 1.5 - Math.PI / 2; g.beginPath(); g.moveTo(kx + Math.cos(a) * 28, ky + Math.sin(a) * 28); g.lineTo(kx + Math.cos(a) * 32, ky + Math.sin(a) * 32); line(g, 1.5); }
    const ka = -Math.PI * .75 + (this.temp - 50) / 200 * Math.PI * 1.5 - Math.PI / 2; g.beginPath(); g.moveTo(kx, ky); g.lineTo(kx + Math.cos(ka) * 18, ky + Math.sin(ka) * 18); line(g, 4, '#FF5C8D');
    rr(g, x + 14, y + 96, w - 28, h - 112, 18); fillLine(g, '#FFCFC1'); rr(g, x + 60, y + 104, w - 120, 12, 6); fillLine(g, '#FFF6F0');
    const wx = x + 34, wy = y + 128, ww = w - 68, wh = h - 160;
    rr(g, wx, wy, ww, wh, 14); g.fillStyle = this.run ? '#5A3A2E' : '#3A3348'; g.fill();
    g.save(); rr(g, wx, wy, ww, wh, 14); g.clip();
    if (this.run){ const gl = g.createRadialGradient(wx + ww / 2, wy + wh / 2, 10, wx + ww / 2, wy + wh / 2, ww * .7); gl.addColorStop(0, `rgba(255,190,90,${.75 + .1 * Math.sin(clock * 3)})`); gl.addColorStop(1, 'rgba(255,120,60,.25)'); g.fillStyle = gl; g.fillRect(wx, wy, ww, wh); }
    if (this.run) for (const ey of [wy + 9, wy + wh - 9]){ const pulse = .6 + .4 * Math.sin(clock * 4); g.beginPath(); g.moveTo(wx + 14, ey); for (let i = 1; i <= 10; i++) g.lineTo(wx + 14 + i * (ww - 28) / 10, ey + (i % 2 ? -4 : 4)); line(g, 6, `rgba(255,120,60,${.35 * pulse})`); line(g, 2.5, `rgba(255,190,120,${.9 * pulse})`); }
    rr(g, wx + 10, wy + wh - 22, ww - 20, 8, 4); g.fillStyle = '#9AA0B8'; g.fill();
    previewOrRaw(this, g, wx + ww / 2, wy + wh / 2 - 4, .62);
    g.restore(); rr(g, wx, wy, ww, wh, 14); line(g, 2.5); g.beginPath(); g.moveTo(wx + 16, wy + 14); g.lineTo(wx + 50, wy + 14); line(g, 4, 'rgba(255,255,255,.4)');
    if (this.run && this.cook > 1.18) steamAt(g, 200, y - 4, true);
  }});
// ---------- microwave (zap) ----------
const MW = {x: 28, y: 160, w: 344, h: 250}, MWIN = {x: 48, y: 182, w: 206, h: 196};
const KEYS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '▶'];
const keyRect = i => ({x: 274 + (i % 3) * 30, y: 246 + Math.floor(i / 3) * 34, w: 26, h: 28});
ST.micro = mk({key: 'micro', name: 'Micro', cap: 3, run: false, buf: '', el: 0, setSec: 0, kern: [], pressed: -1, pressT: 0, snd: null, spin: 0,
  busy(){ return this.run; },
  ck(){ return this.el * 8 / 60; },
  hint(){ return this.run ? (this.ck() < .62 ? 'Warming up… press Stop any time' : this.ck() <= 1 ? 'Nearly ready!' : 'That is a long time…') : this.items.length ? 'Type a time (about 0:50), then press ▶' : 'Warm drinks, melt things, pop popcorn'; },
  meter(){ return this.run ? {v: clamp(this.ck() / 1.4, 0, 1), zone: [.62 / 1.4, 1 / 1.4]} : null; },
  btn(){ return this.run ? {label: 'Stop', enabled: true, ready: this.ck() >= .62 && this.ck() <= 1} : null; },
  onBtn(){ if (this.run) this.finish(); },
  disp(){ if (this.run){ const r = Math.max(0, Math.ceil(this.setSec - this.el * 8)); return `${Math.floor(r / 60)}:${String(r % 60).padStart(2, '0')}`; } const d = this.buf.padStart(3, '0').slice(-3); return `${d[0]}:${d.slice(1)}`; },
  down(p){
    if (!this.run){ KEYS.forEach((k, i) => { const r = keyRect(i); if (p.x > r.x - 2 && p.x < r.x + r.w + 2 && p.y > r.y - 3 && p.y < r.y + r.h + 3) this.press(i); }); return; }
    if (p.y > MW.y && p.y < MW.y + MW.h) this.finish();
  },
  press(i){ const k = KEYS[i]; this.pressed = i; this.pressT = clock; SND.key(); buzz(4);
    if (k === 'C') this.buf = ''; else if (k === '▶'){ if (!this.items.length) toast('Put something in first'); else if (!this.buf) toast('Type a time first'); else this.start(); } else if (this.buf.length < 3) this.buf += k; },
  start(){ const v = parseInt(this.buf, 10); this.setSec = Math.floor(v / 100) * 60 + v % 100; if (this.setSec <= 0) return; this.run = true; this.el = 0; this.snd = loopSnd('hum'); SND.clunk(); },
  finish(){ if (!this.run) return; this.run = false; this.snd?.stop(); SND.beep(); const f = mergeFoods(this.items, 'zap', this.ck()); this.items = []; this.kern = []; this.buf = ''; produce(f, 150, 280); },
  update(dt){
    if (!this.run) return; this.el += dt; this.spin += dt * 2;
    const pop = this.items.some(f => f.comps.some(c => c.ing === 'kernels')), c = this.ck();
    if (pop){ const rate = c < .12 ? 0 : c < 1 ? 22 * Math.pow(Math.sin(Math.PI * Math.min(1, (c - .12) / .95)), 1.3) + 1 : 1.2; if (R() < rate * dt){ SND.kernel(); if (R() < .4) buzz(4); this.kern.push({x: MWIN.x + 60 + R() * 90, y: MWIN.y + MWIN.h - 60, vx: (R() - .5) * 120, vy: -150 - R() * 120}); } }
    for (const k of this.kern){ k.vy += 600 * dt; k.x += k.vx * dt; k.y += k.vy * dt; } this.kern = this.kern.filter(k => k.y < MWIN.y + MWIN.h - 20);
    if (this.setSec - this.el * 8 <= 0) this.finish();
  },
  auto(){ if (!this.items.length) return; if (!this.run){ this.buf = '50'; this.start(); } else { this.el = 50 / 8; this.finish(); } },
  draw(g){
    const {x, y, w, h} = MW;
    rr(g, x + 22, y + h - 4, 26, 14, 4); g.fillStyle = PLUM; g.fill(); rr(g, x + w - 48, y + h - 4, 26, 14, 4); g.fill();
    rr(g, x, y, w, h, 24); fillLine(g, '#A8E6CF', 3); rr(g, x + 10, y + 7, w - 20, 7, 4); g.fillStyle = 'rgba(255,255,255,.55)'; g.fill();
    const {x: wx, y: wy, w: ww, h: wh} = MWIN;
    rr(g, wx - 8, wy - 8, ww + 16, wh + 16, 18); fillLine(g, '#8ED6BC');
    rr(g, wx, wy, ww, wh, 12); g.fillStyle = this.run ? '#FFE9A8' : '#3A4A50'; g.fill();
    g.save(); rr(g, wx, wy, ww, wh, 12); g.clip();
    if (this.run){ const gl = g.createRadialGradient(wx + ww / 2, wy + wh / 2, 10, wx + ww / 2, wy + wh / 2, ww * .7); gl.addColorStop(0, 'rgba(255,250,210,.9)'); gl.addColorStop(1, 'rgba(255,200,120,.6)'); g.fillStyle = gl; g.fillRect(wx, wy, ww, wh); }
    g.beginPath(); g.ellipse(wx + ww / 2, wy + wh - 30, 82, 16, 0, 0, TAU); shadeFill(g, 'rgba(255,255,255,.55)'); line(g, 2);
    g.save(); g.translate(wx + ww / 2, wy + wh - 70); g.scale(this.run ? Math.cos(this.spin) * .25 + .75 : 1, 1);
    if (this.run && this.ck() > .12){ const sp = genericSpec(compsOf(this.items), [...new Set(this.items.flatMap(f => f.hist)), 'zap'], {cook: this.ck(), q: cookQ(this.ck())}); sp.burnt = this.ck() > 1.18; drawArt(g, sp, 0, 0, .7); }
    else this.items.forEach((f, i) => drawFood(g, f, (i - (this.items.length - 1) / 2) * 60, 0, this.items.length > 1 ? .5 : .7));
    g.restore();
    for (const k of this.kern) disc(g, k.x, k.y, 4, '#FFFBEA');
    g.restore();
    rr(g, wx, wy, ww, wh, 12); line(g, 2.5);
    g.beginPath(); g.moveTo(wx + 14, wy + 22); g.lineTo(wx + 60, wy + 22); line(g, 4, 'rgba(255,255,255,.35)');
    rr(g, wx + ww - 6, wy + 40, 10, 110, 5); fillLine(g, '#E8FFF6', 2);
    face(g, 315, 196, .75, this.run ? 'focus' : this.items.length ? 'idle' : 'sleepy');
    rr(g, 270, 212, 92, 28, 7); fillLine(g, '#26303A');
    g.fillStyle = '#8FF0C8'; g.font = '16px "Mochiy Pop One", sans-serif'; g.textAlign = 'center'; g.fillText(this.disp(), 316, 233);
    KEYS.forEach((kk, i) => { const r = keyRect(i), pr = this.pressed === i && clock - this.pressT < .12;
      rr(g, r.x, r.y + (pr ? 2 : 0), r.w, r.h, 7); fillLine(g, kk === '▶' ? '#FF9EBB' : kk === 'C' ? '#FFE27A' : '#F2FFF9', 2);
      g.fillStyle = PLUM; g.font = '800 13px "M PLUS Rounded 1c", sans-serif'; g.fillText(kk, r.x + r.w / 2, r.y + 19 + (pr ? 2 : 0)); });
    if (!this.items.length) { g.save(); g.fillStyle = 'rgba(255,255,255,.75)'; g.font = '700 12px "M PLUS Rounded 1c", sans-serif'; g.textAlign = 'center'; g.fillText('Add food first', wx + ww / 2, wy + wh / 2); g.restore(); }
  }});
// ---------- freezer ----------
ST.freezer = mk({key: 'freezer', name: 'Freezer', cap: 4, run: false, p: 0, snd: null,
  busy(){ return this.run; },
  hint(){ return this.run ? 'Chilling… brrr' : this.items.length ? 'Press Freeze to chill it' : 'Freeze ice creams and popsicles'; },
  meter(){ return this.run ? {v: this.p} : null; },
  btn(){ return this.items.length && !this.run ? {label: 'Freeze', enabled: true} : null; },
  onBtn(){ if (!this.items.length || this.run) return; this.run = true; this.p = 0; this.snd = loopSnd('cold'); SND.clunk(); },
  update(dt){ if (!this.run) return; this.p += dt * .22; if (R() < dt * 8) SND.frost(); if (this.p >= 1){ this.run = false; this.snd?.stop(); SND.ding(); const f = mergeFoods(this.items, 'freeze'); this.items = []; this.p = 0; produce(f, 200, 300); } },
  auto(){ if (!this.items.length) return; if (!this.run) this.onBtn(); else { this.p = 1; this.update(0); } },
  draw(g){
    rr(g, 70, 136, 260, 380, 30); fillLine(g, '#BFE6FF', 3); rr(g, 82, 146, 236, 8, 4); g.fillStyle = 'rgba(255,255,255,.6)'; g.fill();
    face(g, 200, 182, 1, this.run ? 'focus' : this.items.length ? 'happy' : 'sleepy');
    rr(g, 300, 260, 12, 120, 6); fillLine(g, '#E8F6FF', 2);
    rr(g, 96, 220, 196, 260, 20); g.fillStyle = '#4A6A8A'; g.fill();
    g.save(); rr(g, 96, 220, 196, 260, 20); g.clip();
    this.items.forEach((f, i) => drawFood(g, f, 194 + (this.items.length > 1 ? (i % 2 ? 46 : -46) : 0), 300 + (this.items.length > 2 ? Math.floor(i / 2) * 100 : 50), this.items.length > 1 ? .55 : .8));
    const fr = this.run ? this.p : 0; g.fillStyle = `rgba(235,248,255,${fr * .65})`; g.fillRect(96, 220, 196, 260);
    for (let i = 0; i < 14; i++){ const t = (i * .37 + clock * .1) % 1; g.globalAlpha = fr; g.fillStyle = '#FFFFFF'; star4(g, 110 + (i * 61 % 170), 230 + t * 240, 5, i); g.fill(); } g.globalAlpha = 1;
    g.restore(); rr(g, 96, 220, 196, 260, 20); line(g, 2.5); g.beginPath(); g.moveTo(112, 238); g.lineTo(150, 238); line(g, 4, 'rgba(255,255,255,.5)');
    if (!this.items.length) emptyHint(g, '', '');
  }});
// ---------- plate (serve) ----------
ST.plate = mk({key: 'plate', name: 'Plate', cap: 4,
  live(){ return this.items.length ? detect(compsOf(this.items)) : null; },
  hint(){ if (!this.items.length) return 'Put finished food here, then Serve it'; const d = this.live(); if (d && d.match) return `Looks like <em>${d.match.r.n}</em>! Ready to serve`; if (d && d.near) return `Almost <em>${d.near.r.n}</em>: ${missingText(d.near)}`; return 'A new creation? Serve it and see!'; },
  btn(){ return this.items.length ? {label: 'Serve', enabled: true, ready: !!(this.live() || {}).match} : null; },
  onBtn(){ serve(); }, auto(){ if (this.items.length) serve(); },
  draw(g){
    disc(g, CX + 3, CY + 10, 156, 'rgba(59,35,64,.2)'); disc(g, CX, CY, 156, '#F7F8FF'); ring(g, CX, CY, 156, 3);
    g.beginPath(); g.arc(CX, CY, 140, 0, TAU); line(g, 6, '#7C8AD6'); for (let i = 0; i < 24; i++){ const a = i / 24 * TAU; disc(g, CX + Math.cos(a) * 148, CY + Math.sin(a) * 148, 2, '#7C8AD6'); }
    const n = this.items.length; if (!n){ emptyHint(g, 'Plate', 'Tap finished food on the counter'); return; }
    const d = this.live(), r = d && d.match ? d.match.r : null;
    if (r){ g.save(); g.globalCompositeOperation = 'lighter'; g.globalAlpha = .55 + .15 * Math.sin(clock * 3); g.drawImage(GLOW_WARM, CX - 150, CY - 160, 300, 300); g.restore();
      for (let i = 0; i < 6; i++){ const a = clock * .6 + i * TAU / 6, rr2 = 128 + Math.sin(clock * 2 + i) * 6, sx = CX + Math.cos(a) * rr2, sy = CY - 10 + Math.sin(a) * rr2; g.fillStyle = i % 2 ? '#FFE27A' : '#FFFFFF'; star4(g, sx, sy, 6 + 2 * Math.sin(clock * 5 + i), a); g.fill(); g.lineWidth = 1; g.strokeStyle = 'rgba(59,35,64,.35)'; g.stroke(); } }
    if (r && n > 1){ drawArt(g, recipeSpec(r, this.items), CX, CY - 10, 1.45); }
    else { const pos = n === 1 ? [[0, 0]] : n === 2 ? [[-62, 0], [62, 0]] : [[-60, -50], [60, -50], [-60, 60], [60, 60]]; this.items.forEach((f, i) => drawFood(g, f, CX + pos[i][0], CY - 10 + pos[i][1], n === 1 ? 1.45 : n === 2 ? .9 : .72)); }
  }});
// ---------- bin ----------
ST.bin = mk({key: 'bin', name: 'Bin', cap: 0, fed: -9,
  hint(){ return 'Tap food on the counter to throw it away'; },
  draw(g){ const k = clock - this.fed < .5 ? Math.sin((clock - this.fed) * 20) * .06 : 0;
    g.save(); g.translate(200, 330); g.rotate(k); rr(g, -80, -70, 160, 180, [10, 10, 30, 30]); fillLine(g, '#B7A6F2', 3); for (const x of [-40, 0, 40]){ g.beginPath(); g.moveTo(x, -40); g.lineTo(x * .9, 90); line(g, 3, 'rgba(59,35,64,.3)'); }
    rr(g, -92, -96, 184, 30, 14); fillLine(g, '#9C88E8', 3); rr(g, -24, -112, 48, 20, 8); fillLine(g, '#9C88E8', 3);
    face(g, 0, 10, 1.3, clock - this.fed < 1.2 ? 'happy' : 'idle'); g.restore();
  }});
const STATION_ORDER = ['board', 'bowl', 'blender', 'mat', 'pot', 'pan', 'oven', 'micro', 'freezer', 'plate', 'bin'];
const STATION_LABEL = {board: 'Board', bowl: 'Bowl', blender: 'Blender', mat: 'Mat', pot: 'Pot', pan: 'Pan', oven: 'Oven', micro: 'Micro', freezer: 'Freezer', plate: 'Plate', bin: 'Bin'};
function missingText(e){
  const m = e.missing[0]; if (!m) return '';
  if (!m.tag) return `add some ${ingName(m.ing).toLowerCase()}`;
  const v = VERB[m.tag], grp = e.r.groups.find(g => g.ings.includes(m.ing)), idx = grp ? grp.tags.indexOf(m.tag) : -1;
  const subj = grp && grp.ings.length > 1 ? (idx > 0 ? productName(grp.tags[idx - 1], grp.ings) : listNames(grp.ings)) : ingName(m.ing).toLowerCase();
  return `${v[0].toLowerCase()} the ${subj} ${v[1]}`;
}

// ================= appliance upgrades: one-tap actions, alerts =================
Object.assign(ST.board, {inside: new Set(), queue: 0, qT: 0,
  hint(){ return this.items.length ? 'Tap or saw back and forth to chop, or press Chop all' : 'Chop things here. Tap food on the counter, or grab some from the Fridge.'; },
  down(p){ this.inside = new Set(); this.swiped = new Set(); const i = this.hit(p); if (i >= 0){ this.inside.add(this.items[i].uid); this.chop(i); } },
  move(p){ const i = this.hit(p), id = i >= 0 ? this.items[i].uid : null; for (const u of [...this.inside]) if (u !== id) this.inside.delete(u); if (id != null && !this.inside.has(id)){ this.inside.add(id); this.swiped = new Set(); this.chop(i); } },
  btn(){ const n = this.items.filter(f => f.hist[f.hist.length - 1] !== 'chop').length; return n ? {label: this.queue ? 'Chopping…' : 'Chop all', enabled: !this.queue} : null; },
  onBtn(){ this.queue = 1; this.qT = 0; }, busy(){ return !!this.queue; },
  update(dt){ if (!this.queue) return; this.qT -= dt; if (this.qT > 0) return; this.qT = .15; const i = this.items.findIndex(f => f.hist[f.hist.length - 1] !== 'chop'); if (i < 0){ this.queue = 0; return; } this.swiped = new Set(); this.chop(i); },
});
Object.assign(ST.bowl, {autoT: 0,
  hint(){ return this.items.length ? 'Stir in circles, or press Stir' : 'Mix things here: batters, salads, drinks…'; },
  btn(){ return this.items.length ? {label: this.autoT ? 'Stirring…' : 'Stir', enabled: !this.autoT} : null; },
  onBtn(){ if (this.items.length) this.autoT = 1; }, busy(){ return !!this.autoT; },
  update(dt){ if (!this.autoT) return; if (!this.items.length){ this.autoT = 0; return; } this.m += dt * .8; this.swirl += dt * 9; const now = performance.now(); if (now - this.sndT > 70){ this.sndT = now; SND.swish(.7); } if (this.m >= 1){ this.autoT = 0; this.finish(); } },
});
{ const bf = ST.blender.finish;
  Object.assign(ST.blender, {autoRun: false,
    hint(){ return this.items.length ? (this.hold ? 'Whirrrr…' : 'Press Blend, or hold anywhere to blend') : 'Blend fruit, milk or anything into a drink'; },
    btn(){ return this.items.length ? {label: this.hold ? 'Blending…' : 'Blend', enabled: !this.hold} : null; },
    onBtn(){ if (!this.items.length || this.hold) return; this.autoRun = true; this.down(); },
    up(){ if (!this.hold || this.autoRun) return; this.hold = false; this.snd?.stop(); SND.spinDown(); },
    finish(){ this.autoRun = false; bf.call(this); } }); }
Object.assign(ST.mat, {autoT: 0,
  hint(){ return this.items.length ? 'Push up on the mat to roll it, or press Roll' : 'Roll sushi here: nori, cooked rice and fillings'; },
  btn(){ return this.items.length ? {label: this.autoT ? 'Rolling…' : 'Roll', enabled: !this.autoT} : null; },
  onBtn(){ if (this.items.length) this.autoT = 1; }, busy(){ return !!this.autoT; },
  update(dt){ if (!this.autoT) return; if (!this.items.length){ this.autoT = 0; return; } this.push(dt * 330); if (!this.items.length) this.autoT = 0; },
});
const fmtT = b => { const d = String(b).padStart(3, '0').slice(-3); return `${+d[0]}:${d.slice(1)}`; };
{ const mu = ST.micro.update, ms = ST.micro.start;
  Object.assign(ST.micro, {
    hint(){ if (this.run){ const c = this.ck(); return c < .62 ? 'Warming up… press Stop any time' : c <= 1 ? 'Ready! Press Stop now' : 'Careful, it is starting to burn!'; } return this.items.length ? 'Press Start (0:50 is about right), or type a time on the keypad' : 'Warm drinks, melt things and pop popcorn'; },
    btn(){ if (this.run) return {label: 'Stop', enabled: true, ready: this.ck() >= .62 && this.ck() <= 1}; return this.items.length ? {label: `Start ${fmtT(this.buf || '50')}`, enabled: true, ready: true} : null; },
    onBtn(){ if (this.run) this.finish(); else if (this.items.length){ if (!this.buf) this.buf = '50'; this.start(); } },
    start(){ this.rdy = this.warn = false; ms.call(this); },
    update(dt){ mu.call(this, dt); if (!this.run) return; const c = this.ck();
      if (c >= .62 && !this.rdy){ this.rdy = true; SND.ding(); buzz(20); if (kit.open !== 'micro') toast('The microwave is ready!'); }
      if (c >= 1 && !this.warn){ this.warn = true; SND.beep(); if (kit.open !== 'micro') toast('Quick! The microwave is about to burn it'); } } }); }
for (const k of ['pot', 'pan', 'oven']){ const st = ST[k], ot = st.tick, os = st.start;
  st.start = function(){ this.rdy = false; this.warn = false; os.call(this); };
  st.tick = function(dt){ ot.call(this, dt); if (!this.run) return;
    if (this.cook >= .62 && !this.rdy){ this.rdy = true; if (k !== 'oven') SND.ding(); buzz(20); if (kit.open !== k) toast(`The ${STATION_LABEL[k]} is ready!`); }
    if (this.cook >= 1 && !this.warn){ this.warn = true; SND.beep(); if (kit.open !== k) toast(`Quick! The ${STATION_LABEL[k]} is about to burn`); } }; }
