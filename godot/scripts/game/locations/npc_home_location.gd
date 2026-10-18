## A townsperson's cottage (Hana, Ren, Kai or Yuki). One location, refurnished for whoever's
## house you walk into. They're home in the evening and asleep late at night, so knock first,
## or sneak in if you dare.
class_name NpcHomeLocation
extends Location

const STYLE := {
	"hana": {"wall": "Sakura", "floor": "Pale oak", "items": [["bed", -2.65, 1.25, 0], ["flowers", 0.9, -2.3, 0], ["flowers", -1.0, -2.3, 0], ["big_plant", 2.9, -2.1, 0],
		["armchair", 2.0, -0.6, 3], ["rug", 0.3, 0.6, 0], ["lamp", 3.1, 1.9, 0], ["plant", -3.2, -0.6, 0]]},
	"ren": {"wall": "Cocoa", "floor": "Walnut", "items": [["single_bed", -3.0, 1.3, 0], ["bookshelf", 0.6, -2.35, 0], ["bookshelf", 2.2, -2.35, 0], ["armchair", 2.6, -1.0, 3],
		["lamp", 3.1, 0.2, 0], ["rug", 0.6, 0.5, 0], ["plant", -1.0, -2.3, 0]]},
	"kai": {"wall": "Lemon", "floor": "Honey wood", "items": [["bed", -2.65, 1.25, 0], ["tv", 1.6, -2.35, 0], ["sofa", 1.6, -0.7, 2], ["big_plant", 3.1, -2.2, 0],
		["rug", 1.6, -1.4, 0], ["plant", -1.0, -2.3, 0], ["record", 3.1, 1.9, 1]]},
	"yuki": {"wall": "Lilac", "floor": "Lavender", "items": [["bed", -2.65, 1.25, 0], ["piano", 1.4, -2.3, 0], ["big_plant", 3.1, -2.1, 0], ["armchair", 2.7, 0.3, 3],
		["rug", 0.6, 0.6, 0], ["lamp", 3.1, 1.9, 0], ["aquarium", -0.9, -2.35, 0]]},
}

var host := ""
var host_node: Chibi
var sun: DirectionalLight3D
var lamp: OmniLight3D
var window_mat: ShaderMaterial
var zzz: Label3D

func setup(g: Game) -> void:
	super(g)
	key = "npchome"
	title = "A cottage"
	music_mood = "home"
	room = Room.new()
	room.name = "Room"
	add_child(room)
	room.load_glb("res://assets/models/home.glb")
	cam_offset = Vector3(0, 5.0, 5.4)
	cam_look = Vector3(0, 0.5, -0.4)
	cam_bounds = Rect2(-1.2, -0.6, 2.4, 0.9)
	make_nav(Rect2(-3.6, -2.7, 7.2, 5.1))
	furni = FurnitureLayer.new()
	furni.name = "Furniture"
	add_child(furni)
	editable = false
	env = Room.interior_environment()
	we = WorldEnvironment.new()
	we.environment = env
	sun = Room.key_light(Vector3(-55, -20, 0))
	lights.add_child(sun)
	lamp = OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.8, 0.58)
	lamp.omni_range = 4.5
	lights.add_child(lamp)
	lamp.global_position = room.mark("lamp_0")
	var win := Room.rain_window(Vector2(3.0, 1.15))
	add_child(win)
	win.global_position = room.mark("window") + Vector3(0, 0, -0.1)
	window_mat = win.material_override
	zzz = Label3D.new()
	zzz.text = "z z Z"
	zzz.font = load("res://assets/fonts/MochiyPopOne-Regular.ttf")
	zzz.font_size = 48
	zzz.pixel_size = 0.003
	zzz.modulate = Color("C3A6FF")
	zzz.outline_size = 10
	zzz.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	zzz.visible = false
	add_child(zzz)

## Refurnishes the cottage for its host and puts them in it if they're home.
func set_host(id: String) -> void:
	host = id
	title = "%s's house" % People.npc_name(id)
	var st: Dictionary = STYLE[id]
	var lay: Array = []
	for it in st.items: lay.append({"id": it[0], "x": it[1], "z": it[2], "rot": it[3]})
	Save.layouts["npc_" + id] = lay
	furni.setup("npc_" + id, Rect2(-3.5, -2.6, 7.0, 4.9), nav)
	room.set_wall(Furni.WALLS[st.wall])
	room.set_floor(Furni.FLOORS[st.floor])
	if host_node:
		npcs.erase(host_node)
		host_node.queue_free()
		host_node = null
	interacts.clear()
	add_interact("door", room.mark("door"), 0.8, "Leave the house", func(): game.leave_house())
	interacts.back().h = 1.6
	if String(Save.flags.get("live_with", "")) == id:
		var b := furni.first("bed")
		if b.is_empty(): b = furni.first("single_bed")
		if b.size():
			add_interact("bed", nav.nearest_free(Vector3(b.x, 0, b.z) + Vector3(1.0, 0, 0)), 1.1, "Go to bed", func(): game.home._bed_menu())
			interacts.back().at = Vector3(b.x, 0.55, b.z)
	else:
		add_interact("snoop", nav.nearest_free(room.mark("kitchen") + Vector3(0.6, 0, 0.1)), 0.8, "Snoop around", func(): game.life.snoop(host))
		interacts.back().h = 1.2
	if home():
		host_node = make_person(id, People.look_of(id), People.npc_name(id))
		_place_owner()

## Townsfolk are home from 9pm until 7am (and on rainy evenings a little earlier).
func home() -> bool:
	return Life.npc_home(host)

func asleep() -> bool:
	var h := Save.hour()
	return home() and (h >= 23.0 or h < 6.5)

func _place_owner() -> void:
	if host_node == null: return
	var b := furni.first("bed")
	if b.is_empty(): b = furni.first("single_bed")
	if asleep() and b.size():
		host_node.sit_at(Vector3(b.x, 0, b.z + 0.2), 0.0, 0.42)
		host_node.feel("sleepy", 9999.0)
		zzz.visible = true
		zzz.global_position = host_node.global_position + Vector3(0.1, 0.75, 0)
	else:
		host_node.stand_up()
		host_node.global_position = nav.nearest_free(Vector3(0.6, 0, -0.6))
		host_node.feel("idle", 0.1)
		zzz.visible = false

func entry_point(_entry: String) -> Vector3:
	return room.mark("spawn")

func entry_yaw(_entry: String) -> float:
	return -PI * 0.5

func set_hour(h: float) -> void:
	var night := clampf((h - 18.0) / 3.0, 0.0, 1.0) if h > 12.0 else clampf((7.0 - h) / 1.5, 0.0, 1.0)
	window_mat.set_shader_parameter("night", night)
	window_mat.set_shader_parameter("rain", 1.0 if game.weather == "rain" else 0.0)
	sun.light_energy = lerpf(0.85, 0.2, night)
	lamp.light_energy = lerpf(0.5, 1.6 if not asleep() else 0.4, night)
	env.ambient_light_energy = lerpf(0.6, 0.38, night)
	if host_node and is_instance_valid(host_node): _place_owner()

func tick(dt: float) -> void:
	super(dt)
	if zzz.visible:
		zzz.modulate.a = 0.6 + 0.4 * sin(game.clock * 1.5)
