## The inside of a shop on Main Street (market, florist, bookshop, home store, boutique,
## jeweller or the clinic). One room, dressed differently for each: goods on the shelves,
## displays on the floor and the shopkeeper behind the counter.
class_name ShopLocation
extends Location

const OPEN := 8.0
const CLOSE := 20.0
const SHOPS := {
	"market": {"title": "Kai's Market", "keeper": "kai", "wall": "Mint", "floor": "Honey wood", "shelf": "jars",
		"items": [["crate_fruit", -2.6, 1.0, 0], ["crate_fruit", -0.9, 1.0, 0], ["crate_fruit", -2.6, -0.9, 0], ["crate_fruit", -0.9, -0.9, 0], ["big_plant", -3.3, -2.3, 0]]},
	"florist": {"title": "Hana's Flowers", "keeper": "hana", "wall": "Sakura", "floor": "Pale oak", "shelf": "pots",
		"items": [["flower_bucket", -2.6, 1.1, 0], ["flower_bucket", -0.9, 1.1, 0], ["flower_bucket", -2.6, -0.9, 0], ["big_plant", -0.9, -1.0, 0], ["plant", -3.3, -2.3, 0], ["flowers", 3.4, -0.4, 0]]},
	"bookshop": {"title": "Ren's Books", "keeper": "ren", "wall": "Cocoa", "floor": "Walnut", "shelf": "books",
		"items": [["bookshelf", -2.4, 1.6, 0], ["bookshelf", -0.8, 1.6, 0], ["armchair", -2.6, -0.6, 0], ["lamp", -3.3, -2.35, 0], ["rug", -1.4, 0.0, 0]]},
	"homestore": {"title": "Home Store", "keeper": "homestore", "wall": "Lemon", "floor": "Honey wood", "shelf": "boxes",
		"items": [["sofa", -2.5, 1.5, 0], ["table4", -0.6, 0.4, 0], ["lamp", -3.3, -2.2, 0], ["armchair", -2.6, -0.8, 1], ["big_plant", 0.2, -2.2, 0]]},
	"boutique": {"title": "Mimi's Boutique", "keeper": "boutique", "wall": "Lilac", "floor": "Lavender", "shelf": "hats",
		"items": [["clothes_rack", -2.6, 1.1, 0], ["clothes_rack", -0.8, 1.1, 0], ["clothes_rack", -3.2, -0.9, 1], ["plant", 0.2, -2.3, 0], ["rug", -1.2, -0.6, 0]], "mannequins": [Vector3(-1.4, 0, -1.4), Vector3(-0.4, 0, -1.4)]},
	"jeweler": {"title": "Kobayashi Jewels", "keeper": "jeweler", "wall": "Sky", "floor": "Walnut", "shelf": "boxes",
		"items": [["gem_case", -2.5, 1.0, 0], ["gem_case", -0.7, 1.0, 0], ["gem_case", -2.5, -0.9, 0], ["plant", 0.3, -2.3, 0], ["big_plant", -3.3, -2.3, 0]]},
	"clinic": {"title": "Hoshizora Clinic", "keeper": "doctor", "wall": "Mint", "floor": "Mint tiles", "shelf": "jars",
		"items": [["waiting_bench", -2.4, 1.6, 0], ["waiting_bench", -0.6, 1.6, 0], ["crib", -2.8, -1.0, 0], ["crib", -1.5, -1.0, 0], ["plant", 0.3, -2.3, 0], ["toy_box", -3.1, 0.2, 1]], "open": 7.0, "close": 22.0},
}

var shop := ""
var keeper_node: Chibi
var sun: DirectionalLight3D
var lamps: Array = []
var window_mat: ShaderMaterial
var decor: Node3D

func setup(g: Game) -> void:
	super(g)
	key = "shop"
	title = "A shop"
	music_mood = "town"
	editable = false
	room = Room.new()
	room.name = "Room"
	add_child(room)
	room.load_glb("res://assets/models/shop.glb")
	cam_offset = Vector3(0, 5.0, 5.4)
	cam_look = Vector3(0, 0.6, -0.4)
	cam_bounds = Rect2(-1.4, -0.6, 2.8, 0.9)
	make_nav(Rect2(-3.8, -2.8, 7.6, 5.2))
	furni = FurnitureLayer.new()
	furni.name = "Furniture"
	add_child(furni)
	env = Room.interior_environment()
	we = WorldEnvironment.new()
	we.environment = env
	sun = Room.key_light(Vector3(-55, -25, 0))
	lights.add_child(sun)
	for i in 2:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.82, 0.6)
		l.light_energy = 1.2
		l.omni_range = 4.5
		lights.add_child(l)
		l.global_position = room.mark("lamp_%d" % i)
		lamps.append(l)
	var win := Room.rain_window(Vector2(2.6, 1.2))
	add_child(win)
	win.global_position = room.mark("window") + Vector3(0, 0, -0.1)
	window_mat = win.material_override

## Opening hours (the clinic keeps longer hours).
static func is_open(id: String) -> bool:
	var s: Dictionary = SHOPS.get(id, {})
	var h := Save.hour()
	return h >= float(s.get("open", OPEN)) and h < float(s.get("close", CLOSE))

