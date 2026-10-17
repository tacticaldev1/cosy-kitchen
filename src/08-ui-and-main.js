// ================= persistence =================
let found = new Set(), wallet = 3000, pinned = null, wish = null, uiDirty = true;
try { found = new Set(JSON.parse(localStorage.getItem('ck-found') || '[]')); const wv = localStorage.getItem('ck-wallet'); wallet = wv == null || wv === '' || isNaN(+wv) ? 3000 : +wv; const p = localStorage.getItem('ck-pinned'); pinned = p != null && p !== '' && p !== 'null' ? +p : null; } catch (e) {}
function save(){ try { localStorage.setItem('ck-found', JSON.stringify([...found])); localStorage.setItem('ck-wallet', wallet); localStorage.setItem('ck-day', shop.day); localStorage.setItem('ck-pinned', pinned == null ? '' : pinned); } catch (e) {} $('found').textContent = `${found.size}/${RECIPES.length}`; $('coins').textContent = yen(wallet); $('coins').classList.toggle('neg', wallet < 0); }
let toastT = 0;
function toast(msg){ const t = $('toast'); t.textContent = msg; t.classList.add('show'); clearTimeout(toastT); toastT = setTimeout(() => t.classList.remove('show'), 1600); }
function pickWish(){ const pool = RECIPES.filter(r => !found.has(r.id)); const list = pool.length ? pool : RECIPES; wish = list[Math.floor(R() * list.length)].id; }

// ================= backdrops =================
let scale = 1, dpr = 1, KS = 1, bgC, norenC, boardC, counterC, stoveC, lightC;
function layer(){ const c = document.createElement('canvas'); c.width = cv.width; c.height = cv.height; const g = c.getContext('2d'); g.scale(KS, KS); return [c, g]; }
function resize(){
  dpr = Math.min(window.devicePixelRatio || 1, 2);
  const st = $('stage').getBoundingClientRect();
  scale = Math.max(.3, Math.min((st.width - 6) / W, (st.height - 10) / H));
  cv.style.width = W * scale + 'px'; cv.style.height = H * scale + 'px';
  cv.width = Math.round(W * scale * dpr); cv.height = Math.round(H * scale * dpr); KS = scale * dpr; buildBg(); ctx.imageSmoothingQuality = 'high';
}
function woodV(g, y0, y1, a, b){ const gr = g.createLinearGradient(0, y0, 0, y1); gr.addColorStop(0, a); gr.addColorStop(1, b); return gr; }
function softSprite(rgb, n = 64){ const c = document.createElement('canvas'); c.width = c.height = n; const g = c.getContext('2d'), gr = g.createRadialGradient(n / 2, n / 2, 0, n / 2, n / 2, n / 2); gr.addColorStop(0, `rgba(${rgb},1)`); gr.addColorStop(.35, `rgba(${rgb},.55)`); gr.addColorStop(1, `rgba(${rgb},0)`); g.fillStyle = gr; g.fillRect(0, 0, n, n); return c; }
const GLOW_W = softSprite('255,255,255'), GLOW_WARM = softSprite('255,226,170');
const PETAL = (() => { const c = document.createElement('canvas'); c.width = c.height = 48; const g = c.getContext('2d'); g.translate(24, 24);
  g.beginPath(); g.moveTo(0, 19); g.bezierCurveTo(-17, 8, -15, -15, -4, -19); g.lineTo(0, -12); g.lineTo(4, -19); g.bezierCurveTo(15, -15, 17, 8, 0, 19); g.closePath();
  const gr = g.createLinearGradient(0, -19, 0, 19); gr.addColorStop(0, '#FFF0F5'); gr.addColorStop(1, '#FF9DBA'); g.fillStyle = gr; g.fill(); g.strokeStyle = 'rgba(217,82,126,.55)'; g.lineWidth = 1.6; g.stroke();
  g.beginPath(); g.moveTo(0, 14); g.lineTo(0, -6); g.strokeStyle = 'rgba(255,255,255,.7)'; g.lineWidth = 1.4; g.stroke(); return c; })();
