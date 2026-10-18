## The furniture catalogue: every item's name, price, where it can go, its footprint,
## seats (for customers or family) and a procedural toon model.
class_name Furni
extends RefCounted

# id: [name, price, where (cafe/home/both), w, d, category, description]
const CATALOG := {
	"table2": ["Café table for two", 2400, "both", 1.3, 0.75, "Tables", "A round table with two chairs. Customers can sit here."],
	"table4": ["Family table", 4200, "both", 1.5, 1.5, "Tables", "A square table with four chairs. More seats, more customers!"],
	"booth": ["Cosy booth", 5200, "cafe", 1.7, 1.1, "Tables", "A pink booth with a table. Seats two in style."],
	"chair": ["Wooden chair", 700, "both", 0.5, 0.5, "Seating", "A simple chair."],
	"sofa": ["Fluffy sofa", 4800, "home", 1.7, 0.8, "Seating", "A soft sofa for two."],
	"armchair": ["Armchair", 2600, "both", 0.85, 0.8, "Seating", "Perfect for reading."],
	"bed": ["Double bed", 6800, "home", 1.7, 2.1, "Bedroom", "Sleep here to end the day. Room for two."],
	"single_bed": ["Single bed", 3200, "home", 1.0, 2.0, "Bedroom", "A snug single bed."],
	"crib": ["Baby crib", 3800, "home", 1.0, 0.65, "Bedroom", "A crib for a little one. Needed before a baby can arrive."],
	"kid_bed": ["Kid's bed", 3000, "home", 0.9, 1.6, "Bedroom", "A little bed with star sheets."],
	"wardrobe": ["Wardrobe", 3400, "home", 1.1, 0.6, "Bedroom", "Change your outfit at home."],
	"rug": ["Round rug", 1200, "both", 2.0, 2.0, "Decor", "Soft underfoot. You can walk on it."],
	"plant": ["Potted plant", 900, "both", 0.5, 0.5, "Decor", "A leafy friend."],
	"big_plant": ["Big plant", 2200, "both", 0.7, 0.7, "Decor", "A tall monstera for the corner."],
	"lamp": ["Floor lamp", 1600, "both", 0.5, 0.5, "Decor", "A warm glow."],
	"bookshelf": ["Bookshelf", 2800, "both", 1.2, 0.45, "Decor", "Full of cookbooks and novels."],
	"lucky_cat": ["Lucky cat", 2500, "cafe", 0.5, 0.5, "Decor", "Maneki-neko waves in good fortune: +5% tips in the café."],
	"flowers": ["Flower stand", 1800, "both", 0.5, 0.5, "Decor", "Fresh flowers: customers arrive a little sooner."],
	"record": ["Record player", 4500, "both", 0.9, 0.5, "Decor", "Lo-fi on vinyl: customers wait 25% longer."],
	"cat_bed": ["Cat bed + cat", 6000, "both", 0.8, 0.8, "Decor", "A sleepy orange cat moves in. Zzz…"],
	"aquarium": ["Aquarium", 5600, "both", 1.1, 0.5, "Decor", "Little fish swimming in circles."],
	"tv": ["TV stand", 3900, "home", 1.4, 0.5, "Living", "Cartoons and cooking shows."],
	"piano": ["Little piano", 8800, "both", 1.4, 0.6, "Living", "Play a tune."],
	"fireplace": ["Fireplace", 7400, "both", 1.4, 0.5, "Living", "Crackling and warm."],
	"toy_box": ["Toy box", 1400, "home", 0.8, 0.5, "Living", "For the little ones."],
}

const WALLS := {"Peach": "FCE9DE", "Sakura": "FFE0EA", "Mint": "DFF5EC", "Sky": "E2EEFF", "Lemon": "FFF6D2", "Lilac": "EDE3FF", "Cocoa": "E8D2C2", "Night": "B8B0D8"}
const FLOORS := {"Honey wood": ["E8B87A", "E2AE6E", "ECC088", "DDA466"], "Pale oak": ["F2DDB8", "EAD2A8", "F6E4C4", "E4CCA0"], "Walnut": ["A8704A", "9A6440", "B47C54", "8E5A38"],
	"Pink tiles": ["FFD6E2", "FFE6EE", "FFD6E2", "FFE6EE"], "Mint tiles": ["CFEFE2", "E2F8EF", "CFEFE2", "E2F8EF"], "Lavender": ["D8CCF2", "E4DAF8", "CFC2EE", "DCD0F4"]}

