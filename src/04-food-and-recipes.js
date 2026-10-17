// ================= food model =================
const HEAT = new Set(['boil', 'fry', 'bake', 'zap']);
const QRANK = {perfect: 0, ok: 1, under: 2, burnt: 3};
let uidN = 1;
function newFood(ing){ return {uid: uidN++, comps: [{ing, tags: []}], hist: [], cook: 0, q: null, born: clock, recipe: null}; }
function cookQ(level){ return level < .45 ? 'under' : level > 1.18 ? 'burnt' : level >= .62 && level <= 1.0 ? 'perfect' : 'ok'; }
function worstQ(a, b){ if (!a) return b; if (!b) return a; return QRANK[a] >= QRANK[b] ? a : b; }
function applyProc(food, proc, cook){
  for (const c of food.comps) if (!c.tags.includes(proc)) c.tags.push(proc);
  food.hist.push(proc);
  if (HEAT.has(proc)){ food.cook = cook; food.q = worstQ(food.q, cookQ(cook)); food.hot = clock + 8; }
  food.born = clock; food.recipe = null; tagRecipe(food); return food;
}
function mergeFoods(foods, proc, cook){
  const f = {uid: uidN++, comps: [], hist: [], cook: 0, q: null, born: clock, recipe: null};
  for (const x of foods){ for (const c of x.comps) f.comps.push({ing: c.ing, tags: c.tags.slice()}); for (const h of x.hist) if (!f.hist.includes(h)) f.hist.push(h); f.q = worstQ(f.q, x.q); }
  return applyProc(f, proc, cook);
}
const compsOf = foods => foods.flatMap(f => f.comps);