const motes = Array.from({length: 12}, () => ({x: R() * W, y: 110 + R() * 440, r: 6 + R() * 14, a: .12 + R() * .2, f: .6 + R(), ph: R() * TAU, vx: (R() - .5) * 4, vy: -2 - R() * 4}));
function buildBg(){
  let g; const rng = rngFor(7);
  [bgC, g] = layer();
  const wg = g.createLinearGradient(0, 0, 0, 100); wg.addColorStop(0, '#D6C0EE'); wg.addColorStop(.55, '#F4D5E6'); wg.addColorStop(1, '#FFE3D0'); g.fillStyle = wg; g.fillRect(0, 0, W, 100);
  g.fillStyle = 'rgba(255,255,255,.4)'; for (let y = 10, r = 0; y < 96; y += 17, r++) for (let x = (r % 2) * 12; x < W + 12; x += 24){ star4(g, x, y, 3.4, .4); g.fill(); }
  const lg = g.createRadialGradient(336, 58, 6, 336, 58, 100); lg.addColorStop(0, 'rgba(255,222,165,.9)'); lg.addColorStop(1, 'rgba(255,222,165,0)'); g.fillStyle = lg; g.fillRect(226, 0, 174, 100);
  // a little shelf of cute things beside the guest
  rr(g, 222, 84, 84, 6, 3); fillLine(g, '#C8935E', 2);
  rr(g, 228, 58, 22, 26, 7); fillLine(g, '#EAF6FF', 2); ['#FF7EA6', '#FFD24A', '#7FD3F7', '#9BE38F', '#C3A6FF'].forEach((c, i) => disc(g, 233 + (i % 3) * 6, 72 + Math.floor(i / 3) * 6, 3, c)); rr(g, 230, 53, 18, 6, 3); fillLine(g, '#FF9EBB', 2);
  rr(g, 256, 62, 18, 22, 4); fillLine(g, '#8CC152', 2); rr(g, 255, 58, 20, 6, 3); fillLine(g, '#5E9A3A', 2); g.fillStyle = '#FFFFFF'; g.font = '800 9px "M PLUS Rounded 1c", sans-serif'; g.textAlign = 'center'; g.fillText('茶', 265, 77);
  rr(g, 285, 48, 12, 24, 6); fillLine(g, '#6BBF59', 2); rr(g, 278, 56, 9, 11, 4.5); fillLine(g, '#6BBF59', 1.6); disc(g, 291, 47, 3.2, '#FF7EA6'); rr(g, 281, 70, 20, 14, [2, 2, 6, 6]); fillLine(g, '#FFB9A6', 2);
  // cabinet wood all around the work area
  g.fillStyle = woodV(g, 100, H, '#EBC290', '#C68C58'); g.fillRect(0, 100, W, H - 100);
  for (let x = 0; x < W; x += 40){ g.fillStyle = 'rgba(120,70,30,.14)'; g.fillRect(x, 104, 2, H); g.fillStyle = 'rgba(255,255,255,.18)'; g.fillRect(x + 2, 104, 1.5, H); }
  for (let i = 0; i < 40; i++){ const x = rng() * W, y = 110 + rng() * 520; g.beginPath(); g.moveTo(x, y); g.quadraticCurveTo(x + 3, y + 20, x, y + 40); line(g, 1, 'rgba(120,70,30,.14)'); }
  g.fillStyle = woodV(g, 90, 106, '#F8D8AA', '#A8703E'); g.fillRect(0, 90, W, 16); g.fillStyle = 'rgba(255,255,255,.7)'; g.fillRect(0, 91.5, W, 1.5);
  g.beginPath(); g.moveTo(0, 90); g.lineTo(W, 90); line(g, 2.5);
  // ---- cutting board
  [boardC, g] = layer();
  g.save(); g.shadowColor = 'rgba(70,30,20,.42)'; g.shadowBlur = 16 * KS; g.shadowOffsetY = 8 * KS; rr(g, 20, 106, 360, 452, 22); g.fillStyle = '#A8703E'; g.fill(); g.restore();
  rr(g, 20, 108, 360, 450, 22); g.fillStyle = woodV(g, 108, 558, '#D29A62', '#9A663A'); g.fill(); line(g, 3);
  rr(g, 20, 102, 360, 446, 22); const top = g.createLinearGradient(20, 102, 380, 548); top.addColorStop(0, '#FFF2D8'); top.addColorStop(.5, '#F8DDB2'); top.addColorStop(1, '#EBC48E'); g.fillStyle = top; g.fill();
  g.save(); g.clip();
  for (let i = 0; i < 27; i++){ const y0 = 106 + i * 17 + rng() * 6; g.beginPath(); g.moveTo(20, y0); for (let x = 20; x <= 380; x += 18) g.lineTo(x, y0 + Math.sin(x / 47 + i * 1.7) * 5 + Math.sin(x / 13 + i) * 1.2); line(g, .8 + rng() * 1.4, `rgba(185,125,65,${.12 + rng() * .14})`); }
  for (const [kx, ky] of [[92, 214], [306, 432]]){ ell(g, kx, ky, 9, 5, 'rgba(160,100,50,.35)'); for (let r = 6; r < 24; r += 4){ g.beginPath(); g.ellipse(kx, ky, r * 1.8, r, 0, 0, TAU); line(g, 1, `rgba(170,110,60,${.32 - r / 85})`); } }
  rr(g, 36, 118, 328, 414, 16); line(g, 5, 'rgba(170,115,65,.22)'); rr(g, 37, 120, 328, 414, 16); line(g, 1.4, 'rgba(255,255,255,.5)');
  const sheen = g.createLinearGradient(20, 102, 200, 340); sheen.addColorStop(0, 'rgba(255,255,255,.38)'); sheen.addColorStop(1, 'rgba(255,255,255,0)'); g.fillStyle = sheen; g.fillRect(20, 102, 360, 446);
  g.restore();
  disc(g, 356, 126, 7, 'rgba(120,70,30,.5)'); ring(g, 356, 126, 7, 2); g.beginPath(); g.arc(356, 126, 7, Math.PI * .1, Math.PI * .9); line(g, 1.5, 'rgba(255,255,255,.7)');
  rr(g, 22, 104, 356, 442, 21); line(g, 2, 'rgba(255,255,255,.65)'); rr(g, 20, 102, 360, 446, 22); line(g, 3);
  // ---- tiled counter
  [counterC, g] = layer();
  g.save(); rr(g, 20, 104, 360, 450, 20); g.clip();
  g.fillStyle = '#A6D4C4'; g.fillRect(20, 104, 360, 360);
  for (let y = 104; y < 464; y += 36) for (let x = 20; x < 380; x += 36){
    const tg = g.createLinearGradient(x, y, x + 36, y + 36); tg.addColorStop(0, '#F6FFFC'); tg.addColorStop(.55, '#DDF3EA'); tg.addColorStop(1, '#C0E4D6');
    rr(g, x + 1.5, y + 1.5, 33, 33, 5); g.fillStyle = tg; g.fill(); g.fillStyle = 'rgba(255,255,255,.8)'; rr(g, x + 5, y + 5, 10, 3, 1.5); g.fill(); }
  g.save(); g.globalAlpha = .22; g.fillStyle = '#FFFFFF'; g.beginPath(); g.moveTo(60, 104); g.lineTo(130, 104); g.lineTo(20, 300); g.lineTo(20, 210); g.closePath(); g.fill(); g.beginPath(); g.moveTo(150, 104); g.lineTo(168, 104); g.lineTo(40, 340); g.lineTo(28, 340); g.closePath(); g.fill(); g.restore();
  const sun = g.createRadialGradient(300, 170, 10, 300, 170, 220); sun.addColorStop(0, 'rgba(255,236,200,.42)'); sun.addColorStop(1, 'rgba(255,236,200,0)'); g.fillStyle = sun; g.fillRect(20, 104, 360, 360);
  g.fillStyle = woodV(g, 464, 554, '#FFF3DE', '#E8C592'); g.fillRect(20, 464, 360, 90);
  for (let x = 20, i = 0; x < 380; x += 30, i++){ g.fillStyle = `rgba(190,130,70,${.06 + (i % 3) * .045})`; g.fillRect(x, 468, 30, 86); g.fillStyle = 'rgba(160,100,50,.25)'; g.fillRect(x, 468, 1.2, 86); }
  g.fillStyle = woodV(g, 464, 482, 'rgba(70,40,50,.28)', 'rgba(70,40,50,0)'); g.fillRect(20, 467, 360, 16);
  g.fillStyle = 'rgba(255,255,255,.8)'; g.fillRect(20, 464, 360, 3);
  g.beginPath(); g.moveTo(20, 464); g.lineTo(380, 464); line(g, 2.5);
  g.restore(); rr(g, 20, 104, 360, 450, 20); line(g, 3);
  // ---- stove
  [stoveC, g] = layer(); g.drawImage(counterC, 0, 0, W, H);
  g.save(); g.shadowColor = 'rgba(30,20,40,.45)'; g.shadowBlur = 14 * KS; g.shadowOffsetY = 6 * KS; rr(g, 46, 150, 308, 380, 26); g.fillStyle = '#4B4560'; g.fill(); g.restore();
  rr(g, 46, 150, 308, 380, 26); g.fillStyle = woodV(g, 150, 530, '#736A96', '#3C3656'); g.fill(); line(g, 3);
  rr(g, 54, 158, 292, 300, 20); const gl = g.createLinearGradient(54, 158, 346, 458); gl.addColorStop(0, '#2B273E'); gl.addColorStop(1, '#46405F'); g.fillStyle = gl; g.fill(); line(g, 2, 'rgba(0,0,0,.35)');
  g.save(); rr(g, 54, 158, 292, 300, 20); g.clip(); g.globalAlpha = .13; g.fillStyle = '#FFFFFF'; g.beginPath(); g.moveTo(80, 158); g.lineTo(150, 158); g.lineTo(54, 330); g.lineTo(54, 230); g.closePath(); g.fill(); g.restore();
  for (const k of [1, .72]){ g.beginPath(); g.arc(190, 310, 108 * k, 0, TAU); line(g, 1.6, 'rgba(255,140,120,.2)'); }
  rr(g, 54, 466, 292, 56, 14); fillLine(g, '#5A5378', 2);
  for (let i = 0; i < 4; i++){ const x = 100 + i * 66, y = 494, kg = g.createRadialGradient(x - 5, y - 6, 1, x, y, 16); kg.addColorStop(0, '#FFFFFF'); kg.addColorStop(1, '#D3CBE8');
    ell(g, x, y + 3, 15, 15, 'rgba(0,0,0,.28)'); g.beginPath(); g.arc(x, y, 15, 0, TAU); g.fillStyle = kg; g.fill(); line(g, 2.5); g.beginPath(); g.moveTo(x, y); g.lineTo(x, y - 11); line(g, 3.5, '#FF7EA6'); disc(g, x + 23, y - 12, 2.6, i === 1 ? '#FF6A6A' : '#8FF0C8'); }
  // ---- noren curtain
  [norenC, g] = layer();
  for (const [x, w] of [[0, 98], [101, 98], [202, 96], [362, 38]]){
    g.beginPath(); g.moveTo(x, -10); g.lineTo(x + w, -10); g.lineTo(x + w, 52); for (let k = 0; k < 4; k++) g.quadraticCurveTo(x + w - (k + .5) * w / 4, 59, x + w - (k + 1) * w / 4, 52); g.closePath();
    g.save(); g.shadowColor = 'rgba(30,20,60,.4)'; g.shadowBlur = 7 * KS; g.shadowOffsetY = 3 * KS; const ng = g.createLinearGradient(x, 0, x + w, 0); ng.addColorStop(0, '#2C356C'); ng.addColorStop(.5, '#4655A0'); ng.addColorStop(1, '#2C356C'); g.fillStyle = ng; g.fill(); g.restore();
    g.save(); g.clip();
    for (let f = 1; f < 4; f++){ const fx = x + f * w / 4, fg = g.createLinearGradient(fx - 9, 0, fx + 9, 0); fg.addColorStop(0, 'rgba(255,255,255,0)'); fg.addColorStop(.5, 'rgba(255,255,255,.14)'); fg.addColorStop(1, 'rgba(0,0,30,.16)'); g.fillStyle = fg; g.fillRect(fx - 9, -10, 18, 72); }
    g.strokeStyle = 'rgba(255,255,255,.5)'; g.lineWidth = 1.6; for (let cx = x + 8; cx < x + w + 12; cx += 18) for (const r of [9, 6, 3]){ g.beginPath(); g.arc(cx, 55, r, Math.PI, TAU); g.stroke(); }
    g.fillStyle = woodV(g, -4, 22, 'rgba(0,0,20,.4)', 'rgba(0,0,20,0)'); g.fillRect(x, -10, w, 32);
    g.restore(); line(g, 3);
  }
  g.font = '22px "Mochiy Pop One", sans-serif'; g.textAlign = 'center'; g.lineJoin = 'round';
  for (const [t, x] of [['寿', 150], ['司', 250]]){ g.lineWidth = 5; g.strokeStyle = '#26305E'; g.strokeText(t, x, 38); g.fillStyle = '#FFF8EE'; g.fillText(t, x, 38); }
  rr(g, -4, -4, W + 8, 11, 5); g.fillStyle = woodV(g, -4, 7, '#B07A48', '#6A3E20'); g.fill(); line(g, 2);
  // ---- light & vignette overlay
  [lightC, g] = layer();
  const warm = g.createRadialGradient(40, 110, 20, 40, 110, 470); warm.addColorStop(0, 'rgba(255,226,180,.22)'); warm.addColorStop(1, 'rgba(255,226,180,0)'); g.fillStyle = warm; g.fillRect(0, 0, W, H);
  g.save(); g.globalAlpha = .07; g.fillStyle = '#FFF4DC'; for (const [a, b] of [[60, 150], [190, 250]]){ g.beginPath(); g.moveTo(a, 96); g.lineTo(b, 96); g.lineTo(b + 220, 560); g.lineTo(a + 160, 560); g.closePath(); g.fill(); } g.restore();
  const vig = g.createRadialGradient(200, 330, 230, 200, 330, 480); vig.addColorStop(0, 'rgba(50,20,60,0)'); vig.addColorStop(1, 'rgba(50,20,60,.3)'); g.fillStyle = vig; g.fillRect(0, 0, W, H);
}
// ================= toolbar =================
function toolIcon(g, key){
  g.save(); g.lineJoin = 'round'; g.lineCap = 'round';
  const L = (w = 1.6) => line(g, w);
  switch (key){
    case 'fridge': rr(g, 7, 2, 16, 26, 4); fillLine(g, '#BFE6FF', 1.6); g.beginPath(); g.moveTo(7, 12); g.lineTo(23, 12); L(); g.beginPath(); g.moveTo(10, 6); g.lineTo(10, 9); g.moveTo(10, 15); g.lineTo(10, 20); L(1.8); break;
    case 'board': rr(g, 3, 9, 22, 15, 4); fillLine(g, '#F6E2C0'); disc(g, 21, 13, 1.6, PLUM); g.save(); g.translate(17, 4); g.rotate(.6); rr(g, 0, 0, 4, 14, 1); fillLine(g, '#E9EEF8', 1.2); g.restore(); break;
    case 'bowl': g.beginPath(); g.ellipse(15, 14, 12, 11, 0, 0, Math.PI); g.closePath(); fillLine(g, '#A9C8FF'); ell(g, 15, 14, 12, 3.5, '#E8F0FF', 1.6); break;
    case 'blender': g.beginPath(); g.moveTo(8, 5); g.lineTo(22, 5); g.lineTo(20, 19); g.lineTo(10, 19); g.closePath(); fillLine(g, '#FFC0D6'); rr(g, 8, 19, 14, 8, 3); fillLine(g, '#C8B6FF'); break;
    case 'mat': for (let i = 0; i < 5; i++){ rr(g, 4, 5 + i * 4.4, 22, 3.6, 1.5); fillLine(g, i % 2 ? '#DDB874' : '#D3AB63', 1); } break;
    case 'pot': rr(g, 5, 10, 20, 15, [2, 2, 6, 6]); fillLine(g, '#C5CCE6'); ell(g, 15, 10, 11, 3.5, '#BFE3F2', 1.6); rr(g, 1, 12, 5, 3, 1.5); fillLine(g, '#8E96B8', 1.2); rr(g, 24, 12, 5, 3, 1.5); fillLine(g, '#8E96B8', 1.2); break;
    case 'pan': disc(g, 12, 16, 9, '#3E3E54'); ring(g, 12, 16, 9, 1.6); rr(g, 20, 14, 9, 4, 2); fillLine(g, '#A8734A', 1.4); ell(g, 12, 16, 4, 3.4, '#FFFFFF'); disc(g, 12, 16, 1.8, '#FFC93C'); break;
    case 'oven': rr(g, 4, 3, 22, 24, 4); fillLine(g, '#FFB9A6'); rr(g, 8, 11, 14, 11, 2); fillLine(g, '#5A3A2E', 1.4); disc(g, 21, 7, 1.6, PLUM); break;
    case 'micro': rr(g, 2, 7, 26, 18, 4); fillLine(g, '#A8E6CF'); rr(g, 5, 10, 14, 12, 2); fillLine(g, '#3A4A50', 1.4); for (let i = 0; i < 3; i++) disc(g, 23, 12 + i * 3.5, 1.2, PLUM); break;
    case 'freezer': rr(g, 7, 2, 16, 26, 4); fillLine(g, '#E0F4FF'); g.fillStyle = '#7FD3F7'; star4(g, 15, 15, 6); g.fill(); break;
    case 'plate': ell(g, 15, 17, 13, 9, '#F7F8FF', 1.6); g.beginPath(); g.ellipse(15, 17, 9, 6, 0, 0, TAU); L(1.4); break;
    case 'bin': rr(g, 8, 9, 14, 17, [1, 1, 4, 4]); fillLine(g, '#B7A6F2'); rr(g, 6, 5, 18, 4, 2); fillLine(g, '#9C88E8', 1.4); break;
  }
  g.restore();
}
const TOOL_BTNS = {};
function buildToolbar(){
  const bar = $('tools'); bar.innerHTML = '';
  ['fridge', ...STATION_ORDER].forEach(key => {
    const b = document.createElement('button'); b.className = 'tool' + (key === 'fridge' ? ' fridge' : ''); b.type = 'button';
    b.setAttribute('aria-pressed', key === kit.open ? 'true' : 'false'); b.setAttribute('aria-label', key === 'fridge' ? 'Open fridge' : STATION_LABEL[key]);
    const c = document.createElement('canvas'); c.width = 60; c.height = 60; const g = c.getContext('2d'); g.scale(2, 2); toolIcon(g, key); b.appendChild(c);
    const s = document.createElement('span'); s.textContent = key === 'fridge' ? 'Fridge' : STATION_LABEL[key]; b.appendChild(s);
    const n = document.createElement('i'); n.className = 'n'; n.hidden = true; b.appendChild(n);
    b.onclick = () => { initAudio(); key === 'fridge' ? openFridge() : openStation(key); };
    TOOL_BTNS[key] = {b, n}; bar.appendChild(b);
  });
}
function openStation(key){
  if (ST[kit.open].busy() && key !== kit.open) toast(`The ${STATION_LABEL[kit.open]} keeps going in the background`);
  kit.open = key; SND.pop(STATION_ORDER.indexOf(key) % 6);
  for (const k of STATION_ORDER) TOOL_BTNS[k].b.setAttribute('aria-pressed', k === key ? 'true' : 'false');
  uiCache = {}; cv.focus({preventScroll: true});
}