static func info(id: String) -> Dictionary:
	var d: Array = CATALOG[id]
	return {"id": id, "name": d[0], "price": d[1], "where": d[2], "w": d[3], "d": d[4], "cat": d[5], "desc": d[6]}

static func fits(id: String, location: String) -> bool:
	var w: String = CATALOG[id][2]
	return w == "both" or w == location

static func walkable(id: String) -> bool:
	return id == "rug"

## Seats in local space: [position, yaw (facing), height of the sitting origin]
static func seats(id: String) -> Array:
	match id:
		"table2": return [[Vector3(-0.48, 0, 0), PI * 0.5, 0.3], [Vector3(0.48, 0, 0), -PI * 0.5, 0.3]]
		"table4": return [[Vector3(-0.58, 0, 0), PI * 0.5, 0.3], [Vector3(0.58, 0, 0), -PI * 0.5, 0.3], [Vector3(0, 0, -0.58), 0.0, 0.3], [Vector3(0, 0, 0.58), PI, 0.3]]
		"booth": return [[Vector3(-0.55, 0, -0.05), PI * 0.5, 0.28], [Vector3(0.55, 0, -0.05), -PI * 0.5, 0.28]]
		"chair": return [[Vector3(0, 0, 0), 0.0, 0.3]]
		"sofa": return [[Vector3(-0.35, 0, 0.05), 0.0, 0.28], [Vector3(0.35, 0, 0.05), 0.0, 0.28]]
		"armchair": return [[Vector3(0, 0, 0.05), 0.0, 0.28]]
	return []

static var _mesh := {}

static func node(id: String) -> Node3D:
	var n := Node3D.new()
	n.name = id
	if not _mesh.has(id):
		var mb := MB.new()
		_build(mb, id)
		_mesh[id] = FoodArt.finish(mb)
	n.add_child(FoodArt.mesh_node(_mesh[id]))
	if id == "lamp" or id == "fireplace":
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.75, 0.45)
		l.light_energy = 0.9
		l.omni_range = 2.4
		l.position = Vector3(0, 1.4 if id == "lamp" else 0.5, 0.2 if id == "fireplace" else 0.0)
		n.add_child(l)
	return n

# ---------------------------------------------------------------- models
static func _chair(mb: MB, pos: Vector3, yaw: float, c := Color("E8B87A"), seat := Color("FF9EBB")) -> void:
	mb.at(pos, Vector3(0, yaw, 0))
	mb.col(c)
	for p in [Vector3(-0.16, 0, -0.16), Vector3(0.16, 0, -0.16), Vector3(-0.16, 0, 0.16), Vector3(0.16, 0, 0.16)]:
		mb.tube(PackedVector3Array([p, p + Vector3(0, 0.46, 0)]), 0.022, 8)
	mb.col(seat, 1.0, 0.1); mb.at(Vector3(0, 0.48, 0)); mb.rbox(Vector3(0.42, 0.06, 0.42), 0.025, 2); mb.pop()
	mb.col(c); mb.at(Vector3(0, 0.78, -0.19)); mb.rbox(Vector3(0.42, 0.34, 0.05), 0.025, 2); mb.pop()
	mb.col(Color.WHITE, 0.0); mb.at(Vector3(0, 0.82, -0.163)); mb.ellipsoid(0.05, 0.045, 0.006, 10, 4); mb.pop()
	mb.pop()

static func _table_round(mb: MB, r: float, c := Color("FFF4E2")) -> void:
	mb.col(Color("C8864E")); mb.puck(0.22, 0.04, 0.015, 24)
	mb.col(Color("C8864E")); mb.tube(PackedVector3Array([Vector3(0, 0.04, 0), Vector3(0, 0.72, 0)]), 0.045, 12)
	mb.col(c, 1.0, 0.2); mb.at(Vector3(0, 0.72, 0)); mb.puck(r, 0.05, 0.018, 36); mb.pop()

