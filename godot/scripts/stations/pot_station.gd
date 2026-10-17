## Pot: boil rice, noodles, soups and drinks. Bubbles, steam and an optional stir.
class_name PotStation
extends HeatStation

var flames: Node3D
var water: MeshInstance3D
var water_mat: ShaderMaterial
var bubbles: CPUParticles3D
var steam: CPUParticles3D
var last_a = null
var swirl := 0.0
var bloop_t := 0.0

func _init() -> void:
	super("pot", "Pot", 6)
	proc = "boil"; verb = "Boil"; loop_name = "boil"; rate = 0.12
	cooking_text = "Bubbling away… stir if you like"
	item_scale = 0.5

func attach(mo: Node3D) -> void:
	super(mo)
	water = mo.get_node("Water")
	water_mat = water.material_override
	flames = Appl.flames(0.128)
	flames.position = Vector3(0, -0.028, 0)
	flames.visible = false
	add_child(flames)
	bubbles = Fx.bubbles()
	bubbles.position = water.position
	mo.add_child(bubbles)
	steam = Fx.steam(0.12)
	steam.position = water.position + Vector3(0, 0.05, 0)
	mo.add_child(steam)

func slot(i: int, n: int) -> Vector3:
	var a := i * 2.1 + swirl * 0.5 + (game.clock * 0.6 if run and game else 0.0)
	var r := 0.0 if n == 1 else 0.06
	return Vector3(cos(a) * r, 0.01 + (sin(game.clock * 3.0 + i) * 0.004 if game else 0.0), sin(a) * r)

func hint() -> String:
	var s := state_hint()
	if s != "": return s
	return "Press <b>Boil</b> to heat the water" if items.size() else "Boil rice, noodles, soups and drinks here"

func pointer_down(p: Vector2) -> void:
	last_a = (p - screen_of(global_position + Vector3(0, 0.1, 0))).angle()

func pointer_move(p: Vector2, _prev: Vector2) -> void:
	if not run: return
	var a := (p - screen_of(global_position + Vector3(0, 0.1, 0))).angle()
	if last_a != null:
		var d: float = wrapf(a - last_a, -PI, PI)
		swirl += d
		if absf(d) > 0.05: Sfx.play("swish", clampf(absf(d) * 3.0, 0.2, 0.8))
	last_a = a

func pointer_up(_p: Vector2) -> void:
	last_a = null

func on_start() -> void:
	flames.visible = true
	bubbles.emitting = true

func on_take() -> void:
	flames.visible = false
	bubbles.emitting = false
	steam.emitting = false

func on_items_changed() -> void:
	mood("sleepy" if items.is_empty() else "idle")

func preview_scale() -> float: return 1.25
func preview_pos() -> Vector3: return Vector3(0, -0.006, 0)

func step(dt: float) -> void:
	super(dt)
	var comps := G.comps_of(items)
	var wc := Color("BFE3F2")
	if comps.size(): wc = wc.lerp(G.mix_of(comps), clampf(cook, 0.0, 1.0) * 0.75)
	water_mat.set_shader_parameter("albedo", wc)
	steam.emitting = run
	if run:
		bloop_t -= dt
		if bloop_t <= 0.0:
			bloop_t = randf_range(0.12, 0.35)
			Sfx.play("bloop")
		flames.rotation.y += dt * 2.0
		flames.scale = Vector3.ONE * (1.0 + 0.08 * sin(game.clock * 18.0))
	var n := items.size()
	for i in n:
		var node := item_node(items[i])
		if node and node.visible:
			node.position = node.position.lerp(slot(i, n), minf(1.0, dt * 8.0))
