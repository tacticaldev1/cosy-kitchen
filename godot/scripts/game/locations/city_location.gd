## Hoshizora Town: one cosy street of shops (your apartment, the market, the home store, your
## café, the boutique, florist, jeweler and bookshop) with the park and fountain across the road.
class_name CityLocation
extends Location

const SHOPS := {
	"home": "Sakura Apartments", "market": "Kai's Market", "homestore": "Home Store", "cafe": "Cosy Kitchen",
	"boutique": "Mimi's Boutique", "florist": "Hana's Flowers", "jeweler": "Kobayashi Jewels", "bookshop": "Ren's Books",
}
const SIGN_COL := {"home": "8B7BC9", "market": "2E8A68", "homestore": "C87A20", "cafe": "D9527E", "boutique": "6A4AC8", "florist": "4E9A3E", "jeweler": "3A5AB8", "bookshop": "8A4A2A"}

var sun: DirectionalLight3D
var lamps: Array = []
var rain: CPUParticles3D
var petals: CPUParticles3D
var walkers: Array = []
var people := {}            # npc id -> Chibi
var rng := RandomNumberGenerator.new()
var _couple := ""
var _wedding := false
var _confetti_t := 0.0

func setup(g: Game) -> void:
	super(g)
	key = "city"
	title = "Hoshizora Town"
	music_mood = "town"
	rng.seed = 42
	room = Room.new()
	room.name = "Room"
	add_child(room)
	room.load_glb("res://assets/models/city.glb")
	cam_offset = Vector3(0, 7.2, 9.6)
	cam_look = Vector3(0, 0.9, -1.4)
	cam_bounds = Rect2(-49.0, -1.6, 98.0, 11.6)
	make_nav(Rect2(-54.0, -4.15, 108.0, 17.6), 0.2)
	_build_env()
	_build_signs()
	_build_people()
	_build_interacts()

func _build_env() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("BFE3FF")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.82, 0.95)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true
	env.fog_light_color = Color("F2E2F4")
	env.fog_density = 0.004
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	we = WorldEnvironment.new()
	we.environment = env
	sun = Room.key_light(Vector3(-52, -35, 0))
	sun.directional_shadow_max_distance = 26.0
	lights.add_child(sun)
	for nm in room.marks:
		if not String(nm).begins_with("lamp_"): continue
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.8, 0.55)
		l.light_energy = 0.0
		l.omni_range = 4.5
		l.omni_attenuation = 1.3
		lights.add_child(l)
		l.global_position = room.mark(nm)
		lamps.append(l)
	rain = CPUParticles3D.new()
	rain.amount = 500
	rain.lifetime = 0.9
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(12, 0.5, 8)
	rain.direction = Vector3(0.1, -1, 0)
	rain.spread = 2.0
	rain.gravity = Vector3(0, -20, 0)
	rain.initial_velocity_min = 7.0
	rain.initial_velocity_max = 9.0
	var rm := QuadMesh.new()
	rm.size = Vector2(0.015, 0.28)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.9, 1.0, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	rm.material = mat
	rain.mesh = rm
	rain.emitting = false
	add_child(rain)
	petals = CPUParticles3D.new()
	petals.amount = 60
	petals.lifetime = 7.0
	petals.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	petals.emission_box_extents = Vector3(9, 1, 4)
	petals.direction = Vector3(0.4, -1, 0.1)
	petals.spread = 30.0
	petals.gravity = Vector3(0.15, -0.35, 0)
	petals.initial_velocity_min = 0.2
	petals.initial_velocity_max = 0.5
	petals.angular_velocity_min = -90
	petals.angular_velocity_max = 90
	var pm := QuadMesh.new()
	pm.size = Vector2(0.07, 0.05)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color("FFC2D6")
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	pm.material = pmat
	petals.mesh = pm
	add_child(petals)
	petals.position = Vector3(0, 3.6, 8.5)

