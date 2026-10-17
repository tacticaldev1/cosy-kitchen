# Cosy Kitchen: notes for Claude Code

A cosy, anime-style ASMR cooking and café game in **two editions**:
- **Godot 3D edition** in `godot/`, the main product. See "Godot edition" below.
- **Web edition**: one self-contained HTML file (`src/` → `dist/`). No images, audio files or libraries. Art is procedural `<canvas>` and sound is Web Audio. Everything after the Godot section is about the web edition.

Both editions share the same recipe data and rules. If you change recipes, prices or detection in one, port the change to the other (`src/04-food-and-recipes.js`, `src/06-shop.js` ↔ `godot/scripts/autoload/game_data.gd`).

# Godot edition (`godot/`)

Godot **4.6.2**, Forward+ renderer, base resolution 1920×1080 (`canvas_items` stretch). Most of the scene is built in code; `scenes/main.tscn` is just a `Game` node.

## Commands (Git Bash, from `godot/`)
- `tools/gd.sh import`: import assets and refresh the class cache. Run it after adding files or changing `.import` settings.
- `tools/gd.sh test`: the headless test suite (`tests/test_runner.gd` + `tests/test_gameplay.gd`). It checks recipe detection and that every dish and ingredient builds, then plays a full order through the real stations, gestures and shop. **Run it after every change.**
- `tools/gd.sh shot res://scenes/main.tscn <out.png> [frames] [WxH] --dev=<mode>`: screenshot a staged scene. Modes: `overview`, any station key (`board`, `pan`…), `service`, `service_over`, `title`, `book`, `detail`, `result`, `decor`, `summary`, plus `input`, which clicks through real OS events and prints the results. Add `--fps` to a service mode to print frame stats.
- `tools/gd.sh shot res://scenes/dev_sheet.tscn <out.png> 3 1920x1080 --sheet=ingredients|pieces|dishes [--page=0|1]`: contact sheets of all art. Look at them after any art change.
- Release: `tools/release.sh <version> "notes"` bumps the version, tests, exports `build/windows/Cosy-Kitchen.exe` and `build/web/`, pushes, creates the GitHub release (repo in `application/config/github_repo`, currently `tacticaldev1/cosy-kitchen`) and deploys the web build to GitHub Pages (`gh-pages` branch). The in-game updater (`autoload/updater.gd`) looks for the release asset named exactly `Cosy-Kitchen.exe` and compares its tag with `application/config/version`.
- Web build: the Compatibility renderer (WebGL 2) leaves **instance uniforms at zero**, so every instance uniform must default to 0 meaning "normal" (that's why it's `fade_out`, not `fade`).
- Dev, test and screenshot runs use `user://test_save.json` and never touch the player's save.

## Asset pipelines (generated, don't hand-edit the outputs)
- **Café room**: `tools/blender/build_cafe.py`, run as `blender -b -P tools/blender/build_cafe.py -- <abs path>/assets/models/cafe.glb`. Material names carry flags: `noline`, `glass` and `glow`/`emit`. Empties named `mark_*` are anchors (stations, seats, door, lamps…). Groups named `decor_*` are the buyable decorations. Static meshes are joined before export to keep draw calls low.
- **Audio**: `npm run godot:audio` (from the project root). It renders the web edition's own `SND` synth, cut straight from `src/01-core.js` and `src/06-shop.js`, through Chrome's OfflineAudioContext into `assets/audio/sfx/<name>_<n>.wav` (random variations), seamless `loops/*.wav` and three composed lo-fi tracks in `music/`. After re-rendering, check that `loops/*.wav.import` still has `edit/loop_mode=2`.

## Source map (`godot/scripts/`)
| Path | What lives there |
|---|---|
| `autoload/game_data.gd` (`G`) | Ingredients, the 100 recipes (same `RECIPE_SRC` format as the web), prices, food model (`new_food`, `apply_proc`, `merge_foods`), `detect`, `build_steps`, `recipe_spec`/`generic_spec`/`food_spec`, `spec_key`, `invent_name`. |
| `autoload/save_state.gd` (`Save`) | Persistent JSON save: found recipes, wallet, day, decorations, regulars' hearts, stars → café level, settings. |
| `autoload/audio.gd` (`Sfx`) | `Sfx.play(name, intensity, pitch)`, `Sfx.loop(name)` (returns a handle with `set_param`/`stop`), ambience, music playlist and SFX/Ambience/Music buses. |
| `autoload/photo_booth.gd` (`Photo`) | Renders 3D food into cached icon textures (`Photo.recipe/ingredient/food/spec/request`). Textures fill in a frame later. |
| `art/mesh_builder.gd` (`MB`) | Procedural mesh toolkit: lathe, tube, rbox, puck, extrude, blob, leaf, torus. It has a transform stack and per-vertex colour/outline/gloss. `layer(1)` writes glass geometry. |
| `art/toon.gd`, `shaders/toon.gdshader`, `outline.gdshader`, `glass.gdshader`, `particle.gdshader` | The look: cel bands, lavender ambient shadows, rim light and glints, plus constant-pixel plum outlines (inverted hull). Per-instance knobs: `cook` (browning to burnt), `frost`, `flash`, `fade`. |
| `art/ing_art.gd` (`IngArt`) | The 59 ingredients (`build`) and chopped pieces (`piece`). |
| `art/dish_art.gd` (`DishArt`) | Every dish type (`stack`, `bowl`, `glass`, `maki`…), tableware and garnishes. `DishArt.bare` skips plates and bowls for previews inside pans and pots. |
| `art/food_art.gd` (`FoodArt`) | Spec → cached mesh → node (`spec_node`, `food_node`, `ingredient_node`). |
| `world/cafe.gd` | Loads `cafe.glb`, applies toon materials, lights, the rainy window shader, time of day and decor toggles. |
| `world/appliances.gd` (`Appl`) | Procedural appliance models with named moving parts (Knife, Whisk, Jug, Dial, Keys, Turntable…). |
| `world/face.gd`, `world/customer.gd`, `world/fx.gd` | Kawaii faces with moods; chibi customers (and the café cat); particle presets. |
| `stations/*.gd` | `Station` base (items, 3D item models, screen-space gestures) and one script per station. `HeatStation` holds the pot/pan/oven cook meter, alerts and live preview. |
| `game/game.gd` (`Game`) | Builds the world, places stations on the `mark_*` anchors, runs the camera (overview ↔ station close-ups), routes input, and handles the counter, buying, serving, the guide, feedback and dev scenes. `Game.sim(seconds)` steps the simulation for tests. |
| `game/shop.gd` (`Shop`) | Opening hours (`DAY_LEN`), customer spawning (regulars, critic, cat), orders, patience, payment and tips, day summary. |
| `ui/*.gd` | `UI` theme and SVG icons, `Hud` (top bar, ticket, toolbar, counter, footer, toasts, all panels), `BookPanel`, and `Turntable` (a spinning 3D dish in UI). |

## Gotchas
- GDScript lambdas capture locals **by value**. Panels keep the modal in a dictionary (`mh.w`) so close buttons can reach it.
- `var x := …` can't infer a type from untyped arrays or ternaries. Use `var x: float = …` or untyped `var x = …`.
- Godot's SVG loader ignores `<text>`. Draw icons with paths.
- Theme variation names must not clash with built-in class names (that's why it's `SkyBtn`, not `Sky`).
- Built-in particle materials rendered alpha wrongly here. Particles use `shaders/particle.gdshader`.
- If you add a spec field that changes how food looks, add it to `G.spec_key` (and `bare` is appended in `FoodArt.spec_mesh`).

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