## Dresses the room for a shop and puts its keeper behind the counter.
func set_shop(id: String) -> void:
	shop = id
	var s: Dictionary = SHOPS[id]
	title = s.title
	var lay: Array = []
	for it in s.items: lay.append({"id": it[0], "x": it[1], "z": it[2], "rot": it[3]})
	Save.layouts["shop_" + id] = lay
	furni.setup("shop_" + id, Rect2(-3.7, -2.7, 7.4, 5.0), nav)
	_reach_dirty = true
	room.set_wall(Furni.WALLS[s.wall])
	room.set_floor(Furni.FLOORS[s.floor])
	if decor: decor.queue_free()
	decor = Node3D.new()
	add_child(decor)
	_shelves(String(s.shelf))
	for p in s.get("mannequins", []):
		var m := Chibi.new()
		decor.add_child(m)
		var lk := Chibi.random_look(null, "f" if randf() < 0.5 else "m")
		lk.skin = "F2F2F8"
		m.build(lk, "adult")
		m.global_position = p
		m.feel("idle", 0.1)
	if keeper_node:
		npcs.erase(keeper_node)
		keeper_node.queue_free()
		keeper_node = null
	var kid: String = s.keeper
	if keeper_here(kid):
		keeper_node = make_person(kid, People.look_of(kid), People.npc_name(kid))
		keeper_node.floor_y = 0.34   # standing on the step behind the counter
		keeper_node.global_position = room.mark("keeper") + Vector3(0, 0.34, 0.05)
		keeper_node.rotation.y = 0.0
		keeper_node.set_work_clothes(false)
	interacts.clear()
	add_interact("door", room.mark("door"), 0.8, "Back out to the street", func(): game.leave_shop())
	interacts.back().h = 1.6
	add_interact("counter", room.mark("counter"), 0.9, "Browse %s" % s.title, func(): game.open_shop_ui(shop))
	interacts.back().at = room.mark("counter") + Vector3(0, 1.1, -0.8)
	interacts.back().prio = 0.2

## Kai, Hana and Ren mind their shops 9–5 (and are out and about otherwise); the others are always in.
static func keeper_here(kid: String) -> bool:
	if People.NPCS.has(kid): return Life.npc_at_work(kid)
	return true

func _shelves(kind: String) -> void:
	var mb := MB.new()
	var cols := [Color("FF9EBB"), Color("A9C8FF"), Color("FFD24A"), Color("B7E3A0"), Color("C3A6FF"), Color("FFB86A"), Color("E8504A")]
	for side in ["back", "left"]:
		for k in 3:
			var base := room.mark("shelf_%s_%d" % [side, k])
			for i in 9:
				var off := Vector3(-1.2 + i * 0.3, 0, 0) if side == "back" else Vector3(0, 0, -1.15 + i * 0.29)
				var p := base + off
				var c: Color = cols[(i + k * 2 + (3 if side == "left" else 0)) % cols.size()]
				match kind:
					"books":
						for b in 3:
							var bo := Vector3(-0.07 + b * 0.07, 0, 0) if side == "back" else Vector3(0, 0, -0.07 + b * 0.07)
							mb.col(cols[(i + b + k) % cols.size()], 1.0, 0.2); mb.at(p + bo + Vector3(0, 0.13, 0)); mb.rbox(Vector3(0.06, 0.25 - b * 0.02, 0.18) if side == "back" else Vector3(0.18, 0.25 - b * 0.02, 0.06), 0.008, 1); mb.pop()
					"jars":
						mb.col(c.lightened(0.3), 1.0, 0.6); mb.at(p + Vector3(0, 0.09, 0)); mb.cylinder(0.065, 0.17, 12); mb.pop()
						mb.col(Color("C8864E"), 1.0, 0.2); mb.at(p + Vector3(0, 0.19, 0)); mb.cylinder(0.07, 0.03, 12); mb.pop()
					"pots":
						mb.col(Color("E8826A"), 1.0, 0.2); mb.at(p + Vector3(0, 0.07, 0)); mb.cylinder(0.07, 0.13, 12, 0.055); mb.pop()
						mb.col(Color("6BBF59"), 1.0, 0.3); mb.at(p + Vector3(0, 0.17, 0)); mb.sphere(0.08, 10, 8); mb.pop()
						mb.col(c, 1.0, 0.3); mb.at(p + Vector3(0.03, 0.22, 0.03)); mb.sphere(0.03, 8, 6); mb.pop()
					"hats":
						mb.col(c, 1.0, 0.3); mb.at(p + Vector3(0, 0.04, 0)); mb.cylinder(0.12, 0.02, 16); mb.pop()
						mb.at(p + Vector3(0, 0.09, 0)); mb.sphere(0.075, 12, 8); mb.pop()
					_:
						mb.col(c, 1.0, 0.2); mb.at(p + Vector3(0, 0.09, 0)); mb.rbox(Vector3(0.22, 0.18, 0.18), 0.02, 1); mb.pop()
						mb.col(Color.WHITE, 0.0); mb.at(p + Vector3(0, 0.181, 0)); mb.rbox(Vector3(0.23, 0.01, 0.04), 0.002, 1); mb.pop()
	decor.add_child(FoodArt.mesh_node(FoodArt.finish(mb)))

func entry_point(_entry: String) -> Vector3:
	return room.mark("spawn")

func entry_yaw(_entry: String) -> float:
	return -PI * 0.5

func set_hour(h: float) -> void:
	var night := clampf((h - 18.0) / 3.0, 0.0, 1.0)
	window_mat.set_shader_parameter("night", night)
	window_mat.set_shader_parameter("rain", 1.0 if game.weather == "rain" else 0.0)
	sun.light_energy = lerpf(0.85, 0.3, night)
	for l in lamps: l.light_energy = lerpf(0.9, 1.7, night)
	env.ambient_light_energy = lerpf(0.62, 0.42, night)
