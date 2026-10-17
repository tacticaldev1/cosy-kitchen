// ================= dish art =================
// Every dish is drawn around (0,0) inside roughly x -95..95, y -100..85, then baked into a cached sprite.
const lin = (g, x0, y0, x1, y1, st) => { const gr = g.createLinearGradient(x0, y0, x1, y1); for (const [o, c] of st) gr.addColorStop(o, c); return gr; };
const rad = (g, x, y, r, st, fx = 0, fy = 0) => { const gr = g.createRadialGradient(x + fx, y + fy, 0, x, y, r); for (const [o, c] of st) gr.addColorStop(o, c); return gr; };
function paint(g, fill, w = 2.2, c = PLUM){ g.fillStyle = fill; g.fill(); if (w) line(g, w, c); }
function glint(g, x, y, rx, ry, rot = -.5, a = .85){ g.save(); g.globalAlpha *= a; g.beginPath(); g.ellipse(x, y, Math.max(.1, rx), Math.max(.1, ry), rot, 0, TAU); g.fillStyle = '#FFFFFF'; g.fill(); g.restore(); }
function speckle(g, n, cx, cy, rx, ry, r, col, seed){ const rng = rngFor(seed); g.fillStyle = col; for (let i = 0; i < n; i++){ const a = rng() * TAU, d = Math.sqrt(rng()); g.beginPath(); g.arc(cx + Math.cos(a) * rx * d, cy + Math.sin(a) * ry * d, r * (.6 + rng() * .7), 0, TAU); g.fill(); } }
function grains(g, n, cx, cy, rx, ry, seed, col = '#FFFFFF', sh = 'rgba(160,145,120,.5)'){ const rng = rngFor(seed); for (let i = 0; i < n; i++){ const a = rng() * TAU, d = Math.sqrt(rng()), x = cx + Math.cos(a) * rx * d, y = cy + Math.sin(a) * ry * d, rt = rng() * Math.PI; g.beginPath(); g.ellipse(x + .6, y + .8, 3, 1.5, rt, 0, TAU); g.fillStyle = sh; g.fill(); g.beginPath(); g.ellipse(x, y, 3, 1.5, rt, 0, TAU); g.fillStyle = col; g.fill(); } }
const NOT_GARNISH = new Set(['sugar', 'flour', 'milk', 'ice', 'soy', 'curry', 'rice', 'nori', 'noodles', 'pasta', 'oats', 'kernels', 'bread', 'tortilla', 'coffee', 'cream', 'yogurt']);
const extras = (sp, skip = []) => [...(sp.ings || [])].filter(k => !NOT_GARNISH.has(k) && !skip.includes(k));
function steamUp(g, y = -40, smoke = false){
  const col = smoke ? '112,98,112' : '255,255,255';
  for (let i = 0; i < 4; i++){ const t = (clock * .42 + i / 4) % 1, a = Math.sin(t * Math.PI), x = -24 + i * 16 + Math.sin(t * 5 + i * 2) * 7, yy = y - t * 48, r = 8 + t * 15;
    const gr = g.createRadialGradient(x, yy, 0, x, yy, r); gr.addColorStop(0, `rgba(${col},${(smoke ? .6 : .55) * a})`); gr.addColorStop(1, `rgba(${col},0)`); g.fillStyle = gr; g.fillRect(x - r, yy - r, r * 2, r * 2); }
}

// ---------- tableware ----------
function plate(g, y = 40, rx = 80, ry = 29, rim = '#8C9BE0'){
  ell(g, 3, y + 8, rx, ry, 'rgba(59,35,64,.22)'); ell(g, 0, y + 4, rx, ry, '#BCC4E8');
  g.beginPath(); g.ellipse(0, y, rx, ry, 0, 0, TAU); paint(g, lin(g, -rx, y - ry, rx * .6, y + ry, [[0, '#FFFFFF'], [1, '#E2E6F7']]), 2.3);
  g.beginPath(); g.ellipse(0, y + 2, rx * .72, ry * .66, 0, 0, TAU); paint(g, lin(g, 0, y - ry, 0, y + ry, [[0, '#E6E9F7'], [1, '#FFFFFF']]), 1.2, 'rgba(124,138,214,.4)');
  g.save(); g.setLineDash([3, 6]); g.beginPath(); g.ellipse(0, y, rx * .87, ry * .83, 0, 0, TAU); line(g, 2.6, rim); g.restore();
  g.beginPath(); g.ellipse(0, y, rx * .95, ry * .9, 0, Math.PI * 1.08, Math.PI * 1.42); line(g, 3, 'rgba(255,255,255,.95)');
}
function woodBoard(g, y = 42, w = 164, h = 40){
  rr(g, -w / 2 + 3, y - h / 2 + 9, w, h, 9); g.fillStyle = 'rgba(59,35,64,.22)'; g.fill();
  for (const sx of [-w * .33, w * .33]){ rr(g, sx - 9, y + h / 2 - 4, 18, 12, 3); paint(g, '#9A6436', 1.8); }
  rr(g, -w / 2, y - h / 2 + 5, w, h, 9); g.fillStyle = '#B57C48'; g.fill(); line(g, 2.2);
  rr(g, -w / 2, y - h / 2, w, h, 9); paint(g, lin(g, 0, y - h / 2, 0, y + h / 2, [[0, '#F6D29A'], [1, '#DDA668']]));
  g.save(); rr(g, -w / 2, y - h / 2, w, h, 9); g.clip(); for (let i = 0; i < 5; i++){ g.beginPath(); for (let x = -w / 2; x <= w / 2; x += 10) g.lineTo(x, y - h / 2 + 5 + i * 8 + Math.sin(x / 19 + i * 2) * 2); line(g, 1, 'rgba(160,100,50,.28)'); } g.restore();
  g.beginPath(); g.moveTo(-w / 2 + 10, y - h / 2 + 2.5); g.lineTo(w / 2 - 30, y - h / 2 + 2.5); line(g, 2, 'rgba(255,255,255,.7)');
}
function bowl(g, o, inner){
  const y = o.y ?? 0, rx = o.rx ?? 68, ry = o.ry ?? 27, d = o.d ?? 52, c1 = o.c1 || '#FFFFFF', c2 = o.c2 || '#D6DCF2', band = o.band || '#7C8AD6';
  ell(g, 3, y + d + 6, rx * .6, 9, 'rgba(59,35,64,.22)');
  rr(g, -rx * .32, y + d - 9, rx * .64, 14, 5); paint(g, lin(g, 0, y + d - 9, 0, y + d + 5, [[0, c2], [1, darken(c2, .18)]]), 2);
  g.beginPath(); g.moveTo(-rx, y); g.bezierCurveTo(-rx * .96, y + d * 1.12, rx * .96, y + d * 1.12, rx, y); g.ellipse(0, y, rx, ry, 0, 0, Math.PI); g.closePath();
  paint(g, lin(g, -rx, 0, rx, 0, [[0, lighten(c1, .2)], [.5, c1], [1, c2]]), 2.4);
  g.save(); g.clip();
  if (o.pattern === 'wave'){ g.strokeStyle = band; g.lineWidth = 1.8; for (let x = -rx; x < rx + 14; x += 14) for (const r of [6, 3]){ g.beginPath(); g.arc(x, y + ry + 18, r, Math.PI, TAU); g.stroke(); } }
  else if (o.pattern === 'dots'){ g.fillStyle = band; for (let x = -rx + 8, i = 0; x < rx; x += 13, i++){ g.beginPath(); g.arc(x, y + ry + 13 + (i % 2) * 6, 3, 0, TAU); g.fill(); } }
  else if (o.pattern === 'stripe'){ g.fillStyle = band; g.fillRect(-rx, y + ry + 4, rx * 2, 5); g.fillRect(-rx, y + ry + 13, rx * 2, 2); }
  g.fillStyle = 'rgba(255,255,255,.45)'; g.beginPath(); g.ellipse(-rx * .62, y + ry + d * .3, 6, d * .32, -.25, 0, TAU); g.fill();
  g.restore();
  g.beginPath(); g.ellipse(0, y, rx, ry, 0, 0, TAU); paint(g, lin(g, 0, y - ry, 0, y + ry, [[0, darken(c2, .16)], [1, c1]]), 2.4);
  const iy = y + 3, irx = rx - 7, iry = ry - 6;
  if (inner){ g.save(); g.beginPath(); g.ellipse(0, iy, irx, iry, 0, 0, TAU); g.clip(); inner(g, iy, irx, iry);
    g.fillStyle = lin(g, 0, iy - iry, 0, iy - iry * .2, [[0, 'rgba(59,35,64,.26)'], [1, 'rgba(59,35,64,0)']]); g.fillRect(-irx, iy - iry, irx * 2, iry); g.restore();
    g.beginPath(); g.ellipse(0, iy, irx, iry, 0, 0, TAU); line(g, 1.2, 'rgba(59,35,64,.35)'); }
  g.beginPath(); g.ellipse(0, y, rx - 2, ry - 2, 0, Math.PI * 1.12, Math.PI * 1.5); line(g, 2.2, 'rgba(255,255,255,.9)');
}
const fillAll = (g, f) => { g.fillStyle = f; g.fillRect(-200, -200, 400, 400); };
function friedEgg(g, x, y, s = 1){ g.save(); g.translate(x, y); g.scale(s, s); g.beginPath(); for (let k = 0; k <= 20; k++){ const a = k / 20 * TAU, r = 30 + Math.sin(a * 5) * 3 + Math.sin(a * 3) * 2; g.lineTo(Math.cos(a) * r, Math.sin(a) * r * .55); } g.closePath(); paint(g, rad(g, 0, 0, 32, [[0, '#FFFFFF'], [1, '#F4EEE6']]));
  g.beginPath(); g.ellipse(-2, -3, 12, 10, 0, 0, TAU); paint(g, rad(g, -2, -3, 13, [[0, '#FFC94A'], [.7, '#FFA51E'], [1, '#F28A1E']], -3, -3), 1.8); glint(g, -6, -7, 4, 2.2); g.restore(); }

