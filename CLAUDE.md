# Cosy Kitchen: notes for Claude Code

A cosy, anime-style ASMR cooking and café game in **two editions**:
- **Godot 3D edition** in `godot/`, the main product. See "Godot edition" below.
- **Web edition**: one self-contained HTML file (`src/` → `dist/`). No images, audio files or libraries. Art is procedural `<canvas>` and sound is Web Audio. Everything after the Godot section is about the web edition.

Both editions share the same recipe data and rules. If you change recipes, prices or detection in one, port the change to the other (`src/04-food-and-recipes.js`, `src/06-shop.js` ↔ `godot/scripts/autoload/game_data.gd`).

# Godot edition (`godot/`)

Godot **4.6.2**, Forward+ renderer, base resolution 1920×1080 (`canvas_items` stretch). Most of the scene is built in code; `scenes/main.tscn` is just a `Game` node.

Since v3 it's a life sim: you're a chibi chef who walks between three **locations** (your café, Hoshizora Town, your apartment), cooks at the café's stations, carries dishes to customers, shops in town, decorates, dates, marries and raises a family. There's a story mode (8 chapters of quests) and freeplay, plus cheat codes.

## Commands (Git Bash, from `godot/`)
- `tools/gd.sh import`: import assets and refresh the class cache. Run it after adding files or changing `.import` settings.
- `tools/gd.sh test`: the headless test suite (`tests/test_runner.gd` + `tests/test_gameplay.gd` + `tests/test_playthrough.gd`). The playthrough is a bot that plays like a person with **no teleporting**: it walks every route on the real nav grid (flagging stuck/blocked/never-arrived walks), presses E at doors, stations and people, clicks real UI buttons, cooks whatever customers order with each station's buttons and carries plates out, then shops, places furniture, dates, marries and has a baby. Stress it with `"$GODOT" --headless --path . res://tests/test_runner.tscn -- --test --serve=100` (serves 100 random orders). Add `--quick` to skip the playthrough.
- `"$GODOT" --headless --path . -- --dev=navreport [--map] [--obs]`: checks every location's walk grid (unreachable areas, unreachable doors/stations/seats) and prints ASCII maps. Run it after changing a Blender room or the default furniture. It checks recipes and art, then plays a whole life through the real systems: walk to the café, take an order, cook with gestures, carry the plate to the customer, critic reviews, edit mode, chatting/gifts/dates, wedding, a baby, sleeping, cheats and a save round trip. **Run it after every change.** Tests set `game.instant = true` (walking, fades and dialogue resolve immediately).
- `tools/gd.sh shot res://scenes/main.tscn <out.png> [frames] [WxH] --dev=<mode>`: screenshot a staged scene. Modes: `home`, `home:family`, `cafe`, `city`, `city:<x>`, `park`, `date`, `wedding`, `service`, `service:carry`, `edit`, any station key (`board`, `pan`…), `title`, `creator`, `dialogue`, `shop:<market|homestore|boutique|florist|jeweler|bookshop>`, `journal`, `news`, `book`, `detail`, `ticket`, `result`, `summary`, `console`. Dev runs start a fresh story save.
- `tools/gd.sh shot res://scenes/dev_sheet.tscn <out.png> 3 1920x1080 --sheet=ingredients|pieces|dishes [--page=0|1]`: contact sheets of all food art.
- Release: `tools/release.sh <version> "notes"` bumps the version, tests, exports `build/windows/Cosy-Kitchen.exe` and `build/web/`, pushes, creates the GitHub release (repo in `application/config/github_repo`, currently `tacticaldev1/cosy-kitchen`) and deploys the web build to GitHub Pages (`gh-pages` branch). The in-game updater (`autoload/updater.gd`) looks for the release asset named exactly `Cosy-Kitchen.exe` and compares its tag with `application/config/version`.
- Web build: the Compatibility renderer (WebGL 2) leaves **instance uniforms at zero**, so every instance uniform must default to 0 meaning "normal" (that's why it's `fade_out`, not `fade`).
- Dev, test and screenshot runs use `user://test_save.json` and never touch the player's save.

