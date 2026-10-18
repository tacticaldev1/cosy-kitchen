## Your home: the little apartment you start in, or the house you can buy at the east end of
## the street. Furnish it however you like, sleep to end the day, and share it with your family.
class_name HomeLocation
extends Location

## Each kind of home: model, walk area, furniture area, camera, windows and lamps.
const KINDS := {
	"apartment": {"title": "Your apartment", "glb": "res://assets/models/home.glb", "nav": Rect2(-3.6, -2.7, 7.2, 5.1), "area": Rect2(-3.5, -2.6, 7.0, 4.9),
		"cam": Vector3(0, 5.0, 5.4), "bounds": Rect2(-1.2, -0.6, 2.4, 0.9), "windows": ["window"], "win_size": Vector2(3.0, 1.15), "lamps": ["lamp_0"]},
	"house": {"title": "Your house", "glb": "res://assets/models/house.glb", "nav": Rect2(-5.2, -3.4, 10.4, 6.4), "area": Rect2(-5.1, -3.3, 10.2, 6.2),
		"cam": Vector3(0, 6.0, 6.4), "bounds": Rect2(-3.2, -1.2, 6.4, 2.2), "windows": ["window_0", "window_1"], "win_size": Vector2(2.4, 1.2), "lamps": ["lamp_0", "lamp_1"]},
}
const HOUSE_PRICE := 120000

var sun: DirectionalLight3D
var lamp: OmniLight3D
var lamps: Array = []
var window_mat: ShaderMaterial
var window_mats: Array = []
var _windows: Array = []
var family: Array = []
var rng := RandomNumberGenerator.new()
var kind := "apartment"

func setup(g: Game) -> void:
	super(g)
	key = "home"
	music_mood = "home"
	rng.randomize()
	env = Room.interior_environment()
	we = WorldEnvironment.new()
	we.environment = env
	_build(Save.home_kind)

## Builds (or rebuilds, after moving house) the room, walk grid, furniture and lights.
func _build(k: String) -> void:
	kind = k if KINDS.has(k) else "apartment"
	var spec: Dictionary = KINDS[kind]
	title = spec.title
	if room: room.queue_free()
	if furni: furni.queue_free()
	for n in lights.get_children(): n.queue_free()
	for w in _windows: w.queue_free()
	_windows.clear()
	room = Room.new()
	room.name = "Room"
	add_child(room)
	room.load_glb(spec.glb)
	cam_offset = spec.cam
	cam_look = Vector3(0, 0.5, -0.4)
	cam_bounds = spec.bounds
	make_nav(spec.nav)
	_reach_dirty = true
	furni = FurnitureLayer.new()
	furni.name = "Furniture"
	add_child(furni)
	furni.setup("home", spec.area, nav)
	furni.changed.connect(_refresh_interacts)
	apply_theme()
	_build_lights()
	_refresh_interacts()
	refresh_family()

## Moving house: furniture that still fits comes along, the rest goes into storage.
func move_to(k: String) -> void:
	var spec: Dictionary = KINDS[k]
	var keep: Array = []
	for it in Save.layouts.get("home", []):
		var s := FurnitureLayer.size_of(it.id, int(it.rot))
		var r := Rect2(float(it.x) - s.x * 0.5, float(it.z) - s.y * 0.5, s.x, s.y)
		if (spec.area as Rect2).encloses(r): keep.append(it)
		else: Save.furni_inv[it.id] = int(Save.furni_inv.get(it.id, 0)) + 1
	Save.layouts["home"] = keep
	Save.home_kind = k
	_build(k)
	# anything that now cuts off part of the house goes into storage (biggest pieces first)
	var by_size := furni.items.filter(func(it): return not Furni.walkable(it.id))
	by_size.sort_custom(func(a, b): return Furni.info(a.id).w * Furni.info(a.id).d > Furni.info(b.id).w * Furni.info(b.id).d)
	for it in by_size:
		if _cut_off() == 0: break
		var before := _cut_off()
		var held := {"id": it.id, "x": it.x, "z": it.z, "rot": it.rot}
		furni.remove(it)
		if _cut_off() < before:
			Save.furni_inv[held.id] = int(Save.furni_inv.get(held.id, 0)) + 1
		else:
			furni.add(held.id, held.x, held.z, held.rot)
	Save.save()