// ================= recipes =================
const RECIPE_SRC = `Fluffy Pancakes|breakfast|stack|egg,flour,milk:mix,fry|sugar,butter,syrup,strawberry,blueberry,honey|Golden, wobbly and stacked sky high.
Chocolate Pancakes|breakfast|stack.choc|egg,flour,milk,chocolate:mix,fry|syrup,strawberry,banana,cream|Cocoa-dark pancakes for sweet mornings.
Blueberry Pancakes|breakfast|stack|egg,flour,milk,blueberry:mix,fry|syrup,butter|Little purple berries in every bite.
Banana Pancakes|breakfast|stack|egg,flour,milk,banana:mix,fry|honey,syrup|Soft, sweet and extra fluffy.
Strawberry Pancakes|breakfast|stack|egg,flour,milk:mix,fry;strawberry:chop|cream,syrup|A pancake stack crowned with fresh strawberries.
Crêpes|breakfast|stack.crepe|egg,flour,milk,butter:mix,fry|strawberry,banana,chocolate,cream|Thin, buttery and folded into triangles.
Sunny Fried Egg|breakfast|egg|egg:fry|bread|One perfect yolk, sunny side up.
Scrambled Eggs|breakfast|egg.scramble|egg,milk:mix,fry|butter,cheese|Soft fluffy clouds of egg.
Cheese Omelette|breakfast|egg.omelette|egg,cheese:mix,fry|milk,mushroom|Folded over a gooey cheesy middle.
Veggie Omelette|breakfast|egg.omelette|egg:mix,fry;pepper,onion:chop,mix,fry|cheese,mushroom,tomato|Packed with crunchy pepper and onion.
Toast|breakfast|toast|bread:bake|butter,honey|Warm, crunchy and golden.
Egg on Toast|breakfast|toast.egg|bread:bake;egg:fry||A fried egg on a golden slice.
French Toast|breakfast|toast.french|bread,egg,milk:mix,fry|syrup,strawberry,sugar|Eggy bread fried until golden.
Avocado Toast|breakfast|toast.avo|bread:bake;avocado:chop|egg,tomato,lemon|Smashed avocado on crunchy toast.
Porridge|breakfast|bowl.porridge|oats,milk:boil|honey,banana,blueberry,strawberry|A warm hug in a bowl.
Yogurt Parfait|breakfast|glass.parfait|yogurt,oats:mix;strawberry:chop|honey,blueberry|Layers of yogurt, oats and berries.
Bacon & Eggs|breakfast|egg.bacon|egg,bacon:fry|bread|The sizzling classic.
Full Breakfast|breakfast|plate.breakfast|egg,bacon,sausage:fry;bread:bake|tomato,mushroom|Everything you need to start the day.
Strawberry Smoothie|drinks|glass|strawberry,milk:blend|yogurt,ice,honey,banana|Pink, creamy and dreamy.
Banana Smoothie|drinks|glass|banana,milk:blend|honey,ice|Mellow, sweet and smooth.
Berry Blast|drinks|glass|strawberry,blueberry,yogurt:blend|honey,ice,milk|A purple pop of berries.
Mango Lassi|drinks|glass|mango,yogurt:blend|honey,milk|Sunny mango and cool yogurt.
Tropical Smoothie|drinks|glass|mango,pineapple,banana:blend|ice,yogurt,milk|An island holiday in a glass.
Green Smoothie|drinks|glass|spinach,banana,apple:blend|honey,yogurt|Surprisingly sweet and very green.
Chocolate Milkshake|drinks|glass.shake|chocolate,milk,ice:blend|cream,banana|Thick, cold and chocolatey.
Strawberry Milkshake|drinks|glass.shake|strawberry,milk,ice:blend|cream,sugar|Pink with a cherry on top.
Lemonade|drinks|glass.ice|lemon,sugar,ice:mix|strawberry|Sour, sweet and fresh.
Orange Juice|drinks|glass|orange:blend|ice|Squeezed sunshine.
Watermelon Juice|drinks|glass|watermelon:blend|ice,lemon|Summer in a cup.
Hot Chocolate|drinks|mug|chocolate,milk:hot|cream,sugar|Cosy cocoa for rainy nights.
Matcha Latte|drinks|mug|matcha,milk:hot|honey,sugar|Earthy green tea with steamed milk.
Iced Matcha|drinks|glass.ice|matcha,milk,ice:mix|honey|Green, creamy and chilled.
Café Latte|drinks|mug|coffee,milk:hot|sugar,cream|Coffee with a milky heart.
Honey Lemon Tea|drinks|mug|lemon,honey:boil||Soothing, sweet and tangy.
Salmon Maki|japanese|maki|rice:boil,roll,chop;nori:roll,chop;salmon:roll,chop|avocado,cucumber|Rice, nori and salmon rolled and sliced.
Tuna Maki|japanese|maki|rice:boil,roll,chop;nori:roll,chop;tuna:roll,chop|cucumber|Ruby-red tuna in a neat little roll.
Cucumber Maki|japanese|maki|rice:boil,roll,chop;nori:roll,chop;cucumber:roll,chop||Crunchy, fresh and simple.
California Roll|japanese|maki|rice:boil,roll,chop;nori:roll,chop;crab,avocado,cucumber:roll,chop||Crab, avocado and cucumber in one roll.
Futomaki|japanese|maki|rice:boil,roll,chop;nori:roll,chop;egg:fry,roll,chop;crab,cucumber:roll,chop||A big, colourful festival roll.
Onigiri|japanese|onigiri|rice:boil;nori:||A smiling rice ball wrapped in nori.
Salmon Onigiri|japanese|onigiri|rice:boil;nori:;salmon:fry||A rice ball with flaky salmon inside.
Salmon Nigiri|japanese|onigiri.nigiri|rice:boil;salmon:chop||Silky salmon on a pillow of rice.
Tuna Nigiri|japanese|onigiri.nigiri|rice:boil;tuna:chop||Classic tuna on rice.
Tamagoyaki|japanese|egg.tamago|egg,sugar,soy:mix,fry,roll||Sweet rolled omelette, sliced into spirals.
Shoyu Ramen|japanese|bowl.ramen|noodles,soy,egg:boil|spinach,mushroom,corn|Slurpy noodles in soy broth.
Chicken Ramen|japanese|bowl.ramen|noodles,soy,chicken:boil|egg,corn,spinach|Hearty chicken noodle comfort.
Yakisoba|japanese|pile.noodle|noodles,carrot,pepper,soy:fry|cabbage,beef|Sizzling stir-fried noodles.
Japanese Curry|japanese|bowl.curry|rice:boil;curry,potato,carrot,onion:boil|beef,chicken|Mild, thick curry beside fluffy rice.
Katsu Curry|japanese|bowl.curry|rice:boil;curry,potato,carrot:boil;chicken,flour,egg:fry||Crispy chicken cutlet with curry.
Oyakodon|japanese|bowl.don|rice:boil;chicken,egg,onion:boil|soy|Chicken and egg simmered over rice.
Okonomiyaki|japanese|stack.okonomi|flour,egg,cabbage:mix,fry|bacon,soy|A savoury cabbage pancake with a sauce zig-zag.
Gyoza|japanese|pile.dumpling|flour,beef,cabbage:mix,fry|soy,onion|Pan-fried dumplings with crispy bottoms.
Mochi|japanese|scoop.mochi|rice,sugar:boil,mix|matcha,strawberry|Squishy, chewy rice cakes.
Dorayaki|japanese|stack.dorayaki|flour,egg,honey:mix,fry;redbean:||Two fluffy pancakes hugging sweet red bean.
Shrimp Tempura|japanese|pile.tempura|shrimp,flour,egg:fry|soy|Light, crunchy battered shrimp.
Honey Toast|japanese|toast.honey|bread:bake;honey,butter:|cream|A tall toast tower dripping with honey.
Spaghetti Pomodoro|mains|bowl.pasta|pasta:boil;tomato,onion:fry|cheese|Pasta in a bright tomato sauce.
Mac & Cheese|mains|bowl.mac|pasta:boil;cheese,milk:hot|butter|Creamy, cheesy, cosy.
Carbonara|mains|bowl.pasta|pasta:boil;egg,cheese,bacon:fry||Silky egg and crispy bacon pasta.
Margherita Pizza|mains|pizza|flour:mix,bake;tomato,cheese:bake||Tomato, cheese and a golden crust.
Pepperoni Pizza|mains|pizza|flour:mix,bake;tomato,cheese,sausage:bake||Little sausage coins on a cheesy pizza.
Hamburger|mains|burger|beef:fry;bread:;lettuce:|tomato,onion|A juicy patty in a soft bun.
Cheeseburger|mains|burger|beef:fry;bread:;cheese:|lettuce,tomato|A burger with a melty cheese hat.
Hot Dog|mains|hotdog|sausage:fry;bread:|onion|A sausage tucked in a bun.
Roast Chicken|mains|plate.roast|chicken:bake|potato,carrot|Golden, crackly and juicy.
Fish & Chips|mains|plate.fish|salmon,flour:fry;potato:chop,fry|lemon|Crunchy battered fish with chips.
Fried Rice|mains|pile.rice|rice:boil,fry;egg,carrot:fry|soy,pepper|Egg-fried rice with bright veg.
Veggie Stir-fry|mains|pile|broccoli,pepper,carrot:chop,fry;soy:|tofu,mushroom|Crunchy veg tossed in a hot pan.
Tacos|mains|taco|tortilla:;beef:fry;lettuce,tomato,cheese:||Crunchy shells piled with fillings.
Grilled Cheese|mains|toast.grilled|bread,cheese,butter:fry|tomato|Golden bread with a cheesy stretch.
Tomato Soup|soups|bowl.smooth|tomato,onion:boil,blend|cream,bread|Velvety and bright red.
Pumpkin Soup|soups|bowl.smooth|pumpkin,milk:boil,blend|cream|Autumn in a bowl.
Corn Soup|soups|bowl.smooth|corn,milk:boil,blend|butter|Sweet, golden and creamy.
Mushroom Soup|soups|bowl.smooth|mushroom,milk,butter:boil,blend||Earthy and silky smooth.
Chicken Noodle Soup|soups|bowl.ramen|chicken,noodles,carrot:boil|onion|The get-well-soon classic.
Beef Stew|soups|bowl|beef,potato,carrot:boil|onion|Slow, rich and chunky.
Garden Salad|snacks|salad|lettuce,tomato,cucumber:chop,mix|carrot,pepper|Crisp, crunchy and fresh.
Fruit Salad|snacks|salad.fruit|apple,banana,strawberry:chop,mix|blueberry,orange,honey|A rainbow of fruit.
Popcorn|snacks|pile.popcorn|kernels:zap||Pop, pop, pop!
Butter Popcorn|snacks|pile.popcorn|kernels:zap;butter:||Buttery movie-night popcorn.
Caramel Popcorn|snacks|pile.popcorn|kernels:zap;sugar,butter:hot||Sticky, sweet and crunchy.
Fries|snacks|pile.fries|potato:chop,fry||Crispy golden sticks.
Guacamole|snacks|bowl.guac|avocado,tomato,onion,lemon:chop,mix|tortilla|Chunky avocado dip.
Corn on the Cob|snacks|plate.corn|corn:boil;butter:||Sweet corn dripping with butter.
Cheesy Nachos|snacks|pile.nachos|tortilla:chop,bake;cheese:|tomato,avocado|Crunchy chips under melty cheese.
Chocolate Chip Cookies|desserts|cookie.choc|flour,butter,sugar,chocolate:mix,bake||Chewy middles, crispy edges.
Sugar Cookies|desserts|cookie|flour,butter,sugar:mix,bake|sprinkles|Simple, sweet and sprinkle-ready.
Vanilla Cupcakes|desserts|cupcake|flour,egg,sugar,butter:mix,bake|cream,sprinkles,strawberry|Fluffy little cakes with pink frosting.
Chocolate Cupcakes|desserts|cupcake|flour,egg,sugar,butter,chocolate,milk:mix,bake|cream,cherry|Rich cocoa cupcakes.
Strawberry Shortcake|desserts|cake.short|flour,egg,sugar:mix,bake;cream:;strawberry:chop||Sponge, cream and strawberries.
Chocolate Cake|desserts|cake.choc|flour,egg,sugar,chocolate,milk:mix,bake|cream|A dark, glossy slice.
Carrot Cake|desserts|cake.carrot|flour,egg,sugar,carrot:mix,bake|cream|Soft sponge with creamy frosting.
Apple Pie|desserts|cake.pie|flour,butter:mix,bake;apple:chop,bake;sugar:|cream|Lattice crust over sweet apples.
Banana Bread|desserts|cake.loaf|flour,egg,banana,sugar:mix,bake|chocolate|A cosy loaf for sharing.
Brownies|desserts|cake.brownie|chocolate,butter,egg,sugar,flour:mix,bake||Fudgy squares with a crackly top.
Strawberry Ice Cream|desserts|scoop|strawberry,milk,cream,sugar:stir,freeze||Pink scoops in a cup.
Matcha Ice Cream|desserts|scoop|matcha,milk,cream,sugar:stir,freeze|redbean|Cool, creamy green tea.
Mango Sorbet|desserts|scoop|mango,sugar:blend,freeze|lemon|Icy and bursting with mango.
Purin|desserts|scoop.purin|egg,milk,sugar:mix,bake|cream,cherry|Wobbly custard pudding with caramel.
Rainbow Popsicle|desserts|scoop.pop|strawberry,orange,blueberry:blend,freeze||A stripy frozen treat.`;
const RCATS = [['breakfast', 'Breakfast'], ['drinks', 'Drinks'], ['japanese', 'Japanese'], ['mains', 'Mains'], ['soups', 'Soups'], ['snacks', 'Snacks'], ['desserts', 'Desserts']];
const TOOLMAP = {chop: 'board', mix: 'bowl', blend: 'blender', roll: 'mat', boil: 'pot', fry: 'pan', bake: 'oven', zap: 'micro', freeze: 'freezer', hot: 'pot', stir: 'bowl'};
const RECIPES = RECIPE_SRC.split('\n').map((line, i) => {
  const [n, cat, art, needS, optS, desc] = line.split('|');
  const groups = needS.split(';').map(gs => { const [a, b] = gs.split(':'); return {ings: a.split(',').filter(Boolean), tags: (b || '').split(',').filter(Boolean)}; });
  const need = [...new Set(groups.flatMap(g => g.ings))], opt = (optS || '').split(',').filter(Boolean);
  const tools = [...new Set(groups.flatMap(g => g.tags).map(t => TOOLMAP[t]))];
  const r = {id: i, n, cat, art, groups, need, opt, desc, tools, weight: groups.reduce((a, g) => a + g.ings.length * (2 + g.tags.length), 0)};
  r.search = (n + ' ' + need.map(ingName).join(' ') + ' ' + opt.map(ingName).join(' ') + ' ' + desc).toLowerCase();
  return r;
});
for (const r of RECIPES) for (const k of [...r.need, ...r.opt]) if (!ING[k]) console.warn('unknown ingredient', k, r.n);