// ================= fridge =================
let fridgeCat = 'fruit';
const iconCache = new Map();
function iconCanvas(key, px){ const c = document.createElement('canvas'); c.width = px; c.height = px; const g = c.getContext('2d'); drawIng(g, key, px / 2, px / 2 + px * .04, px * .4); return c; }
function buildFridge(){
  const cats = $('fcats'); cats.innerHTML = '';
  CATS.forEach(([k, n]) => { const b = document.createElement('button'); b.className = 'chip'; b.type = 'button'; b.textContent = n; b.setAttribute('aria-pressed', k === fridgeCat); b.onclick = () => { fridgeCat = k; buildFridge(); }; cats.appendChild(b); });
  const grid = $('fgrid'); grid.innerHTML = '';
  Object.values(ING).filter(i => i.cat === fridgeCat).forEach(it => {
    const b = document.createElement('button'); b.className = 'ingb'; b.type = 'button'; b.appendChild(iconCanvas(it.key, 80)); const s = document.createElement('span'); s.textContent = it.n; b.appendChild(s); const pr = document.createElement('small'); pr.textContent = yen(ING_COST[it.key] || 0); b.appendChild(pr);
    b.onclick = () => addIngredient(it.key); grid.appendChild(b);
  });
  $('fridgeSub').textContent = fridgeTarget();
}
function fridgeTarget(){ const st = ST[kit.open]; return kit.open !== 'bin' && !st.busy() && st.items.length < st.cap ? `Tap to add to the ${STATION_LABEL[kit.open]}` : 'Tap to put it on the counter'; }
function openFridge(){ buildFridge(); $('fridge').hidden = false; SND.clunk(); }
$('fridgeX').onclick = () => { $('fridge').hidden = true; };
$('fridge').addEventListener('click', e => { if (e.target.id === 'fridge') $('fridge').hidden = true; });
function addIngredient(key){
  initAudio(); const f = newFood(key), st = ST[kit.open];
  if (kit.open !== 'bin' && !st.busy() && st.items.length < st.cap){ st.items.push(f); toast(`${ING[key].n} ${yen(ING_COST[key] || 0)} → ${STATION_LABEL[kit.open]}`); SND.plunk(); }
  else if (kit.counter.length < CAP_COUNTER){ kit.counter.push(f); f.arrive = clock; toast(`${ING[key].n} ${yen(ING_COST[key] || 0)} → counter`); SND.pop(2); }
  else { toast('No room! Clear the counter first'); return; }
  chargeIng(key); buzz(5); $('fridgeSub').textContent = fridgeTarget();
}

