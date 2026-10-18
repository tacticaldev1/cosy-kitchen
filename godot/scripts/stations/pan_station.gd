## Frying pan: sizzle, swipe up to flip, take it out in the golden zone.
class_name PanStation
extends HeatStation

var flames: Node3D
var oil: Node3D
var steam: CPUParticles3D
var down_p := Vector2.ZERO
var flipped := false
var flip_t := 9.0
var crack_t := 0.0

func _init() -> void:
	super("pan", "Pan", 4)
	proc = "fry"; verb = "Fry"; loop_name = "sizzle"; rate = 0.065
	cooking_text = "Sizzling… swipe up to flip"
	item_scale = 0.8

func attach(mo: Node3D) -> void:
	super(mo)
	oil = mo.get_node("Oil")
	flames = Appl.flames(0.135)
	flames.position = Vector3(0, -0.028, 0)
	flames.visible = false
	add_child(flames)
	steam = Fx.steam(0.14)
	steam.position = Vector3(0, 0.06, 0)
	mo.add_child(steam)

func slot(i: int, n: int) -> Vector3:
	if n == 1: return Vector3.ZERO
	var p := [Vector3(-0.055, 0, 0), Vector3(0.055, 0, 0), Vector3(0, 0, -0.05), Vector3(0, 0, 0.05)]
	return p[i % 4]

func hint() -> String:
	var s := state_hint()
	if s != "": return s
	return "Press <b>Fry</b> to heat the pan" if items.size() else "Fry eggs, pancakes, chips and more"

func pointer_down(p: Vector2) -> void:
	flipped = false
	down_p = p

func pointer_move(p: Vector2, _prev: Vector2) -> void:
	if run and not flipped and down_p.y - p.y > 70.0:
		flipped = true
		flip_t = 0.0
		Sfx.play("flip")
		cook += 0.02

func on_start() -> void:
	flames.visible = true
	oil.visible = true

func on_take() -> void:
	flames.visible = false
	oil.visible = false

func on_items_changed() -> void:
	mood("idle")

func preview_scale() -> float: return 0.78

func step(dt: float) -> void:
	super(dt)
	steam.emitting = run
	flip_t += dt
	var up := 0.0
	var rx := 0.0
	if flip_t < 0.6:
		var k := flip_t / 0.6
		up = sin(k * PI) * 0.16
		rx = k * TAU
	contents.position = Vector3(0, 0.008 + up, 0)
	contents.rotation = Vector3(rx, 0, 0)
	if run:
		crack_t -= dt
		if crack_t <= 0.0:
			crack_t = 0.04 + randf() * 0.18
			Sfx.play("crackle")
		flames.rotation.y += dt * 2.0
		flames.scale = Vector3.ONE * (1.0 + 0.08 * sin(game.clock * 18.0))
		Toon.set_param(oil, &"flash", 0.08 + 0.06 * sin(game.clock * 6.0))