## How many walkable spots can't be reached from the front door.
func _cut_off() -> int:
	var seen := NavReport.reach(nav, entry_point("door"))
	var n := 0
	for i in seen.size():
		if nav.blocked[i] == 0 and seen[i] == 0: n += 1
	return n

## Reloads furniture and family from the save (after a new game or a cheat).
func reload() -> void:
	furni.load_layout()
	apply_theme()
	_refresh_interacts()
	refresh_family()

func apply_theme() -> void:
	var th: Dictionary = Save.themes.get("home", {})
	room.set_wall(Furni.WALLS.get(th.get("wall", "Lilac"), "EDE3FF"))
	room.set_floor(Furni.FLOORS.get(th.get("floor", "Pale oak"), Furni.FLOORS["Pale oak"]))

func _build_lights() -> void:
	var spec: Dictionary = KINDS[kind]
	sun = Room.key_light(Vector3(-55, -20, 0))
	lights.add_child(sun)
	lamps.clear()
	for m in spec.lamps:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.8, 0.58)
		l.light_energy = 1.2
		l.omni_range = 4.5
		l.omni_attenuation = 1.2
		lights.add_child(l)
		l.global_position = room.mark(m)
		lamps.append(l)
	lamp = lamps[0]
	if room.has_mark("fire"):
		var f := OmniLight3D.new()
		f.light_color = Color(1.0, 0.6, 0.3)
		f.light_energy = 1.0
		f.omni_range = 3.0
		lights.add_child(f)
		f.global_position = room.mark("fire")
	window_mats.clear()
	for m in spec.windows:
		var win := Room.rain_window(spec.win_size)
		add_child(win)
		win.global_position = room.mark(m) + Vector3(0, 0, -0.1)
		_windows.append(win)
		window_mats.append(win.material_override)
	window_mat = window_mats[0]

func activate(on: bool) -> void:
	super(on)
	if on and family.size() != int(Save.married and Save.partner != "") + Save.family.kids.size():
		refresh_family()

func set_hour(h: float) -> void:
	var night := clampf((h - 18.0) / 3.0, 0.0, 1.0) if h > 12.0 else clampf((7.0 - h) / 1.5, 0.0, 1.0)
	for wm in window_mats:
		wm.set_shader_parameter("night", night)
		wm.set_shader_parameter("rain", 1.0 if game.weather == "rain" else 0.0)
	sun.light_energy = lerpf(0.85, 0.25, night)
	sun.light_color = Color(1.0, 0.94, 0.85).lerp(Color(0.7, 0.7, 1.0), night)
	for l in lamps: l.light_energy = lerpf(0.6, 1.8, night)
	env.ambient_light_energy = lerpf(0.6, 0.4, night)
	_place_family()

func entry_point(entry: String) -> Vector3:
	if entry == "bed":
		var b := _bed()
		if b.size(): return nav.nearest_free(Vector3(b.x, 0, b.z) + Vector3(0.9, 0, 0))
	return room.mark("spawn")

func entry_yaw(entry: String) -> float:
	return -PI * 0.5 if entry != "bed" else 0.0

func _bed() -> Dictionary:
	var b := furni.first("bed")
	return b if b.size() else furni.first("single_bed")