func _build_signs() -> void:
	var font: Font = load("res://assets/fonts/MochiyPopOne-Regular.ttf")
	for s in SHOPS:
		if not room.has_mark("sign_" + s): continue
		var l := Label3D.new()
		l.text = SHOPS[s]
		l.font = font
		l.font_size = 72
		l.pixel_size = 0.0042 if s != "home" else 0.0036
		l.modulate = Color(SIGN_COL[s])
		l.outline_modulate = Color.WHITE
		l.outline_size = 10
		add_child(l)
		l.global_position = room.mark("sign_" + s) + Vector3(0, 0, 0.02)

func _build_people() -> void:
	for id in People.NPCS:
		var d: Dictionary = People.NPCS[id]
		var c := make_person(id, d.look, d.name)
		var spot := nav.nearest_free(room.mark("spot_" + d.spot))
		c.global_position = spot
		c.set_meta("home_spot", spot)
		c.set_meta("busy", true)
		people[id] = c
	# Yuki's easel
	var mb := MB.new()
	mb.col(Color("C8864E"))
	for p in [Vector3(-0.2, 0, 0.1), Vector3(0.2, 0, 0.1), Vector3(0, 0, -0.18)]:
		mb.tube(PackedVector3Array([p, Vector3(p.x * 0.3, 1.1, p.z * 0.3)]), 0.018, 6)
	mb.col(Color.WHITE); mb.at(Vector3(0, 0.82, 0.06), Vector3(-0.15, 0, 0)); mb.rbox(Vector3(0.5, 0.42, 0.02), 0.01, 1); mb.pop()
	mb.col(Color("FFC2D6"), 0.0); mb.at(Vector3(-0.08, 0.86, 0.075), Vector3(-0.15, 0, 0)); mb.sphere(0.07, 10, 8); mb.pop()
	mb.col(Color("8ED16B"), 0.0); mb.at(Vector3(0.1, 0.75, 0.08), Vector3(-0.15, 0, 0)); mb.ellipsoid(0.12, 0.05, 0.01, 10, 6); mb.pop()
	var easel := FoodArt.mesh_node(FoodArt.finish(mb))
	add_child(easel)
	easel.global_position = room.mark("spot_yuki") + Vector3(0.45, 0, -0.25)
	easel.rotation.y = -0.5
	# Grandpa Jiro on the bus stop bench
	var j := make_person("jiro", People.KEEPERS.jiro.look, "Grandpa Jiro")
	j.sit_at(Vector3(19.0, 0, 3.4), 0.0, 0.32)
	people["jiro"] = j
	# townsfolk strolling about
	for i in 7:
		var w := Chibi.new()
		add_child(w)
		w.build(Chibi.random_look(rng), "child" if i == 5 else "adult")
		w.speed = rng.randf_range(0.7, 1.0)
		w.global_position = _random_spot()
		walkers.append(w)
	var cat := Chibi.new()
	add_child(cat)
	cat.build({"hair": "FFB86A"}, "cat")
	cat.speed = 0.6
	cat.global_position = Vector3(-4, 0, 5)
	walkers.append(cat)

func _random_spot() -> Vector3:
	var p := Vector3(rng.randf_range(-48, 48), 0, [-3.0, -2.6, 2.7, 3.0][rng.randi() % 4]) if rng.randf() < 0.7 else Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(5, 12))
	return nav.nearest_free(p)