## Asset pipelines (generated, don't hand-edit the outputs)
- **Blender rooms** (`tools/blender/`, shared helpers in `lib.py`): `build_cafe.py` (walkable café: kitchen, pass with bar stools, dining room, street door), `build_city.py` (the shop street and park), `build_home.py` (the apartment). Run as `blender -b -P tools/blender/build_<x>.py -- <abs path>/assets/models/<x>.glb`. Material names carry flags (`noline`, `glass`, `glow`/`emit`, `wall`/`panel` and `floor_d_<n>` for themable surfaces). Empties named `mark_*` are anchors; `obs_<i>_<w>_<d>` empties are walk-grid obstacles. Static meshes are joined before export to keep draw calls low.
- **Audio**: `npm run godot:audio` (from the project root) renders the web edition's synth into `assets/audio/`. After re-rendering, check that `loops/*.wav.import` still has `edit/loop_mode=2`.

## Source map (`godot/scripts/`)
| Path | What lives there |
|---|---|
| `autoload/game_data.gd` (`G`) | Ingredients, the 100 recipes, prices, food model, `detect`, `build_steps`, specs, and **difficulty** (`G.difficulty(r)` 1–5 chef hats, ranked across the menu; `G.diff_bonus(r)` tip bonus). |
| `autoload/save_state.gd` (`Save`) | Persistent JSON save (version 3, migrates v2 saves): recipes, wallet, café rating `reputation` and critic `reviews`, the clock (`minute`), `energy`, `weather`, player name/look, furniture `layouts`/`themes`/`furni_inv`, market `pantry`, `gifts`, relationships `rel` (`Save.r(id)`, `hearts`, `add_hearts`), `partner`/`married`/`family`, story `chapter`/`flags`. `new_game(mode, name, look)`. |
| `autoload/audio.gd`, `photo_booth.gd`, `updater.gd` | `Sfx`, `Photo` (3D → cached icon textures; `opts.focus` frames portraits), `Updater`. |
| `art/*` | `MB` mesh builder, `Toon` shading, ingredient/dish/food art. |
| `world/chibi.gd` (`Chibi`) | Every character: build from a look dict (adult/child/toddler/baby/cat), walk along paths, sit, wave, eat, carry. `world/customer.gd` and `game/player.gd` extend it. |
| `world/room.gd` (`Room`) | Loads a GLB, applies toon materials, collects `mark_*` and `obs_*`, recolours walls/floors; shared interior lighting helpers. |
| `world/appliances.gd` (`Appl`) | Appliance models with named moving parts (Knife, Whisk, Jug, Dial…). |
| `stations/*.gd` | `Station` base and one script per station. |
| `game/game.gd` (`Game`) | Orchestrator: locations and `travel()`, the player and follow camera, station close-ups (`open_station` walks you there first), input (WASD/click/E), focus prompts, the counter, buying, `serve()` (plate → your hands) / `deliver()` / `eat_carried()`, dates, the wedding and family scenes, dev scenes. `Game.sim(seconds)` for tests. |
| `game/locations/*.gd` | `Location` base (room, `NavGrid`, furniture, interactables, `npcs`), `CafeLocation` (stations, stand points, OPEN sign, seats), `CityLocation` (shops, townsfolk, Grandpa Jiro, walkers, sky by hour, rain, park bench dates, wedding), `HomeLocation` (bed, kitchenette, wardrobe, TV, spouse and kids). |
| `game/nav_grid.gd`, `furniture.gd` (`Furni`), `furniture_layer.gd`, `edit_mode.gd` | A* walk grid; the furniture catalogue, models and seats; placed furniture per room; edit mode (pick up, move, rotate, store, place from storage). |
| `game/shop.gd` (`Shop`) | Café hours (8:00 to last orders 21:30), customers walking to random free table/bar seats, orders by difficulty, patience, tips, reputation, townsfolk regulars (hearts), critics and their reviews. |
| `game/life.gd` (`Life`) | Clock (1 real second = 1 game minute), energy, sleep and mornings (newspaper, wedding, pregnancy, birth, kids growing), talking/gifts/dates/partner/proposal, family, story checks, `cheat(code)`. |
| `game/people.gd` (`People`), `game/story.gd` (`Story`) | Townsfolk data, gifts, dialogue lines and date questions; story chapters and quest checks. |
| `ui/hud.gd` (`Hud`), `ui/life_ui.gd` (`LifeUI`) | Cooking HUD (top bar, ticket, toolbar, counter, footer, book, result, settings, title). `LifeUI`: status card, prompt, carry panel, fades (incl. the tasteful family fade), dialogue with portraits and choices, shops, character creator/boutique with live preview, journal, newspaper, cheat console, edit-mode storage bar. `Hud` forwards to it. |

