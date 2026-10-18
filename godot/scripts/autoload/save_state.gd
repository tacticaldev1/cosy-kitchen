## Save: everything that persists between sessions, stored as JSON in user://cosy_save.json.
extends Node

var PATH := "user://cosy_save.json"
const VERSION := 3

# --- cooking & café
var found := {}          # recipe id (as String) -> times made
var wallet := 3000
var day := 1
var pinned := -1
var friends := {}        # café regular name -> hearts (legacy, regulars who aren't townsfolk)
var stars_total := 0
var served_total := 0
var best_day := 0
var seen_tutorial := false
var reputation := 1.0    # café rating 0..5 (critics and happy customers move it)
var reviews: Array = []  # [{day, critic, stars, dish, quote, read}]
var cookbooks := 0       # plating books bought from the bookshop: +5% tips each
# --- you
var started := false
var mode := "story"      # story | freeplay
var player_name := "Chef"
var player_look := {}
var energy := 100.0
var minute := 420.0      # minutes since midnight (7:00), can run past 24:00 until 2:00
var weather := "sun"
var location := "home"
# --- stuff you own
var layouts := {}        # location key -> [{id, x, z, rot}]
var themes := {}         # location key -> {wall, floor}
var furni_inv := {}      # furniture id -> count owned but not placed
var pantry := {}         # ingredient key -> count bought at the market
var gifts := {}          # gift id -> count
var has_ring := false
var home_kind := "apartment"  # apartment | house
# --- people
var rel := {}            # npc id -> {hearts, talked, gifted, dates, partner}
var partner := ""
var married := false
var wedding_day := -1
var family := {"expecting": -1, "kids": []}   # kids: [{name, born, look}]
# --- story
var chapter := 0
var flags := {}
var cheats_used := false
var settings := {"master": 1.0, "sfx": 0.9, "amb": 0.6, "music": 0.45, "rain": true, "fullscreen": false, "shake": true}

signal changed

func _ready() -> void:
	# tests and screenshot runs never touch the player's real save
	var args := OS.get_cmdline_user_args()
	if args.has("--test") or Shot.arg("dev") != "" or Shot.arg("shot") != "":
		PATH = "user://test_save.json"
		return
	load_game()

func has_save() -> bool:
	return started

const FIELDS := ["found", "wallet", "day", "pinned", "friends", "stars_total", "served_total", "best_day", "seen_tutorial", "reputation", "reviews", "cookbooks",
	"started", "mode", "player_name", "player_look", "energy", "minute", "weather", "location", "layouts", "themes", "furni_inv", "pantry", "gifts", "has_ring", "home_kind",
	"rel", "partner", "married", "wedding_day", "family", "chapter", "flags", "cheats_used"]

func load_game() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	for k in FIELDS:
		if not d.has(k): continue
		var cur = get(k)
		var v = d[k]
		match typeof(cur):
			TYPE_INT: set(k, int(v))
			TYPE_FLOAT: set(k, float(v))
			TYPE_BOOL: set(k, bool(v))
			_: set(k, v)
	var s: Dictionary = d.get("settings", {})
	for k in s: settings[k] = s[k]
	if int(d.get("version", 1)) < 3:
		_migrate_v2(d)
	_fix_v300_layout()

## v3.0.0's starting tables crowded the bar stools; move them if they're still where we put them.
func _fix_v300_layout() -> void:
	var cafe: Array = layouts.get("cafe", [])
	var old := [[1.0, -1.9], [2.9, -1.9], [1.0, 0.1]]
	var new_ := [[1.4, -1.5], [3.0, -1.5], [1.4, 0.9]]
	for it in cafe:
		for i in 3:
			if it.id == "table2" and absf(float(it.x) - old[i][0]) < 0.01 and absf(float(it.z) - old[i][1]) < 0.01 and int(it.rot) == 0:
				it.x = new_[i][0]
				it.z = new_[i][1]
				it.rot = 1

## Players from v2 keep their recipes, money and stars; their old café decorations become
## furniture in the new café, and they start the new life in story mode on the day they were on.
func _migrate_v2(d: Dictionary) -> void:
	var old: Dictionary = d.get("decor", {})
	var map := {"lucky_cat": "lucky_cat", "flowers": "flowers", "big_plant": "big_plant", "record_player": "record", "cat_bed": "cat_bed"}
	for k in old:
		if map.has(k): furni_inv[map[k]] = int(furni_inv.get(map[k], 0)) + 1
	reputation = clampf(1.0 + stars_total / 120.0, 1.0, 3.5)
	started = false