func _build_interacts() -> void:
	var font: Font = load("res://assets/fonts/MochiyPopOne-Regular.ttf")
	if room.has_mark("door_forsale"):
		add_interact("door_forsale", room.mark("door_forsale"), 1.0, "The house on the corner", func(): game.life.house_door())
		interacts.back().h = 2.4
		var sl := Label3D.new()
		sl.font = font
		sl.font_size = 40
		sl.pixel_size = 0.0028
		sl.modulate = Color("D9527E")
		sl.outline_modulate = Color.WHITE
		sl.outline_size = 8
		sl.name = "ForSale"
		add_child(sl)
		sl.global_position = room.mark("sign_forsale")
		_forsale_sign = sl
		update_forsale()
	for id in People.NPCS:
		var hid: String = id
		if not room.has_mark("door_house_" + id): continue
		add_interact("house_" + id, room.mark("door_house_" + id), 0.95, "%s's house" % People.npc_name(id), func(): game.visit_house(hid))
		interacts.back().h = 2.2
		var l := Label3D.new()
		l.text = "%s's" % People.npc_name(id)
		l.font = font
		l.font_size = 56
		l.pixel_size = 0.0035
		l.modulate = Color("FFFDF6")
		l.outline_modulate = Color("3B2340")
		l.outline_size = 14
		add_child(l)
		l.global_position = room.mark("sign_house_" + id) + Vector3(0, 0, 0.03)
	for s in SHOPS:
		if not room.has_mark("door_" + s): continue
		var sid: String = s
		var act: Callable
		var label := ""
		match s:
			"home":
				label = "Sakura Apartments"
				act = func():
					if Save.home_kind == "house": game.hud.say([["", "You moved out of your little apartment. Home is the house at the east end of the street now."]])
					else: game.travel("home", "door")
			"cafe":
				label = "Enter the café"
				act = func(): game.travel("cafe", "door")
			_:
				label = "Shop at " + SHOPS[s]
				act = func(): game.open_shop_ui(sid)
		add_interact("door_" + s, room.mark("door_" + s), 0.95, label, act)
		interacts.back().h = 2.2

func entry_point(entry: String) -> Vector3:
	if entry == "park": return Vector3(-2.4, 0, 5.3)
	if room.has_mark("door_" + entry): return room.mark("door_" + entry) + Vector3(0, 0, 0.35)
	return room.mark("door_home") + Vector3(0, 0, 0.35)

func entry_yaw(entry: String) -> float:
	return PI if entry == "park" else 0.0

func activate(on: bool) -> void:
	super(on)
	if on: set_hour(Save.hour())

func set_hour(h: float) -> void:
	# sky: dawn peach, day blue, evening rose, night navy
	var keys := [[5.0, Color("2A2A55")], [7.0, Color("FFD6C2")], [9.5, Color("BFE3FF")], [16.5, Color("BFE3FF")], [18.5, Color("FFB49A")], [20.0, Color("5A4A8A")], [21.5, Color("232248")], [27.0, Color("1E1E40")]]
	var col: Color = keys[0][1]
	for i in keys.size() - 1:
		if h >= keys[i][0] and h < keys[i + 1][0]:
			col = (keys[i][1] as Color).lerp(keys[i + 1][1], (h - keys[i][0]) / (keys[i + 1][0] - keys[i][0]))
	var cloudy := game.weather != "sun"
	if cloudy: col = col.lerp(Color("A8AEC0") if col.v > 0.5 else col, 0.45)
	env.background_color = col
	env.fog_light_color = col.lightened(0.15)
	var night := clampf((h - 18.5) / 2.0, 0.0, 1.0) if h > 12.0 else clampf((6.5 - h) / 1.5, 0.0, 1.0)
	sun.light_energy = lerpf(0.9 if not cloudy else 0.55, 0.12, night)
	sun.light_color = Color(1.0, 0.95, 0.88).lerp(Color(1.0, 0.7, 0.55), clampf((h - 16.5) / 2.5, 0.0, 1.0)).lerp(Color(0.6, 0.65, 1.0), night)
	env.ambient_light_energy = lerpf(0.5, 0.38, night)
	env.ambient_light_color = Color(0.85, 0.82, 0.95).lerp(Color(0.55, 0.55, 0.85), night)
	for l in lamps: l.light_energy = 1.6 * night
	rain.emitting = game.weather == "rain"
	# townsfolk are out from 8:00 till 20:00
	var out := h >= 7.0 and h < 21.0
	for id in People.NPCS:
		var c: Chibi = people[id]
		var at_home_with_you: bool = Save.married and Save.partner == id
		c.visible = (out and not at_home_with_you) or _couple == id or _wedding
	for w in walkers: w.visible = h >= 7.0 and h < 21.5
	refresh_npc_kids()
	for k in npc_kid_nodes: k.visible = h >= 8.0 and h < 19.0
	people.jiro.visible = (h >= 7.0 and h < 19.0) or _wedding