static func _plant_leaves(mb: MB, base: Vector3, n: int, size: float, seed_: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	for i in n:
		var a := i * 2.4
		var tilt := -0.6 - rng.randf() * 0.6
		mb.push(Transform3D(Basis.from_euler(Vector3(tilt, a, 0)), base + Vector3(0, rng.randf() * size * 0.6, 0)))
		mb.col(Color("6BBF59") if i % 2 else Color("4E9E57"), 1.0, 0.1)
		mb.at(Vector3(0, 0, size)); mb.leaf(size, size * 0.5, 0.006, 0.5); mb.pop()
		mb.pop()

static func _build(mb: MB, id: String) -> void:
	match id:
		"table2":
			_table_round(mb, 0.38)
			_chair(mb, Vector3(-0.5, 0, 0), PI * 0.5)
			_chair(mb, Vector3(0.5, 0, 0), -PI * 0.5)
			mb.col(Color("A9C8FF"), 1.0, 0.5); mb.at(Vector3(0.05, 0.77, 0.05)); mb.cylinder(0.035, 0.1, 14, 0.028); mb.pop()
			mb.col(Color("FF7EA6"), 0.6); mb.at(Vector3(0.05, 0.89, 0.05)); mb.sphere(0.035, 10, 8); mb.pop()
		"table4":
			mb.col(Color("C8864E"))
			for p in [Vector3(-0.32, 0, -0.32), Vector3(0.32, 0, -0.32), Vector3(-0.32, 0, 0.32), Vector3(0.32, 0, 0.32)]:
				mb.tube(PackedVector3Array([p, p + Vector3(0, 0.72, 0)]), 0.035, 10)
			mb.col(Color("FFF4E2"), 1.0, 0.2); mb.at(Vector3(0, 0.74, 0)); mb.rbox(Vector3(0.85, 0.05, 0.85), 0.02, 2); mb.pop()
			mb.col(Color("FFC2D6"), 0.0); mb.at(Vector3(0, 0.7695, 0)); mb.rbox(Vector3(0.5, 0.003, 0.86), 0.001, 1); mb.pop()
			_chair(mb, Vector3(-0.6, 0, 0), PI * 0.5)
			_chair(mb, Vector3(0.6, 0, 0), -PI * 0.5)
			_chair(mb, Vector3(0, 0, -0.6), 0.0)
			_chair(mb, Vector3(0, 0, 0.6), PI)
		"booth":
			for s in [-1.0, 1.0]:
				mb.col(Color("FF9EBB"), 1.0, 0.2); mb.at(Vector3(s * 0.62, 0.22, 0)); mb.rbox(Vector3(0.42, 0.44, 1.05), 0.06, 3); mb.pop()
				mb.col(Color("FF7EA6"), 1.0, 0.2); mb.at(Vector3(s * 0.8, 0.7, 0)); mb.rbox(Vector3(0.12, 0.6, 1.05), 0.05, 3); mb.pop()
			mb.col(Color("C8864E")); mb.tube(PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 0.72, 0)]), 0.05, 12)
			mb.col(Color("FFF4E2"), 1.0, 0.2); mb.at(Vector3(0, 0.74, 0)); mb.rbox(Vector3(0.7, 0.05, 0.9), 0.04, 2); mb.pop()
		"chair":
			_chair(mb, Vector3.ZERO, 0.0)
		"sofa", "armchair":
			var wdt := 1.6 if id == "sofa" else 0.75
			mb.col(Color("C3A6FF") if id == "sofa" else Color("FFB86A"), 1.0, 0.15)
			mb.at(Vector3(0, 0.22, 0.02)); mb.rbox(Vector3(wdt, 0.36, 0.72), 0.08, 3); mb.pop()
			mb.at(Vector3(0, 0.55, -0.27)); mb.rbox(Vector3(wdt, 0.6, 0.2), 0.08, 3); mb.pop()
			for s in [-1.0, 1.0]:
				mb.at(Vector3(s * (wdt * 0.5 - 0.08), 0.42, 0.02)); mb.rbox(Vector3(0.18, 0.42, 0.74), 0.08, 3); mb.pop()
			var cushions := 2 if id == "sofa" else 1
			for i in cushions:
				mb.col(Color("FFE3EC"), 1.0, 0.1); mb.at(Vector3((i - (cushions - 1) * 0.5) * 0.62, 0.43, 0.08)); mb.rbox(Vector3(0.56 if id == "sofa" else 0.46, 0.12, 0.5), 0.05, 2); mb.pop()
			mb.col(Color("8A6A4A"))
			for p in [Vector3(-wdt * 0.42, 0, -0.25), Vector3(wdt * 0.42, 0, -0.25), Vector3(-wdt * 0.42, 0, 0.28), Vector3(wdt * 0.42, 0, 0.28)]:
				mb.at(p); mb.cylinder(0.03, 0.05, 8); mb.pop()
		"bed", "single_bed", "kid_bed":
			var bw := 1.6 if id == "bed" else 0.9 if id == "single_bed" else 0.8
			var bl := 2.0 if id != "kid_bed" else 1.5
			mb.col(Color("E8B87A"), 1.0, 0.1); mb.at(Vector3(0, 0.18, 0)); mb.rbox(Vector3(bw, 0.24, bl), 0.04, 2); mb.pop()
			mb.at(Vector3(0, 0.55, -bl * 0.5 + 0.04)); mb.rbox(Vector3(bw + 0.04, 0.8, 0.08), 0.04, 2); mb.pop()
			mb.col(Color.WHITE, 1.0, 0.1); mb.at(Vector3(0, 0.36, 0)); mb.rbox(Vector3(bw - 0.06, 0.16, bl - 0.08), 0.06, 3); mb.pop()
			var sheet := Color("A9C8FF") if id == "bed" else Color("FFC2D6") if id == "single_bed" else Color("FFE27A")
			mb.col(sheet, 1.0, 0.1); mb.at(Vector3(0, 0.42, bl * 0.12)); mb.rbox(Vector3(bw - 0.02, 0.1, bl * 0.72), 0.05, 3); mb.pop()
			var pillows := 2 if id == "bed" else 1
			for i in pillows:
				mb.col(Color("FFFDF6"), 1.0, 0.1); mb.at(Vector3((i - (pillows - 1) * 0.5) * 0.7, 0.48, -bl * 0.5 + 0.28)); mb.rbox(Vector3(0.55 if id == "bed" else 0.5, 0.12, 0.3), 0.06, 3); mb.pop()
			if id == "kid_bed":
				mb.col(Color("FFFFFF"), 0.0)
				for i in 6:
					mb.at(Vector3(-0.3 + (i % 3) * 0.3, 0.475, -0.1 + (i / 3) * 0.4)); mb.ellipsoid(0.04, 0.004, 0.04, 6, 3); mb.pop()
		"crib":
			mb.col(Color("FFFDF6"), 1.0, 0.1)
			for x in [-0.45, 0.45]:
				for z in [-0.28, 0.28]:
					mb.tube(PackedVector3Array([Vector3(x, 0, z), Vector3(x, 0.85, z)]), 0.025, 8)
			for i in 11:
				var x := -0.4 + i * 0.08
				for z in [-0.28, 0.28]:
					mb.tube(PackedVector3Array([Vector3(x, 0.32, z), Vector3(x, 0.8, z)]), 0.012, 6)
			for y in [0.32, 0.8]:
				for z in [-0.28, 0.28]:
					mb.tube(PackedVector3Array([Vector3(-0.45, y, z), Vector3(0.45, y, z)]), 0.02, 8)
			mb.col(Color("FFC2D6"), 1.0, 0.1); mb.at(Vector3(0, 0.36, 0)); mb.rbox(Vector3(0.86, 0.1, 0.52), 0.04, 2); mb.pop()
			mb.col(Color("FFE27A"), 0.6)
			for i in 3:
				mb.at(Vector3(-0.2 + i * 0.2, 1.05, 0)); mb.sphere(0.04, 8, 6); mb.pop()
			mb.col(Color("C8C8D8"), 0.4); mb.tube(PackedVector3Array([Vector3(0.45, 0.85, 0), Vector3(0.3, 1.1, 0), Vector3(-0.3, 1.1, 0)]), 0.008, 6)
		"wardrobe":
			mb.col(Color("FFE3D4"), 1.0, 0.1); mb.at(Vector3(0, 0.9, 0)); mb.rbox(Vector3(1.05, 1.8, 0.55), 0.04, 2); mb.pop()
			mb.col(Color("FFD6C2"), 0.6)
			for s in [-1.0, 1.0]:
				mb.at(Vector3(s * 0.26, 0.95, 0.28)); mb.rbox(Vector3(0.48, 1.55, 0.02), 0.02, 1); mb.pop()
				mb.col(Color("FFD24A"), 0.6); mb.at(Vector3(s * 0.05, 0.95, 0.3)); mb.sphere(0.025, 8, 6); mb.pop(); mb.col(Color("FFD6C2"), 0.6)
		"rug":
			mb.col(Color("C3A6FF"), 0.0, 0.0); mb.at(Vector3(0, 0.004, 0)); mb.puck(1.0, 0.012, 0.004, 48); mb.pop()
			mb.col(Color("E2D6FF"), 0.0, 0.0); mb.at(Vector3(0, 0.009, 0)); mb.puck(0.82, 0.012, 0.004, 48); mb.pop()
			mb.col(Color("FFC2D6"), 0.0, 0.0); mb.at(Vector3(0, 0.014, 0)); mb.puck(0.5, 0.012, 0.004, 40); mb.pop()
		"plant", "big_plant":
			var big := id == "big_plant"
			mb.col(Color("E8826A") if not big else Color.WHITE, 1.0, 0.1)
			mb.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.14 if not big else 0.2, 0.0), Vector2(0.2 if not big else 0.26, 0.36 if not big else 0.5), Vector2(0.0, 0.36 if not big else 0.5)]), 24)
			if big:
				mb.col(Color("FF7EA6"), 0.6); mb.at(Vector3(0, 0.12, 0)); mb.puck(0.225, 0.08, 0.01, 24, 0.235); mb.pop()
			mb.col(Color("6A4A2A"), 0.0); mb.at(Vector3(0, 0.355 if not big else 0.495, 0)); mb.puck(0.17 if not big else 0.24, 0.01, 0.004, 20); mb.pop()
			_plant_leaves(mb, Vector3(0, 0.4 if not big else 0.55, 0), 9 if not big else 14, 0.22 if not big else 0.36, 3 if not big else 7)
		"lamp":
			mb.col(Color("C8864E")); mb.puck(0.18, 0.04, 0.012, 20)
			mb.col(Color("C8864E")); mb.tube(PackedVector3Array([Vector3(0, 0.04, 0), Vector3(0, 1.35, 0)]), 0.02, 8)
			mb.col(Color("FFE3D0"), 1.0, 0.1); mb.at(Vector3(0, 1.3, 0)); mb.lathe(PackedVector2Array([Vector2(0, 0.0), Vector2(0.22, 0.0), Vector2(0.13, 0.26), Vector2(0, 0.26)]), 28); mb.pop()
		"bookshelf":
			mb.col(Color("C8864E"), 1.0, 0.1)
			mb.at(Vector3(0, 0.75, -0.18)); mb.rbox(Vector3(1.2, 1.5, 0.06), 0.02, 1); mb.pop()
			for x in [-0.58, 0.58]:
				mb.at(Vector3(x, 0.75, 0)); mb.rbox(Vector3(0.05, 1.5, 0.42), 0.02, 1); mb.pop()
			for y in [0.03, 0.5, 1.0, 1.48]:
				mb.at(Vector3(0, y, 0)); mb.rbox(Vector3(1.2, 0.05, 0.42), 0.02, 1); mb.pop()
			var cols := [Color("FF7EA6"), Color("A9C8FF"), Color("FFD24A"), Color("B7E3A0"), Color("C3A6FF"), Color("FFB86A")]
			var rng := RandomNumberGenerator.new(); rng.seed = 4
			for row in 3:
				var x := -0.52
				while x < 0.5:
					var bw := rng.randf_range(0.05, 0.1)
					var bh := rng.randf_range(0.28, 0.4)
					mb.col(cols[rng.randi() % cols.size()], 0.6, 0.1); mb.at(Vector3(x + bw * 0.5, 0.055 + row * 0.48 + bh * 0.5, 0.02)); mb.rbox(Vector3(bw - 0.008, bh, 0.3), 0.01, 1); mb.pop()
					x += bw
		"lucky_cat":
			mb.col(Color("C8864E")); mb.at(Vector3(0, 0.3, 0)); mb.rbox(Vector3(0.4, 0.6, 0.4), 0.03, 2); mb.pop()
			mb.col(Color.WHITE, 1.0, 0.2); mb.at(Vector3(0, 0.72, 0)); mb.ellipsoid(0.13, 0.14, 0.12, 18, 12); mb.pop()
			mb.at(Vector3(0, 0.92, 0.01)); mb.ellipsoid(0.12, 0.1, 0.1, 18, 12); mb.pop()
			for s in [-1.0, 1.0]:
				mb.at(Vector3(s * 0.07, 1.02, 0), Vector3(0, 0, -s * 0.3)); mb.cone(0.04, 0.07, 8); mb.pop()
			mb.at(Vector3(0.12, 0.95, 0.06)); mb.sphere(0.04, 10, 8); mb.pop()
			mb.col(Color("E8404A")); mb.at(Vector3(0, 0.82, 0.01)); mb.torus(0.09, 0.012, 20, 6); mb.pop()
			mb.col(Color("FFD24A"), 1.0, 1.0); mb.at(Vector3(-0.05, 0.72, 0.12)); mb.ellipsoid(0.05, 0.06, 0.015, 12, 6); mb.pop()
			mb.col(Color("3B2340"), 0.0)
			for s in [-1.0, 1.0]:
				mb.at(Vector3(s * 0.04, 0.93, 0.1)); mb.ellipsoid(0.012, 0.016, 0.006, 8, 4); mb.pop()
		"flowers":
			mb.col(Color("A9C8FF"), 1.0, 0.4); mb.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.12, 0), Vector2(0.16, 0.3), Vector2(0.1, 0.5), Vector2(0, 0.5)]), 20)
			var cols := [Color("FF7EA6"), Color("FFD24A"), Color("FFFFFF"), Color("C3A6FF")]
			for i in 7:
				var a := i * 0.9
				var p := Vector3(cos(a) * 0.1, 0.75 + (i % 3) * 0.06, sin(a) * 0.1)
				mb.col(Color("4E9E57"), 0.5); mb.tube(PackedVector3Array([Vector3(0, 0.45, 0), p]), 0.008, 5)
				mb.col(cols[i % 4], 0.8, 0.1); mb.at(p); mb.ellipsoid(0.06, 0.04, 0.06, 10, 6); mb.pop()
				mb.col(Color("FFB52E"), 0.0); mb.at(p + Vector3(0, 0.03, 0)); mb.sphere(0.02, 6, 4); mb.pop()
		"record":
			mb.col(Color("E8B87A"), 1.0, 0.1); mb.at(Vector3(0, 0.3, 0)); mb.rbox(Vector3(0.85, 0.6, 0.45), 0.03, 2); mb.pop()
			mb.col(Color("C8864E")); mb.at(Vector3(0, 0.66, 0)); mb.rbox(Vector3(0.5, 0.12, 0.36), 0.02, 2); mb.pop()
			mb.col(Color("3B2340"), 1.0, 0.8); mb.at(Vector3(-0.06, 0.725, 0)); mb.puck(0.14, 0.01, 0.003, 32); mb.pop()
			mb.col(Color("FF7EA6"), 0.0); mb.at(Vector3(-0.06, 0.73, 0)); mb.puck(0.04, 0.008, 0.002, 16); mb.pop()
			mb.col(Color("D8D8E8"), 0.6); mb.tube(PackedVector3Array([Vector3(0.18, 0.74, -0.1), Vector3(0.18, 0.76, 0.08)]), 0.008, 6)
		"cat_bed":
			mb.col(Color("C3A6FF"), 1.0, 0.1); mb.puck(0.36, 0.18, 0.06, 32)
			mb.col(Color("F2ECFF"), 1.0, 0.1); mb.at(Vector3(0, 0.1, 0)); mb.puck(0.27, 0.1, 0.04, 28); mb.pop()
			mb.col(Color("FFB86A"), 1.0, 0.1); mb.at(Vector3(0, 0.24, 0)); mb.ellipsoid(0.2, 0.11, 0.17, 18, 10); mb.pop()
			mb.at(Vector3(0.17, 0.27, 0.07)); mb.sphere(0.1, 14, 10); mb.pop()
			for s in [-1.0, 1.0]:
				mb.at(Vector3(0.17 + s * 0.06, 0.36, 0.07), Vector3(0, 0, -s * 0.3)); mb.cone(0.035, 0.06, 8); mb.pop()
			mb.col(Color("3B2340"), 0.0)
			for s in [-1.0, 1.0]:
				mb.tube(PackedVector3Array([Vector3(0.17 + s * 0.035, 0.28, 0.165), Vector3(0.17 + s * 0.06, 0.285, 0.16)]), 0.004, 4)
		"aquarium":
			mb.col(Color("C8864E")); mb.at(Vector3(0, 0.3, 0)); mb.rbox(Vector3(1.05, 0.6, 0.45), 0.03, 2); mb.pop()
			mb.col(Color("8ED6F0"), 0.0, 0.6); mb.at(Vector3(0, 0.82, 0)); mb.rbox(Vector3(0.98, 0.42, 0.38), 0.02, 1); mb.pop()
			mb.col(Color("FFE8A0"), 0.0); mb.at(Vector3(0, 0.63, 0)); mb.rbox(Vector3(0.96, 0.04, 0.36), 0.01, 1); mb.pop()
			for i in 4:
				mb.col([Color("FF9A3C"), Color("FF7EA6"), Color("FFD24A"), Color("A9C8FF")][i], 0.6, 0.5)
				mb.at(Vector3(-0.3 + i * 0.2, 0.75 + (i % 2) * 0.12, 0.05)); mb.ellipsoid(0.05, 0.03, 0.02, 10, 6); mb.pop()
			_plant_leaves(mb, Vector3(0.38, 0.64, 0), 4, 0.12, 2)
			mb.layer(1); mb.at(Vector3(0, 0.84, 0)); mb.rbox(Vector3(1.0, 0.46, 0.4), 0.02, 1); mb.pop(); mb.layer(0)
		"tv":
			mb.col(Color("E8B87A"), 1.0, 0.1); mb.at(Vector3(0, 0.25, 0)); mb.rbox(Vector3(1.35, 0.5, 0.45), 0.03, 2); mb.pop()
			mb.col(Color("3B3550"), 1.0, 0.4); mb.at(Vector3(0, 0.88, -0.05)); mb.rbox(Vector3(1.0, 0.62, 0.06), 0.03, 2); mb.pop()
			mb.col(Color("8FD1F0"), 0.0, 0.6); mb.at(Vector3(0, 0.88, -0.018)); mb.rbox(Vector3(0.9, 0.52, 0.004), 0.01, 1); mb.pop()
			mb.col(Color("FFE27A"), 0.0); mb.at(Vector3(-0.15, 0.9, -0.014)); mb.sphere(0.07, 10, 6); mb.pop()
		"piano":
			mb.col(Color("3B3550"), 1.0, 0.6); mb.at(Vector3(0, 0.6, -0.08)); mb.rbox(Vector3(1.35, 1.2, 0.4), 0.04, 2); mb.pop()
			mb.col(Color.WHITE, 0.6, 0.3); mb.at(Vector3(0, 0.74, 0.18)); mb.rbox(Vector3(1.2, 0.05, 0.16), 0.01, 1); mb.pop()
			mb.col(Color("2A2438"), 0.0)
			for i in 14:
				if i % 7 in [2, 6]: continue
				mb.at(Vector3(-0.56 + i * 0.085, 0.775, 0.14)); mb.rbox(Vector3(0.04, 0.02, 0.08), 0.004, 1); mb.pop()
		"fireplace":
			mb.col(Color("F2DDB8"), 1.0, 0.1); mb.at(Vector3(0, 0.55, -0.1)); mb.rbox(Vector3(1.4, 1.1, 0.3), 0.04, 2); mb.pop()
			mb.col(Color("FFF4E2"), 1.0, 0.1); mb.at(Vector3(0, 1.14, -0.05)); mb.rbox(Vector3(1.5, 0.08, 0.42), 0.03, 2); mb.pop()
			mb.col(Color("3A2A2A"), 0.6); mb.at(Vector3(0, 0.38, 0.05)); mb.rbox(Vector3(0.8, 0.6, 0.02), 0.06, 2); mb.pop()
			mb.col(Color("FFB86A"), 0.0)
			for i in 5:
				mb.at(Vector3(-0.2 + i * 0.1, 0.15, 0.08), Vector3(0, 0, (i - 2) * 0.15)); mb.cone(0.06, 0.22 + (i % 2) * 0.1, 8); mb.pop()
		"toy_box":
			mb.col(Color("FFC2D6"), 1.0, 0.1); mb.at(Vector3(0, 0.22, 0)); mb.rbox(Vector3(0.75, 0.44, 0.45), 0.05, 2); mb.pop()
			mb.col(Color("FFD24A"), 1.0, 0.4); mb.at(Vector3(-0.15, 0.5, 0)); mb.sphere(0.1, 12, 8); mb.pop()
			mb.col(Color("A9C8FF"), 1.0, 0.2); mb.at(Vector3(0.18, 0.5, 0.02), Vector3(0, 0.4, 0)); mb.rbox(Vector3(0.14, 0.14, 0.14), 0.02, 1); mb.pop()