// ================= counter =================
const slotX = i => 12 + (W - 24) * (i + .5) / CAP_COUNTER;
function drawCounter(g){
  rr(g, 22, 551, 76, 18, [9, 9, 0, 0]); fillLine(g, '#FFE3EC', 2); g.fillStyle = PLUM; g.font = '800 9px "M PLUS Rounded 1c", sans-serif'; g.textAlign = 'center'; g.fillText('COUNTER', 60, 564);
  g.save(); g.shadowColor = 'rgba(59,35,64,.32)'; g.shadowBlur = 8 * KS; g.shadowOffsetY = 3 * KS; rr(g, 12, 566, W - 24, 66, 16); g.fillStyle = '#FFF6EA'; g.fill(); g.restore();
  rr(g, 12, 566, W - 24, 66, 16); g.fillStyle = woodV(g, 566, 632, '#FFFDF6', '#F3DDC2'); g.fill(); line(g);
  g.beginPath(); g.moveTo(28, 569.5); g.lineTo(W - 28, 569.5); line(g, 2, 'rgba(255,255,255,.95)');
  for (let i = 0; i < CAP_COUNTER; i++){
    const x = slotX(i), f = kit.counter[i];
    if (!f){ g.setLineDash([3, 4]); ring(g, x, 597, 18, 1.5, 'rgba(59,35,64,.22)'); g.setLineDash([]); continue; }
    const k = f.arrive ? easeBack((clock - f.arrive) / .35) : 1, hit = f.recipe != null;
    ell(g, x + 1, 603, 22, 9, 'rgba(59,35,64,.16)');
    const pg = g.createRadialGradient(x - 7, 590, 1, x, 597, 22); pg.addColorStop(0, '#FFFFFF'); pg.addColorStop(1, hit ? '#FFD3E2' : '#E2E6F8');
    g.beginPath(); g.arc(x, 597, 21, 0, TAU); g.fillStyle = pg; g.fill(); line(g, 1.8, hit ? '#D9527E' : 'rgba(59,35,64,.42)');
    g.beginPath(); g.arc(x, 597, 16, 0, TAU); line(g, 1, hit ? 'rgba(217,82,126,.35)' : 'rgba(124,138,214,.4)');
    drawFood(g, f, x, 600, .27 * k);
    if (f.q === 'burnt') disc(g, x + 15, 580, 5, '#5A4A50');
    else if (f.q === 'perfect' || hit){ g.save(); g.globalCompositeOperation = 'lighter'; g.globalAlpha = .6; g.drawImage(GLOW_WARM, x + 5, 570, 20, 20); g.restore(); g.fillStyle = '#FFD24A'; star4(g, x + 15, 580, 6, clock); g.fill(); g.lineWidth = 1; g.strokeStyle = 'rgba(59,35,64,.5)'; g.stroke(); }
  }
}
function counterTap(i){
  const f = kit.counter[i]; if (!f) return;
  if (kit.open === 'bin'){ kit.counter.splice(i, 1); SND.trash(); puff(200, 330); ST.bin.fed = clock; buzz(10); return; }
  const st = ST[kit.open];
  if (st.busy()){ toast(`The ${STATION_LABEL[kit.open]} is busy`); return; }
  if (st.items.length >= st.cap){ toast(`The ${STATION_LABEL[kit.open]} is full`); return; }
  kit.counter.splice(i, 1); st.items.push(f); SND.plunk(); buzz(5); f.flyUntil = clock + .35; flyers.push({f, x0: slotX(i), y0: 597, s0: .27, x1: 200, y1: 330, s1: .9, t: clock, dur: .35}); setTimeout(() => burst(200, 330, 4, ['#FFFFFF']), 340);
}
function emptyStation(){ const st = ST[kit.open]; if (st.busy()) return; while (st.items.length && kit.counter.length < CAP_COUNTER){ const f = st.items.shift(); f.arrive = clock; kit.counter.push(f); } if (st.items.length) toast('The counter is full'); st.p = 0; st.m = 0; SND.pop(1); }