func tick(dt: float) -> void:
	super(dt)
	set_festival(festival_now())
	_fireworks(dt)

	if game.loc == self and game.camera:
		rain.global_position = game.camera.global_position + Vector3(0, 3, -6)
	for w in walkers:
		w.tick(dt, game.clock)
		if not w.walking and not _wedding:
			var wait: float = w.get_meta("wait", 0.0) - dt
			w.set_meta("wait", wait)
			if wait <= 0.0:
				w.set_meta("wait", rng.randf_range(1.0, 5.0))
				w.walk_path(nav.path(w.global_position, _random_spot()))
	# townsfolk drift back to their spot after a chat, and face the street
	for id in People.NPCS:
		var c: Chibi = people[id]
		if _couple == id or _wedding: continue
		var pause: float = c.get_meta("pause", 0.0)
		if pause > 0.0:
			c.set_meta("pause", pause - dt)
			continue
		var spot: Vector3 = c.get_meta("home_spot")
		if not c.walking and c.global_position.distance_to(spot) > 0.3:
			c.walk_path(nav.path(c.global_position, spot))
			c.set_meta("pause", 2.0)  # don't re-plan every frame if the spot can't quite be reached
		elif not c.walking:
			c.rotation.y = lerp_angle(c.rotation.y, 0.0 if id != "yuki" else -0.6, minf(1.0, dt * 3.0))
	if _wedding:
		_confetti_t -= dt
		if _confetti_t <= 0.0:
			_confetti_t = 0.35
			game.burst(Vector3(rng.randf_range(-1.2, 1.2), 2.0, 10.9 + rng.randf_range(-0.5, 0.5)), [Color("FF7EA6"), Color("FFD24A"), Color.WHITE, Color("C3A6FF"), Color("7FD3B8")], 14, 1.3)

var _blanket: Node3D
var _forsale_sign: Label3D
var festival_root: Node3D
var festival_on := false
var fireworks_t := 0.0
var _fw_next := 0.0
var _delivery_mark: Label3D

## Festival stalls on the closed road: [id, x, sign, roof colour, label, action]
const STALLS := [["takoyaki", -9.0, "Takoyaki", "FF7EA6"], ["goldfish", -4.5, "Goldfish", "6A8AD8"], ["candy", 4.5, "Cotton candy", "C3A6FF"], ["masks", 9.0, "Masks", "FFB86A"]]

static func festival_now() -> bool:
	return Save.flags.get("event", "") == "festival" and Save.hour() >= 16.0 and Save.hour() < 23.5

## Lanterns, food stalls and fireworks on Main Street.
func set_festival(on: bool) -> void:
	if on == festival_on: return
	festival_on = on
	if on and festival_root == null: _build_festival()
	if festival_root: festival_root.visible = on
	nav.reset_to_static()
	if on:
		for s in STALLS: nav.block_rect(s[1], 1.25, 2.4, 1.0, 0.15)
	_reach_dirty = true
	interacts = interacts.filter(func(it): return not String(it.id).begins_with("fest_"))
	if on:
		var acts := {"takoyaki": ["Run the takoyaki stall (job)", func(): game.life.festival_job()],
			"goldfish": ["Goldfish scooping (¥300)", func(): game.life.festival_game()],
			"candy": ["Cotton candy (¥300, +15 energy)", func(): game.life.festival_snack()],
			"masks": ["Fox mask (¥800)", func(): game.life.festival_mask()]}
		for s in STALLS:
			add_interact("fest_" + s[0], Vector3(s[1], 0, 2.1), 0.9, acts[s[0]][0], acts[s[0]][1])
			interacts.back().h = 2.4
			interacts.back().at = Vector3(s[1], 1.2, 1.6)