## Gotchas
- GDScript lambdas capture locals **by value**. Panels keep the modal in a dictionary (`mh.w`) so close buttons can reach it.
- Godot's importer turns "." in node names into "_", so `obs_3_3.48_0.70` arrives as `obs_3_3_48_0_70`; `Room` handles both.
- Seats have an `approach` point (behind or beside the chair) that customers walk to before sitting; seats whose approach isn't reachable are skipped. Edit mode refuses placements that cut off a door, station, bed or you (`EditMode.blocks_paths`).
- Characters have a body type in their look (`body`: `f`/`m`, `bottom`: pants/shorts/skirt/dress); `Chibi.body_of()` guesses it for old saves.
- Dialogue option buttons are removed immediately when a choice is made (not just queued for deletion), so quick clicks can't hit stale options.
- Warnings are errors: `var x := …` can't infer a type from untyped arrays, dictionaries or ternaries. Use `var x: float = …`.
- Locations overlap at the origin; only the active one is visible and processing, and it owns the one `WorldEnvironment`.
- Godot's SVG loader ignores `<text>`. Draw icons with paths.
- Theme variation names must not clash with built-in class names (that's why it's `SkyBtn`, not `Sky`).
- If you add a spec field that changes how food looks, add it to `G.spec_key`.
- Family content stays tasteful: the "starting a family" moment is a dim, hearts and fade to black, never more.

# Web edition

## Commands
- `npm run build`: concatenate `src/` into `dist/index.html` (standalone page) and `dist/artifact.html` (the same game without doctype/head/body, for a Claude artifact).
- `npm run dev`: build, then serve `dist/` at http://localhost:5173.
- `npm test`: build, then run the Playwright smoke test (`tests/smoke.mjs`). It checks that all 100 recipes are detected, that a full customer order works and that every dish renders. **Run it after every change.**
- `npm run sheets`: render every ingredient and every dish to `tests/sheet-*.png`. Look at these after any art change.
- First-time setup: `npm install` and then `npx playwright install chromium`.

There is no bundler. `scripts/build.mjs` joins `src/*.js` **in filename order** inside one IIFE, so every file shares one scope. Order matters only for code that runs at load time. Top-level `const`/`let` used by a function are fine as long as the function is first *called* after load.

## Source map (`src/`)
| File | What lives there |
|---|---|
| `shell.html` | `<title>`, CSS (tokens at the top, polish overrides at the bottom), and the HTML for the header, toolbar, sheets (fridge, recipe book, ticket, result) and footer. |
| `01-core.js` | Constants (logical canvas **400×640**, `CX/CY`), drawing helpers (`rr`, `disc`, `ell`, `ring`, `fillLine`, `face`), colour maths, the **automatic shading engine** and all synthesised audio (`SND.*`, `loopSnd`). |
| `02-ingredients.js` | `ING_DEF` (59 ingredients: name, category, shape, colours) and `drawIng` (whole ingredient), `piece` (chopped piece). |
| `03-dish-art.js` | `ART[artName](g, spec)`: every dish picture, tableware (`plate`, `bowl`, `woodBoard`), `garnish(g, ingKey, …)`, and the sprite cache (`drawArt` → `bakeArt`). |
| `04-food-and-recipes.js` | Food model, the 100-line `RECIPE_SRC`, recipe detection (`detect`), auto-generated step instructions (`buildSteps`), and how food *looks* (`recipeSpec`, `genericSpec`, `inventName`). |
| `05-stations.js` | The 11 stations in `ST`: board, bowl, blender, mat, pot, pan, oven, micro, freezer, plate and bin. Upgrades (one-tap buttons, ready and burn alerts) are at the bottom. |
| `06-shop.js` | Prices (`ING_COST`, `MENU_PRICE`), customers, orders, patience, serving and the day summary. Also the canvas drawing for customers, speech bubbles, the OPEN sign and the order ticket. |
| `07-flow.js` | Ticket popup with **Buy all** (`openTicket`, `buyFor`), the "Next: Pan" hint (`nextHint`) and food flying between the counter and stations (`flyers`). |
| `08-ui-and-main.js` | Saving (localStorage keys `ck-found`, `ck-wallet`, `ck-day`, `ck-pinned`), background layers, toolbar, fridge, counter, recipe book (search and filters), footer sync, input, render loop and `start()`. Also `window.__ck` test hooks. |