// ---------- garnishes, by ingredient ----------
function garnish(g, k, x, y, s = 1, rot = 0){
  g.save(); g.translate(x, y); g.rotate(rot); g.scale(s, s); g.lineJoin = 'round';
  switch (k){
    case 'strawberry':
      g.beginPath(); g.moveTo(0, 10); g.bezierCurveTo(-12, 2, -10, -9, 0, -7); g.bezierCurveTo(10, -9, 12, 2, 0, 10); paint(g, rad(g, -2, -2, 13, [[0, '#FF8A9A'], [1, '#D92A44']]), 1.6);
      g.beginPath(); g.moveTo(0, 6); g.bezierCurveTo(-6, 1, -5, -4, 0, -3); g.bezierCurveTo(5, -4, 6, 1, 0, 6); g.fillStyle = '#FFD3DA'; g.fill();
      g.fillStyle = '#FFE680'; for (const [a, b] of [[-5, -2], [5, -2], [0, 4], [-3, 6], [3, 6]]){ g.beginPath(); g.ellipse(a, b, .9, 1.4, 0, 0, TAU); g.fill(); }
      for (const a of [-.7, 0, .7]){ g.save(); g.translate(0, -7); g.rotate(a); ell(g, 0, -3, 2.4, 4.5, '#5DB04B', 1.2); g.restore(); } glint(g, -5, -3, 2.5, 1.4); break;
    case 'blueberry': g.beginPath(); g.arc(0, 0, 6, 0, TAU); paint(g, rad(g, 0, 0, 7, [[0, '#8C9BFF'], [1, '#3442A0']], -2, -2), 1.4); star4(g, 1, -2, 2.2, .3); g.fillStyle = '#26307A'; g.fill(); glint(g, -2.4, -2.4, 1.6, 1); break;
    case 'banana': g.beginPath(); g.ellipse(0, 0, 9, 6.5, 0, 0, TAU); paint(g, rad(g, 0, 0, 9, [[0, '#FFFBE6'], [1, '#F6DE8E']]), 1.4); for (let i = 0; i < 5; i++){ const a = i / 5 * TAU; disc(g, Math.cos(a) * 2.6, Math.sin(a) * 1.8, .8, '#B89A5A'); } break;
    case 'cherry': g.beginPath(); g.moveTo(0, -3); g.quadraticCurveTo(2, -14, 9, -16); line(g, 1.6, '#5A8A3A'); g.beginPath(); g.arc(0, 2, 7, 0, TAU); paint(g, rad(g, 0, 2, 8, [[0, '#FF6A80'], [1, '#B8102E']], -2, -3), 1.5); glint(g, -2.5, -1, 2.2, 1.4); break;
    case 'chocolate': for (const [a, b, r] of [[-6, 0, .3], [5, 2, -.4], [0, -5, .8]]){ g.save(); g.translate(a, b); g.rotate(r); rr(g, -4, -2.5, 8, 5, 1.5); paint(g, lin(g, 0, -3, 0, 3, [[0, '#8A5236'], [1, '#4A2416']]), 1.1); g.restore(); } break;
    case 'cream': for (let i = 0; i < 3; i++){ g.beginPath(); g.ellipse(0, 4 - i * 5, 11 - i * 3.2, 4.4, 0, 0, TAU); paint(g, lin(g, 0, -i * 5, 0, 8 - i * 5, [[0, '#FFFFFF'], [1, '#F2E6EE']]), 1.4); } g.beginPath(); g.moveTo(-2, -9); g.quadraticCurveTo(0, -15, 3, -10); line(g, 1.4); break;
    case 'butter': rr(g, -8, -6, 16, 12, 3); paint(g, lin(g, 0, -6, 0, 6, [[0, '#FFF3B0'], [1, '#F6D25A']]), 1.5); g.beginPath(); g.ellipse(0, 7, 12, 3.4, 0, 0, TAU); g.fillStyle = 'rgba(255,220,100,.7)'; g.fill(); glint(g, -3, -3, 3, 1.2, 0); break;
    case 'mushroom': g.beginPath(); g.moveTo(-9, 2); g.quadraticCurveTo(-9, -9, 0, -9); g.quadraticCurveTo(9, -9, 9, 2); g.lineTo(3, 2); g.lineTo(3, 8); g.lineTo(-3, 8); g.lineTo(-3, 2); g.closePath(); paint(g, '#F6E6D2', 1.4); g.beginPath(); g.moveTo(-9, 2); g.quadraticCurveTo(-9, -9, 0, -9); g.quadraticCurveTo(9, -9, 9, 2); line(g, 2.4, '#A8714A'); break;
    case 'tomato': g.beginPath(); g.arc(0, 0, 8, 0, TAU); paint(g, rad(g, 0, 0, 8, [[0, '#FF8A70'], [1, '#D8301E']]), 1.4); g.beginPath(); g.arc(0, 0, 5.5, 0, TAU); g.fillStyle = '#FFB09A'; g.fill(); for (const a of [0, 2.1, 4.2]) ell(g, Math.cos(a) * 2.8, Math.sin(a) * 2.8, 1.8, 1.1, '#FFE6B0', 0, a); glint(g, -3, -3, 2, 1.2); break;
    case 'cucumber': g.beginPath(); g.arc(0, 0, 8, 0, TAU); paint(g, '#3E8E48', 1.4); g.beginPath(); g.arc(0, 0, 6.4, 0, TAU); g.fillStyle = '#D8F2C2'; g.fill(); for (const a of [0, 2.1, 4.2]) ell(g, Math.cos(a) * 2.4, Math.sin(a) * 2.4, 1.6, 1, '#F6FFE8', 0, a); break;
    case 'carrot': g.beginPath(); g.arc(0, 0, 7, 0, TAU); paint(g, rad(g, 0, 0, 7, [[0, '#FFC27A'], [1, '#F27A1E']]), 1.3); ring(g, 0, 0, 3.4, 1, 'rgba(255,240,200,.8)'); break;
    case 'corn': for (const [a, b] of [[-4, 0], [4, 0], [0, -5], [0, 5]]){ g.beginPath(); g.ellipse(a, b, 3.4, 3, 0, 0, TAU); paint(g, rad(g, a, b, 4, [[0, '#FFF0A0'], [1, '#F6C21E']]), 1); } break;
    case 'spinach': case 'lettuce': g.beginPath(); g.ellipse(0, 0, 11, 6, 0, 0, TAU); paint(g, k === 'spinach' ? '#3F8A4A' : '#8ED16B', 1.3); g.beginPath(); g.moveTo(-9, 0); g.lineTo(9, 0); line(g, 1, 'rgba(255,255,255,.7)'); break;
    case 'egg': g.beginPath(); g.ellipse(0, 0, 11, 8, 0, 0, TAU); paint(g, '#FFFFFF', 1.4); g.beginPath(); g.ellipse(0, .5, 5.5, 4.5, 0, 0, TAU); paint(g, rad(g, 0, .5, 6, [[0, '#FFB02E'], [1, '#F27A1E']]), 1); glint(g, -1.5, -1, 1.6, 1); break;
    case 'bacon': for (const [w, c] of [[6, '#B8434E'], [2, '#FFD8D0']]){ g.beginPath(); g.moveTo(-10, 0); for (let i = 1; i <= 5; i++) g.lineTo(-10 + i * 4, (i % 2 ? -3 : 3)); line(g, w, c); } break;
    case 'cheese': for (const [a, b, r] of [[-5, 0, .5], [4, -2, -.3], [1, 4, .9]]){ g.save(); g.translate(a, b); g.rotate(r); rr(g, -5, -1.4, 10, 2.8, 1.4); paint(g, '#FFD54A', .9); g.restore(); } break;
    case 'onion': for (const [a, b] of [[-4, -1], [3, -3], [2, 3]]) ring(g, a, b, 2.6, 1.6, '#6BBF59'); break;
    case 'pepper': g.beginPath(); g.arc(0, 4, 9, Math.PI * 1.15, Math.PI * 1.85); line(g, 4, '#E8402E'); g.beginPath(); g.arc(0, 4, 9, Math.PI * 1.2, Math.PI * 1.5); line(g, 1.2, 'rgba(255,255,255,.7)'); break;
    case 'avocado': for (let i = 0; i < 3; i++){ g.save(); g.rotate(-.4 + i * .4); g.beginPath(); g.ellipse(0, -5, 4, 9, 0, 0, TAU); paint(g, lin(g, -4, 0, 4, 0, [[0, '#E2F09A'], [1, '#8CC152']]), 1.2); g.restore(); } break;
    case 'sausage': g.beginPath(); g.arc(0, 0, 6.5, 0, TAU); paint(g, '#C8503A', 1.3); g.beginPath(); g.arc(0, 0, 4.4, 0, TAU); g.fillStyle = '#F2A08A'; g.fill(); break;
    case 'chicken': rr(g, -9, -5, 18, 10, 4); paint(g, lin(g, 0, -5, 0, 5, [[0, '#FFE6C8'], [1, '#E8B07A']]), 1.3); for (const a of [-4, 1, 6]){ g.beginPath(); g.moveTo(a, -4); g.lineTo(a - 3, 4); line(g, 1.2, '#B87A4A'); } break;
    case 'beef': g.beginPath(); g.ellipse(0, 0, 10, 6, 0, 0, TAU); paint(g, lin(g, 0, -6, 0, 6, [[0, '#B85A4A'], [1, '#6A2A20']]), 1.3); g.beginPath(); g.moveTo(-6, -1); g.quadraticCurveTo(0, 2, 6, -1); line(g, 1, 'rgba(255,220,210,.6)'); break;
    case 'salmon': case 'tuna': rr(g, -8, -5, 16, 10, 3); paint(g, k === 'salmon' ? '#F4895A' : '#D63B4E', 1.3); for (let i = -1; i <= 1; i++){ g.beginPath(); g.moveTo(i * 5 - 2, 5); g.lineTo(i * 5 + 2, -5); line(g, 1.2, k === 'salmon' ? '#FFE3D2' : 'rgba(255,190,200,.6)'); } break;
    case 'shrimp': g.beginPath(); g.arc(0, 0, 6, Math.PI * .2, Math.PI * 1.5); line(g, 5.5); g.beginPath(); g.arc(0, 0, 6, Math.PI * .2, Math.PI * 1.5); line(g, 3.6, '#FF9C7A'); break;
    case 'honey': case 'syrup': case 'caramel': g.beginPath(); g.ellipse(0, 0, 10, 4, 0, 0, TAU); g.fillStyle = k === 'syrup' ? '#B4642A' : '#F6B73C'; g.fill(); glint(g, -3, -1, 3, 1, 0, .7); break;
    case 'sprinkles': { const cols = ['#FF7EA6', '#7FD3F7', '#FFD24A', '#9BE38F', '#C3A6FF']; for (let i = 0; i < 6; i++){ g.save(); g.translate(Math.cos(i * 2.1) * 6, Math.sin(i * 2.1) * 4); g.rotate(i * .9); rr(g, -3, -1, 6, 2, 1); g.fillStyle = cols[i % 5]; g.fill(); g.restore(); } break; }
    case 'redbean': g.beginPath(); g.ellipse(0, 0, 10, 6, 0, 0, TAU); paint(g, '#6A2230', 1.3); speckle(g, 6, 0, 0, 7, 4, 1.5, '#8E3A48', 3); break;
    case 'matcha': speckle(g, 12, 0, 0, 10, 6, 1, '#7DB54A', 2); break;
    case 'orange': case 'lemon': { const c = k === 'orange' ? '#FF9F2E' : '#FFD83A'; g.beginPath(); g.arc(0, 0, 8, 0, TAU); paint(g, c, 1.4); g.beginPath(); g.arc(0, 0, 6.4, 0, TAU); g.fillStyle = lighten(c, .55); g.fill(); g.strokeStyle = c; g.lineWidth = 1; for (let i = 0; i < 6; i++){ const a = i / 6 * TAU; g.beginPath(); g.moveTo(0, 0); g.lineTo(Math.cos(a) * 6.4, Math.sin(a) * 6.4); g.stroke(); } break; }
    case 'apple': g.beginPath(); g.arc(0, 0, 8, Math.PI * .9, Math.PI * 2.1); g.closePath(); paint(g, '#FFF2D6', 1.3); g.beginPath(); g.arc(0, 0, 8, Math.PI * .9, Math.PI * 2.1); line(g, 2.2, '#E8404A'); break;
    default: piece(g, k, 0, 0, 8, 0);
  }
  g.restore();
}
function scatter(g, keys, n, cx, cy, rx, ry, s, seed){ if (!keys.length) return; const rng = rngFor(seed), pts = []; for (let i = 0; i < n; i++){ const a = rng() * TAU, d = Math.sqrt(rng()) * .9; pts.push([cx + Math.cos(a) * rx * d, cy + Math.sin(a) * ry * d, keys[i % keys.length], rng() * 2 - 1]); } pts.sort((a, b) => a[1] - b[1]).forEach(([x, y, k, r]) => garnish(g, k, x, y, s, r)); }
function drizzle(g, col, x0, y0, w, n = 4, h = 8){ for (const [lw, c, dy] of [[3.4, col, 0], [1, 'rgba(255,255,255,.6)', -1]]){ g.beginPath(); g.moveTo(x0, y0 + dy); for (let i = 1; i <= n * 2; i++) g.quadraticCurveTo(x0 + (i - .5) * w / (n * 2), y0 + dy + (i % 2 ? -h : h), x0 + i * w / (n * 2), y0 + dy); line(g, lw, c); } }
function riceMound(g, x, y, rx, ry, seed){ g.beginPath(); g.moveTo(x - rx, y + ry * .35); g.bezierCurveTo(x - rx, y - ry * 1.2, x + rx, y - ry * 1.2, x + rx, y + ry * .35); g.quadraticCurveTo(x, y + ry * .9, x - rx, y + ry * .35); paint(g, lin(g, x - rx, y - ry, x + rx, y + ry, [[0, '#FFFFFF'], [1, '#EAE2D2']])); g.save(); g.clip(); grains(g, Math.round(rx * ry / 9), x, y - ry * .1, rx * .95, ry * .95, seed); g.restore(); }
function bacon2(g, x, y){ g.save(); g.translate(x, y); g.rotate(-.2); for (const [w, c, dy] of [[9, PLUM, 0], [6.5, '#B8434E', 0], [1.6, '#FFD0C8', -1]]){ g.beginPath(); g.moveTo(-18, dy); for (let i = 1; i <= 6; i++) g.lineTo(-18 + i * 6, dy + (i % 2 ? -4 : 4)); line(g, w, c); } g.restore(); }