func _build_festival() -> void:
	festival_root = Node3D.new()
	festival_root.name = "Festival"
	add_child(festival_root)
	var font: Font = load("res://assets/fonts/MochiyPopOne-Regular.ttf")
	for s in STALLS:
		var mb := MB.new()
		var x: float = s[1]
		mb.col(Color("C8864E"), 1.0, 0.2)
		for px in [-1.1, 1.1]:
			for pz in [-0.45, 0.45]:
				mb.tube(PackedVector3Array([Vector3(px, 0, pz), Vector3(px, 2.2, pz)]), 0.05, 8)
		mb.col(Color("FFF4E2"), 1.0, 0.2); mb.at(Vector3(0, 0.85, -0.35)); mb.rbox(Vector3(2.3, 0.12, 0.5), 0.03, 2); mb.pop()
		mb.col(Color(s[3]).darkened(0.1), 1.0, 0.2); mb.at(Vector3(0, 0.42, -0.35)); mb.rbox(Vector3(2.2, 0.8, 0.45), 0.03, 2); mb.pop()
		for k in 6:
			mb.col(Color(s[3]) if k % 2 == 0 else Color.WHITE, 1.0, 0.3)
			mb.at(Vector3(-1.05 + k * 0.42, 2.35, 0.0), Vector3(0.25, 0, 0)); mb.rbox(Vector3(0.43, 0.07, 1.3), 0.02, 1); mb.pop()
		for k in 3:
			mb.col(Color("FF5C5C") if k != 1 else Color("FFE27A"), 1.0, 0.6)
			mb.at(Vector3(-0.8 + k * 0.8, 1.9, -0.6)); mb.ellipsoid(0.13, 0.17, 0.13, 14, 10); mb.pop()
		var n := FoodArt.mesh_node(FoodArt.finish(mb))
		festival_root.add_child(n)
		n.position = Vector3(x, 0, 1.25)
		n.rotation.y = PI
		var l := Label3D.new()
		l.text = s[2]
		l.font = font
		l.font_size = 56
		l.pixel_size = 0.004
		l.modulate = Color(s[3]).darkened(0.25)
		l.outline_modulate = Color.WHITE
		l.outline_size = 12
		festival_root.add_child(l)
		l.position = Vector3(x, 2.62, 1.95)
		var lamp := OmniLight3D.new()
		lamp.light_color = Color(1.0, 0.7, 0.45)
		lamp.light_energy = 1.4
		lamp.omni_range = 4.0
		festival_root.add_child(lamp)
		lamp.position = Vector3(x, 2.0, 0.6)
	# strings of paper lanterns across the street
	var lmb := MB.new()
	for row in [-1.6, 2.2]:
		for i in 33:
			var x := -16.0 + i * 1.0
			var sag := 0.25 * sin(fposmod(x, 4.0) / 4.0 * PI)
			lmb.col([Color("FF5C5C"), Color("FFF4E2"), Color("FF9EBB")][i % 3], 1.0, 0.7)
			lmb.at(Vector3(x, 3.5 - sag, row)); lmb.ellipsoid(0.12, 0.16, 0.12, 12, 8); lmb.pop()
		lmb.col(Color("3B2340"), 0.0)
		var line := PackedVector3Array()
		for i in 65:
			var x := -16.0 + i * 0.5
			line.append(Vector3(x, 3.66 - 0.25 * sin(fposmod(x, 4.0) / 4.0 * PI), row))
		lmb.tube(line, 0.01, 4)
	festival_root.add_child(FoodArt.mesh_node(FoodArt.finish(lmb)))
	var banner := Label3D.new()
	banner.text = "Hoshizora Summer Festival"
	banner.font = font
	banner.font_size = 80
	banner.pixel_size = 0.0042
	banner.modulate = Color("D9527E")
	banner.outline_modulate = Color.WHITE
	banner.outline_size = 16
	festival_root.add_child(banner)
	banner.position = Vector3(0, 4.1, 2.25)

## Fireworks over the rooftops (festival nights 8:30pm–10pm, or when you watch them on a date).
func _fireworks(dt: float) -> void:
	var show := festival_on and Save.hour() >= 20.5 and Save.hour() < 22.0
	if fireworks_t > 0.0:
		fireworks_t -= dt
		show = true
	if not show: return
	_fw_next -= dt
	if _fw_next > 0.0: return
	_fw_next = rng.randf_range(0.25, 0.7)
	var cam := game.camera.global_position
	var at := Vector3(cam.x + rng.randf_range(-9, 9), rng.randf_range(8.5, 12.5), -9.0)
	var cols: Array = [[Color("FF5C8D"), Color("FFD24A")], [Color("7FD3F8"), Color.WHITE], [Color("C3A6FF"), Color("FF9EBB")], [Color("8ED16B"), Color("FFE27A")]][rng.randi() % 4]
	game.burst(at, cols, 48, 9.0)
	Sfx.play("pop", 0.5, 0.5)

