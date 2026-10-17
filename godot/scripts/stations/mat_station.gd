## Bamboo mat: push up to roll sushi (or press Roll). The mat curls into a log.
class_name MatStation
extends Station

var p := 0.0
var click_at := 0.0
var auto_roll := false
var log_node: MeshInstance3D
var sheet: MeshInstance3D
var rice: MeshInstance3D

func _init() -> void:
	super("mat", "Mat", 5)
	item_scale = 0.55

func attach(mo: Node3D) -> void:
	super(mo)
	sheet = MeshInstance3D.new()
	var sm := BoxMesh.new(); sm.size = Vector3(0.3, 0.003, 0.28)
	sheet.mesh = sm
	sheet.material_override = Toon.solid(Color("1F2C25"), 0.8)
	sheet.position = Vector3(0, 0.012, -0.005)
	sheet.visible = false
	contents.add_child(sheet)
	rice = MeshInstance3D.new()
	var rm := BoxMesh.new(); rm.size = Vector3(0.28, 0.012, 0.21)
	rice.mesh = rm
	rice.material_override = Toon.solid(Color("FDFAF3"), 0.6)
	rice.position = Vector3(0, 0.018, 0.025)
	rice.visible = false
	contents.add_child(rice)
	log_node = MeshInstance3D.new()
	var lm := CylinderMesh.new(); lm.top_radius = 1.0; lm.bottom_radius = 1.0; lm.height = 0.35; lm.radial_segments = 32
	log_node.mesh = lm
	log_node.rotation = Vector3(0, 0, PI * 0.5)
	log_node.material_override = Toon.solid(Color("D3AB63"), 1.0)
	log_node.visible = false
	contents.add_child(log_node)

func _nori() -> Dictionary:
	for f in items:
		if f.comps.size() == 1 and f.comps[0].ing == "nori" and f.hist.is_empty(): return f
	return {}

func _is_rice(f: Dictionary) -> bool:
	return f.comps.any(func(c): return c.ing == "rice")

func slot(i: int, n: int) -> Vector3:
	var others: Array = items.filter(func(f): return not f.is_empty() and f != _nori() and not _is_rice(f))
	var idx := others.find(items[i]) if i < items.size() else i
	if idx < 0: return Vector3(0, -1, 0)
	return Vector3(-0.08 + (idx % 3) * 0.08, 0.03, 0.05 - (idx / 3) * 0.05)

func refresh(delay := 0.0) -> void:
	super(delay)
	var nori := _nori()
	sheet.visible = not nori.is_empty()
	rice.visible = items.any(_is_rice)
	for f in items:
		var node := item_node(f)
		if node: node.visible = f != nori and not _is_rice(f)

func hint() -> String:
	return "Push up on the mat to roll it, or press <b>Roll</b>" if items.size() else "Roll sushi here: nori, cooked rice and fillings"

func meter() -> Dictionary: return {"v": p} if items.size() else {}
func btn() -> Dictionary: return {"label": "Rolling…" if auto_roll else "Roll", "enabled": not auto_roll} if items.size() else {}
func on_btn() -> void:
	if items.size(): auto_roll = true
func busy() -> bool: return auto_roll

func pointer_move(pp: Vector2, prev: Vector2) -> void:
	if items.size() and prev.y > pp.y:
		push(prev.y - pp.y)

func push(d: float) -> void:
	p = minf(1.0, p + d / 520.0)
	while p >= click_at + 0.045:
		click_at += 0.045
		Sfx.play("click")
	if p >= 1.0:
		Sfx.play("fwip")
		var f := G.merge_foods(items, "roll", 0.0, game.clock)
		items = []
		p = 0.0
		click_at = 0.0
		auto_roll = false
		refresh()
		log_node.visible = false
		produce(f)

func auto() -> void:
	if items.size(): push(600.0)

func step(dt: float) -> void:
	if auto_roll:
		if items.is_empty(): auto_roll = false
		else: push(dt * 330.0)
	var rolling := p > 0.0 and items.size() > 0
	log_node.visible = rolling
	if rolling:
		var r := 0.012 + p * 0.022
		var z := 0.15 - p * 0.29
		log_node.scale = Vector3(r, 1.0, r)
		log_node.position = Vector3(0, 0.01 + r, z)
		log_node.rotation = Vector3(-p * 22.0, 0, PI * 0.5)
		for f in items:
			var node := item_node(f)
			if node and f != _nori() and not _is_rice(f):
				node.visible = node.position.z < z - 0.02
		sheet.scale = Vector3(1, 1, clampf(1.0 - p, 0.02, 1.0))
		sheet.position.z = -0.005 - (0.28 * p) * 0.5
		rice.scale = sheet.scale
		rice.position.z = 0.025 - (0.21 * p) * 0.5
	else:
		sheet.scale = Vector3.ONE
		sheet.position.z = -0.005
		rice.scale = Vector3.ONE
		rice.position.z = 0.025
