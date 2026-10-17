## Mixing bowl: stir in circles (or press Stir). Ingredients swirl and melt into batter.
class_name BowlStation
extends Station

var m := 0.0
var last_a = null
var swirl := 0.0
var auto_stir := false
var snd_t := 0.0
var whisk: Node3D
var batter: MeshInstance3D
var batter_mat: ShaderMaterial
var _down := false
var _ptr := Vector2.ZERO

func _init() -> void:
	super("bowl", "Bowl", 6)
	item_scale = 0.62

func attach(mo: Node3D) -> void:
	super(mo)
	whisk = mo.get_node("Whisk")
	batter = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.135; cm.bottom_radius = 0.1; cm.height = 0.02; cm.radial_segments = 40
	batter.mesh = cm
	batter_mat = Appl.tint_mat(Color("F6D58A"))
	batter.material_override = batter_mat
	batter.visible = false
	contents.add_child(batter)

func slot(i: int, n: int) -> Vector3:
	var d := (0.25 + 0.5 * fmod(i * 0.37, 1.0)) * 0.11 * (1.0 - m * 0.6)
	var a := i * 2.4 + swirl * 0.6
	return Vector3(cos(a) * d, 0.035 + sin(game.clock * 2.0 + i) * 0.003 if game else 0.035, sin(a) * d)

func hint() -> String:
	return "Stir in circles, or press <b>Stir</b>" if items.size() else "Mix things here: batters, salads, drinks…"

func meter() -> Dictionary:
	return {"v": m} if items.size() else {}

func btn() -> Dictionary:
	return {"label": "Stirring…" if auto_stir else "Stir", "enabled": not auto_stir} if items.size() else {}

func on_btn() -> void:
	if items.size(): auto_stir = true

func busy() -> bool: return auto_stir

func _center() -> Vector2:
	return screen_of(global_position + Vector3(0, 0.06, 0))

func pointer_down(p: Vector2) -> void:
	_down = true
	_ptr = p
	last_a = (p - _center()).angle()

func pointer_move(p: Vector2, _prev: Vector2) -> void:
	_ptr = p
	if items.is_empty(): return
	var c := _center()
	var a := (p - c).angle()
	if last_a != null and p.distance_to(c) > 18.0:
		var d: float = wrapf(a - last_a, -PI, PI)
		_stir(d)
	last_a = a

func pointer_up(_p: Vector2) -> void:
	_down = false
	last_a = null

func _stir(d: float) -> void:
	m += absf(d) / (2.0 * TAU)
	swirl += d
	snd_t -= absf(d)
	if snd_t <= 0.0:
		snd_t = 0.5
		Sfx.play("swish", clampf(absf(d) * 4.0, 0.3, 1.0))
	mood("happy")
	if m >= 1.0:
		finish()

func finish() -> void:
	auto_stir = false
	var f := G.merge_foods(items, "mix", 0.0, game.clock)
	items = []
	m = 0.0
	refresh()
	batter.visible = false
	mood("happy", 1.2)
	mood("idle")
	produce(f)

func auto() -> void:
	if items.is_empty(): return
	m += 0.35
	swirl += 2.0
	Sfx.play("swish", 0.7)
	if m >= 1.0: finish()

func on_items_changed() -> void:
	if items.is_empty():
		m = 0.0
		mood("sleepy")
	else:
		mood("idle")

func step(dt: float) -> void:
	if auto_stir:
		if items.is_empty():
			auto_stir = false
		else:
			_stir(dt * 0.8 * 2.0 * TAU * (1.0 if fmod(game.clock, 1.0) < 2.0 else 1.0))
	# items orbit with the swirl and melt into batter
	var n := items.size()
	for i in n:
		var node := item_node(items[i])
		if node:
			node.position = node.position.lerp(slot(i, n), minf(1.0, dt * 10.0))
			node.rotation.y = swirl * 0.8 + i
			var s := item_scale * item_size_for(n) * clampf(1.0 - m * 0.85, 0.1, 1.0)
			node.scale = node.scale.lerp(Vector3.ONE * s, minf(1.0, dt * 6.0))
	if n:
		batter.visible = m > 0.04
		batter_mat.set_shader_parameter("albedo", G.mix_of(G.comps_of(items)))
		batter.scale = Vector3(clampf(m * 1.4, 0.2, 1.0), 1.0, clampf(m * 1.4, 0.2, 1.0))
		batter.position = Vector3(0, 0.02 + m * 0.03, 0)
		batter.rotation.y = swirl
	else:
		batter.visible = false
	# whisk follows the pointer while stirring, otherwise circles gently
	if whisk:
		var target := Vector3(cos(game.clock * 2.4) * 0.07, 0.05, sin(game.clock * 2.4) * 0.07)
		if _down and items.size():
			var hit = on_plane(_ptr, global_position.y + 0.08)
			if hit != null:
				var local: Vector3 = model.global_transform.affine_inverse() * hit
				target = Vector3(clampf(local.x, -0.11, 0.11), 0.05, clampf(local.z, -0.11, 0.11))
		elif auto_stir:
			target = Vector3(cos(swirl) * 0.08, 0.05, sin(swirl) * 0.08)
		whisk.visible = items.size() > 0
		whisk.position = whisk.position.lerp(target, minf(1.0, dt * 14.0))
		whisk.rotation = Vector3(-whisk.position.z * 2.0, swirl, whisk.position.x * 2.0)