function tagOk(c, t){ if (t === 'hot') return c.tags.some(x => HEAT.has(x)); if (t === 'stir') return c.tags.includes('mix') || c.tags.includes('blend'); return c.tags.includes(t); }
function evalRecipe(r, comps){
  let pairs = 0, ok = 0, full = true; const missing = [];
  for (const g of r.groups) for (const ing of g.ings){
    const mine = comps.filter(c => c.ing === ing); pairs += 1 + g.tags.length;
    if (mine.length) ok++; else { full = false; missing.push({ing}); }
    for (const t of g.tags){ if (mine.some(c => tagOk(c, t))) ok++; else if (mine.length) missing.push({ing, tag: t}); }
    if (mine.length && !mine.some(c => g.tags.every(t => tagOk(c, t)))) full = false;
  }
  const all = new Set([...r.need, ...r.opt]);
  const extras = [...new Set(comps.map(c => c.ing))].filter(k => !all.has(k));
  return {r, full, cover: ok / pairs, missing, extras};
}
function detect(comps){
  if (!comps.length) return null;
  const evals = RECIPES.map(r => evalRecipe(r, comps));
  const full = evals.filter(e => e.full).sort((a, b) => b.r.weight - a.r.weight || a.extras.length - b.extras.length);
  if (full.length) return {match: full[0]};
  const near = evals.filter(e => e.cover >= .55 && e.cover < 1 && e.missing.length <= 3).sort((a, b) => b.cover - a.cover || b.r.weight - a.r.weight)[0];
  return {near};
}
// a single food that already is a whole recipe gets that recipe's look
function tagRecipe(food){
  const d = detect(food.comps);
  if (d && d.match && d.match.extras.length <= 1){ food.recipe = d.match.r.id; return RECIPES[food.recipe]; }
  return null;
}
const VERB = {chop: ['Chop', 'on the board'], mix: ['Mix', 'in the bowl'], blend: ['Blend', 'in the blender'], roll: ['Roll', 'on the bamboo mat'], boil: ['Boil', 'in the pot'], fry: ['Fry', 'in the pan'], bake: ['Bake', 'in the oven'], zap: ['Microwave', 'in the microwave'], freeze: ['Freeze', 'in the freezer'], hot: ['Heat', 'in the pot or microwave'], stir: ['Mix', 'in the bowl or blender']};
function productName(t, ings){
  const has = k => ings.includes(k);
  return {chop: ings.length > 1 ? 'pieces' : 'chopped ' + ingName(ings[0]).toLowerCase(), mix: has('flour') || has('egg') ? (has('flour') && !has('egg') && !has('milk') ? 'dough' : 'batter') : 'mixture', blend: 'blend', stir: 'mixture', roll: 'roll',
    boil: ings.length === 1 ? 'cooked ' + ingName(ings[0]).toLowerCase() : 'pot of food', fry: ings.length === 1 ? 'fried ' + ingName(ings[0]).toLowerCase() : 'fried mix', bake: 'bake', zap: ings.length === 1 && ings[0] === 'kernels' ? 'popcorn' : 'warm mix', freeze: 'frozen mix', hot: 'warm drink'}[t];
}
function joinNames(parts){ return parts.length < 2 ? parts.join('') : parts.slice(0, -1).join(', ') + ' and ' + parts[parts.length - 1]; }
function buildSteps(r){
  if (r._steps) return r._steps;
  const steps = [{text: `Take ${listNames(r.need)} from the fridge.`, check: {type: 'have', ings: r.need}}];
  const order = []; r.groups.forEach(g => g.tags.forEach(t => { if (!order.includes(t)) order.push(t); }));
  let batches = r.groups.map((g, i) => ({ings: g.ings.slice(), gi: [i], product: null}));
  for (const t of order){
    const gs = r.groups.map((g, i) => i).filter(i => r.groups[i].tags.includes(t));
    const bs = batches.filter(b => b.gi.some(i => gs.includes(i)));
    const allFirst = gs.every(i => r.groups[i].tags[0] === t);
    let targets = bs, labels = bs.map(b => b.product ? 'the ' + b.product : 'the ' + listNames(b.ings));
    if (!allFirst && bs.length > 1){
      const merged = {ings: bs.flatMap(b => b.ings), gi: bs.flatMap(b => b.gi), product: null};
      const lab = 'the ' + joinNames(bs.map(b => b.product ? b.product : listNames(b.ings)));
      batches = batches.filter(b => !bs.includes(b)).concat(merged); targets = [merged]; labels = [lab];
    }
    targets.forEach((b, k) => { steps.push({text: `${VERB[t][0]} ${labels[k]} ${VERB[t][1]}.`, check: {type: 'tag', ings: b.ings.slice(), tag: t}, tool: TOOLMAP[t]}); b.product = productName(t, b.ings); });
  }
  const plain = r.groups.filter(g => !g.tags.length).flatMap(g => g.ings);
  steps.push({text: plain.length ? `Put it on the plate with the ${listNames(plain)}, then serve.` : 'Put it on the plate and serve!', check: {type: 'plate', ings: r.need}, tool: 'plate'});
  if (r.opt.length) steps.optional = `Optional extras: ${listNames(r.opt)}.`;
  return (r._steps = steps);
}