func _refresh_interacts() -> void:
	interacts.clear()
	add_interact("door", room.mark("door"), 0.8, "Go out to town", func(): game.travel("city", "forsale" if kind == "house" else "home"))
	interacts.back().h = 1.6
	add_interact("kitchen", room.mark("kitchen"), 0.8, "Make a snack (¥300, +20 energy)", _snack)
	interacts.back().h = 1.2
	for it in furni.items:
		var p := Vector3(it.x, 0, it.z)
		match it.id:
			"bed", "single_bed":
				add_interact("bed", nav.nearest_free(p + Vector3(0.9, 0, 0)), 1.1, "Go to bed", _bed_menu)
				interacts.back().at = p + Vector3(0, 0.55, 0)
			"wardrobe":
				add_interact("wardrobe", nav.nearest_free(p + Vector3(0, 0, -0.6).rotated(Vector3.UP, it.rot * PI * 0.5)), 0.9, "Change your outfit", func(): game.hud.open_boutique(true))
				interacts.back().at = p + Vector3(0, 1.0, 0)
			"tv":
				add_interact("tv", nav.nearest_free(p + Vector3(0, 0, 0.9)), 0.8, "Watch TV (1 hour)", func():
					game.life.skip_time(60.0)
					game.life.eat(4.0)
					game.toast(["A cooking show! You pick up a plating trick.", "Cartoons. You laugh more than you'd admit.", "The weather report says: cosy."][rng.randi() % 3]))
			"piano":
				add_interact("piano", nav.nearest_free(p + Vector3(0, 0, 0.8)), 0.8, "Play the piano", func():
					for i in 6: game.after(i * 0.22, func(): Sfx.play("note", 0.8, 0.8 + rng.randf() * 0.6))
					game.burst(p + Vector3(0, 1.2, 0), [Color("C3A6FF"), Color("FF7EA6")], 8))
	for k in interacts:
		if not k.has("h"): k.h = 1.0

func _snack() -> void:
	if Save.wallet < 300:
		game.toast("Not enough yen for a snack")
		return
	Save.wallet -= 300
	game.life.eat(20.0)
	game.life.skip_time(15.0)
	Sfx.play("nom")
	game.toast("You make onigiri and miso soup. +20 energy")
	Save.save()

func _bed_menu() -> void:
	var opts: Array = [["Sleep until morning", func(): game.life.sleep()]]
	if Save.married and int(Save.family.expecting) < 0 and Save.minute >= 19 * 60 and furni.has_item("bed"):
		opts.append(["Talk about starting a family ♥", func(): game.life.start_family()])
	opts.append(["Not yet", func(): pass])
	var h := Save.hour()
	game.hud.ask("", "Go to sleep? It's %s.%s" % [Save.time_text(), " (A bit early for bed!)" if h < 18.0 else ""], opts)

# ---------------------------------------------------------------- family
func refresh_family() -> void:
	for n in family:
		npcs.erase(n)
		n.queue_free()
	family.clear()
	if Save.married and Save.partner != "":
		var p := make_person("partner", People.look_of(Save.partner), People.npc_name(Save.partner))
		family.append(p)
	for i in Save.family.kids.size():
		var k: Dictionary = Save.family.kids[i]
		var stage := Life.kid_stage(k)
		var c := make_person("kid:%d" % i, k.look, k.name, stage)
		c.speed = 0.5 if stage == "toddler" else 0.8
		family.append(c)
	_place_family()

func _place_family() -> void:
	var crib := furni.first("crib")
	for n in family:
		var id := String(n.get_meta("npc"))
		n.visible = true
		if id == "partner":
			var sofa := furni.first("sofa")
			if sofa.is_empty(): sofa = furni.first("armchair")
			if sofa.size():
				var s: Array = Furni.seats(sofa.id)[0]
				var b := Basis.from_euler(Vector3(0, sofa.rot * PI * 0.5, 0))
				n.sit_at(Vector3(sofa.x, 0, sofa.z) + b * s[0], s[1] + sofa.rot * PI * 0.5, s[2])
			else:
				n.stand_up()
				n.global_position = nav.nearest_free(room.mark("kitchen") + Vector3(0.6, 0, 0.3))
		elif n.kind == "baby":
			if crib.size():
				n.sit_at(Vector3(crib.x, 0, crib.z), crib.rot * PI * 0.5, 0.32)
			else:
				n.sit_at(nav.nearest_free(Vector3(0.2, 0, 0.6)), 0.0, 0.0)
		else:
			n.stand_up()
			n.global_position = nav.nearest_free(Vector3(rng.randf_range(-2, 2), 0, rng.randf_range(-0.5, 1.5)))

func tick(dt: float) -> void:
	super(dt)
	for n in family:
		if n.kind != "toddler" and n.kind != "child": continue
		if n.walking or n.sitting: continue
		var pause: float = n.get_meta("pause", 0.0) - dt
		n.set_meta("pause", pause)
		if pause <= 0.0:
			n.set_meta("pause", rng.randf_range(2.0, 6.0))
			n.walk_path(nav.path(n.global_position, nav.nearest_free(Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-1.8, 2.0)))))
