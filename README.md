# Cosy Kitchen

**[⬇ Download for Windows](https://github.com/tacticaldev1/cosy-kitchen/releases/latest/download/Cosy-Kitchen.exe)** · **[▶ Play in your browser](https://tacticaldev1.github.io/cosy-kitchen/)**

A cosy anime-style life sim about running a little café. Walk your chibi chef around the café, the town and your apartment; cook 100 recipes with 11 cute appliances; carry dishes to customers; impress food critics; decorate; make friends, fall in love and raise a family.

There are two versions in this folder:

| | Godot 3D edition (`godot/`) | Web edition (`src/` → `dist/`) |
|---|---|---|
| Look | A 3D café diorama with toon shading, rain on the window and warm lamps | Hand-drawn 2D canvas |
| Play | Download `Cosy-Kitchen.exe` or play it on the web (links above) | Open `dist/index.html` in a browser |
| Extras | A walkable café, town and apartment, story mode and freeplay, recipe difficulty, food critics and a newspaper, furniture you place yourself, shops, dating, marriage, kids, cheat codes, lo-fi music | A single file you can share or turn into a Claude artifact |

Both editions share the same 100 recipes, ingredients, prices and recipe detection, so a dish cooked one way in one is the same dish in the other.

## Play the 3D edition
Download **Cosy-Kitchen.exe** (link above) and double-click it. Nothing to install. When a new version comes out, an **Update** button appears in the game's top bar. Or play the web version in your browser.

How to play:
- **New story** inherits Grandma's café (chapters of goals in your Journal, `J`). **Freeplay** starts with ¥20,000 and no story. Make your character first.
- Walk with `WASD`/arrows or by clicking. `E` (or clicking) interacts with whatever the prompt shows: doors, stations, people, your bed.
- At the café, flip the **OPEN** sign by the door. Customers walk in and sit at tables or the bar. Walk up to them to take orders.
- Cook at the stations: every station has a gesture and a one-tap button. On the order ticket, **Buy all** gets the ingredients. Harder recipes (more chef hats) pay bigger tips.
- Put the dish on the **Plate**, pick it up, and carry it to the customer. Anything nobody ordered is a staff meal (`Q`) that restores energy.
- Critics visit once your café has a reputation. Their reviews appear in the next morning's newspaper and move your café rating.
- In town: Kai's Market (cheap pantry stock), the Home Store (furniture, wall and floor themes), the Boutique, Hana's Flowers, Ren's Books and Kobayashi Jewels. Use **Edit mode** (pencil button) to arrange furniture in the café or at home.
- Chat with Hana, Ren, Kai and Yuki, give gifts, go on dates, become partners, propose with a ring and get married. With a double bed and a crib at home, you can start a family.
- Sleep in your bed to end the day. Stay up past 2am and you'll faint!
- Cheats: press `` ` `` (backtick) for the cheat console, or type a code in Settings. Try `kaching`, `motherlode`, `cookbook`, `fivestars`, `lovebirds`, `nap`, `timeskip`, `freedecor`, `storkdelivery`.

Your progress saves automatically.

## Change the 3D edition
1. Open the project in Godot 4.6: in the Godot project manager, click Import and choose `godot/project.godot`.
2. Press F5 to play.
3. After a change, run `godot/tools/gd.sh test` (Git Bash). It runs the headless test suite, which plays a whole life through the real systems (cooking, serving, town, dating, family).
4. To publish a new version (exe release, in-game update and web version), run `godot/tools/release.sh 3.1.0 "what's new"` from Git Bash.

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