// ================= guest, ticket =================
const GUESTS = [['#4B2E5A', '#8B7BC9', '#FFE2D2'], ['#E8A04A', '#7FD3B8', '#FFE6D6'], ['#6A4AC8', '#FF9EBB', '#FFE2D2'], ['#3A2A2A', '#FFD24A', '#F2CDB0'], ['#F2B8C8', '#A9C8FF', '#FFEADF']];
let guestI = 0, guestMood = null, guestMoodT = 0;
function drawGuest(g){
  const [hair, shirt, skin] = GUESTS[guestI % GUESTS.length], x = 336, y = 66, mood = clock < guestMoodT ? guestMood : kit.eating ? 'focus' : 'idle';
  g.save(); g.translate(0, Math.sin(clock * 1.6) * 1.2);
  g.beginPath(); g.moveTo(x - 32, y + 64); g.quadraticCurveTo(x - 32, y + 26, x, y + 24); g.quadraticCurveTo(x + 32, y + 26, x + 32, y + 64); g.closePath(); fillLine(g, shirt);
  g.beginPath(); g.moveTo(x - 12, y + 25); g.lineTo(x, y + 36); g.lineTo(x + 12, y + 25); g.closePath(); fillLine(g, '#FFFFFF', 2); disc(g, x, y + 40, 3, '#FF7EA6');
  g.beginPath(); g.ellipse(x, y + 4, 30, 31, 0, 0, TAU); fillLine(g, hair);
  if (guestI % 2){ for (const k of [-1, 1]){ g.beginPath(); g.arc(x + k * 24, y - 18, 9, 0, TAU); fillLine(g, hair, 2.2); } }
  ell(g, x, y + 7, 24, 23, skin, 2.5);
  g.beginPath(); g.moveTo(x - 29, y + 10); g.quadraticCurveTo(x - 30, y - 26, x, y - 25); g.quadraticCurveTo(x + 30, y - 26, x + 29, y + 10);
  for (const [dx, dy] of [[21, -2], [15, 4], [8, -6], [0, 2], [-7, -6], [-15, 4], [-21, -2]]) g.lineTo(x + dx, y + dy);
  g.closePath(); fillLine(g, hair);
  g.beginPath(); g.arc(x - 4, y - 4, 19, Math.PI * 1.12, Math.PI * 1.42); line(g, 4, 'rgba(255,255,255,.55)'); g.beginPath(); g.arc(x - 4, y - 4, 19, Math.PI * 1.5, Math.PI * 1.58); line(g, 4, 'rgba(255,255,255,.55)');
  face(g, x, y + 10, .82, mood === 'focus' ? 'happy' : mood || 'idle');
  if (mood === 'happy' || mood === 'wow') for (let i = 0; i < 2; i++){ const t = (clock * .7 + i * .5) % 1; g.globalAlpha = 1 - t; const hx = x - 34 + i * 68, hy = y - 2 - t * 30; g.beginPath(); g.moveTo(hx, hy + 5); g.bezierCurveTo(hx - 9, hy - 3, hx - 4, hy - 9, hx, hy - 3); g.bezierCurveTo(hx + 4, hy - 9, hx + 9, hy - 3, hx, hy + 5); fillLine(g, '#FF7EA6', 1.4); } g.globalAlpha = 1;
  if (mood === 'yuck'){ g.beginPath(); g.moveTo(x + 22, y - 6); g.quadraticCurveTo(x + 27, y + 2, x + 22, y + 4); g.quadraticCurveTo(x + 17, y + 2, x + 22, y - 6); fillLine(g, '#9FD3F5', 1.5); }
  g.restore();
}
function wrapText(g, text, x, y, maxW, lh, maxLines){
  const words = text.split(' '); let ln = '', n = 0;
  for (let i = 0; i < words.length; i++){ const t = ln ? ln + ' ' + words[i] : words[i]; if (g.measureText(t).width > maxW && ln){ if (n === maxLines - 1){ g.fillText(ln + '…', x, y + n * lh); return; } g.fillText(ln, x, y + n * lh); n++; ln = words[i]; } else ln = t; }
  g.fillText(ln, x, y + n * lh);
}
let guideCache = {t: -1, cur: 0, done: []};
function stepDone(st){
  const comps = compsOf(allFoods()), ck = st.check;
  if (ck.type === 'have') return ck.ings.every(k => comps.some(c => c.ing === k));
  if (ck.type === 'tag') return ck.ings.every(k => comps.some(c => c.ing === k && tagOk(c, ck.tag)));
  const pc = compsOf(ST.plate.items); return ck.ings.every(k => pc.some(c => c.ing === k));
}
function guide(){
  if (pinned == null) return null;
  if (clock - guideCache.t > .3 || guideCache.id !== pinned){ const steps = buildSteps(RECIPES[pinned]); const done = steps.map(stepDone); let cur = done.findIndex(d => !d); if (cur < 0) cur = steps.length - 1; guideCache = {t: clock, id: pinned, steps, done, cur}; }
  return guideCache;
}
function drawTicket(g){
  g.save(); g.translate(14, 10); g.rotate(-.02);
  rr(g, 3, 4, 200, 80, 6); g.fillStyle = 'rgba(59,35,64,.2)'; g.fill(); rr(g, 0, 0, 200, 80, 6); fillLine(g, '#FFFDF6');
  rr(g, 80, -8, 40, 14, 3); g.fillStyle = 'rgba(255,126,166,.75)'; g.fill();
  g.textAlign = 'left'; const gd = guide();
  if (gd){ const r = RECIPES[pinned];
    g.fillStyle = '#9C7FA3'; g.font = '800 9px "M PLUS Rounded 1c", sans-serif'; g.fillText(`GUIDE · STEP ${gd.cur + 1} OF ${gd.steps.length}`, 10, 17);
    g.fillStyle = PLUM; g.font = '13px "Mochiy Pop One", sans-serif'; wrapText(g, r.n, 10, 34, 182, 14, 1);
    g.font = '700 10.5px "M PLUS Rounded 1c", sans-serif'; g.fillStyle = PLUM; wrapText(g, gd.steps[gd.cur].text, 10, 52, 182, 13, 2);
    for (let i = 0; i < gd.steps.length; i++) disc(g, 192 - (gd.steps.length - 1 - i) * 7, 13, 2.6, gd.done[i] ? '#2E8A68' : 'rgba(59,35,64,.25)');
  } else if (wish != null){ const r = RECIPES[wish];
    g.fillStyle = '#9C7FA3'; g.font = '800 9px "M PLUS Rounded 1c", sans-serif'; g.fillText("TODAY'S CRAVING", 10, 17);
    g.fillStyle = PLUM; g.font = '14px "Mochiy Pop One", sans-serif'; wrapText(g, r.n, 10, 37, 182, 15, 1);
    g.font = '700 10.5px "M PLUS Rounded 1c", sans-serif'; g.fillStyle = '#7D6283'; wrapText(g, 'Serve it for a bonus tip. Tap here for the recipe.', 10, 56, 182, 13, 2);
  }
  g.restore();
}

