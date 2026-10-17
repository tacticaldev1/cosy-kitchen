# Cosy Kitchen

**[⬇ Download for Windows](https://github.com/tacticaldev1/cosy-kitchen/releases/latest/download/Cosy-Kitchen.exe)** · **[▶ Play in your browser](https://tacticaldev1.github.io/cosy-kitchen/)**

A cosy anime-style ASMR café game. Take customers' orders, buy ingredients and cook with 11 cute appliances. The game works out what you made, and a recipe book holds 100 recipes.

There are two versions in this folder:

| | Godot 3D edition (`godot/`) | Web edition (`src/` → `dist/`) |
|---|---|---|
| Look | A 3D café diorama with toon shading, rain on the window and warm lamps | Hand-drawn 2D canvas |
| Play | Download `Cosy-Kitchen.exe` or play it on the web (links above) | Open `dist/index.html` in a browser |
| Extras | Customers walk in and sit at the bar, regulars with friendship hearts, a food critic, a café cat, decorations you buy, café levels, lo-fi music, a sound mixer | A single file you can share or turn into a Claude artifact |

Both editions share the same 100 recipes, ingredients, prices and recipe detection, so a dish cooked one way in one is the same dish in the other.

## Play the 3D edition
Download **Cosy-Kitchen.exe** (link above) and double-click it. Nothing to install. When a new version comes out, an **Update** button appears in the game's top bar. Or play the web version in your browser.

How to play:
- Tap the **Day** button or the ticket in the top-left to open the shop. Customers come in and sit at the bar. Click one to take their order.
- On the order ticket, **Buy all** buys the ingredients and drops them into the right station. A green **Next** chip and the pulsing toolbar button show the next step.
- Every station has a gesture and a one-tap button. Chop by tapping or sawing across food. Stir in circles, hold to blend, swipe up to roll sushi, and swipe up to flip in the pan. Turn the oven dial and type on the microwave keypad.
- Take food out of the pot, pan or oven while the meter is in the green zone for a perfect dish. Leave it too long and it burns.
- Put the dish on the **Plate** (on the bar) and **Serve** it. New recipes are stamped in your book.
- Spend your earnings in **Decorate** (the plant button). Serve well to raise your café level, which unlocks more seats and decorations.
- Keys: `Space` does the station's action, `1`–`8` take food from the counter, `F` opens the fridge, `B` opens the book, `←`/`→` switch stations, `Esc` goes back to the café view.

Your progress saves automatically.

## Change the 3D edition
1. Open the project in Godot 4.6: in the Godot project manager, click Import and choose `godot/project.godot`.
2. Press F5 to play.
3. After a change, run `godot/tools/gd.sh test` (Git Bash). It runs the headless test suite, which plays a whole customer order through the real stations.
4. To publish a new version (exe release, in-game update and web version), run `godot/tools/release.sh 2.2.0 "what's new"` from Git Bash.

`CLAUDE.md` explains how everything fits together, so you can keep building it with Claude Code.

## The web edition
- `npm install`, then `npm run dev`. Play it at http://localhost:5173.
- `npm test` builds and checks the web game. `npm run sheets` draws every dish onto one picture.
- To put it back into Claude, attach `dist/index.html` and ask Claude to publish it as an artifact.

## Folder layout
- `godot/` holds the Godot 3D edition (scripts, shaders, assets, tests, and the Blender and audio tools that generate the assets).
- `src/`, `scripts/` and `dist/` hold the web edition.
- `tests/` holds the web edition's smoke test and contact sheets.
- `CLAUDE.md` is the developer guide for Claude Code.
