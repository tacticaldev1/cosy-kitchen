## Your café: kitchen stations on the left, the pass with bar stools in the middle, a dining
## room you furnish yourself, and the street door.
class_name CafeLocation
extends Location

var stations := {}
var stand := {}           # station key -> where you stand to use it (world)
var window_mat: ShaderMaterial
var lamps: Array = []
var sun: DirectionalLight3D
var sign_node: Label3D

func setup(g: Game) -> void:
	super(g)
	key = "cafe"
	title = "Cosy Kitchen Café"
	room = Room.new()
	room.name = "Room"
	add_child(room)
	room.load_glb("res://assets/models/cafe.glb")
	cam_offset = Vector3(0, 4.2, 4.9)
	cam_look = Vector3(0, 0.6, -0.6)
	cam_bounds = Rect2(-2.6, -1.6, 5.2, 2.6)
	make_nav(Rect2(-4.2, -3.0, 8.4, 5.6))
	_build_stations()
	furni = FurnitureLayer.new()
	furni.name = "Furniture"
	add_child(furni)
	furni.setup("cafe", Rect2(-0.05, -2.95, 4.2, 5.25), nav)
	apply_theme()
	_build_lights()
	_build_interacts()

func apply_theme() -> void:
	var th: Dictionary = Save.themes.get("cafe", {})
	room.set_wall(Furni.WALLS.get(th.get("wall", "Peach"), "FCE9DE"))
	room.set_floor(Furni.FLOORS.get(th.get("floor", "Honey wood"), Furni.FLOORS["Honey wood"]))

func _build_stations() -> void:
	var stove := Appl.stove()
	add_child(stove)
	stove.global_position = (room.mark("pot") + room.mark("pan")) * 0.5
	var fridge := Appl.fridge()
	fridge.name = "Fridge"
	add_child(fridge)
	fridge.global_position = room.mark("fridge")
	stand["fridge"] = room.mark("fridge") + Vector3(0, 0, 0.75)
	var top := Vector3(0, 0.62, 0.72)
	var look := Vector3(0, 0.04, -0.05)
	_place(BoardStation.new(), Appl.board(), "board", top, look, Vector3(0, 0, 0.62))
	_place(BowlStation.new(), Appl.bowl(), "bowl", top + Vector3(0, 0.06, 0.04), look + Vector3(0, 0.05, 0), Vector3(0, 0, 0.62))
	_place(BlenderStation.new(), Appl.blender(), "blender", Vector3(0, 0.5, 0.82), Vector3(0, 0.2, -0.02), Vector3(0, 0, 0.62))
	_place(MatStation.new(), Appl.mat(), "mat", top, look, Vector3(0, 0, 0.62))
	_place(PotStation.new(), Appl.pot(), "pot", Vector3(0.05, 0.7, 0.72), Vector3(0.02, 0.1, -0.05), Vector3(0, 0, 0.86), Vector3(0, 0.026, -0.02))
	_place(PanStation.new(), Appl.pan(), "pan", Vector3(0.05, 0.62, 0.7), Vector3(0.04, 0.03, -0.05), Vector3(0, 0, 0.86), Vector3(0, 0.026, -0.02))
	_place(OvenStation.new(), Appl.oven(), "oven", Vector3(0, 0.78, 1.32), Vector3(0, 0.4, 0.0), Vector3(0, 0, 0.5))
	_place(MicroStation.new(), Appl.micro(), "micro", Vector3(-0.05, 0.5, 0.82), Vector3(0, 0.16, 0.0), Vector3(0, 0, 0.86))
	_place(FreezerStation.new(), Appl.freezer(), "freezer", Vector3(-0.25, 1.15, 1.45), Vector3(0, 0.62, 0), Vector3(0, 0, 0.66))
	_place(PlateStation.new(), Appl.pass_plate(), "pass", Vector3(0, 0.82, 1.9), Vector3(0, 0.1, -0.35), Vector3(0, 0, 0.62), Vector3.ZERO, "plate", -PI * 0.5)
	_place(BinStation.new(), Appl.bin(), "bin", Vector3(-0.25, 1.0, 1.15), Vector3(0, 0.32, 0), Vector3(0, 0, 0.62))
	for k in stations:
		var st: Station = stations[k]
		if st.items.is_empty(): st.on_items_changed()