// ================= serving =================
function serve(){
  const foods = ST.plate.items.slice(); if (!foods.length) return;
  const comps = compsOf(foods), d = detect(comps), q = foods.reduce((a, f) => worstQ(a, f.q), null);
  const cust = d && d.match ? orderFor(d.match.r.id) : null;
  ST.plate.items = []; kit.eating = {t: clock, foods, tx: cust ? cust.x : 200, ty: cust ? 74 : 40}; SND.nom(); setTimeout(() => SND.nom(), 700);
  setTimeout(() => { if (kit.eating && kit.eating.foods === foods) kit.eating = null; }, 1200);
  if (cust){ serveOrder(cust, foods, d, q); return; }
  const res = {foods, q, near: d && d.near};
  if (d && d.match){ const r = d.match.r; res.r = r; res.isNew = !found.has(r.id); res.stars = q === 'burnt' ? 1 : q === 'under' ? 2 : 3; res.extras = d.match.extras; found.add(r.id); if (pinned === r.id && !activeCust()) pinned = null; }
  else { res.stars = q === 'burnt' ? 1 : 2; res.name = inventName(foods); }
  save(); setTimeout(() => showResult(res), 1300);
}
function showResult(res){
  kit.eating = null;
  const card = $('resultCard'), r = res.r;
  const note = res.q === 'burnt' ? 'A little bit burnt!' : res.q === 'under' ? 'A tiny bit undercooked.' : res.q === 'perfect' ? 'Cooked perfectly.' : '';
  card.innerHTML = '';
  const add = (tag, cls, html) => { const e = document.createElement(tag); if (cls) e.className = cls; if (html != null) e.innerHTML = html; card.appendChild(e); return e; };
  add('div', 'jp', r ? (res.stars === 3 ? 'おいしい！' : 'もぐもぐ') : 'ふしぎ？');
  const c = document.createElement('canvas'); c.width = 300; c.height = 300; card.appendChild(c);
  const g = c.getContext('2d'); g.fillStyle = '#FFF4EC'; rr(g, 0, 0, 300, 300, 30); g.fill();
  const sp = r ? recipeSpec(r, res.foods) : (res.foods.length === 1 ? foodSpec(res.foods[0]) : genericSpec(compsOf(res.foods), [...new Set(res.foods.flatMap(f => f.hist))], {q: res.q}));
  drawArt(g, sp, 150, 160, 1.7);
  add('h2', '', r ? `You made ${r.n}!` : res.name);
  add('div', 'stars', '★'.repeat(res.stars) + '<span style="color:#E3D3C0">' + '★'.repeat(3 - res.stars) + '</span>');
  if (r && res.isNew) add('span', 'newb', 'New recipe stamped in your book!');
  add('p', '', [note, r ? '' : 'Your very own invention.', res.near ? `So close to <b>${res.near.r.n}</b>: try to ${missingText(res.near)}.` : '', r && res.extras && res.extras.length ? `With a twist of ${listNames(res.extras)}.` : ''].filter(Boolean).join(' '));
  add('p', '', res.paid ? `${res.cust} paid ${yen(res.paid)}. Thank you!` : r ? `Staff meal. On the menu for ${yen(r.price)}.` : 'Staff meal: a one-of-a-kind dish.');
  const row = add('div', 'drow'); row.style.justifyContent = 'center';
  const b1 = document.createElement('button'); b1.className = 'btn'; b1.textContent = 'Keep cooking'; b1.onclick = closeResult; row.appendChild(b1);
  if (r || res.near){ const b2 = document.createElement('button'); b2.className = 'btn ghost'; b2.textContent = 'See recipe'; b2.onclick = () => { closeResult(); openBook((r || res.near.r).id); }; row.appendChild(b2); }
  $('result').hidden = false; if (r){ res.isNew ? SND.stamp() : SND.chime(); } else SND.yay();
  setTimeout(() => b1.focus(), 30);
}
function closeResult(){ $('result').hidden = true; cv.focus({preventScroll: true}); }

// ================= recipe book =================
const book = {cat: 'all', tools: new Set(), stat: 'all', q: ''};
const TOOL_NAMES = {board: 'Knife', bowl: 'Bowl', blender: 'Blender', mat: 'Bamboo mat', pot: 'Pot', pan: 'Pan', oven: 'Oven', micro: 'Microwave', freezer: 'Freezer'};
const thumbCache = new Map();
function thumb(r){ let c = thumbCache.get(r.id); if (!c){ c = document.createElement('canvas'); c.width = c.height = 208; const g = c.getContext('2d'); g.fillStyle = '#FFF4EC'; g.fillRect(0, 0, 208, 208); drawArt(g, recipeSpec(r), 104, 112, 1.22); thumbCache.set(r.id, c); } return c; }
function chip(label, pressed, onclick){ const b = document.createElement('button'); b.type = 'button'; b.className = 'chip'; b.textContent = label; b.setAttribute('aria-pressed', pressed ? 'true' : 'false'); b.onclick = onclick; return b; }
function buildBookFilters(){
  const fc = $('fcat'); fc.innerHTML = ''; fc.appendChild(chip('All', book.cat === 'all', () => { book.cat = 'all'; buildBookFilters(); renderBook(); }));
  RCATS.forEach(([k, n]) => fc.appendChild(chip(n, book.cat === k, () => { book.cat = book.cat === k ? 'all' : k; buildBookFilters(); renderBook(); })));
  const ft = $('ftool'); ft.innerHTML = ''; Object.entries(TOOL_NAMES).forEach(([k, n]) => ft.appendChild(chip(n, book.tools.has(k), () => { book.tools.has(k) ? book.tools.delete(k) : book.tools.add(k); buildBookFilters(); renderBook(); })));
  const fs = $('fstat'); fs.innerHTML = ''; [['all', 'Every recipe'], ['found', 'Made it'], ['new', 'Not yet']].forEach(([k, n]) => fs.appendChild(chip(n, book.stat === k, () => { book.stat = k; buildBookFilters(); renderBook(); })));
}
function renderBook(){
  const words = book.q.toLowerCase().split(/\s+/).filter(Boolean);
  const list = RECIPES.filter(r => (book.cat === 'all' || r.cat === book.cat) && [...book.tools].every(t => r.tools.includes(t) || (t === 'pot' && r.tools.includes('micro') && r.groups.some(g => g.tags.includes('hot')))) && (book.stat === 'all' || (book.stat === 'found') === found.has(r.id)) && words.every(w => r.search.includes(w)));
  $('count').textContent = list.length ? `Showing ${list.length} recipe${list.length === 1 ? '' : 's'}` : '';
  const grid = $('rgrid'); grid.innerHTML = '';
  if (!list.length){ const e = document.createElement('div'); e.className = 'empty'; e.textContent = 'No recipes match. Try fewer filters or another word.'; grid.appendChild(e); return; }
  for (const r of list){
    const b = document.createElement('button'); b.type = 'button'; b.className = 'rc' + (found.has(r.id) ? '' : ' locked');
    const c = document.createElement('canvas'); c.width = c.height = 104; c.getContext('2d').drawImage(thumb(r), 0, 0, 104, 104); b.appendChild(c);
    const t = document.createElement('div'); t.style.minWidth = '0'; t.innerHTML = `<b></b><small></small>`; t.querySelector('b').textContent = r.n; t.querySelector('small').textContent = yen(r.price) + ' · ' + r.tools.map(k => TOOL_NAMES[k]).join(' · '); b.appendChild(t);
    if (found.has(r.id)){ const s = document.createElement('span'); s.className = 'stamp'; s.textContent = 'Made'; b.appendChild(s); }
    b.onclick = () => openDetail(r.id); grid.appendChild(b);
  }
}
function openBook(id){
  initAudio(); $('book').hidden = false; $('bookSub').textContent = `${found.size} of ${RECIPES.length} discovered`; buildBookFilters();
  if (id != null) openDetail(id); else { $('bookDetail').hidden = true; $('bookList').style.display = 'flex'; renderBook(); }
  SND.fwip();
}
function openDetail(id){
  const r = RECIPES[id], el = $('bookDetail'); $('bookList').style.display = 'none'; el.hidden = false; el.innerHTML = '';
  const back = chip('‹ All recipes', false, () => { el.hidden = true; $('bookList').style.display = 'flex'; renderBook(); }); back.style.margin = '0 0 10px'; el.appendChild(back);
  const head = document.createElement('div'); head.className = 'dhead';
  const c = document.createElement('canvas'); c.width = c.height = 220; c.getContext('2d').drawImage(thumb(r), 0, 0, 220, 220); head.appendChild(c);
  const info = document.createElement('div'); info.style.minWidth = '0';
  const h3 = document.createElement('h3'); h3.textContent = r.n; info.appendChild(h3);
  const p = document.createElement('p'); p.textContent = r.desc; info.appendChild(p); const pp = document.createElement('p'); pp.className = 'price'; pp.textContent = `Menu price ${yen(r.price)} · ingredients ${yen(r.cost)}`; info.appendChild(pp);
  const tags = document.createElement('div'); tags.className = 'tags';
  [RCATS.find(x => x[0] === r.cat)[1], ...r.tools.map(k => TOOL_NAMES[k]), found.has(r.id) ? 'Made it' : 'Not made yet'].forEach(t => { const s = document.createElement('span'); s.className = 'tag'; s.textContent = t; tags.appendChild(s); });
  info.appendChild(tags); head.appendChild(info); el.appendChild(head);
  const sec = (title) => { const d = document.createElement('div'); d.className = 'dsec'; const h = document.createElement('h4'); h.textContent = title; d.appendChild(h); el.appendChild(d); return d; };
  const ingS = sec('Ingredients'), ings = document.createElement('div'); ings.className = 'ings';
  r.need.forEach(k => ings.appendChild(ingChip(k, false))); r.opt.forEach(k => ings.appendChild(ingChip(k, true))); ingS.appendChild(ings);
  const stS = sec('How to make it'), ol = document.createElement('ol'); ol.className = 'steps';
  const steps = buildSteps(r), done = pinned === id ? steps.map(stepDone) : [];
  steps.forEach((s, i) => { const li = document.createElement('li'); li.textContent = s.text; if (done[i]) li.className = 'done'; ol.appendChild(li); });
  stS.appendChild(ol); if (steps.optional){ const o = document.createElement('p'); o.style.cssText = 'font-size:12px;color:var(--muted);font-weight:700;margin:6px 0 0'; o.textContent = steps.optional + ' Dashed ingredients are optional.'; stS.appendChild(o); }
  const row = document.createElement('div'); row.className = 'drow';
  const b1 = document.createElement('button'); b1.className = 'btn'; b1.textContent = `Cook this · buy ${yen(r.need.filter(k => !onHand().has(k)).reduce((a, k) => a + (ING_COST[k] || 0), 0) || r.cost)}`; b1.onclick = () => { $('book').hidden = true; buyFor(r, null); cv.focus({preventScroll: true}); };
  row.appendChild(b1);
  if (pinned === id){ const b3 = document.createElement('button'); b3.className = 'btn ghost'; b3.textContent = 'Stop guide'; b3.onclick = () => { pinned = null; save(); openDetail(id); }; row.appendChild(b3); }
  el.appendChild(row); el.scrollTop = 0;
}
function ingChip(k, opt){ const s = document.createElement('span'); s.className = 'ingc' + (opt ? ' opt' : ''); s.appendChild(iconCanvas(k, 44)); s.appendChild(document.createTextNode(ING[k].n)); return s; }
function getIngredients(r){
  const have = new Set(compsOf(allFoods()).map(c => c.ing)); let added = 0, spent = 0;
  for (const k of r.need){ if (have.has(k)) continue; if (kit.counter.length >= CAP_COUNTER) { toast('Counter full: grab the rest from the fridge'); break; } const f = newFood(k); f.arrive = clock + added * .08; kit.counter.push(f); spent += chargeIng(k); added++; }
  if (added){ SND.pop(3); setTimeout(() => toast(`Bought ${added} ingredient${added > 1 ? 's' : ''} for ${yen(spent)}`), 900); }
}
$('bookBtn').onclick = () => openBook();
$('nextChip').onclick = () => { initAudio(); $('nextChip')._act?.(); };
$('tkX').onclick = () => { $('ticketSheet').hidden = true; cv.focus({preventScroll: true}); };
$('ticketSheet').addEventListener('click', e => { if (e.target.id === 'ticketSheet') $('ticketSheet').hidden = true; });
$('bookX').onclick = () => { $('book').hidden = true; cv.focus({preventScroll: true}); };
$('q').addEventListener('input', e => { book.q = e.target.value; renderBook(); });