func save() -> void:
	var d := {"version": VERSION, "settings": settings}
	for k in FIELDS: d[k] = get(k)
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "  "))
	changed.emit()

func is_found(rid: int) -> bool: return found.has(str(rid))
func mark_found(rid: int) -> bool:
	var k := str(rid)
	var fresh := not found.has(k)
	found[k] = int(found.get(k, 0)) + 1
	return fresh
func found_count() -> int: return found.size()

## Café level from total stars earned: unlocks harder orders and more customers.
func level() -> int:
	return int(level_progress().z)

func level_progress() -> Vector3:
	var lv := 1
	var need := 12
	var s := stars_total
	while s >= need and lv < 10:
		s -= need
		lv += 1
		need += 8
	return Vector3(s, need, lv)

# ---------------------------------------------------------------- relationships
func r(npc: String) -> Dictionary:
	if not rel.has(npc):
		rel[npc] = {"hearts": 0.0, "talked": -1, "gifted": -1, "dates": 0, "dated": -1}
	return rel[npc]

func hearts(npc: String) -> float:
	return float(r(npc).hearts)

func add_hearts(npc: String, h: float) -> float:
	var d := r(npc)
	d.hearts = clampf(float(d.hearts) + h, 0.0, 10.0)
	return d.hearts

func time_text(m := -1.0) -> String:
	var mm := int(minute if m < 0.0 else m) % 1440
	var hh := mm / 60
	return "%d:%02d %s" % [12 if hh % 12 == 0 else hh % 12, mm % 60, "am" if hh < 12 else "pm"]

func hour() -> float:
	return minute / 60.0

## A brand-new life. Recipes you've discovered stay (they're your knowledge), the rest restarts.
func new_game(m: String, name_: String, look: Dictionary) -> void:
	var keep_found := found.duplicate()
	var keep_settings := settings.duplicate()
	reset(false)
	found = keep_found
	settings = keep_settings
	started = true
	mode = m
	player_name = name_
	player_look = look
	wallet = 20000 if m == "freeplay" else 3000
	reputation = 2.5 if m == "freeplay" else 1.0
	chapter = 0 if m == "story" else -1
	layouts = {
		"cafe": [{"id": "table2", "x": 1.4, "z": -1.5, "rot": 1}, {"id": "table2", "x": 3.0, "z": -1.5, "rot": 1}, {"id": "table2", "x": 1.4, "z": 0.9, "rot": 1},
			{"id": "plant", "x": 3.75, "z": -2.6, "rot": 0}, {"id": "rug", "x": 2.4, "z": 0.4, "rot": 0}],
		"home": [{"id": "single_bed", "x": -2.95, "z": 1.3, "rot": 0}, {"id": "armchair", "x": 1.6, "z": -1.7, "rot": 0}, {"id": "rug", "x": 0.0, "z": 0.4, "rot": 0},
			{"id": "lamp", "x": 2.95, "z": -2.2, "rot": 0}, {"id": "plant", "x": -1.0, "z": -2.3, "rot": 0}, {"id": "wardrobe", "x": 3.25, "z": -1.5, "rot": 3}],
	}
	if m == "freeplay":
		for id in ["table4", "lucky_cat", "flowers", "bookshelf", "sofa"]: furni_inv[id] = 1
	location = "home"
	minute = 420.0
	save()

func reset(write := true) -> void:
	found = {}; wallet = 3000; day = 1; pinned = -1; friends = {}
	stars_total = 0; served_total = 0; best_day = 0; seen_tutorial = false
	reputation = 1.0; reviews = []; cookbooks = 0
	started = false; mode = "story"; player_name = "Chef"; player_look = {}; energy = 100.0; minute = 420.0; weather = "sun"; location = "home"
	layouts = {}; themes = {}; furni_inv = {}; pantry = {}; gifts = {}; has_ring = false; home_kind = "apartment"
	rel = {}; partner = ""; married = false; wedding_day = -1; family = {"expecting": -1, "kids": []}
	chapter = 0; flags = {}; cheats_used = false
	if write: save()
