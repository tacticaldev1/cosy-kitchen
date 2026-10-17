## Save: everything that persists between sessions, stored as JSON in user://cosy_save.json.
extends Node

var PATH := "user://cosy_save.json"

var found := {}          # recipe id (as String) -> times made
var wallet := 3000
var day := 1
var pinned := -1
var decor := {}          # decor key -> true when owned
var decor_on := {}       # decor key -> shown
var friends := {}        # regular customer name -> hearts
var stars_total := 0
var served_total := 0
var best_day := 0
var seen_tutorial := false
var settings := {"master": 1.0, "sfx": 0.9, "amb": 0.6, "music": 0.45, "rain": true, "fullscreen": false, "shake": true}

signal changed

func _ready() -> void:
	# tests and screenshot runs never touch the player's real save
	var args := OS.get_cmdline_user_args()
	if args.has("--test") or Shot.arg("dev") != "" or Shot.arg("shot") != "":
		PATH = "user://test_save.json"
		return
	load_game()

func load_game() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	found = d.get("found", {})
	wallet = int(d.get("wallet", 3000))
	day = int(d.get("day", 1))
	pinned = int(d.get("pinned", -1))
	decor = d.get("decor", {})
	decor_on = d.get("decor_on", {})
	friends = d.get("friends", {})
	stars_total = int(d.get("stars_total", 0))
	served_total = int(d.get("served_total", 0))
	best_day = int(d.get("best_day", 0))
	seen_tutorial = bool(d.get("seen_tutorial", false))
	var s: Dictionary = d.get("settings", {})
	for k in s: settings[k] = s[k]

func save() -> void:
	var d := {"found": found, "wallet": wallet, "day": day, "pinned": pinned, "decor": decor, "decor_on": decor_on, "friends": friends,
		"stars_total": stars_total, "served_total": served_total, "best_day": best_day, "seen_tutorial": seen_tutorial, "settings": settings, "version": 2}
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

## Café level from total stars earned: unlocks seats, decor and harder orders.
func level() -> int:
	var lv := 1
	var need := 12
	var s := stars_total
	while s >= need and lv < 10:
		s -= need
		lv += 1
		need += 8
	return lv

func level_progress() -> Vector2:
	var lv := 1
	var need := 12
	var s := stars_total
	while s >= need and lv < 10:
		s -= need
		lv += 1
		need += 8
	return Vector2(s, need)

func reset() -> void:
	found = {}; wallet = 3000; day = 1; pinned = -1; decor = {}; decor_on = {}; friends = {}
	stars_total = 0; served_total = 0; best_day = 0; seen_tutorial = false
	save()