func _place(st: Station, model: Node3D, mark: String, cam_off: Vector3, look_off: Vector3, stand_off: Vector3, nudge := Vector3.ZERO, k := "", yaw := 0.0) -> void:
	st.game = game
	add_child(st)
	st.attach(model)
	var p := room.mark(mark) + nudge
	st.global_position = p
	st.rotation.y = yaw
	var b := Basis.from_euler(Vector3(0, yaw, 0))
	st.cam_pos = p + b * cam_off
	st.cam_look = p + b * look_off
	var key_ := k if k != "" else st.key
	stations[key_] = st
	var sp := p + b * stand_off
	stand[key_] = Vector3(sp.x, 0, sp.z)

func _build_lights() -> void:
	env = Room.interior_environment()
	we = WorldEnvironment.new()
	we.environment = env
	sun = Room.key_light()
	lights.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.75, 0.8, 1.0)
	fill.light_energy = 0.12
	fill.rotation_degrees = Vector3(-15, 160, 0)
	lights.add_child(fill)
	for i in 3:
		if not room.has_mark("lamp_%d" % i): continue
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.78, 0.52)
		l.light_energy = 1.3
		l.omni_range = 2.8
		l.omni_attenuation = 1.4
		lights.add_child(l)
		l.global_position = room.mark("lamp_%d" % i)
		lamps.append(l)
	var win := Room.rain_window(Vector2(3.4, 1.4))
	add_child(win)
	win.global_position = room.mark("window") + Vector3(0, 0, -0.1)
	window_mat = win.material_override
	# the OPEN sign by the door
	sign_node = Label3D.new()
	sign_node.font = load("res://assets/fonts/MochiyPopOne-Regular.ttf")
	sign_node.font_size = 64
	sign_node.pixel_size = 0.0022
	sign_node.outline_size = 14
	sign_node.outline_modulate = Color("3B2340")
	sign_node.pixel_size = 0.0028
	add_child(sign_node)
	var d := room.mark("door")
	sign_node.global_position = Vector3(4.14, 2.42, d.z)
	sign_node.rotation.y = -PI * 0.5
	set_sign(false)

func set_sign(open: bool) -> void:
	sign_node.text = "OPEN" if open else "CLOSED"
	sign_node.modulate = Color("FF7EA6") if open else Color("E8D2B4")

func _build_interacts() -> void:
	for k in stations:
		var st: Station = stations[k]
		var kk: String = k
		var it := {"id": "st_" + k, "pos": stand[k], "r": 0.75, "label": "Use the " + Game.LABEL[k], "act": func(): game.open_station(kk), "h": 1.1}
		interacts.append(it)
	add_interact("fridge", stand["fridge"], 0.8, "Open the fridge", func(): game.hud.open_fridge())
	interacts.back().h = 1.4
	add_interact("door", room.mark("door"), 0.8, "Go outside", func(): game.travel("city", "cafe"))
	add_interact("sign", room.mark("door") + Vector3(-0.3, 0, -0.75), 0.75, "Flip the OPEN sign", func(): game.shop.toggle())

func entry_point(entry: String) -> Vector3:
	return room.mark("spawn") if entry != "kitchen" else stand["board"]

func entry_yaw(_entry: String) -> float:
	return -PI * 0.5

## Seats customers can use: the bar stools plus every chair you've placed.
func seats() -> Array:
	var out: Array = []
	for i in 3:
		if room.has_mark("bar_%d" % i):
			var p := room.mark("bar_%d" % i)
			out.append({"pos": p, "yaw": -PI * 0.5, "h": 0.6, "id": "bar", "approach": p + Vector3(0.55, 0, 0)})
	out.append_array(furni.seats())
	return out

func set_hour(h: float) -> void:
	var night := clampf((h - 17.0) / 4.0, 0.0, 1.0)
	if window_mat:
		window_mat.set_shader_parameter("night", night)
		window_mat.set_shader_parameter("rain", 1.0 if game.weather == "rain" else 0.0)
	if sun:
		sun.light_energy = lerpf(0.9, 0.5, night)
		sun.light_color = Color(1.0, 0.94, 0.85).lerp(Color(1.0, 0.75, 0.6), night)
	for l in lamps:
		l.light_energy = lerpf(1.0, 2.0, night)
	if env:
		env.ambient_light_energy = lerpf(0.6, 0.45, night)