// ================= how food looks =================
function compColor(c){ let col = ING[c.ing].mix; if (c.tags.includes('fry') || c.tags.includes('bake')) col = lerpC(col, '#D08A3A', .38); else if (c.tags.includes('boil')) col = lighten(col, .08); return col; }
const mixOf = comps => mixC(comps.map(c => [compColor(c), ING[c.ing].w]));
const FLAVOUR = new Set(['sugar', 'soy', 'ice', 'butter', 'honey', 'syrup', 'flour', 'milk', 'cream', 'nori', 'rice']);
function recipeSpec(r, foods){
  const comps = foods ? compsOf(foods) : null, present = new Set(comps ? comps.map(c => c.ing) : r.need.concat(r.opt.slice(0, 2)));
  const [art, style] = r.art.split('.');
  const ings = new Set([...r.need, ...r.opt.filter(o => present.has(o))]);
  const base = r.groups.reduce((a, g) => g.tags.length > a.tags.length ? g : a, r.groups[0]);
  let main = mixC(base.ings.map(k => [ING[k].mix, ING[k].w]));
  if (base.tags.includes('fry') || base.tags.includes('bake')) main = lerpC(main, '#E0A050', .45);
  const others = [...ings].filter(k => !base.ings.includes(k));
  let tops = others.filter(k => !FLAVOUR.has(k)).map(k => ING[k].c);
  const has = k => ings.has(k), protein = [...ings].find(k => PROTEIN.has(k));
  const sp = {art, style, main, tops, ings};
  switch (art){
    case 'maki': sp.tops = [...ings].filter(k => k !== 'rice' && k !== 'nori' && !FLAVOUR.has(k)).map(k => ING[k].c); break;
    case 'onigiri': sp.main = protein ? ING[protein].c : '#F4895A'; sp.tops = protein && style !== 'nigiri' ? [ING[protein].c] : []; break;
    case 'stack': sp.main = style === 'choc' ? '#7A4A33' : style === 'okonomi' ? '#E8B26A' : style === 'dorayaki' ? '#E8A44A' : style === 'crepe' ? '#F6D58A' : '#EBB25A'; sp.tops = [...ings].filter(k => FRUIT.has(k) && !base.ings.includes(k) || (k === 'blueberry')).map(k => ING[k].c); break;
    case 'toast': sp.main = '#E2A55A'; sp.tops = [...ings].filter(k => FRUIT.has(k)).map(k => ING[k].c); break;
    case 'glass': case 'mug': sp.main = lighten(mixC(base.ings.map(k => [ING[k].mix, ING[k].w])), .06); sp.tops = [...ings].filter(k => FRUIT.has(k) && !base.ings.includes(k)).map(k => ING[k].c); if (style === 'parfait') sp.main = '#FFF4F7'; break;
    case 'bowl':
      if (style === 'curry') sp.main = '#B8732A'; else if (style === 'ramen') sp.main = has('soy') ? '#E0B070' : '#F6E3B8'; else if (style === 'porridge') sp.main = '#EEDCB8'; else if (style === 'pasta') { sp.main = '#F7D27A'; sp.tops = has('tomato') ? ['#E84A3A'] : ['#FFF0C0']; } else if (style === 'mac') sp.main = '#F7C24A'; else if (style === 'don') sp.main = '#FFD45A'; else if (style === 'mash') sp.main = '#FFF0C8'; else if (style === 'guac') sp.main = '#A8D46A'; else sp.main = lighten(main, .1);
      if (style === 'ramen' || style === 'curry' || !style) sp.tops = [...ings].filter(k => !FLAVOUR.has(k) && k !== 'noodles' && k !== 'curry').map(k => ING[k].c); sp.hot = true; break;
    case 'salad': sp.tops = [...ings].filter(k => !LEAFY.has(k) && !FLAVOUR.has(k)).map(k => ING[k].c); break;
    case 'scoop': sp.main = lighten(mixC([...ings].filter(k => !['sugar', 'milk', 'cream'].includes(k)).map(k => [ING[k].mix, 1])), .25); sp.tops = [...ings].filter(k => FRUIT.has(k)).map(k => ING[k].c); if (style === 'mochi') sp.main = has('matcha') ? '#CDE8A8' : has('strawberry') ? '#FFC2D2' : '#FFF0F4'; break;
    case 'cookie': sp.main = '#E8B26A'; break;
    case 'cupcake': sp.main = has('chocolate') ? '#7A4A33' : has('banana') ? '#E8C07A' : '#E9B45A'; sp.frost = has('chocolate') ? '#8A5A3E' : '#FFB3CF'; sp.tops = [...ings].filter(k => ['strawberry', 'cherry', 'blueberry'].includes(k)).map(k => ING[k].c); if (r.art === 'cupcake' && !has('sugar')) sp.style = 'muffin'; break;
    case 'cake': sp.main = style === 'choc' ? '#6B3A26' : style === 'carrot' ? '#E8A060' : style === 'loaf' ? '#D9A060' : style === 'brownie' ? '#5A2E1E' : '#F6E0A8'; sp.tops = style === 'pie' ? [ING.apple.c2] : style === 'short' ? ['#F0475E'] : []; break;
    case 'pizza': sp.tops = [...ings].filter(k => !['flour', 'tomato', 'cheese'].includes(k) && !FLAVOUR.has(k)).map(k => ING[k].c); break;
    case 'pile': if (style === 'fries') sp.main = '#FFD24A'; else if (style === 'noodle') sp.main = '#C8955A'; else if (style === 'rice') sp.main = '#F6E7B8'; else if (style === 'dumpling') sp.main = '#D9954A'; else if (style === 'tempura') sp.main = '#F2C47A';
      sp.tops = [...ings].filter(k => !FLAVOUR.has(k) && k !== 'noodles').map(k => ING[k].c); if (style === 'popcorn' && has('sugar')) sp.ings = new Set([...ings, 'caramel']); if (!style) sp.cook = .8; break;
    case 'egg': sp.main = '#FFD84A'; sp.tops = [...ings].filter(k => ING[k].cat === 'veg').map(k => ING[k].c); break;
    case 'plate': sp.main = style === 'roast' ? '#C8742E' : '#8A3A2A'; sp.tops = [...ings].filter(k => ING[k].cat === 'veg').map(k => ING[k].c); break;
  }
  if (foods){ const q = foods.reduce((a, f) => worstQ(a, f.q), null); sp.burnt = q === 'burnt'; }
  return sp;
}
function foodSpec(food){
  if (food.recipe != null) { const sp = recipeSpec(RECIPES[food.recipe], [food]); sp.steam = food.hot > clock; return sp; }
  return genericSpec(food.comps, food.hist, food);
}
function genericSpec(comps, hist, food){
  const ings = new Set(comps.map(c => c.ing)), has = k => ings.has(k), last = hist[hist.length - 1], some = set => [...ings].some(k => set.has(k));
  const cols = [...ings].filter(k => !FLAVOUR.has(k) || ings.size === 1).map(k => compColor(comps.find(c => c.ing === k)));
  const sp = {ings, main: mixOf(comps), tops: cols, burnt: food && food.q === 'burnt', cook: food ? food.cook : 0, steam: food && food.hot > clock};
  const only = list => [...ings].every(k => list.includes(k));
  if (!last) return comps.length === 1 ? {...sp, art: 'raw', ing: comps[0].ing} : {...sp, art: 'chunks', pieces: [...ings]};
  switch (last){
    case 'chop': return hist.includes('roll') ? {...sp, art: 'maki', tops: [...ings].filter(k => k !== 'rice' && k !== 'nori').map(k => ING[k].c)} : {...sp, art: 'chunks', pieces: [...ings]};
    case 'roll': return has('egg') && !has('rice') ? {...sp, art: 'egg', style: 'tamago'} : {...sp, art: 'log', tops: [...ings].filter(k => k !== 'rice' && k !== 'nori').map(k => ING[k].c)};
    case 'mix':
      if (only([...FRUIT, 'honey', 'sugar'])) return {...sp, art: 'salad', style: 'fruit'};
      if (some(LEAFY) && !has('flour') && !has('egg')) return {...sp, art: 'salad'};
      if (has('ice')) return {...sp, art: 'glass', style: 'ice'};
      if (has('yogurt') && has('oats')) return {...sp, art: 'glass', style: 'parfait'};
      return {...sp, art: 'bowl', style: 'batter', tops: []};
    case 'blend': return hist.includes('boil') ? {...sp, art: 'bowl', style: 'smooth'} : {...sp, art: 'glass', style: has('ice') && has('milk') ? 'shake' : '', tops: []};
    case 'freeze': return hist.includes('blend') && !has('milk') && !has('cream') && !has('yogurt') ? {...sp, art: 'scoop', style: 'pop', tops: cols} : {...sp, art: 'scoop', main: lighten(sp.main, .2), tops: []};
    case 'boil':
      if (has('noodles')) return {...sp, art: 'bowl', style: 'ramen', main: has('soy') ? '#E0B070' : '#F6E3B8', tops: cols.filter((c, i) => [...ings].filter(k => !FLAVOUR.has(k) || ings.size === 1)[i] !== 'noodles')};
      if (has('pasta')) return {...sp, art: 'bowl', style: 'pasta', main: '#F7D27A', tops: has('tomato') ? ['#E84A3A'] : ['#FFF0C0']};
      if (has('curry')) return {...sp, art: 'bowl', style: 'curry', main: '#B8732A'};
      if (has('oats')) return {...sp, art: 'bowl', style: 'porridge', main: '#EEDCB8'};
      if (has('rice') && ings.size <= 2) return {...sp, art: 'bowl', style: 'rice', main: '#FFFFFF'};
      if (only([...LIQUID, 'sugar', 'ice'])) return {...sp, art: 'mug'};
      return {...sp, art: 'bowl', main: lighten(sp.main, .15), hot: true};
    case 'fry':
      if (has('egg') && !has('flour') && !has('bread') && !has('rice') && !has('noodles') && !has('tortilla')) return {...sp, art: 'egg', style: hist.includes('mix') ? (has('cheese') || some(new Set(['pepper', 'onion', 'mushroom', 'tomato'])) ? 'omelette' : 'scramble') : has('bacon') ? 'bacon' : '', tops: [...ings].filter(k => ING[k].cat === 'veg').map(k => ING[k].c)};
      if (has('flour') && (has('egg') || has('milk')) && hist.includes('mix')) return {...sp, art: 'stack', main: has('chocolate') ? '#7A4A33' : '#EBB25A', tops: [...ings].filter(k => FRUIT.has(k)).map(k => ING[k].c)};
      if (has('bread')) return {...sp, art: 'toast', style: has('cheese') ? 'grilled' : has('egg') ? 'french' : '', main: '#D9954A'};
      if (has('potato') && hist.includes('chop')) return {...sp, art: 'pile', style: 'fries', main: '#FFD24A'};
      if (has('noodles')) return {...sp, art: 'pile', style: 'noodle', main: '#C8955A'};
      if (has('rice')) return {...sp, art: 'pile', style: 'rice', main: '#F6E7B8'};
      if (has('tortilla')) return {...sp, art: 'taco', style: 'quesadilla'};
      if (has('flour')) return {...sp, art: 'pile', style: 'tempura', main: '#F2C47A'};
      return {...sp, art: 'pile'};
    case 'bake':
      if (has('flour')){ if (has('sugar')) return has('egg') ? {...sp, art: has('milk') ? 'cake' : 'cupcake', main: lerpC(sp.main, '#E9A84C', .5), frost: '#FFB3CF'} : {...sp, art: 'cookie', style: has('chocolate') ? 'choc' : ''}; return has('tomato') || has('cheese') ? {...sp, art: 'pizza', tops: cols.filter((c, i) => true).slice(3)} : {...sp, art: 'cake', style: 'loaf', main: '#D9A060'}; }
      if (has('bread')) return {...sp, art: 'toast', main: '#E2A55A', style: has('cheese') ? 'cheese' : ''};
      if (has('tortilla')) return {...sp, art: 'pile', style: 'nachos'};
      if (has('potato') && !hist.includes('chop')) return {...sp, art: 'plate', style: 'potato'};
      if (has('chicken') && ings.size <= 2) return {...sp, art: 'plate', style: 'roast'};
      return {...sp, art: 'pile'};
    case 'zap':
      if (has('kernels')) return {...sp, art: 'pile', style: 'popcorn'};
      if (only([...LIQUID, 'sugar'])) return {...sp, art: 'mug'};
      return {...genericSpec(comps, hist.slice(0, -1), food), steam: true};
  }
  return {...sp, art: 'chunks', pieces: [...ings]};
}
const NOUN = {glass: 'Smoothie', mug: 'Warm Drink', bowl: 'Soup', salad: 'Salad', stack: 'Pancakes', egg: 'Eggs', toast: 'Toast', pile: 'Bites', cookie: 'Cookies', cake: 'Cake', cupcake: 'Cupcakes', scoop: 'Ice Pop', chunks: 'Medley', raw: 'Snack', log: 'Roll', maki: 'Maki', pizza: 'Flatbread', taco: 'Wrap', plate: 'Plate'};
const ADJ = {chop: 'Chopped', mix: 'Mixed', blend: '', roll: 'Rolled', boil: 'Simmered', fry: 'Crispy', bake: 'Baked', zap: 'Zapped', freeze: 'Frozen'};
function inventName(foods){
  const comps = compsOf(foods), ings = [...new Set(comps.map(c => c.ing))];
  const rank = k => (PROTEIN.has(k) ? 0 : FRUIT.has(k) ? 1 : ING[k].cat === 'veg' ? 2 : FLAVOUR.has(k) ? 5 : 3);
  const mains = ings.slice().sort((a, b) => rank(a) - rank(b)).slice(0, 2).map(ingName);
  const f = foods[0], sp = foodSpec(f), last = f.hist[f.hist.length - 1];
  if (foods.length === 1 && !last && comps.length === 1) return `A Whole ${mains[0]}`;
  const noun = sp.art === 'bowl' && sp.style === 'batter' ? 'Batter' : sp.art === 'bowl' && sp.style === 'rice' ? 'Rice Bowl' : NOUN[sp.art] || 'Surprise';
  const adj = ADJ[last] || '';
  return `${adj ? adj + ' ' : ''}${mains.join(' & ')} ${noun}`.replace(/\s+/g, ' ');
}