## Core concepts
**Food.** `{uid, comps: [{ing, tags: []}], hist: [], cook, q, recipe}`. Processes are `chop mix blend roll boil fry bake zap freeze`. A station calls `applyProc` (one food) or `mergeFoods` (several foods become one). `q` is a quality from `cookQ(level)`: `under | ok | perfect | burnt`.

**Recipes.** Each line of `RECIPE_SRC` is `Name|category|art.style|groups|optional|description`.
- Groups are `ing,ing:tag,tag;ing:tag` and are separated by `;`. Each ingredient in a group needs **all** of that group's tags.
- `hot` means any heat (boil, fry, bake or zap). `stir` means mix or blend.
- Detection picks the heaviest fully-satisfied recipe. If none is satisfied, it reports a "near miss" with the missing step.
- `buildSteps` writes the instructions automatically from the groups.
- Adding a recipe:
  1. Add a line to `RECIPE_SRC`.
  2. Add its price to `MENU_PRICE` in `06-shop.js`.
  3. Run `npm test`. A new recipe must not "steal" detection from an existing one.

**Art.**
- `ART[name](g, sp)` draws around (0,0) and must stay inside about x −95…95, y −100…85.
- `sp` (from `recipeSpec`/`genericSpec`) has `art, style, main, tops, ings (Set), pieces, ing, frost, cook, burnt, steam, hot`.
- `drawArt` bakes each spec once into a sprite, with shading, a light pass and a drop shadow, and caches it by `specKey(sp)`. **If you add a spec field that changes the picture, add it to `specKey`.** Animated bits (steam, smoke) are drawn live on top.

**Shading engine** (`01-core.js`).
- `CanvasRenderingContext2D` path methods are wrapped so every path knows its bounding box.
- `fillLine(g, '#hex')`, `paint(g, '#hex')` and `ell(..., stroke)` automatically add a highlight, a soft cel shadow and a specular glint. Gradients and `rgba()` fills are left alone.
- Set `GFX.shade = false` to compare without it.

**Stations.** Each station is a `mk({...})` object with any of these:
- `hint()` and `meter()`: the footer text and progress bar.
- `btn()` and `onBtn()`: the main footer button.
- `busy()`
- `down`, `move` and `up(p)`: pointer handlers in logical coordinates.
- `update(dt)` and `draw(g)`
- `auto()`: what Space or Enter does.

The heat stations use `heatStation()`. Finished food goes through `produce(food)`, which flies it to the counter.

## Constraints to keep
- It must stay a **single HTML file** with no network fetches. The only external resource is Google Fonts, and the game falls back gracefully without it.
- It must work at **phone width**: the logical canvas scales to fit, and the device pixel ratio is capped at 2 for performance.
- Wrap every `localStorage` access in try/catch. Don't use `alert`, `confirm` or `prompt`; they are blocked in Claude artifacts.
- Sound only starts after a user gesture (`initAudio()` is called on the first tap).
- The look is pastel anime: plum outlines (`PLUM = #3B2340`), soft gradients, kawaii faces on appliances.

## Ideas backlog
- Unlockable kitchen decorations and themes bought with earnings.
- More customer personalities: picky eaters, regulars, VIPs with special orders.
- Plating and decoration mode with free-placed toppings.
- A save slot and export.
- More appliances: rice cooker, toaster, steamer, grill.
- An actual audio mixer screen (ASMR volume per sound type).