// ================= footer sync =================
let uiCache = {};
function syncUI(){
  const st = ST[kit.open], h = st.hint();
  if (uiCache.h !== h){ uiCache.h = h; $('hintText').innerHTML = h; }
  const m = st.meter(), meter = $('meter');
  if ((m == null) !== meter.hidden) meter.hidden = m == null;
  if (m){ $('meterFill').style.width = (m.v * 100).toFixed(1) + '%'; const z = $('zone'); z.hidden = !m.zone; if (m.zone){ z.style.left = m.zone[0] * 100 + '%'; z.style.width = (m.zone[1] - m.zone[0]) * 100 + '%'; } }
  const b = st.btn(), go = $('go'), key = b ? b.label : null;
  if (uiCache.b !== key){ uiCache.b = key; go.hidden = !b; if (b) go.textContent = b.label; }
  if (b){ if (go.disabled !== !b.enabled) go.disabled = !b.enabled; const rd = !!b.ready; if (uiCache.rd !== rd){ uiCache.rd = rd; go.classList.toggle('ready', rd); } }
  const showBack = st.items.length > 0 && !st.busy() && kit.open !== 'bin';
  if ($('back').hidden === showBack) $('back').hidden = !showBack;
  const nh = nextHint();
  for (const k of STATION_ORDER){ const st = ST[k], n = st.items.length, t = TOOL_BTNS[k]; if (!t) continue;
    const ck = k === 'micro' ? (st.run ? st.ck() : -1) : st.run && st.cook != null ? st.cook : -1;
    const cls = ck >= 0 ? (ck > 1 ? 'burning' : ck >= .62 ? 'ready' : 'cooking') : st.busy() ? 'cooking' : '';
    const lab = cls === 'ready' ? '✓' : cls === 'burning' ? '!' : cls ? '●' : n ? String(n) : '';
    if (t.n.textContent !== lab){ t.n.textContent = lab; t.n.hidden = !lab; }
    if (t.cls !== cls){ t.b.classList.remove('cooking', 'ready', 'burning'); if (cls) t.b.classList.add(cls); t.cls = cls; }
    const nx = !!(nh && nh.tool === k); if (t.nx !== nx){ t.b.classList.toggle('next', nx); t.nx = nx; } }
  const chipEl = $('nextChip'), nlab = nh ? nh.label : null; if (uiCache.nx !== nlab){ uiCache.nx = nlab; chipEl.hidden = !nh; if (nh) chipEl.textContent = nh.label + ' ›'; } chipEl._act = nh ? nh.act : null;
}
$('go').onclick = () => { initAudio(); const st = ST[kit.open], b = st.btn(); if (b && b.enabled) st.onBtn(); cv.focus({preventScroll: true}); };
$('back').onclick = () => { emptyStation(); cv.focus({preventScroll: true}); };
$('sfx').onclick = () => { sfxOn = !sfxOn; $('sfx').setAttribute('aria-pressed', sfxOn); initAudio(); };
$('amb').onclick = () => { ambOn = !ambOn; $('amb').setAttribute('aria-pressed', ambOn); initAudio(); setAmb(); };
$('helloGo').onclick = () => { initAudio(); $('hello').hidden = true; SND.chime(); toast('Tap the Fridge to grab ingredients'); cv.focus({preventScroll: true}); };
$('helloBook').onclick = () => { $('hello').hidden = true; openBook(); };