## A big marker over the door for a delivery.
func set_delivery_mark(pos: Variant) -> void:
	if _delivery_mark == null:
		_delivery_mark = Label3D.new()
		_delivery_mark.text = "▼ Deliver here"
		_delivery_mark.font = load("res://assets/fonts/MochiyPopOne-Regular.ttf")
		_delivery_mark.font_size = 64
		_delivery_mark.pixel_size = 0.0042
		_delivery_mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_delivery_mark.no_depth_test = true
		_delivery_mark.modulate = Color("FFD24A")
		_delivery_mark.outline_modulate = Color("3B2340")
		_delivery_mark.outline_size = 16
		add_child(_delivery_mark)
	_delivery_mark.visible = pos != null
	if pos != null: _delivery_mark.global_position = (pos as Vector3) + Vector3(0, 4.7, 0.3)

func update_forsale() -> void:
	if _forsale_sign: _forsale_sign.text = ("%s's home" % Save.player_name) if Save.home_kind == "house" else "FOR SALE\n%s" % G.yen(HomeLocation.HOUSE_PRICE)
	for it in interacts:
		if it.id == "door_forsale": it.label = "Go home" if Save.home_kind == "house" else "The house for sale"
var _affair_on := false
var npc_kid_nodes: Array = []

## Date scenes: where the two of you sit or stand.
func stage_couple(id: String, spot: String) -> void:
	if spot == "bench":
		seat_couple(id)
		return
	_couple = id
	var c: Chibi = people[id]
	c.visible = true
	c.stop()
	var p := game.player
	match spot:
		"picnic":
			if _blanket == null:
				var mb := MB.new()
				for i in 6:
					for j in 4:
						mb.col(Color("FF9EBB") if (i + j) % 2 else Color("FFF8EE"), 0.0, 0.1)
						mb.at(Vector3(-0.6 + i * 0.24 + 0.12, 0.012, -0.36 + j * 0.24 + 0.12)); mb.rbox(Vector3(0.24, 0.012, 0.24), 0.002, 1); mb.pop()
				mb.col(Color("FFD24A"), 1.0, 0.4); mb.at(Vector3(0, 0.06, 0.15)); mb.rbox(Vector3(0.28, 0.1, 0.18), 0.03, 2); mb.pop()
				mb.col(Color("F2545B"), 1.0, 0.5)
				for k in 4:
					mb.at(Vector3(-0.1 + k * 0.06, 0.045, -0.15)); mb.sphere(0.03, 8, 6); mb.pop()
				_blanket = FoodArt.mesh_node(FoodArt.finish(mb))
				add_child(_blanket)
			_blanket.visible = true
			_blanket.global_position = Vector3(-5.2, 0.0, 7.9)
			c.sit_at(Vector3(-4.75, 0, 7.9), -PI * 0.5, 0.08)
			p.sit_at(Vector3(-5.65, 0, 7.9), PI * 0.5, 0.08)
		"fountain":
			c.sit_at(Vector3(0.32, 0, 10.05), 0.0, 0.5)
			p.sit_at(Vector3(-0.32, 0, 10.05), 0.0, 0.5)
		"festival":
			c.global_position = Vector3(0.3, 0, 0.0)
			c.rotation.y = PI
			p.global_position = Vector3(-0.3, 0, 0.0)
			p.rotation.y = PI
			fireworks_t = 25.0
		_:
			var d := room.mark("door_" + spot) if room.has_mark("door_" + spot) else Vector3(0, 0, -3)
			c.global_position = nav.nearest_free(d + Vector3(0.38, 0, 0.55))
			c.rotation.y = -PI * 0.5
			p.global_position = nav.nearest_free(d + Vector3(-0.38, 0, 0.55))
			p.rotation.y = PI * 0.5
	c.feel("happy", 30.0)
	set_hour(Save.hour())