// ---------- dishes ----------
const ART = {
  raw(g, sp){ drawIng(g, sp.ing, 0, 0, 50); },
  chunks(g, sp){ plate(g, 34); const rng = rngFor(7), pts = []; (sp.pieces || []).forEach(k => { for (let j = 0; j < 5; j++){ const a = rng() * TAU, d = Math.sqrt(rng()) * 34; pts.push([Math.cos(a) * d * 1.3, 26 + Math.sin(a) * d * .42 - j * 3, k, rng() * 3]); } }); pts.sort((a, b) => a[1] - b[1]).forEach(([x, y, k, r]) => piece(g, k, x, y, 13, r)); },
  log(g, sp){ woodBoard(g, 42); rr(g, -62, -2, 116, 40, 20); paint(g, lin(g, 0, -4, 0, 40, [[0, '#2E4A3A'], [.3, '#4E6E5A'], [.55, '#22362A'], [1, '#121C16']]));
    g.beginPath(); g.ellipse(54, 18, 10, 20, 0, 0, TAU); paint(g, '#1F2C25', 2); g.beginPath(); g.ellipse(54, 18, 8, 17, 0, 0, TAU); g.fillStyle = '#FDFAF3'; g.fill(); (sp.tops || []).slice(0, 3).forEach((c, i) => ell(g, 54, 11 + i * 7, 3.5, 3, c, 1)); g.beginPath(); g.moveTo(-46, 6); g.lineTo(26, 6); line(g, 3, 'rgba(255,255,255,.55)'); },
  glass(g, sp){
    const st = sp.style, ings = sp.ings || new Set(), c = sp.main || '#FF9DB8', top = -48, bot = 56, wt = 34, wb = 26;
    const gx = (yy, s) => s * (wt + (wb - wt) * (yy - top) / (bot - top));
    const path = () => { g.beginPath(); g.moveTo(gx(top, -1), top); g.lineTo(gx(top, 1), top); g.lineTo(gx(bot, 1), bot - 4); g.quadraticCurveTo(0, bot + 5, gx(bot, -1), bot - 4); g.closePath(); };
    ell(g, 2, bot + 8, 48, 10, 'rgba(59,35,64,.2)'); g.beginPath(); g.ellipse(0, bot + 3, 44, 10, 0, 0, TAU); paint(g, lin(g, 0, bot - 6, 0, bot + 12, [[0, '#FFE3EC'], [1, '#FFB8CE']]), 2);
    const ly = st === 'shake' ? top + 9 : top + 15;
    g.save(); path(); g.clip(); g.fillStyle = 'rgba(225,242,255,.55)'; g.fillRect(-60, top, 120, 120);
    if (st === 'parfait'){ const fr = ings.has('blueberry') ? '#5B6CD6' : '#E0405A'; ['#FFF8FA', fr, '#E8D2A6', '#FFF8FA', fr, '#E8D2A6'].forEach((col, i) => { const yy = ly + i * 14; g.fillStyle = col; g.beginPath(); g.moveTo(-60, yy + 4); for (let x = -60; x <= 60; x += 10) g.lineTo(x, yy + Math.sin(x / 8 + i) * 2.5); g.lineTo(60, yy + 22); g.lineTo(-60, yy + 22); g.fill(); if (col === '#E8D2A6') speckle(g, 9, 0, yy + 7, 28, 4, 2, '#B8925E', i); }); }
    else if (ings.has('matcha') && ings.has('ice')){ g.fillStyle = '#FFFDF6'; g.fillRect(-60, ly + 34, 120, 80); g.fillStyle = lin(g, 0, ly, 0, ly + 40, [[0, '#B8DC7A'], [1, '#8CC152']]); g.fillRect(-60, ly, 120, 36); g.fillStyle = 'rgba(255,255,255,.5)'; g.beginPath(); for (let x = -60; x <= 60; x += 8) g.lineTo(x, ly + 34 + Math.sin(x / 6) * 3); g.lineTo(60, ly + 40); g.lineTo(-60, ly + 40); g.fill(); }
    else { g.fillStyle = lin(g, 0, ly, 0, bot, [[0, lighten(c, .28)], [1, darken(c, .1)]]); g.fillRect(-60, ly, 120, 120); speckle(g, 12, 0, (ly + bot) / 2, 22, (bot - ly) / 2 - 6, 1.6, 'rgba(255,255,255,.5)', 3);
      if (ings.has('strawberry') || ings.has('blueberry') || ings.has('watermelon')) speckle(g, 16, 0, (ly + bot) / 2, 22, 30, 1, 'rgba(110,20,50,.25)', 4); }
    if (st === 'ice' || ings.has('ice') && st !== 'shake') for (const [x, yy, r] of [[-12, ly + 12, .2], [11, ly + 24, -.3], [-3, ly + 44, .5]]){ g.save(); g.translate(x, yy); g.rotate(r); rr(g, -9, -9, 18, 18, 4); g.fillStyle = 'rgba(255,255,255,.6)'; g.fill(); line(g, 1.3, 'rgba(110,150,200,.7)'); g.fillStyle = 'rgba(255,255,255,.9)'; g.fillRect(-6, -6, 5, 2); g.restore(); }
    g.beginPath(); g.ellipse(0, ly, gx(ly, 1), 5, 0, 0, TAU); g.fillStyle = lighten(st === 'parfait' ? '#FFF8FA' : c, .45); g.fill();
    g.restore();
    g.save(); g.translate(13, top - 32); g.rotate(.24); rr(g, -4.5, 0, 9, 104, 4.5); g.fillStyle = '#FFFFFF'; g.fill(); g.save(); g.clip(); g.fillStyle = '#FF7EA6'; for (let i = 0; i < 10; i++){ g.save(); g.translate(0, i * 12); g.rotate(-.5); g.fillRect(-10, 0, 20, 5); g.restore(); } g.restore(); rr(g, -4.5, 0, 9, 104, 4.5); line(g, 1.8); g.restore();
    path(); line(g, 2.4); g.beginPath(); g.ellipse(0, top, wt, 6, 0, 0, TAU); g.fillStyle = 'rgba(255,255,255,.3)'; g.fill(); line(g, 2.2);
    g.beginPath(); g.moveTo(gx(top + 10, -1) + 6, top + 10); g.lineTo(gx(bot - 16, -1) + 6, bot - 16); line(g, 4.5, 'rgba(255,255,255,.85)'); g.beginPath(); g.moveTo(gx(top + 14, 1) - 7, top + 14); g.lineTo(gx(top + 30, 1) - 7, top + 30); line(g, 2.4, 'rgba(255,255,255,.7)');
    const rng = rngFor(9); for (let i = 0; i < 7; i++){ const yy = top + 20 + rng() * 70, x = gx(yy, rng() < .5 ? -1 : 1) * (.55 + rng() * .35); ell(g, x, yy, 1.6, 2.2, 'rgba(255,255,255,.85)'); }
    if (st === 'shake'){ for (let i = 0; i < 4; i++){ g.beginPath(); g.ellipse(0, top - 2 - i * 8, 32 - i * 7, 8, 0, 0, TAU); paint(g, lin(g, 0, top - 10 - i * 8, 0, top + 6 - i * 8, [[0, '#FFFFFF'], [1, '#F0E4EE']]), 2); }
      if (ings.has('chocolate')) drizzle(g, '#6B3A26', -22, top - 6, 44, 3, 4); garnish(g, 'cherry', 3, top - 40, 1.1); }
    else { const rim = ['strawberry', 'lemon', 'orange', 'watermelon', 'mango', 'pineapple', 'banana'].find(k => ings.has(k)); if (rim) garnish(g, rim, -24, top - 2, 1.2, -.3); if (ings.has('cream')) garnish(g, 'cream', -2, top - 6, 1.4); }
  },
  mug(g, sp){
    const ings = sp.ings || new Set(), c = sp.main || '#8A5A40';
    ell(g, 3, 54, 62, 16, 'rgba(59,35,64,.2)'); g.beginPath(); g.ellipse(0, 48, 60, 15, 0, 0, TAU); paint(g, lin(g, 0, 33, 0, 63, [[0, '#FFFFFF'], [1, '#E2E6F7']])); g.beginPath(); g.ellipse(0, 46, 40, 9, 0, 0, TAU); line(g, 1.2, 'rgba(124,138,214,.5)');
    g.beginPath(); g.arc(37, 10, 16, -Math.PI / 2, Math.PI / 2); line(g, 11); g.beginPath(); g.arc(37, 10, 16, -Math.PI / 2, Math.PI / 2); line(g, 6.5, '#FFB3CC');
    g.beginPath(); g.moveTo(-40, -26); g.lineTo(38, -26); g.lineTo(34, 38); g.quadraticCurveTo(-2, 50, -36, 38); g.closePath(); paint(g, lin(g, -40, 0, 40, 0, [[0, '#FFE0EA'], [.45, '#FFC2D6'], [1, '#E58AAE']]), 2.4);
    g.save(); g.clip(); g.fillStyle = 'rgba(255,255,255,.6)'; for (let x = -30; x < 34; x += 14) for (const yy of [8, 24]){ star4(g, x + (yy === 24 ? 7 : 0), yy, 3, 0); g.fill(); } g.fillStyle = 'rgba(255,255,255,.45)'; g.fillRect(-30, -20, 7, 54); g.restore();
    g.beginPath(); g.ellipse(-1, -26, 39, 9, 0, 0, TAU); paint(g, '#FFF4F8', 2.2);
    g.beginPath(); g.ellipse(-1, -25, 34, 6.6, 0, 0, TAU); g.fillStyle = rad(g, -1, -25, 34, [[0, lighten(c, .2)], [1, darken(c, .12)]]); g.fill();
    if (ings.has('milk') || ings.has('cream')){ if (ings.has('chocolate')){ for (const [x, y, col] of [[-12, -26, '#FFFFFF'], [4, -24, '#FFD6E4'], [14, -27, '#FFFFFF']]){ rr(g, x - 5, y - 4, 10, 8, 3); paint(g, col, 1.2); } }
      else { g.save(); g.translate(-1, -25); g.scale(1, .32); g.beginPath(); g.moveTo(0, 14); g.bezierCurveTo(-22, 0, -14, -18, 0, -8); g.bezierCurveTo(14, -18, 22, 0, 0, 14); g.fillStyle = 'rgba(255,250,240,.92)'; g.fill(); g.restore(); } }
    if (ings.has('lemon')) garnish(g, 'lemon', 8, -26, .9);
    face(g, -2, 12, .8, 'happy');
  },
  bowl(g, sp){
    const st = sp.style, ings = sp.ings || new Set(), has = k => ings.has(k), main = sp.main || '#E9B970';
    if (st === 'curry'){
      plate(g, 36, 88, 32, '#E8A85A');
      g.save(); g.beginPath(); g.ellipse(0, 36, 70, 24, 0, 0, TAU); g.clip();
      g.beginPath(); g.moveTo(-8, -10); g.bezierCurveTo(30, -12, 80, 0, 80, 30); g.lineTo(80, 70); g.lineTo(-20, 70); g.bezierCurveTo(-30, 40, -10, 20, -8, -10); paint(g, lin(g, 0, 10, 60, 60, [[0, '#D08A36'], [1, '#7A4416']]), 0);
      scatter(g, ['carrot', 'potato', has('beef') ? 'beef' : has('chicken') && !has('flour') ? 'chicken' : 'onion'], 7, 40, 34, 26, 12, 1.15, 5);
      glint(g, 30, 22, 10, 2.5, -.2, .5); glint(g, 52, 42, 7, 2, -.2, .4); g.restore();
      riceMound(g, -32, 30, 40, 22, 3);
      if (has('flour') && has('egg')) for (let i = 0; i < 4; i++){ const x = -10 + i * 15; g.save(); g.translate(x, 18 + i * 2); g.rotate(-.35); rr(g, -7, -16, 14, 30, 3); paint(g, lin(g, -7, 0, 7, 0, [[0, '#F2B85A'], [1, '#C8822E']]), 1.6); speckle(g, 10, 0, 0, 5, 13, 1.2, '#FFE2A0', i); rr(g, -7, -16, 3, 30, 1.5); g.fillStyle = '#FFF2E2'; g.fill(); g.restore(); }
      ell(g, -66, 44, 8, 4, '#E8404A', 1.2); return; }
    if (st === 'pasta'){ plate(g, 38, 82, 30, '#E8A85A');
      for (let i = 0; i < 14; i++){ const a = i / 14 * TAU; for (const [lw, col, dy] of [[3.6, '#E8B84A', 0], [1.6, '#FFE9A8', -1]]){ g.beginPath(); g.ellipse(Math.cos(a) * 6, 26 + dy + Math.sin(a) * 2, 46 - (i % 3) * 7, 15 - (i % 3) * 3, Math.sin(i) * .2, Math.PI * (1 + (i % 4) * .1), Math.PI * (2.6 + (i % 3) * .2)); line(g, lw, col); } }
      if (has('tomato')){ g.beginPath(); g.ellipse(0, 16, 28, 9, 0, 0, TAU); paint(g, rad(g, 0, 16, 28, [[0, '#FF6A4A'], [1, '#C8281E']], -6, -3), 1.6); speckle(g, 6, 0, 16, 18, 5, 2, '#FF9A80', 2); glint(g, -8, 12, 8, 2, -.1, .5); garnish(g, 'spinach', 10, 8, .8, -.6); garnish(g, 'spinach', 18, 12, .7, .4); }
      else if (has('egg')){ speckle(g, 14, 0, 22, 34, 9, 2.2, '#FFF4C8', 4); scatter(g, ['bacon'], 6, 0, 18, 30, 8, .8, 5); speckle(g, 22, 0, 20, 34, 10, .9, '#3A2A2A', 6); }
      if (has('cheese')) speckle(g, 16, 0, 14, 22, 6, 1.6, '#FFF6D8', 7); return; }
    if (st === 'guac'){ bowl(g, {y: 4, c1: '#77738A', c2: '#4E4A60', band: '#3A3648', pattern: 'stripe'}, (g, cy, rx, ry) => { fillAll(g, lin(g, 0, cy - ry, 0, cy + ry, [[0, '#B8DC7A'], [1, '#7DB54A']])); speckle(g, 24, 0, cy, rx, ry, 4, 'rgba(225,245,170,.8)', 2); scatter(g, ['tomato', 'onion'], 8, 0, cy, rx * .8, ry * .7, .7, 3); });
      for (const [x, r] of [[-38, -.5], [30, .4], [46, .9]]){ g.save(); g.translate(x, -14); g.rotate(r); g.beginPath(); g.moveTo(-11, 10); g.lineTo(11, 10); g.lineTo(0, -16); g.closePath(); paint(g, lin(g, 0, -16, 0, 10, [[0, '#FFE08A'], [1, '#F2B33A']]), 1.8); speckle(g, 5, 0, 2, 5, 6, 1, '#E8A030', 2); g.restore(); }
      garnish(g, 'lemon', 50, 0, 1); return; }
    const pal = st === 'ramen' ? {c1: '#3A3550', c2: '#221E33', band: '#E8404A', pattern: 'stripe'} : st === 'don' ? {c1: '#3A3550', c2: '#221E33', band: '#D9A040', pattern: 'wave'} : st === 'mac' ? {c1: '#FFE3EC', c2: '#F2B3C8', band: '#FFFFFF', pattern: 'dots'} : {pattern: 'wave'};
    bowl(g, {y: 2, ...pal}, (g, cy, rx, ry) => {
      if (st === 'ramen'){ fillAll(g, rad(g, 0, cy, rx, [[0, lighten(main, .25)], [1, darken(main, .1)]], -rx * .2, -ry * .3));
        for (let i = 0; i < 9; i++){ const yy = cy - ry * .15 + i * ry * .13; for (const [lw, col, dy] of [[3.6, '#F3D27E', 0], [1.1, 'rgba(255,250,220,.9)', -1]]){ g.beginPath(); for (let x = -rx; x <= rx; x += 6) g.lineTo(x, yy + dy + Math.sin(x / 7 + i * 1.3) * 2.6); line(g, lw, col); } }
        for (const [x, y, r] of [[-.5, -.4, 3], [.4, -.5, 2.4], [-.1, -.7, 2], [.65, -.1, 1.8], [-.75, -.05, 2.2]]) ring(g, x * rx, cy + y * ry, r, 1.2, 'rgba(255,240,190,.9)');
        g.save(); g.translate(-rx * .72, cy - ry * .35); g.rotate(-.15); rr(g, -8, -14, 16, 24, 2); paint(g, lin(g, -8, 0, 8, 0, [[0, '#2E4A3A'], [1, '#14201A']]), 1.4); g.restore();
        if (has('chicken')){ for (const [x, r] of [[-.35, -.2], [-.12, .2]]) garnish(g, 'chicken', x * rx, cy - ry * .2, 1.3, r); }
        else { g.beginPath(); g.arc(-rx * .28, cy - ry * .25, 13, 0, TAU); paint(g, rad(g, -rx * .28, cy - ry * .25, 13, [[0, '#F2C8A8'], [.7, '#C97E5A'], [1, '#8A4A2A']]), 1.4); g.beginPath(); g.arc(-rx * .28, cy - ry * .25, 8, 0, TAU); line(g, 1.4, 'rgba(255,230,210,.8)'); }
        if (has('egg')){ g.save(); g.translate(rx * .4, cy - ry * .2); g.beginPath(); g.ellipse(0, 0, 14, 10, -.2, 0, TAU); paint(g, '#FFFFFF', 1.5); g.beginPath(); g.ellipse(-1, 0, 8, 6, -.2, 0, TAU); paint(g, rad(g, -1, 0, 8, [[0, '#FFA12E'], [.7, '#F27A1E'], [1, '#FFC24A']]), 1); glint(g, -3, -2, 2.4, 1.2); g.restore(); }
        else { g.beginPath(); g.arc(rx * .38, cy - ry * .25, 9, 0, TAU); paint(g, '#FFFFFF', 1.4); g.beginPath(); for (let k = 0; k < 24; k++){ const a = k / 24 * TAU * 2, d = 1 + k * .28; g.lineTo(rx * .38 + Math.cos(a) * d, cy - ry * .25 + Math.sin(a) * d); } line(g, 1.6, '#FF7EA6'); }
        scatter(g, extras(sp, ['egg', 'chicken', 'beef']), 4, rx * .1, cy + ry * .35, rx * .45, ry * .25, .8, 4);
        for (let i = 0; i < 9; i++) ring(g, -rx * .6 + i * rx * .15, cy + ry * (.05 + (i % 3) * .14), 2.3, 1.4, '#6BBF59');
        return; }
      if (st === 'don'){ fillAll(g, '#FFFDF6'); grains(g, 50, 0, cy, rx, ry, 4); const rng = rngFor(6);
        for (let i = 0; i < 9; i++){ const a = rng() * TAU, d = Math.sqrt(rng()) * .75, x = Math.cos(a) * rx * d, y = cy + Math.sin(a) * ry * d; g.beginPath(); g.ellipse(x, y, 13, 7, rng(), 0, TAU); paint(g, rad(g, x, y, 13, [[0, '#FFE680'], [1, '#F6B83A']]), 1.2); }
        scatter(g, ['chicken', 'onion'], 7, 0, cy, rx * .7, ry * .7, .8, 7); garnish(g, 'spinach', 8, cy - 4, .7, -.4); return; }
      if (st === 'mac'){ fillAll(g, rad(g, 0, cy, rx, [[0, '#FFD45A'], [1, '#F2A21E']], -10, -6)); const rng = rngFor(8);
        for (let i = 0; i < 26; i++){ const a = rng() * TAU, d = Math.sqrt(rng()), x = Math.cos(a) * rx * d, y = cy + Math.sin(a) * ry * d, s0 = rng() * TAU; g.beginPath(); g.arc(x, y, 5, s0, s0 + 3.4); line(g, 4.2, '#F7C24A'); g.beginPath(); g.arc(x, y - .6, 5, s0 + .4, s0 + 1.6); line(g, 1.2, '#FFF4C8'); }
        glint(g, -rx * .3, cy - ry * .3, 10, 2.5, -.1, .5); return; }
      if (st === 'smooth'){ fillAll(g, rad(g, 0, cy, rx, [[0, lighten(main, .2)], [1, darken(main, .1)]], -rx * .2, -ry * .3));
        g.beginPath(); for (let k = 0; k < 40; k++){ const a = k / 40 * TAU * 2.2, d = 3 + k * .7; g.lineTo(Math.cos(a) * d, cy + Math.sin(a) * d * .38); } line(g, 3, 'rgba(255,255,255,.85)');
        if (has('pumpkin')) for (let i = 0; i < 6; i++) ell(g, -14 + i * 6, cy - 6 + (i % 2) * 3, 2.2, 1.3, '#5E9A3A', 0, i);
        if (has('corn')) garnish(g, 'corn', 16, cy - 2, .9); if (has('mushroom')) garnish(g, 'mushroom', 16, cy - 3, .9);
        if (has('tomato')){ garnish(g, 'spinach', 14, cy - 4, .8, -.5); garnish(g, 'spinach', 22, cy - 2, .7, .4); }
        if (has('bread') || has('cream')) for (const [x, y] of [[-26, -3], [-18, 4], [28, 3]]){ rr(g, x - 4, cy + y - 4, 8, 8, 2); paint(g, '#F2C47A', 1.1); }
        speckle(g, 10, 0, cy, rx * .6, ry * .5, .9, '#5E9A3A', 9); return; }
      if (st === 'porridge'){ fillAll(g, rad(g, 0, cy, rx, [[0, '#FBEED2'], [1, '#E2CBA0']])); speckle(g, 40, 0, cy, rx, ry, 2, 'rgba(200,170,120,.55)', 2);
        const fr = extras(sp, ['honey']); scatter(g, fr.length ? fr : ['blueberry'], 6, rx * .1, cy - 2, rx * .55, ry * .5, .9, 3); if (has('honey')) drizzle(g, '#F6B73C', -rx * .6, cy + ry * .3, rx * .8, 3, 3); return; }
      if (st === 'rice'){ fillAll(g, '#FFFDF6'); grains(g, 70, 0, cy, rx, ry, 5); speckle(g, 8, 0, cy, rx * .5, ry * .5, .9, '#2A2A2A', 4); return; }
      if (st === 'batter'){ const bc = has('chocolate') ? '#8A5A40' : has('egg') ? '#FBE4A6' : main; fillAll(g, rad(g, 0, cy, rx, [[0, lighten(bc, .2)], [1, darken(bc, .06)]])); g.beginPath(); g.arc(0, cy, rx * .5, .2, Math.PI * 1.6); line(g, 3, 'rgba(255,255,255,.6)'); glint(g, -rx * .3, cy - ry * .3, 9, 2.4, -.1, .5); return; }
      if (st === 'mash'){ fillAll(g, '#FFF0C8'); return; }
      fillAll(g, rad(g, 0, cy, rx, [[0, lighten(main, .15)], [1, darken(main, .15)]], -rx * .2, -ry * .3));
      const k = extras(sp); scatter(g, k.length ? k : ['carrot'], 9, 0, cy, rx * .8, ry * .7, 1.1, 6); glint(g, -rx * .35, cy - ry * .35, 10, 2.4, -.1, .45);
    });
    if (st === 'mash'){ for (let i = 0; i < 3; i++){ g.beginPath(); g.ellipse(0, -i * 9, 46 - i * 12, 15 - i * 2, 0, 0, TAU); paint(g, lin(g, 0, -16 - i * 9, 0, 14 - i * 9, [[0, '#FFF8E2'], [1, '#F2DCA0']]), 2); } garnish(g, 'butter', 0, -26, 1); }
  },
  salad(g, sp){
    const fruit = sp.style === 'fruit', ings = sp.ings || new Set();
    bowl(g, fruit ? {y: 6, c1: '#FFE9F1', c2: '#F6B8CE', band: '#FFFFFF', pattern: 'dots'} : {y: 6, c1: '#EBB878', c2: '#B97A3E', band: '#9A5A2A', pattern: 'stripe'}, g => fillAll(g, fruit ? '#FFF6E8' : '#5E9A3A'));
    const rng = rngFor(11);
    if (!fruit) for (let i = 0; i < 14; i++){ const x = -50 + (i % 7) * 16 + rng() * 6, y = 2 - Math.floor(i / 7) * 10 - rng() * 6; g.save(); g.translate(x, y); g.rotate(rng() * 2 - 1); g.beginPath(); g.moveTo(-16, 0); for (let k = 0; k <= 8; k++){ const a = Math.PI + k / 8 * Math.PI; g.lineTo(Math.cos(a) * 16 + (k % 2) * 1.5, Math.sin(a) * 9 - (k % 2) * 2); } g.quadraticCurveTo(0, 6, -16, 0); paint(g, lin(g, 0, -9, 0, 4, [[0, i % 3 ? '#A8E07A' : '#7CC85A'], [1, '#4E9E40']]), 1.5); g.beginPath(); g.moveTo(-12, 0); g.lineTo(12, -2); line(g, 1, 'rgba(255,255,255,.75)'); g.restore(); }
    const keys = fruit ? [...ings].filter(k => FRUIT.has(k)) : extras(sp, ['lettuce', 'spinach', 'cabbage']);
    scatter(g, keys.length ? keys : ['tomato'], fruit ? 14 : 9, 0, -6, 46, 13, fruit ? 1.25 : 1.1, 12);
    if (ings.has('honey')) drizzle(g, '#F6B73C', -30, -12, 60, 3, 3);
  },
  stack(g, sp){
    const st = sp.style, ings = sp.ings || new Set();
    plate(g, 46);
    if (st === 'crepe'){ for (const [sd, rot] of [[-1, -.08], [1, .08]]){ g.save(); g.translate(sd * 4, 40); g.rotate(rot); g.beginPath(); g.moveTo(0, 0); g.lineTo(sd * 62, -6); g.quadraticCurveTo(sd * 46, -50, 0, -40); g.closePath(); paint(g, lin(g, 0, -40, sd * 60, 0, [[0, '#FBE2A8'], [1, '#E8B464']]), 2.2); speckle(g, 8, sd * 26, -16, 14, 10, 2.4, 'rgba(200,130,50,.35)', sd + 3); g.restore(); }
      const f = ['strawberry', 'banana', 'blueberry'].filter(k => ings.has(k)); scatter(g, f.length ? f : ['strawberry'], 5, 0, 20, 34, 6, 1.1, 3);
      if (ings.has('chocolate')) drizzle(g, '#5A2E1E', -34, 4, 68, 4, 5); if (ings.has('cream')) garnish(g, 'cream', 0, 6, 1.5); speckle(g, 30, 0, -4, 52, 20, .9, '#FFFFFF', 4); return; }
    if (st === 'okonomi'){ g.beginPath(); g.ellipse(0, 36, 60, 20, 0, 0, TAU); paint(g, '#C8823A'); g.fillStyle = '#C8823A'; g.fillRect(-60, 24, 120, 12); g.beginPath(); g.ellipse(0, 24, 60, 20, 0, 0, TAU); paint(g, rad(g, 0, 24, 60, [[0, '#7A3A1A'], [1, '#4A2010']], -12, -6));
      g.beginPath(); g.moveTo(-60, 24); g.lineTo(-60, 36); g.moveTo(60, 24); g.lineTo(60, 36); line(g); glint(g, -18, 16, 14, 3, -.15, .5);
      g.beginPath(); for (let x = -42; x <= 42; x += 7) g.lineTo(x, 24 + ((x + 42) / 7 % 2 ? -7 : 7)); line(g, 2.6, '#FFFDF2'); const rng = rngFor(4);
      for (let i = 0; i < 9; i++){ g.save(); g.translate((rng() - .5) * 70, 18 + (rng() - .5) * 18); g.rotate(rng() * 3); g.beginPath(); g.moveTo(-6, 0); g.quadraticCurveTo(0, -6, 6, 0); g.quadraticCurveTo(0, -2, -6, 0); g.fillStyle = '#F6D2A8'; g.fill(); line(g, .8, '#C88A5A'); g.restore(); }
      speckle(g, 18, 0, 22, 44, 12, 1.1, '#5E9A3A', 6); ell(g, 44, 34, 7, 4, '#E8404A', 1.2); return; }
    if (st === 'dorayaki'){ for (const y of [36, 16]){ g.beginPath(); g.ellipse(0, y, 50, 17, 0, 0, TAU); paint(g, rad(g, 0, y, 50, [[0, '#E8A04A'], [.65, '#C27A30'], [.85, '#A8602A'], [1, '#F6CF8A']], -10, -4), 2.4); if (y === 36){ g.beginPath(); g.ellipse(0, 28, 46, 14, 0, 0, TAU); paint(g, '#5A1E28', 2); speckle(g, 10, 0, 28, 40, 6, 2, '#7A2E3A', 3); } }
      glint(g, -14, 10, 12, 3, -.15, .45); ring(g, 0, 15, 8, 2, 'rgba(255,230,190,.6)'); return; }
    const choc = st === 'choc', top = choc ? '#6A3A26' : '#E9A848', side = choc ? '#8A5236' : '#F6D59A';
    for (let i = 0; i < 4; i++){ const y = 38 - i * 13;
      g.beginPath(); g.ellipse(0, y + 9, 56, 16, 0, 0, Math.PI); g.lineTo(-56, y); g.ellipse(0, y, 56, 16, 0, Math.PI, 0, true); g.closePath(); paint(g, lin(g, 0, y, 0, y + 25, [[0, side], [1, darken(side, .18)]]));
      g.beginPath(); g.ellipse(0, y, 56, 16, 0, 0, TAU); paint(g, rad(g, 0, y, 56, [[0, lighten(top, .12)], [.75, top], [1, darken(top, .2)]], -10, -4)); }
    const ty = 38 - 3 * 13; speckle(g, 10, 0, ty, 38, 9, 2.4, choc ? 'rgba(40,15,8,.4)' : 'rgba(170,90,30,.35)', 5);
    if (ings.has('syrup') || ings.has('honey')){ const sc = ings.has('syrup') ? '#B4642A' : '#F6B73C'; g.beginPath(); g.ellipse(0, ty, 34, 9, 0, 0, TAU); g.fillStyle = sc; g.fill(); for (const [x, h] of [[-40, 30], [-14, 44], [26, 36], [46, 22]]){ rr(g, x - 3.5, ty + 4, 7, h, 3.5); g.fill(); } glint(g, -10, ty - 3, 10, 2, -.1, .6); }
    if (ings.has('butter')) garnish(g, 'butter', 2, ty - 5, 1.2);
    const fr = ['strawberry', 'blueberry', 'banana', 'chocolate'].filter(k => ings.has(k)); scatter(g, fr, fr.length * 3, 0, ty - 2, 34, 7, 1.1, 8);
    if (ings.has('cream')) garnish(g, 'cream', -22, ty - 6, 1.3);
    speckle(g, 22, 0, ty, 44, 10, .8, '#FFFFFF', 9);
  },
  egg(g, sp){
    const st = sp.style; plate(g, 38);
    if (st === 'scramble'){ const rng = rngFor(3); for (let i = 0; i < 13; i++){ const x = (rng() - .5) * 76, y = 30 + (rng() - .5) * 18 - (i > 8 ? 8 : 0); g.beginPath(); g.ellipse(x, y, 13, 9, rng(), 0, TAU); paint(g, rad(g, x, y, 13, [[0, '#FFF0A0'], [1, '#F6C83A']], -3, -3), 1.4); } for (let i = 0; i < 8; i++) ring(g, -30 + i * 9, 24 + (i % 3) * 5, 2, 1.4, '#5E9A3A'); return; }
    if (st === 'omelette'){ g.beginPath(); g.moveTo(-54, 32); g.quadraticCurveTo(-30, -16, 4, -14); g.quadraticCurveTo(46, -12, 54, 32); g.quadraticCurveTo(0, 46, -54, 32); paint(g, lin(g, 0, -14, 0, 40, [[0, '#FFE268'], [1, '#F2B22A']])); glint(g, -16, 2, 16, 4, -.25, .55);
      g.beginPath(); for (let x = -28; x <= 28; x += 6) g.lineTo(x, 12 + ((x + 28) / 6 % 2 ? -4 : 4)); line(g, 4, '#D8301E'); scatter(g, extras(sp, ['egg', 'milk']), 4, 0, 36, 34, 4, .7, 2); garnish(g, 'spinach', 34, 4, .7, -.4); return; }
    if (st === 'tamago'){ woodBoard(g, 42, 150, 34); for (let i = 0; i < 4; i++){ const x = -51 + i * 34; rr(g, x - 14, 0, 28, 30, 5); paint(g, lin(g, 0, 0, 0, 30, [[0, '#FFE680'], [1, '#F2B83A']])); g.beginPath(); for (let k = 0; k < 26; k++){ const a = k / 26 * TAU * 2.3, d = 1 + k * .45; g.lineTo(x + Math.cos(a) * d, 15 + Math.sin(a) * d * 1.1); } line(g, 1.6, '#D99A1E'); glint(g, x - 6, 4, 5, 1.5, 0, .7); } return; }
    friedEgg(g, -6, 26);
    if (st === 'bacon') for (let j = 0; j < 2; j++) bacon2(g, 40, 22 + j * 12); else speckle(g, 6, -4, 22, 14, 6, .8, '#3A2A2A', 4);
  },
  toast(g, sp){
    const st = sp.style, ings = sp.ings || new Set(), bc = '#E2A55A';
    plate(g, 46);
    const slice = (ox, oy, sc, toasted = .6) => { g.save(); g.translate(ox, oy); g.scale(sc, sc);
      g.beginPath(); g.moveTo(-36, 32); g.lineTo(-36, -14); g.arc(-18, -20, 19, Math.PI * .95, Math.PI * 1.9); g.arc(18, -20, 19, Math.PI * 1.1, Math.PI * .05); g.lineTo(36, 32); g.closePath(); paint(g, lin(g, 0, -40, 0, 32, [[0, '#C8782E'], [1, '#9A5420']]));
      rr(g, -29, -22, 58, 50, 9); g.fillStyle = rad(g, 0, 2, 40, [[0, lerpC('#FFF0D2', bc, toasted)], [1, lerpC('#F6DDB0', '#C8823A', toasted)]]); g.fill();
      speckle(g, 16, 0, 2, 24, 20, 1.1, 'rgba(170,100,40,.35)', 3); g.restore(); };
    if (st === 'honey'){ g.beginPath(); g.moveTo(-36, -8); g.lineTo(-10, -24); g.lineTo(38, -24); g.lineTo(38, 26); g.lineTo(14, 42); g.lineTo(-36, 42); g.closePath(); paint(g, '#C8823A');
      g.beginPath(); g.rect(-36, -8, 50, 50); paint(g, lin(g, -36, -8, 14, 42, [[0, '#F6D29A'], [1, '#E2A55A']])); g.beginPath(); g.moveTo(-36, -8); g.lineTo(-10, -24); g.lineTo(38, -24); g.lineTo(14, -8); g.closePath(); paint(g, '#F2C27A');
      for (let i = 0; i < 3; i++) for (let j = 0; j < 3; j++){ rr(g, -32 + i * 16, -4 + j * 15, 12, 11, 2); g.fillStyle = 'rgba(200,130,50,.25)'; g.fill(); }
      g.beginPath(); g.ellipse(4, -16, 20, 6, 0, 0, TAU); g.fillStyle = '#F6B73C'; g.fill(); for (const [x, h] of [[-30, 20], [-12, 34], [8, 16]]){ rr(g, x - 3, -8, 6, h, 3); g.fill(); } glint(g, -2, -18, 8, 1.6, 0, .6);
      for (let i = 0; i < 3; i++){ g.beginPath(); g.ellipse(6, -28 - i * 8, 16 - i * 4, 6, 0, 0, TAU); paint(g, '#FFFFFF', 1.8); } garnish(g, 'cherry', 8, -50, 1); return; }
    if (st === 'grilled'){ slice(-10, 12, 1, .8); g.beginPath(); g.moveTo(-32, 34); g.quadraticCurveTo(-36, 48, -26, 47); g.lineTo(-6, 44); g.quadraticCurveTo(0, 54, 6, 44); g.lineTo(26, 42); g.quadraticCurveTo(36, 46, 30, 32); paint(g, '#FFD03A', 1.6); slice(10, 2, 1, .85); for (let i = 0; i < 3; i++){ g.beginPath(); g.moveTo(-10 + i * 14, -14); g.lineTo(2 + i * 14, 24); line(g, 3, 'rgba(120,60,20,.35)'); } return; }
    slice(0, 8, 1, st === 'french' ? .9 : .65);
    if (st === 'egg'){ g.save(); g.translate(0, 8); g.beginPath(); for (let k = 0; k <= 20; k++){ const a = k / 20 * TAU, r = 22 + Math.sin(a * 5) * 2; g.lineTo(Math.cos(a) * r, Math.sin(a) * r * .8); } g.closePath(); paint(g, '#FFFFFF', 1.8); g.beginPath(); g.ellipse(-1, -1, 9, 8, 0, 0, TAU); paint(g, rad(g, -1, -1, 10, [[0, '#FFC94A'], [1, '#F28A1E']], -2, -2), 1.6); glint(g, -4, -4, 3, 1.6); g.restore(); }
    else if (st === 'avo'){ g.save(); g.translate(0, 10); for (let i = 0; i < 5; i++){ g.save(); g.translate(-18 + i * 9, 0); g.rotate(.3); g.beginPath(); g.ellipse(0, 0, 6, 16, 0, 0, TAU); paint(g, lin(g, -6, 0, 6, 0, [[0, '#E6F2A0'], [.7, '#9CCB5A'], [1, '#5E9A3A']]), 1.4); g.restore(); } speckle(g, 8, 0, 0, 20, 12, 1.2, '#D8301E', 3); speckle(g, 10, 0, 0, 20, 12, .8, '#2A2A2A', 4); g.restore(); if (ings.has('egg')) garnish(g, 'egg', 18, -8, 1.1); }
    else if (st === 'cheese'){ rr(g, -26, -14, 52, 40, 8); paint(g, lin(g, 0, -14, 0, 26, [[0, '#FFE268'], [1, '#F6B83A']]), 2); glint(g, -10, -6, 10, 2.5, -.1, .5); }
    else if (st === 'french'){ speckle(g, 16, 0, 6, 22, 18, 1.4, '#FFFFFF', 3); const f = ['strawberry', 'blueberry', 'banana'].filter(k => ings.has(k)); scatter(g, f.length ? f : ['strawberry'], 4, 0, 24, 30, 6, 1.1, 2); if (ings.has('syrup')) drizzle(g, '#B4642A', -24, 0, 48, 3, 5); }
    else { if (ings.has('butter')) garnish(g, 'butter', 0, 6, 1.4); if (ings.has('honey')) drizzle(g, '#F6B73C', -22, 0, 44, 3, 5); }
  },
  sandwich(g, sp){ plate(g, 46); const layers = (sp.tops && sp.tops.length ? sp.tops : ['#8ED16B', '#F24B3B']).slice(0, 4);
    for (const [ox, sc] of [[-22, 1], [22, -1]]){ g.save(); g.translate(ox, 24); g.scale(sc, 1); g.beginPath(); g.moveTo(-28, 18); g.lineTo(28, 18); g.lineTo(-28, -36); g.closePath(); paint(g, '#F8E6BC'); layers.forEach((c, i) => { g.beginPath(); g.moveTo(-28, 12 - i * 7); g.lineTo(20 - i * 5, 12 - i * 7); line(g, 6, c); }); g.beginPath(); g.moveTo(-28, 18); g.lineTo(28, 18); g.lineTo(-28, -36); g.closePath(); line(g, 3, '#C8823A'); g.restore(); } },
  burger(g, sp){
    const ings = sp.ings || new Set(); plate(g, 50);
    g.beginPath(); g.ellipse(0, 40, 48, 12, 0, 0, TAU); paint(g, lin(g, 0, 28, 0, 52, [[0, '#F2B062'], [1, '#C8823A']]));
    g.beginPath(); g.ellipse(0, 26, 52, 14, 0, 0, TAU); paint(g, rad(g, 0, 26, 52, [[0, '#8A4A30'], [1, '#4A2416']], -10, -4)); speckle(g, 16, 0, 26, 44, 10, 1.4, 'rgba(160,90,60,.6)', 2);
    if (ings.has('cheese')){ g.beginPath(); g.moveTo(-50, 16); g.lineTo(50, 16); g.lineTo(42, 22); g.lineTo(30, 34); g.lineTo(20, 22); g.lineTo(-2, 32); g.lineTo(-16, 22); g.lineTo(-34, 30); g.lineTo(-42, 20); g.closePath(); paint(g, lin(g, 0, 14, 0, 34, [[0, '#FFE268'], [1, '#F6B22A']]), 2); }
    if (ings.has('tomato')) for (const x of [-22, 18]){ g.beginPath(); g.ellipse(x, 12, 20, 6, 0, 0, TAU); paint(g, '#E8402E', 1.8); g.beginPath(); g.ellipse(x, 11, 15, 4, 0, 0, TAU); g.fillStyle = '#FF8A70'; g.fill(); }
    g.beginPath(); g.moveTo(-54, 8); for (let x = -54; x <= 54; x += 6) g.lineTo(x, 8 + ((x + 54) / 6 % 2 ? -5 : 4)); g.lineTo(54, 2); g.lineTo(-54, 2); g.closePath(); paint(g, lin(g, 0, 0, 0, 12, [[0, '#B8E888'], [1, '#5EAE40']]), 1.8);
    g.beginPath(); g.moveTo(-50, 4); g.quadraticCurveTo(-50, -40, 0, -40); g.quadraticCurveTo(50, -40, 50, 4); g.closePath(); paint(g, rad(g, -10, -22, 56, [[0, '#FFD08A'], [.6, '#F2A84A'], [1, '#C8782E']], -8, -8), 2.6);
    const rng = rngFor(5); for (let i = 0; i < 12; i++){ const a = Math.PI * (1.1 + rng() * .8), d = 16 + rng() * 22; ell(g, Math.cos(a) * d * 1.2, -12 + Math.sin(a) * d * .9, 3.2, 1.6, '#FFF6D8', 0, rng() * 3); }
    glint(g, -20, -26, 12, 4, -.4, .6);
  },
  hotdog(g, sp){ plate(g, 42); rr(g, -60, 14, 120, 32, 16); paint(g, lin(g, 0, 14, 0, 46, [[0, '#F6C27A'], [1, '#D08A3A']])); rr(g, -66, 6, 132, 20, 10); paint(g, lin(g, 0, 6, 0, 26, [[0, '#E8705A'], [1, '#A83A28']])); glint(g, -30, 11, 22, 2.5, 0, .55);
    g.beginPath(); for (let x = -50; x <= 50; x += 7) g.lineTo(x, 14 + ((x + 50) / 7 % 2 ? -4 : 4)); line(g, 3.6, '#FFD23A'); if ((sp.ings || new Set()).has('onion')) speckle(g, 10, 0, 10, 46, 3, 1.6, '#FFF6E8', 3);
    rr(g, -60, 22, 120, 24, 12); g.fillStyle = lin(g, 0, 22, 0, 46, [[0, '#F2B062'], [1, '#C8823A']]); g.fill(); line(g); glint(g, -36, 28, 16, 3, 0, .45); },
  taco(g, sp){
    const st = sp.style; plate(g, 46);
    if (st === 'quesadilla'){ for (const [ox, rot] of [[-24, -.35], [10, .1], [36, .55]]){ g.save(); g.translate(ox, 30); g.rotate(rot); g.beginPath(); g.moveTo(-26, 10); g.lineTo(26, 10); g.lineTo(0, -28); g.closePath(); paint(g, lin(g, 0, -28, 0, 10, [[0, '#F6D29A'], [1, '#E2A55A']])); g.beginPath(); g.moveTo(-24, 9); g.lineTo(24, 9); line(g, 4, '#FFD03A'); speckle(g, 6, 0, -4, 10, 10, 1.6, 'rgba(160,90,40,.45)', ox); g.restore(); } return; }
    if (st === 'wrap'){ for (const ox of [-26, 26]){ g.beginPath(); g.ellipse(ox, 22, 22, 26, 0, 0, TAU); paint(g, '#F2D49B'); g.beginPath(); g.ellipse(ox, 22, 16, 19, 0, 0, TAU); g.fillStyle = '#FFF6E0'; g.fill(); const k = extras(sp); scatter(g, k.length ? k : ['egg'], 6, ox, 22, 12, 14, .8, ox + 50); } return; }
    for (const [ox, sc] of [[-28, .92], [26, 1]]){ g.save(); g.translate(ox, 30); g.scale(sc, sc);
      g.save(); g.beginPath(); g.moveTo(-34, 8); g.arc(0, 8, 34, Math.PI, TAU); g.closePath(); g.clip(); g.fillStyle = '#6A3A22'; g.fillRect(-40, -30, 80, 30); speckle(g, 12, 0, -8, 26, 6, 3, '#8A4A2A', 3);
      for (let i = 0; i < 10; i++){ g.save(); g.translate(-24 + i * 5.5, -14 - (i % 3) * 3); g.rotate(-.5 + (i % 4) * .3); rr(g, -2, -7, 4, 14, 2); g.fillStyle = i % 2 ? '#8ED16B' : '#B8E888'; g.fill(); g.restore(); }
      speckle(g, 10, 0, -14, 24, 5, 2.4, '#FFD03A', 4); speckle(g, 6, 0, -16, 22, 5, 2.8, '#E8402E', 5); g.restore();
      g.beginPath(); g.moveTo(-34, 8); g.arc(0, 8, 34, Math.PI, TAU); g.arc(0, 8, 26, TAU, Math.PI, true); g.closePath(); paint(g, lin(g, 0, -26, 0, 8, [[0, '#FFE08A'], [1, '#F2B33A']])); speckle(g, 8, 0, -12, 26, 14, 1.3, 'rgba(200,120,30,.5)', 6); g.restore(); }
  },
  pizza(g, sp){
    const ings = sp.ings || new Set(); woodBoard(g, 44, 176, 44);
    g.beginPath(); g.ellipse(0, 26, 76, 34, 0, 0, TAU); paint(g, rad(g, 0, 26, 76, [[0, '#F6D29A'], [.85, '#E8A85A'], [1, '#C8782E']]), 2.4);
    speckle(g, 16, 0, 26, 74, 32, 2.2, 'rgba(140,70,20,.4)', 2);
    g.beginPath(); g.ellipse(0, 24, 64, 27, 0, 0, TAU); g.fillStyle = rad(g, 0, 24, 64, [[0, '#F0503A'], [1, '#C8281E']]); g.fill();
    const rng = rngFor(3); for (let i = 0; i < 16; i++){ const a = rng() * TAU, d = Math.sqrt(rng()) * .82, x = Math.cos(a) * 60 * d, y = 24 + Math.sin(a) * 25 * d; g.beginPath(); g.ellipse(x, y, 11 + rng() * 5, 6 + rng() * 2, rng(), 0, TAU); g.fillStyle = rad(g, x, y, 12, [[0, '#FFF6D0'], [1, '#FFD86A']]); g.fill(); }
    if (ings.has('sausage')) for (let i = 0; i < 9; i++){ const a = rng() * TAU, d = .25 + rng() * .6, x = Math.cos(a) * 58 * d, y = 24 + Math.sin(a) * 24 * d; g.beginPath(); g.ellipse(x, y, 7, 4.4, 0, 0, TAU); paint(g, rad(g, x, y, 7, [[0, '#E8604A'], [1, '#A8301E']], -2, -1), 1.2); speckle(g, 3, x, y, 4, 2, .8, '#7A1E14', i); }
    const tp = extras(sp, ['tomato', 'cheese', 'sausage']); if (tp.length) scatter(g, tp, 8, 0, 24, 54, 20, .8, 7);
    if (!ings.has('sausage')) for (const [x, y, r] of [[-20, 14, .4], [18, 30, -.6], [30, 12, 1.2]]) garnish(g, 'spinach', x, y, .8, r);
    for (let i = 0; i < 3; i++){ const a = i * Math.PI / 3; g.beginPath(); g.moveTo(Math.cos(a) * -66, 26 + Math.sin(a) * -29); g.lineTo(Math.cos(a) * 66, 26 + Math.sin(a) * 29); line(g, 1.4, 'rgba(120,50,20,.35)'); }
    glint(g, -30, 12, 14, 3, -.2, .35);
  },
  maki(g, sp){
    woodBoard(g, 46, 172, 46);
    const fills = (sp.tops && sp.tops.length ? sp.tops : ['#F4895A']).slice(0, 3);
    for (const [x, y] of [[-54, 22], [-18, 22], [18, 22], [-36, 44], [0, 44], [36, 44]]){
      g.beginPath(); g.moveTo(x - 16, y - 14); g.lineTo(x - 16, y + 2); g.ellipse(x, y + 2, 16, 8, 0, Math.PI, 0, true); g.lineTo(x + 16, y - 14); g.closePath(); paint(g, lin(g, x - 16, 0, x + 16, 0, [[0, '#3E5E4A'], [.4, '#22362A'], [1, '#121C16']]), 2);
      g.beginPath(); g.ellipse(x, y - 14, 16, 8, 0, 0, TAU); paint(g, '#1E2B24', 2); g.beginPath(); g.ellipse(x, y - 14, 13.6, 6.6, 0, 0, TAU); g.fillStyle = '#FDFAF3'; g.fill(); grains(g, 10, x, y - 14, 12, 5.6, x + y);
      fills.forEach((c, j) => { const a = j / fills.length * TAU, dd = fills.length > 1 ? 3.6 : 0; g.beginPath(); g.ellipse(x + Math.cos(a) * dd, y - 14 + Math.sin(a) * dd * .5, 4.6, 3, 0, 0, TAU); paint(g, c, 1); });
      g.beginPath(); g.moveTo(x - 11, y - 6); g.lineTo(x - 11, y + 4); line(g, 2.5, 'rgba(255,255,255,.4)'); }
    g.beginPath(); g.moveTo(58, 34); g.quadraticCurveTo(64, 20, 72, 34); g.closePath(); paint(g, lin(g, 0, 22, 0, 34, [[0, '#A8D46A'], [1, '#6EA83A']]), 1.6);
    for (let i = 0; i < 3; i++){ g.save(); g.translate(64 + i * 3, 44 - i * 2); g.rotate(-.3 + i * .3); g.beginPath(); g.ellipse(0, 0, 8, 4, 0, 0, TAU); paint(g, 'rgba(255,190,200,.95)', 1.2); g.restore(); }
  },
  onigiri(g, sp){
    if (sp.style === 'nigiri'){ woodBoard(g, 46, 160, 40); const salmon = sp.ings && sp.ings.has('salmon'), fc = sp.main || (salmon ? '#F4895A' : '#D63B4E');
      for (const ox of [-34, 34]){ g.beginPath(); g.ellipse(ox, 34, 28, 12, 0, 0, TAU); paint(g, lin(g, 0, 22, 0, 46, [[0, '#FFFFFF'], [1, '#E8E0D0']]), 2); grains(g, 14, ox, 32, 24, 9, ox);
        g.save(); g.translate(ox, 24); g.rotate(-.06); g.beginPath(); g.moveTo(-32, 6); g.quadraticCurveTo(-30, -12, 0, -12); g.quadraticCurveTo(32, -12, 32, 6); g.quadraticCurveTo(0, 14, -32, 6); paint(g, lin(g, 0, -12, 0, 12, [[0, lighten(fc, .2)], [1, darken(fc, .08)]]), 2.2);
        g.save(); g.clip(); g.strokeStyle = salmon ? 'rgba(255,238,225,.95)' : 'rgba(255,190,200,.55)'; g.lineWidth = 2.6; for (let i = -4; i <= 4; i++){ g.beginPath(); g.moveTo(i * 8 - 6, 14); g.quadraticCurveTo(i * 8 + 2, 0, i * 8 + 6, -14); g.stroke(); } g.restore();
        glint(g, -12, -6, 10, 2.4, -.1, .65); g.restore(); }
      g.beginPath(); g.moveTo(68, 30); g.quadraticCurveTo(72, 18, 78, 30); g.closePath(); paint(g, '#8CC152', 1.4); return; }
    plate(g, 48);
    g.beginPath(); g.moveTo(0, -36); g.quadraticCurveTo(14, -36, 42, 18); g.quadraticCurveTo(50, 40, 26, 42); g.lineTo(-26, 42); g.quadraticCurveTo(-50, 40, -42, 18); g.quadraticCurveTo(-14, -36, 0, -36); paint(g, lin(g, -30, -36, 30, 42, [[0, '#FFFFFF'], [1, '#EAE2D2']]), 2.6);
    g.save(); g.clip(); grains(g, 40, 0, 8, 40, 32, 5); g.restore();
    if (sp.tops && sp.tops[0]){ g.beginPath(); g.ellipse(0, -14, 8, 5, 0, 0, TAU); paint(g, sp.tops[0], 1.4); }
    rr(g, -22, 16, 44, 26, 3); paint(g, lin(g, -22, 0, 22, 0, [[0, '#2E4A3A'], [1, '#14201A']]), 2); g.beginPath(); g.moveTo(-18, 20); g.lineTo(-18, 38); line(g, 2, 'rgba(255,255,255,.25)');
    face(g, 0, -2, .7, 'happy');
  },
  pile(g, sp){
    const st = sp.style, ings = sp.ings || new Set();
    if (st === 'popcorn'){ const caramel = ings.has('caramel') || ings.has('sugar'), col = caramel ? '#F2B33A' : sp.burnt ? '#C8A890' : '#FFFBEA', rng = rngFor(77);
      g.beginPath(); g.moveTo(-50, -4); g.lineTo(50, -4); g.lineTo(40, 58); g.lineTo(-40, 58); g.closePath(); g.save(); g.clip(); g.fillStyle = '#FFFFFF'; g.fillRect(-60, -10, 120, 80); g.fillStyle = '#FF7EA6'; for (let i = -6; i <= 6; i++){ g.beginPath(); g.moveTo(i * 15 - 4, -6); g.lineTo(i * 12.5 - 3, 60); g.lineTo(i * 12.5 + 4, 60); g.lineTo(i * 15 + 4, -6); g.fill(); } g.restore();
      const pts = []; for (let i = 0; i < 34; i++){ const t = i / 34, a = rng() * Math.PI, d = Math.sqrt(rng()); pts.push([Math.cos(a) * d * 52 * (1 - t * .45), -2 - Math.sin(a) * d * 6 - t * 44 + rng() * 8, rng()]); }
      pts.sort((a, b) => a[1] - b[1]).forEach(([x, y, r]) => { for (let k = 0; k < 5; k++){ const px = x + Math.cos(k * 1.3 + r * 6) * 5, py = y + Math.sin(k * 1.3 + r * 6) * 4; g.beginPath(); g.arc(px, py, 5.6, 0, TAU); g.fillStyle = rad(g, px, py, 6, [[0, '#FFFFFF'], [1, col]], -2, -2); g.fill(); g.lineWidth = 1; g.strokeStyle = 'rgba(59,35,64,.55)'; g.stroke(); } disc(g, x + 1, y + 3, 1.8, '#F2B33A'); });
      if (ings.has('butter')) glint(g, -10, -30, 20, 4, -.2, .4);
      g.beginPath(); g.moveTo(-50, -4); g.lineTo(50, -4); g.lineTo(40, 58); g.lineTo(-40, 58); g.closePath(); line(g, 2.6); rr(g, -14, 18, 28, 16, 5); paint(g, '#FFFFFF', 1.6); g.fillStyle = '#FF5C8D'; g.font = '800 9px sans-serif'; g.textAlign = 'center'; g.fillText('POP', 0, 30); return; }
    if (st === 'fries'){ const rng = rngFor(3); for (let i = 0; i < 13; i++){ g.save(); g.translate(-28 + i * 4.6, -2); g.rotate(-.32 + i * .055 + (rng() - .5) * .1); rr(g, -4.5, -42 - rng() * 10, 9, 54, 2); paint(g, lin(g, -4, 0, 4, 0, [[0, '#FFE680'], [1, '#F2B22A']]), 1.6); g.beginPath(); g.moveTo(-2, -38); g.lineTo(-2, 0); line(g, 1.4, 'rgba(255,255,255,.6)'); g.restore(); }
      speckle(g, 14, 0, -28, 26, 14, .9, '#FFFFFF', 4);
      g.beginPath(); g.moveTo(-36, -6); g.lineTo(36, -6); g.lineTo(26, 56); g.lineTo(-26, 56); g.closePath(); paint(g, lin(g, -36, 0, 36, 0, [[0, '#FF9EBB'], [1, '#E85A84']]), 2.6); g.save(); g.translate(0, 22); g.beginPath(); g.moveTo(0, 8); g.bezierCurveTo(-12, -2, -6, -12, 0, -4); g.bezierCurveTo(6, -12, 12, -2, 0, 8); g.fillStyle = '#FFFFFF'; g.fill(); g.restore(); return; }
    plate(g, 40);
    if (st === 'dumpling'){ for (let i = 0; i < 5; i++){ const x = -48 + i * 24, y = 30 - (i % 2) * 7; g.beginPath(); g.moveTo(x - 18, y + 8); g.quadraticCurveTo(x - 16, y - 20, x, y - 20); g.quadraticCurveTo(x + 16, y - 20, x + 18, y + 8); g.closePath(); paint(g, lin(g, 0, y - 20, 0, y + 8, [[0, '#FFF8EA'], [1, '#F2E2C2']]), 2); for (let k = -2; k <= 2; k++){ g.beginPath(); g.moveTo(x + k * 5, y - 18); g.quadraticCurveTo(x + k * 6 + 2, y - 12, x + k * 6, y - 8); line(g, 1.3); } g.beginPath(); g.moveTo(x - 17, y + 6); g.quadraticCurveTo(x, y + 12, x + 17, y + 6); line(g, 4.5, '#C8782E'); glint(g, x - 6, y - 10, 4, 1.6, -.5, .7); }
      g.beginPath(); g.ellipse(56, 52, 14, 6, 0, 0, TAU); paint(g, '#FFFFFF', 1.8); g.beginPath(); g.ellipse(56, 51, 10, 4, 0, 0, TAU); g.fillStyle = '#4A2618'; g.fill(); return; }
    if (st === 'tempura'){ const rng = rngFor(5); for (let i = 0; i < 3; i++){ g.save(); g.translate(-30 + i * 30, 28); g.rotate(-.6 + i * .32); if (ings.has('shrimp')){ g.beginPath(); g.moveTo(0, -30); g.lineTo(-8, -44); g.lineTo(0, -40); g.lineTo(8, -44); g.closePath(); paint(g, '#FF6A4A', 1.6); }
      g.beginPath(); for (let k = 0; k <= 24; k++){ const a = k / 24 * TAU, r = 1 + (k % 2) * .12; g.lineTo(Math.cos(a) * 13 * r, Math.sin(a) * 30 * r); } g.closePath(); paint(g, lin(g, -12, -30, 12, 30, [[0, '#FFE6A0'], [1, '#E8A44A']]), 1.8);
      for (let k = 0; k < 9; k++) disc(g, (rng() - .5) * 16, (rng() - .5) * 46, 2.6, 'rgba(255,248,215,.85)'); g.restore(); }
      g.beginPath(); g.ellipse(56, 50, 14, 6, 0, 0, TAU); paint(g, '#FFFFFF', 1.8); g.beginPath(); g.ellipse(56, 49, 10, 4, 0, 0, TAU); g.fillStyle = '#8A5A2A'; g.fill(); return; }
    if (st === 'noodle'){ g.beginPath(); g.ellipse(0, 28, 58, 20, 0, 0, TAU); g.fillStyle = '#8A5426'; g.fill(); const rng = rngFor(12);
      for (let i = 0; i < 30; i++){ const cx = (rng() - .5) * 90, cy = 28 + (rng() - .5) * 26 - (1 - Math.abs(cx) / 50) * 8, r = 10 + rng() * 14, a0 = rng() * TAU, a1 = a0 + 1.6 + rng() * 2;
        for (const [lw, col] of [[4, i % 3 ? '#B8783A' : '#A86A2E'], [1.2, 'rgba(255,225,170,.75)']]){ g.beginPath(); g.ellipse(cx, cy, r, r * .45, rng() * .4 - .2, a0, a1); line(g, lw, col); } }
      const k = extras(sp, ['soy']); scatter(g, k.length ? k : ['carrot', 'pepper'], 8, 0, 22, 40, 9, .9, 3); speckle(g, 14, 0, 18, 40, 9, 1, '#5E9A3A', 4); ell(g, 22, 12, 7, 4, '#E8404A', 1.2); return; }
    if (st === 'rice'){ g.beginPath(); g.moveTo(-58, 38); g.bezierCurveTo(-56, -8, 56, -8, 58, 38); g.quadraticCurveTo(0, 48, -58, 38); paint(g, lin(g, -50, -4, 50, 40, [[0, '#FFF0C0'], [1, '#E8C882']])); g.save(); g.clip(); grains(g, 80, 0, 22, 56, 22, 6, '#FFF6D8', 'rgba(170,130,60,.5)');
      speckle(g, 10, 0, 20, 46, 16, 2.4, '#7CC85A', 2); speckle(g, 10, 0, 20, 46, 16, 2.4, '#FF8A2B', 3); speckle(g, 8, 0, 20, 46, 16, 3, '#FFD84A', 4); g.restore(); for (let i = 0; i < 6; i++) ring(g, -16 + i * 7, 4 + (i % 2) * 4, 2, 1.4, '#5E9A3A'); return; }
    if (st === 'nachos'){ const rng = rngFor(5); for (let i = 0; i < 12; i++){ g.save(); g.translate((rng() - .5) * 90, 28 + (rng() - .5) * 18); g.rotate(rng() * 6); g.beginPath(); g.moveTo(-13, 9); g.lineTo(13, 9); g.lineTo(0, -14); g.closePath(); paint(g, lin(g, 0, -14, 0, 9, [[0, '#FFE08A'], [1, '#F2B33A']]), 1.6); g.restore(); }
      for (const [lw, col, dy] of [[6, '#FFC93C', 0], [1.6, 'rgba(255,250,210,.8)', -1]]){ g.beginPath(); g.moveTo(-44, 18 + dy); for (let x = -44; x <= 44; x += 11) g.quadraticCurveTo(x - 5, 32 + dy, x, 18 + dy + ((x + 44) / 11 % 2 ? 6 : -4)); line(g, lw, col); }
      scatter(g, extras(sp, ['cheese']), 5, 0, 20, 36, 8, .8, 2); return; }
    const k = extras(sp); g.beginPath(); g.ellipse(0, 30, 56, 16, 0, 0, TAU); g.fillStyle = 'rgba(160,90,30,.35)'; g.fill(); scatter(g, k.length ? k : ['carrot', 'broccoli'], 16, 0, 30, 50, 12, 1.3, 7); scatter(g, k.length ? k : ['carrot'], 9, 0, 18, 34, 8, 1.3, 8); glint(g, -20, 18, 16, 3, -.1, .3); speckle(g, 12, 0, 22, 44, 12, .9, '#FFF6D8', 5);
  },
  cookie(g, sp){ plate(g, 42); const choc = sp.style === 'choc' || (sp.ings && sp.ings.has('chocolate'));
    for (const [x, y] of [[-32, 30], [32, 30], [0, 14]]){ g.beginPath(); for (let k = 0; k <= 16; k++){ const a = k / 16 * TAU, r = 1 + Math.sin(k * 2.7) * .05; g.lineTo(x + Math.cos(a) * 29 * r, y + Math.sin(a) * 18 * r); } g.closePath(); paint(g, rad(g, x, y, 30, [[0, '#F6CF8A'], [.75, '#E2A250'], [1, '#B8742E']], -6, -4));
      for (let i = 0; i < 3; i++){ g.beginPath(); g.moveTo(x - 12 + i * 10, y - 8 + i * 4); g.lineTo(x - 6 + i * 10, y - 2 + i * 4); line(g, 1.2, 'rgba(140,80,30,.55)'); }
      if (choc){ const rng = rngFor(x + 9); for (let i = 0; i < 6; i++){ const px = x + (rng() - .5) * 38, py = y + (rng() - .5) * 20; g.beginPath(); g.moveTo(px - 3.5, py + 2.5); g.quadraticCurveTo(px, py - 5, px + 3.5, py + 2.5); g.closePath(); paint(g, '#4A2416', 1); } }
      else if (sp.ings && sp.ings.has('sprinkles')) garnish(g, 'sprinkles', x, y, 1.4);
      glint(g, x - 10, y - 8, 8, 2.4, -.3, .4); } },
  cupcake(g, sp){
    for (const ox of [-28, 28]){ g.save(); g.translate(ox, 50); g.scale(.82, .82);
      ell(g, 2, 4, 30, 8, 'rgba(59,35,64,.2)');
      g.beginPath(); g.moveTo(-34, -40); g.lineTo(34, -40); g.lineTo(26, 0); g.quadraticCurveTo(0, 6, -26, 0); g.closePath(); paint(g, lin(g, -34, 0, 34, 0, [[0, '#FFD6E4'], [1, '#F294B6']]), 2.4); g.save(); g.clip(); for (let i = -4; i <= 4; i++){ g.beginPath(); g.moveTo(i * 9, -40); g.lineTo(i * 7.2, 4); line(g, 2.4, 'rgba(255,255,255,.65)'); } g.restore();
      const cb = sp.main || '#E9A84C'; g.beginPath(); g.ellipse(0, -40, 38, 22, 0, Math.PI, TAU); g.closePath(); paint(g, rad(g, 0, -46, 38, [[0, lighten(cb, .2)], [1, darken(cb, .15)]]));
      if (sp.style !== 'muffin'){ const fc = sp.frost || '#FFB3CF'; for (let k = 0; k < 4; k++){ const yy = -46 - k * 11, rx = 34 - k * 8; g.beginPath(); g.ellipse(0, yy, Math.max(6, rx), 10, 0, 0, TAU); paint(g, lin(g, 0, yy - 10, 0, yy + 10, [[0, lighten(fc, .3)], [1, darken(fc, .1)]]), 2); glint(g, -rx * .35, yy - 3, rx * .3, 2.4, -.1, .6); }
        g.beginPath(); g.moveTo(-6, -84); g.quadraticCurveTo(0, -100, 8, -86); g.fillStyle = fc; g.fill(); line(g, 2);
        if (sp.ings && sp.ings.has('sprinkles')) garnish(g, 'sprinkles', 0, -58, 1.5); }
      const t = sp.ings ? ['cherry', 'strawberry', 'blueberry'].find(k => sp.ings.has(k)) : null; if (t) garnish(g, t, 2, sp.style === 'muffin' ? -58 : -94, 1.3);
      g.restore(); }
  },
  cake(g, sp){
    const st = sp.style, c = sp.main || '#F6E0A8'; plate(g, 46);
    if (st === 'pie'){ g.beginPath(); g.ellipse(0, 30, 60, 24, 0, 0, TAU); paint(g, lin(g, 0, 6, 0, 54, [[0, '#F2C47A'], [1, '#C8823A']])); g.beginPath(); g.ellipse(0, 25, 52, 19, 0, 0, TAU); g.fillStyle = '#C8742E'; g.fill();
      g.save(); g.beginPath(); g.ellipse(0, 25, 52, 19, 0, 0, TAU); g.clip(); for (let i = -4; i <= 4; i++){ rr(g, i * 12 - 4, -4, 8, 60, 4); paint(g, lin(g, 0, -4, 0, 56, [[0, '#FFDCA0'], [1, '#E2A55A']]), 1.2); } for (let i = -3; i <= 3; i++){ rr(g, -60, 25 + i * 7 - 3.5, 120, 7, 3.5); paint(g, lin(g, 0, 22 + i * 7, 0, 28 + i * 7, [[0, '#FFE2B0'], [1, '#E8AC62']]), 1.2); } g.restore();
      g.beginPath(); g.ellipse(0, 25, 52, 19, 0, 0, TAU); line(g, 2.2); for (let k = 0; k < 18; k++){ const a = k / 18 * TAU; g.beginPath(); g.arc(Math.cos(a) * 56, 28 + Math.sin(a) * 22, 4, 0, TAU); g.fillStyle = '#F2C47A'; g.fill(); } glint(g, -20, 14, 14, 3, -.15, .5); speckle(g, 12, 0, 22, 40, 14, 1, '#FFFFFF', 3); return; }
    if (st === 'loaf'){ rr(g, -54, 2, 108, 40, 10); paint(g, lin(g, 0, 2, 0, 42, [[0, '#D9954A'], [1, '#A8642A']])); g.beginPath(); g.moveTo(-54, 10); g.quadraticCurveTo(0, -26, 54, 10); g.lineTo(54, 16); g.lineTo(-54, 16); g.closePath(); paint(g, lin(g, 0, -16, 0, 16, [[0, '#8A4A1E'], [1, '#B8742E']]));
      g.beginPath(); g.moveTo(-30, 0); g.quadraticCurveTo(0, -12, 30, 0); line(g, 2, '#FFE2B0'); rr(g, 30, 4, 20, 38, 4); paint(g, '#F6D29A', 1.8); speckle(g, 8, 40, 22, 7, 14, 1.2, '#C8823A', 3); speckle(g, 4, 40, 22, 7, 14, 1.8, '#5A2E1E', 4); return; }
    if (st === 'brownie'){ for (let i = 0; i < 4; i++){ const x = -26 + (i % 2) * 46, y = 6 + Math.floor(i / 2) * 26; g.beginPath(); g.moveTo(x - 20, y); g.lineTo(x + 6, y - 9); g.lineTo(x + 28, y - 9); g.lineTo(x + 28, y + 12); g.lineTo(x, y + 22); g.lineTo(x - 20, y + 22); g.closePath(); paint(g, '#3E1E12');
      g.beginPath(); g.moveTo(x - 20, y); g.lineTo(x + 6, y - 9); g.lineTo(x + 28, y - 9); g.lineTo(x, y); g.closePath(); paint(g, lin(g, x - 20, y - 9, x + 28, y, [[0, '#8A5236'], [1, '#5A2E1E']]), 1.6); g.beginPath(); g.moveTo(x - 10, y - 3); g.lineTo(x, y - 5); g.lineTo(x + 8, y - 3); line(g, 1.2, 'rgba(255,230,210,.5)'); rr(g, x - 20, y, 20, 22, 2); paint(g, '#4A2416', 1.8); speckle(g, 4, x - 10, y + 11, 7, 8, 1, '#2A120A', i); } return; }
    const fr = st === 'choc' ? '#4A2416' : '#FFFFFF', fill2 = st === 'choc' ? '#7A4430' : st === 'carrot' ? '#FFF6E8' : '#FFFFFF';
    g.beginPath(); g.moveTo(-52, 38); g.lineTo(28, 38); g.lineTo(56, 18); g.lineTo(56, -18); g.lineTo(-24, -18); g.lineTo(-52, 2); g.closePath(); paint(g, lin(g, 0, -18, 0, 38, [[0, lighten(c, .1)], [1, darken(c, .1)]]));
    g.beginPath(); g.moveTo(28, 38); g.lineTo(56, 18); g.lineTo(56, -18); g.lineTo(28, 2); g.closePath(); paint(g, st === 'choc' ? '#3E1E12' : '#F2E6EE');
    g.beginPath(); g.moveTo(-52, 2); g.lineTo(28, 2); g.lineTo(56, -18); g.lineTo(-24, -18); g.closePath(); paint(g, lin(g, -52, -18, 56, 2, [[0, lighten(fr, .1)], [1, darken(fr, .06)]]));
    speckle(g, 22, -12, 26, 36, 8, 1.1, 'rgba(160,100,40,.3)', 3); speckle(g, 22, -12, 12, 36, 6, 1.1, 'rgba(160,100,40,.3)', 4);
    g.beginPath(); g.moveTo(-52, 18); g.lineTo(28, 18); line(g, 6, fill2);
    if (st === 'short') for (let i = 0; i < 4; i++){ g.save(); g.translate(-42 + i * 20, 18); g.beginPath(); g.moveTo(0, 5); g.bezierCurveTo(-7, 1, -6, -5, 0, -4); g.bezierCurveTo(6, -5, 7, 1, 0, 5); paint(g, '#F0475E', 1.2); g.beginPath(); g.moveTo(0, 3); g.bezierCurveTo(-3, 1, -3, -2, 0, -2); g.bezierCurveTo(3, -2, 3, 1, 0, 3); g.fillStyle = '#FFD3DA'; g.fill(); g.restore(); }
    g.beginPath(); g.rect(-52, 2, 80, 36); line(g, 2.2);
    if (st === 'choc'){ g.beginPath(); g.moveTo(-52, 2); for (let x = -52; x < 28; x += 10) g.quadraticCurveTo(x + 5, 12 + ((x + 52) / 10 % 2) * 5, x + 10, 2); g.fillStyle = '#4A2416'; g.fill(); line(g, 1.6); glint(g, -14, -10, 18, 2.4, -.15, .5); garnish(g, 'cherry', 14, -26, 1.2); }
    else if (st === 'carrot') for (let i = 0; i < 3; i++){ g.save(); g.translate(-10 + i * 16, -9); g.rotate(.6); rr(g, -2.4, -7, 4.8, 14, 2.4); paint(g, '#FF8A2B', 1.2); g.restore(); }
    else garnish(g, 'strawberry', 12, -26, 1.4);
    for (let i = 0; i < 3; i++){ g.beginPath(); g.ellipse(-30 + i * 22, -10, 7, 4, 0, 0, TAU); paint(g, st === 'choc' ? '#8A4A30' : '#FFE9F1', 1.4); }
  },
  scoop(g, sp){
    const st = sp.style, ings = sp.ings || new Set(), c = st || !ings.size ? (sp.main || '#FFB3CF') : ings.has('matcha') ? '#B8E07A' : ings.has('mango') ? '#FFCF4A' : ings.has('strawberry') ? '#FFA8C0' : ings.has('chocolate') ? '#A8704A' : (sp.main || '#FFB3CF');
    if (st === 'pop'){ rr(g, -6, 22, 12, 42, 5); paint(g, lin(g, -6, 0, 6, 0, [[0, '#F2D8A8'], [1, '#D2A868']])); g.save(); rr(g, -27, -48, 54, 78, [27, 27, 9, 9]); g.clip(); const cols = sp.tops && sp.tops.length ? sp.tops : [c, lighten(c, .3)]; cols.forEach((cc, i) => { g.fillStyle = lin(g, -27, 0, 27, 0, [[0, lighten(cc, .2)], [1, darken(cc, .1)]]); g.fillRect(-30, -48 + i * 78 / cols.length, 60, 78 / cols.length + 1); }); g.restore(); rr(g, -27, -48, 54, 78, [27, 27, 9, 9]); line(g); g.beginPath(); g.moveTo(-17, -32); g.lineTo(-17, 12); line(g, 4.5, 'rgba(255,255,255,.6)'); face(g, 0, -6, .8, 'happy'); return; }
    if (st === 'purin'){ plate(g, 46); g.beginPath(); g.moveTo(-42, 40); g.quadraticCurveTo(0, 48, 42, 40); g.lineTo(28, -16); g.lineTo(-28, -16); g.closePath(); paint(g, lin(g, -42, 0, 42, 0, [[0, '#FFF0A8'], [1, '#F6C84A']])); glint(g, -20, 10, 5, 18, .1, .5);
      g.beginPath(); g.moveTo(-28, -16); g.lineTo(28, -16); g.lineTo(26, -4); g.quadraticCurveTo(14, 4, 8, -3); g.quadraticCurveTo(-4, 8, -12, -3); g.quadraticCurveTo(-20, 4, -26, -4); g.closePath(); paint(g, lin(g, 0, -16, 0, 4, [[0, '#B8641E'], [1, '#7A3A10']])); glint(g, -12, -12, 9, 1.8, 0, .6);
      for (let i = 0; i < 3; i++){ g.beginPath(); g.ellipse(0, -21 - i * 7, 15 - i * 4.5, 5, 0, 0, TAU); paint(g, '#FFFFFF', 1.8); } garnish(g, 'cherry', 2, -44, 1.1); face(g, 0, 18, .7, 'happy'); return; }
    if (st === 'mochi'){ plate(g, 46); for (const [x, y, cc] of [[-30, 30, c], [30, 30, lighten(c, .25)], [0, 14, '#FFF4F7']]){ g.beginPath(); g.ellipse(x, y, 27, 20, 0, 0, TAU); paint(g, rad(g, x, y, 28, [[0, lighten(cc, .3)], [1, darken(cc, .08)]], -6, -6), 2.4); speckle(g, 14, x, y - 4, 20, 12, .9, 'rgba(255,255,255,.85)', x); glint(g, x - 9, y - 9, 7, 3, -.4, .7); } face(g, 0, 12, .55, 'happy'); return; }
    g.beginPath(); g.moveTo(-36, 6); g.lineTo(36, 6); g.lineTo(24, 52); g.quadraticCurveTo(0, 58, -24, 52); g.closePath(); paint(g, lin(g, -36, 0, 36, 0, [[0, '#D8CCFF'], [1, '#9C88E8']])); g.beginPath(); g.moveTo(-30, 28); g.lineTo(30, 28); line(g, 3, 'rgba(255,255,255,.6)');
    const flk = ings.has('strawberry') ? '#E0405A' : ings.has('matcha') ? '#5E9A3A' : ings.has('mango') ? '#FFF2B0' : '#FFFFFF';
    for (const [x, y, cc] of [[-15, -6, c], [15, -6, lighten(c, .12)], [0, -28, c]]){ g.beginPath(); g.arc(x, y, 21, Math.PI * .92, Math.PI * 2.08); g.lineTo(x + 21, y + 4); for (let k = 0; k < 5; k++) g.quadraticCurveTo(x + 17 - k * 8.4, y + 12 + (k % 2) * 4, x + 13 - k * 8.4, y + 4); g.closePath(); paint(g, rad(g, x, y, 22, [[0, lighten(cc, .3)], [1, darken(cc, .08)]], -6, -8)); speckle(g, 7, x, y - 4, 13, 9, 1, flk, x + y); glint(g, x - 8, y - 9, 6, 3, -.4, .75); }
    g.save(); g.translate(22, -40); g.rotate(.5); rr(g, -4, -16, 8, 30, 2); paint(g, '#F2C27A', 1.6); g.restore();
    const t = ['cherry', 'blueberry'].find(k => ings.has(k)); if (t) garnish(g, t, -6, -50, 1.1);
  },
  plate(g, sp){
    const st = sp.style; plate(g, 40, 84, 31);
    if (st === 'breakfast'){ friedEgg(g, -24, 22, .78);
      for (let j = 0; j < 2; j++){ rr(g, 14, 16 + j * 13, 44, 11, 5.5); paint(g, lin(g, 0, 16 + j * 13, 0, 27 + j * 13, [[0, '#E8705A'], [1, '#A83A28']]), 1.8); glint(g, 22, 19 + j * 13, 10, 1.6, 0, .6); }
      bacon2(g, -44, 46); garnish(g, 'tomato', 46, 48, 1.2); garnish(g, 'mushroom', -6, 52, 1); return; }
    if (st === 'roast'){ g.save(); g.translate(0, 18);
      g.beginPath(); g.ellipse(0, 6, 46, 26, 0, 0, TAU); paint(g, rad(g, -10, -4, 50, [[0, '#F6C27A'], [.6, '#D9893A'], [1, '#9A5420']], -8, -8), 2.6);
      for (const sd of [-1, 1]){ g.save(); g.translate(sd * 40, 14); g.rotate(sd * .5); g.beginPath(); g.ellipse(0, 0, 14, 18, 0, 0, TAU); paint(g, rad(g, 0, 0, 18, [[0, '#F2B062'], [1, '#B8682A']], -3, -4), 2.2); rr(g, -3, 14, 6, 14, 3); paint(g, '#FFF8EE', 1.6); disc(g, -3, 28, 3.4, '#FFF8EE'); disc(g, 3, 28, 3.4, '#FFF8EE'); g.restore(); }
      glint(g, -14, -6, 16, 6, -.4, .5); speckle(g, 12, 0, 2, 34, 16, 1.1, '#5E9A3A', 3); g.restore(); scatter(g, ['potato', 'carrot'], 6, 0, 52, 64, 6, 1, 2); return; }
    if (st === 'fish'){ g.save(); g.translate(-14, 24); g.rotate(-.1); g.beginPath(); for (let k = 0; k <= 22; k++){ const a = k / 22 * TAU, r = 1 + (k % 2) * .08; g.lineTo(Math.cos(a) * 38 * r, Math.sin(a) * 17 * r); } g.closePath(); paint(g, lin(g, 0, -17, 0, 17, [[0, '#FFE08A'], [1, '#E2A04A']]), 2.2); speckle(g, 14, 0, 0, 30, 12, 2.4, 'rgba(255,250,220,.8)', 3); g.restore();
      for (let i = 0; i < 8; i++){ g.save(); g.translate(32 + (i % 4) * 7, 12 + Math.floor(i / 4) * 12); g.rotate(.9); rr(g, -3.5, -15, 7, 30, 2); paint(g, lin(g, -3, 0, 3, 0, [[0, '#FFE680'], [1, '#F2B22A']]), 1.4); g.restore(); }
      garnish(g, 'lemon', -50, 44, 1.2); speckle(g, 6, -16, 48, 10, 3, 2.4, '#7CC85A', 4); return; }
    if (st === 'potato'){ g.beginPath(); g.ellipse(0, 24, 46, 26, 0, 0, TAU); paint(g, rad(g, 0, 24, 46, [[0, '#D9A86C'], [1, '#9A6A3A']], -8, -6)); g.beginPath(); g.ellipse(0, 16, 28, 12, 0, 0, TAU); paint(g, '#FFF4D2', 1.8); garnish(g, 'butter', 0, 10, 1.4); for (let i = 0; i < 6; i++) ring(g, -14 + i * 6, 18 + (i % 2) * 3, 1.8, 1.2, '#5E9A3A'); return; }
    if (st === 'corn'){ g.save(); g.translate(0, 26); g.rotate(-.15); rr(g, -50, -15, 100, 30, 15); paint(g, lin(g, 0, -15, 0, 15, [[0, '#FFE680'], [1, '#F2B21E']])); g.save(); rr(g, -50, -15, 100, 30, 15); g.clip(); for (let i = -12; i <= 12; i++){ g.beginPath(); g.moveTo(i * 4.4, -16); g.lineTo(i * 4.4, 16); line(g, 1, 'rgba(200,140,20,.55)'); } for (let j = -2; j <= 2; j++){ g.beginPath(); g.moveTo(-52, j * 6); g.lineTo(52, j * 6); line(g, .8, 'rgba(200,140,20,.4)'); } speckle(g, 8, 0, 0, 40, 10, 2.4, 'rgba(130,70,10,.35)', 3); g.restore(); g.restore(); garnish(g, 'butter', -4, 14, 1.4); return; }
    g.beginPath(); g.ellipse(-8, 24, 40, 21, -.1, 0, TAU); paint(g, rad(g, -8, 24, 40, [[0, '#B8584A'], [1, '#5A2014']], -8, -6)); for (let i = 0; i < 4; i++){ g.beginPath(); g.moveTo(-34 + i * 15, 12); g.lineTo(-22 + i * 15, 34); line(g, 3, '#3A140C'); } glint(g, -18, 14, 12, 3, -.2, .4);
  },
};

