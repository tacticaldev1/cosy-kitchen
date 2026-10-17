// ================= ticket popup, buy all, next-step hints, flying food =================
function onHand(){ return new Set(compsOf(allFoods()).map(c => c.ing)); }
function buyFor(r, cust){
  if (cust && cust.state === 'order') setActive(cust);
  const have = onHand(), missing = r.need.filter(k => !have.has(k)), list = missing.length ? missing : r.need.slice();
  const steps = buildSteps(r), first = steps.find(s => s.check.type === 'tag'), tool = first && ST[first.tool] ? first.tool : null, st = tool ? ST[tool] : null;
  const into = st && !st.busy() ? new Set(first.check.ings) : new Set();
  let spent = 0, n = 0, toSt = 0, full = false;
  if (st && into.size) for (let i = kit.counter.length - 1; i >= 0; i--){ const f = kit.counter[i]; if (!f.hist.length && f.comps.length === 1 && into.has(f.comps[0].ing) && st.items.length < st.cap){ kit.counter.splice(i, 1); st.items.push(f); toSt++; } }
  for (const k of list){
    const f = newFood(k);
    if (st && into.has(k) && st.items.length < st.cap){ st.items.push(f); toSt++; }
    else if (kit.counter.length < CAP_COUNTER){ f.arrive = clock + n * .06; kit.counter.push(f); }
    else { full = true; continue; }
    spent += chargeIng(k); n++;
  }
  if (!activeCust()){ pinned = r.id; guideCache.t = -1; save(); }
  if (toSt && tool) openStation(tool);
  if (n){ SND.coin(); buzz(10); }
  toast(full ? `Bought ${n} for ${yen(spent)}, but the counter is full` : n ? `Bought ${n} ingredient${n > 1 ? 's' : ''} for ${yen(spent)}${toSt && tool ? ` · into the ${STATION_LABEL[tool]}` : ''}` : 'Everything is already here');
}
function openTicket(rid, cust){
  initAudio();
  const r = RECIPES[rid], body = $('tkBody'), have = onHand(), missing = r.need.filter(k => !have.has(k)), buyList = missing.length ? missing : r.need, cost = buyList.reduce((a, k) => a + (ING_COST[k] || 0), 0);
  $('tkTitle').textContent = r.n;
  $('tkSub').textContent = cust ? `${cust.name}'s order · pays ${yen(r.price)}` : `Menu price ${yen(r.price)} · ingredients ${yen(r.cost)}`;
  body.innerHTML = '';
  const top = document.createElement('div'); top.className = 'tktop';
  const c = document.createElement('canvas'); c.width = c.height = 200; c.getContext('2d').drawImage(thumb(r), 0, 0, 200, 200); top.appendChild(c);
  const ings = document.createElement('div'); ings.className = 'ings';
  for (const k of r.need){ const chipEl = ingChip(k, false); if (have.has(k)) chipEl.classList.add('got'); const pr = document.createElement('small'); pr.textContent = have.has(k) ? '✓' : yen(ING_COST[k] || 0); chipEl.appendChild(pr); ings.appendChild(chipEl); }
  top.appendChild(ings); body.appendChild(top);
  const row = document.createElement('div'); row.className = 'drow';
  const buy = document.createElement('button'); buy.className = 'btn'; buy.id = 'buyAll';
  buy.textContent = missing.length ? `Buy all · ${yen(cost)}` : `Buy another set · ${yen(cost)}`;
  buy.onclick = () => { $('ticketSheet').hidden = true; buyFor(r, cust); cv.focus({preventScroll: true}); };
  const full = document.createElement('button'); full.className = 'btn ghost'; full.textContent = 'Full recipe'; full.onclick = () => { $('ticketSheet').hidden = true; openBook(rid); };
  row.appendChild(buy); row.appendChild(full); body.appendChild(row);
  if (missing.length && missing.length < r.need.length){ const p = document.createElement('p'); p.className = 'tknote'; p.textContent = `You already have ${r.need.length - missing.length} of ${r.need.length}, so this buys just the ${missing.length} missing.`; body.appendChild(p); }
  const h = document.createElement('h4'); h.className = 'tkh'; h.textContent = 'Steps'; body.appendChild(h);
  const ol = document.createElement('ol'); ol.className = 'steps';
  buildSteps(r).forEach(sx => { const li = document.createElement('li'); li.textContent = sx.text; if (stepDone(sx)) li.className = 'done'; ol.appendChild(li); });
  body.appendChild(ol);
  $('ticketSheet').hidden = false; SND.note(); setTimeout(() => buy.focus(), 30);
}
function nextHint(){
  const gd = guide(); if (!gd) return null;
  const st = gd.steps[gd.cur];
  if (st.check.type === 'have') return {label: 'Buy ingredients', act: () => openTicket(pinned, activeCust())};
  const tool = st.tool; if (!tool || tool === kit.open || !ST[tool]) return null;
  return {label: `Next: ${STATION_LABEL[tool]}`, tool, act: () => openStation(tool)};
}
function drawFlyers(g){
  for (let i = flyers.length - 1; i >= 0; i--){
    const fl = flyers[i], k = (clock - fl.t) / fl.dur; if (k >= 1){ flyers.splice(i, 1); continue; }
    let x1 = fl.x1, y1 = fl.y1, s1 = fl.s1;
    if (fl.to === 'counter'){ const idx = kit.counter.indexOf(fl.f); if (idx < 0){ flyers.splice(i, 1); continue; } x1 = slotX(idx); y1 = 600; s1 = .27; }
    const e = ease(k), x = fl.x0 + (x1 - fl.x0) * e, y = fl.y0 + (y1 - fl.y0) * e - Math.sin(k * Math.PI) * 70, s = fl.s0 + (s1 - fl.s0) * e;
    drawArt(g, foodSpec(fl.f), x, y, s);
    if (!reduced && R() < .5) fx.push({x, y, vx: 0, vy: 0, life: .35, r: 3 + R() * 3, c: '#FFFFFF', rot: R() * 3});
  }
}