## Your partner, out with someone else (you might spot them by the fountain).
func affair_scene(on: bool) -> void:
	if on == _affair_on: return
	_affair_on = on
	var aff: Dictionary = Save.flags.get("affair", {})
	if on and aff.size() and Save.partner != "":
		var a: Chibi = people[Save.partner]
		var b: Chibi = people[String(aff.with)]
		for x in [a, b]:
			x.stop()
			x.visible = true
			x.set_meta("pause", 99999.0)
		a.global_position = Vector3(-0.3, 0, 10.4)
		a.rotation.y = PI * 0.5
		b.global_position = Vector3(0.3, 0, 10.4)
		b.rotation.y = -PI * 0.5
		a.feel("happy", 9999.0)
		b.feel("happy", 9999.0)
	else:
		for id in People.NPCS:
			people[id].set_meta("pause", 0.0)
		set_hour(Save.hour())

## Townsfolk's own children play near their parents' spots.
func refresh_npc_kids() -> void:
	var kids: Array = Save.flags.get("npc_kids", [])
	while npc_kid_nodes.size() < kids.size():
		var k: Dictionary = kids[npc_kid_nodes.size()]
		var c := Chibi.new()
		add_child(c)
		var age := Save.day - int(k.born)
		c.build(k.look, "toddler" if age < 10 else "child")
		var par: Chibi = people[String(k.parents[0])]
		c.global_position = nav.nearest_free(par.get_meta("home_spot", par.global_position) + Vector3(0.5, 0, 0.4))
		c.set_meta("npc", "")
		npc_kid_nodes.append(c)

## Date: you and your date sit together on the park bench by the fountain.
func seat_couple(id: String) -> void:
	_couple = id
	var c: Chibi = people[id]
	c.visible = true
	c.stop()
	c.sit_at(Vector3(-3.25, 0, 6.0), 0.0, 0.32)
	game.player.sit_at(Vector3(-3.95, 0, 6.0), 0.0, 0.32)
	c.feel("happy", 4.0)
	set_hour(Save.hour())

func end_couple() -> void:
	if _blanket: _blanket.visible = false
	if _couple == "": return
	var c: Chibi = people[_couple]
	c.stand_up()
	c.global_position = nav.nearest_free(Vector3(-3.25, 0, 5.3))
	c.set_meta("pause", 3.0)
	_couple = ""
	game.player.global_position = nav.nearest_free(Vector3(-3.95, 0, 5.3))

## The wedding at the fountain: the whole town gathers under the cherry blossoms.
func wedding(on: bool) -> void:
	_wedding = on
	if not on:
		for id in People.NPCS: people[id].set_meta("pause", 0.0)
		set_hour(Save.hour())
		return
	var p := game.player
	p.global_position = Vector3(-0.42, 0, 10.9)
	p.rotation.y = PI * 0.5
	var guests: Array = []
	for id in People.NPCS:
		var c: Chibi = people[id]
		c.stop()
		if id == Save.partner:
			c.global_position = Vector3(0.42, 0, 10.9)
			c.rotation.y = -PI * 0.5
			c.feel("wow", 30.0)
		else:
			guests.append(c)
	var j: Chibi = people.jiro
	j.stand_up()
	j.global_position = Vector3(0, 0, 10.3)
	j.rotation.y = 0.0
	var spots := [Vector3(-1.9, 0, 10.6), Vector3(1.9, 0, 10.6), Vector3(-2.4, 0, 11.4), Vector3(2.4, 0, 11.4), Vector3(-1.4, 0, 11.9), Vector3(1.4, 0, 11.9)]
	var all: Array = guests + walkers.slice(0, 3)
	for i in mini(all.size(), spots.size()):
		var g: Chibi = all[i]
		g.stop()
		g.visible = true
		g.global_position = spots[i]
		g.rotation.y = atan2(-spots[i].x, 10.9 - spots[i].z)
		g.feel("happy", 30.0)
	set_hour(Save.hour())
	game.after(18.0, func(): wedding(false))
