## Blender: hold anywhere (or press Blend). Contents whirl into one smooth colour.
class_name BlenderStation
extends Station

var p := 0.0
var hold := false
var auto_run := false
var snd = null
var jug: Node3D
var blade: Node3D
var liquid: MeshInstance3D
var liquid_mat: ShaderMaterial

func _init() -> void:
	super("blender", "Blender", 5)
	item_scale = 0.55

func attach(mo: Node3D) -> void:
	super(mo)
	jug = mo.get_node("Jug")
	blade = jug.get_node("Blade")
	liquid = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.bottom_radius = 0.055; cm.top_radius = 0.076; cm.height = 1.0; cm.radial_segments = 32
	liquid.mesh = cm
	liquid_mat = Appl.tint_mat(Color.WHITE)
	liquid.material_override = liquid_mat
	liquid.visible = false
	contents.add_child(liquid)

func slot(i: int, n: int) -> Vector3:
	return Vector3(((i % 2) - 0.5) * 0.04 * (1 if n > 1 else 0), 0.035 + i * 0.038, ((i % 3) - 1) * 0.012)

func hint() -> String:
	if items.is_empty(): return "Blend fruit, milk or anything into a drink"
	return "Whirrrr…" if hold else "Press <b>Blend</b>, or hold anywhere to blend"

func meter() -> Dictionary: return {"v": clampf(p, 0.0, 1.0)} if items.size() else {}
func busy() -> bool: return hold
func btn() -> Dictionary:
	return {"label": "Blending…" if hold else "Blend", "enabled": not hold} if items.size() else {}

func on_btn() -> void:
	if items.is_empty() or hold: return
	auto_run = true
	_start()

func pointer_down(_p: Vector2) -> void:
	if items.size() and not hold:
		_start()

func pointer_up(_p: Vector2) -> void:
	if not hold or auto_run: return
	hold = false
	if snd: snd.stop()
	snd = null
	Sfx.play("spinDown")
	mood("idle")

func _start() -> void:
	hold = true
	snd = Sfx.loop("blender")
	mood("focus")

func finish() -> void:
	if hold:
		hold = false
		if snd: snd.stop()
		snd = null
		Sfx.play("spinDown")
	auto_run = false
	var f := G.merge_foods(items, "blend", 0.0, game.clock)
	items = []
	p = 0.0
	refresh()
	liquid.visible = false
	mood("happy", 1.2)
	mood("idle")
	produce(f, jug.global_position + Vector3(0, 0.2, 0))

func auto() -> void:
	if items.size(): finish()

func on_items_changed() -> void:
	mood("sleepy" if items.is_empty() else "idle")

func step(dt: float) -> void:
	if hold:
		p += dt * 0.2
		if snd: snd.set_param(clampf(p, 0.0, 1.0))
		if p >= 1.0:
			finish()
			return
	var spin := hold
	if model:
		model.position = Vector3(sin(game.clock * 70.0) * 0.0025, 0, cos(game.clock * 63.0) * 0.0015) if spin else Vector3.ZERO
	if blade:
		blade.rotation.y += dt * (40.0 if spin else 0.0)
	var n := items.size()
	if n:
		var comps := G.comps_of(items)
		var mix := G.lighten(G.mix_of(comps), 0.08)
		var first: Color = G.comp_color(comps[0])
		liquid.visible = p > 0.02
		var h := 0.04 + 0.12 * clampf(p * 1.4, 0.0, 1.0)
		liquid.scale = Vector3(1.0, h, 1.0)
		liquid.position = Vector3(0, 0.008 + h * 0.5, 0)
		liquid_mat.set_shader_parameter("albedo", first.lerp(mix, clampf(p * 1.6, 0.0, 1.0)))
		for i in n:
			var node := item_node(items[i])
			if node:
				var a := game.clock * (14.0 if spin else 0.0) + i * 2.1
				var base := slot(i, n)
				node.position = base + (Vector3(cos(a) * 0.03, 0, sin(a) * 0.03) if spin else Vector3.ZERO)
				node.rotation.y = a
				node.scale = Vector3.ONE * item_scale * clampf(1.0 - p * 2.2, 0.02, 1.0)
	else:
		liquid.visible = false