// ================= input =================
function toLocal(e){ const r = cv.getBoundingClientRect(); return {x: (e.clientX - r.left) / r.width * W, y: (e.clientY - r.top) / r.height * H}; }
cv.addEventListener('pointerdown', e => {
  initAudio(); e.preventDefault(); try { cv.setPointerCapture(e.pointerId); } catch (_) {}
  const p = toLocal(e); Object.assign(pointer, {down: true, x: p.x, y: p.y, sx: p.x, sy: p.y, lastT: performance.now()});
  if (p.y > 562){ const i = Math.floor((p.x - 12) / ((W - 24) / CAP_COUNTER)); if (i >= 0 && i < CAP_COUNTER) counterTap(i); pointer.down = false; return; }
  if (p.y < 96 && shopTap(p)){ pointer.down = false; return; }
  ST[kit.open].down?.(p);
});
cv.addEventListener('pointermove', e => {
  const p = toLocal(e);
  if (pointer.down){ const now = performance.now(), dt = Math.max(1, now - pointer.lastT), sp = Math.min(1, Math.hypot(p.x - pointer.x, p.y - pointer.y) / dt / 1.2); ST[kit.open].move?.(p, {x: pointer.x, y: pointer.y}, sp); pointer.lastT = now; }
  pointer.x = p.x; pointer.y = p.y;
});
const endP = e => { if (!pointer.down) return; pointer.down = false; ST[kit.open].up?.(toLocal(e)); };
cv.addEventListener('pointerup', endP); cv.addEventListener('pointercancel', endP);
cv.addEventListener('keydown', e => {
  if (e.key === ' ' || e.key === 'Enter'){ e.preventDefault(); initAudio(); ST[kit.open].auto?.(); }
  else if (/^[1-8]$/.test(e.key)) counterTap(+e.key - 1);
  else if (e.key === 'f') openFridge();
  else if (e.key === 'ArrowRight' || e.key === 'ArrowLeft'){ e.preventDefault(); const i = STATION_ORDER.indexOf(kit.open), n = STATION_ORDER.length; openStation(STATION_ORDER[(i + (e.key === 'ArrowRight' ? 1 : -1) + n) % n]); }
});
document.addEventListener('keydown', e => { if (e.key === 'Escape'){ for (const id of ['fridge', 'book', 'result', 'ticketSheet']) if (!$(id).hidden){ id === 'result' ? closeResult() : ($(id).hidden = true); } } });

// ================= render loop =================
function render(){
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.drawImage(bgC, 0, 0);
  const st = ST[kit.open]; ctx.drawImage(st.back === 'board' ? boardC : st.back === 'stove' ? stoveC : counterC, 0, 0);
  ctx.setTransform(KS, 0, 0, KS, 0, 0);
  ctx.save(); ctx.beginPath(); ctx.rect(0, 0, W, 90); ctx.clip(); for (const c of shop.customers) drawCustomer(ctx, c); ctx.restore();
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.drawImage(norenC, 0, 0); ctx.setTransform(KS, 0, 0, KS, 0, 0);
  drawShopOverlay(ctx); drawShopTicket(ctx);
  ctx.save(); ctx.beginPath(); ctx.rect(20, 104, 360, 450); ctx.clip(); st.draw(ctx); ctx.restore();
  drawCounter(ctx);
  drawFlyers(ctx);
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.drawImage(lightC, 0, 0); ctx.setTransform(KS, 0, 0, KS, 0, 0);
  if (!reduced){ ctx.globalCompositeOperation = 'lighter'; for (const b of motes){ ctx.globalAlpha = b.a * (.55 + .45 * Math.sin(clock * b.f + b.ph)); ctx.drawImage(GLOW_WARM, b.x - b.r, b.y - b.r, b.r * 2, b.r * 2); } ctx.globalAlpha = 1; ctx.globalCompositeOperation = 'source-over'; }
  if (kit.eating){ const k = clamp((clock - kit.eating.t) / 1.1, 0, 1); const n = kit.eating.foods.length; kit.eating.foods.forEach((f, i) => { const x = CX + (i - (n - 1) / 2) * 50, y = CY; drawFood(ctx, f, x + (kit.eating.tx - x) * ease(k), y + (kit.eating.ty - y) * ease(k), (n > 1 ? .7 : 1.2) * (1 - k * .9)); }); }
  for (const p of fx){ const a = clamp(p.life * 2, 0, 1);
    if (p.cloud){ const r = p.r * (2.4 - p.life); ctx.globalAlpha = a * .9; ctx.drawImage(GLOW_W, p.x - r, p.y - r, r * 2, r * 2); continue; }
    ctx.globalCompositeOperation = 'lighter'; ctx.globalAlpha = a * .55; const gr = p.r * 2.8; ctx.drawImage(GLOW_W, p.x - gr, p.y - gr, gr * 2, gr * 2); ctx.globalCompositeOperation = 'source-over';
    ctx.globalAlpha = a; ctx.fillStyle = p.c; star4(ctx, p.x, p.y, p.r, p.rot); ctx.fill(); ctx.lineWidth = 1; ctx.strokeStyle = 'rgba(59,35,64,.3)'; ctx.stroke(); }
  ctx.globalAlpha = 1; ctx.textAlign = 'center'; ctx.lineJoin = 'round';
  for (const f of floats){ const k = .4 + .6 * easeBack((1.4 - f.life) / .3); ctx.save(); ctx.globalAlpha = Math.min(1, f.life * 2); ctx.translate(f.x, f.y); ctx.scale(k, k);
    ctx.font = '20px "Mochiy Pop One", sans-serif'; ctx.lineWidth = 7; ctx.strokeStyle = PLUM; ctx.strokeText(f.txt, 0, 0);
    const tg = ctx.createLinearGradient(0, -17, 0, 3); tg.addColorStop(0, '#FFF8C2'); tg.addColorStop(1, '#FF9EBB'); ctx.fillStyle = tg; ctx.fillText(f.txt, 0, 0);
    ctx.lineWidth = 1.4; ctx.strokeStyle = 'rgba(255,255,255,.85)'; ctx.strokeText(f.txt, 0, -1); ctx.restore(); }
  if (!reduced) for (const p of petals){ ctx.save(); ctx.globalAlpha = .9; ctx.translate(p.x, p.y); ctx.rotate(p.ph); ctx.scale(.35 + .65 * Math.abs(Math.cos(clock * 1.6 + p.ph * 3)), 1); ctx.drawImage(PETAL, -p.s, -p.s, p.s * 2, p.s * 2); ctx.restore(); }
}
for (let i = 0; i < 9; i++) petals.push({x: R() * W, y: R() * H, s: 5 + R() * 3, v: 10 + R() * 14, ph: R() * TAU});
let last = performance.now();
function frame(now){
  const dt = Math.min(.05, (now - last) / 1000); last = now; clock += dt;
  for (const k of STATION_ORDER) ST[k].update?.(dt);
  shopUpdate(dt);
  for (const p of fx){ p.life -= dt; if (!p.cloud) p.vy += 260 * dt; p.x += p.vx * dt; p.y += p.vy * dt; p.vx *= .97; p.rot = (p.rot || 0) + dt * 3; }
  fx = fx.filter(p => p.life > 0);
  for (const f of floats){ f.life -= dt; f.y -= 28 * dt; } floats = floats.filter(f => f.life > 0);
  for (const b of motes){ b.x += b.vx * dt; b.y += b.vy * dt; if (b.y < 100){ b.y = 560; b.x = R() * W; } }
  for (const p of petals){ p.y += p.v * dt; p.x += Math.sin(clock + p.ph) * 12 * dt + 6 * dt; p.ph += dt * .8; if (p.y > H + 10){ p.y = -10; p.x = R() * W; } if (p.x > W + 10) p.x = -10; }
  syncUI(); render(); requestAnimationFrame(frame);
}

// testing hooks (harmless for players)
window.__ck = {drawIng, drawArt, recipeSpec, foodSpec, genericSpec, newFood, applyProc, ING, buyFor, openTicket, nextHint, shop, toggleShop, takeOrder, spawnCustomer, shopTap, get wallet(){ return wallet; }, render, ST, kit, RECIPES, detect, compsOf, add: k => addIngredient(k), open: k => openStation(k), tap: i => counterTap(i), auto: () => ST[kit.open].auto?.(), serve, step: s => { for (let i = 0; i < s * 60; i++){ clock += 1 / 60; for (const k of STATION_ORDER) ST[k].update?.(1 / 60); shopUpdate(1 / 60); } }};

function start(){
  resize(); buildToolbar(); save();
  requestAnimationFrame(t => { last = t; requestAnimationFrame(frame); });
}
window.addEventListener('resize', resize);
if (document.fonts && document.fonts.ready) document.fonts.ready.then(() => { resize(); thumbCache.clear(); });
window.claude?.hot?.ready ? window.claude.hot.ready(start) : start();