// ---------- sprite baking (shading, soft drop shadow, light pass) ----------
const SPR = new Map(); let sprPx = 0;
function specKey(sp){ return [sp.art, sp.style || '', sp.main || '', (sp.tops || []).join(','), (sp.pieces || []).join(','), sp.ing || '', sp.burnt ? 1 : 0, sp.frost || '', sp.ings ? [...sp.ings].sort().join(',') : '', sp.cook ? Math.round(sp.cook * 10) : 0].join('|'); }
function bakeArt(sp, pr){
  const S = 220, n = Math.ceil(S * pr), t = document.createElement('canvas'); t.width = t.height = n;
  const tg = t.getContext('2d'); tg.setTransform(pr, 0, 0, pr, 110 * pr, 120 * pr); tg.lineJoin = 'round'; tg.lineCap = 'round';
  try { (ART[sp.art] || ART.chunks)(tg, sp); } catch (e) { console.warn('art', sp.art, sp.style, e); }
  tg.globalCompositeOperation = 'source-atop';
  const lg = tg.createLinearGradient(-90, -100, 90, 90); lg.addColorStop(0, 'rgba(255,244,226,.16)'); lg.addColorStop(.5, 'rgba(255,255,255,0)'); lg.addColorStop(1, 'rgba(84,40,120,.12)'); tg.fillStyle = lg; tg.fillRect(-110, -120, 220, 220);
  if (sp.burnt){ tg.fillStyle = 'rgba(52,30,26,.55)'; tg.fillRect(-110, -120, 220, 220); }
  tg.globalCompositeOperation = 'source-over';
  const c = document.createElement('canvas'); c.width = c.height = n; const g = c.getContext('2d');
  g.shadowColor = 'rgba(59,35,64,.3)'; g.shadowBlur = 9 * pr; g.shadowOffsetY = 5 * pr; g.drawImage(t, 0, 0);
  return c;
}
function drawArt(g, sp, x, y, s){
  let px = s * 2; if (g.getTransform){ const m = g.getTransform(); px = Math.hypot(m.a, m.b) * s; }
  const pr = clamp(Math.ceil(px * 2) / 2, .5, 6), key = specKey(sp);
  let e = SPR.get(key);
  if (!e || pr > e.pr * 1.05){ const c = bakeArt(sp, pr); if (e) sprPx -= e.c.width * e.c.height; sprPx += c.width * c.height; if (sprPx > 30e6){ SPR.clear(); sprPx = c.width * c.height; } e = {pr, c}; SPR.set(key, e); }
  g.drawImage(e.c, x - 110 * s, y - 120 * s, 220 * s, 220 * s);
  const steam = sp.steam || sp.art === 'mug' || sp.hot;
  if (!sp.burnt && !steam) return;
  g.save(); g.translate(x, y); g.scale(s, s); if (sp.burnt) steamUp(g, -16, true); else steamUp(g, sp.art === 'mug' ? -40 : -30); g.restore();
}
