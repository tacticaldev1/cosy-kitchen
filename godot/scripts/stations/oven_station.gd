## Oven: turn the dial (about 180°) and bake; peek through the glowing window.
class_name OvenStation
extends HeatStation

var temp := 180
var drag := false
var last_tick := 180
var tick_t := 0.0
var dial: Node3D
var temp_label: Label3D
var glow: OmniLight3D
var smoke: CPUParticles3D

func _init() -> void:
	super("oven", "Oven", 4)
	proc = "bake"; verb = "Bake"; loop_name = "hum"; rate = 0.045
	cooking_text = "Baking… peek through the window"
	item_scale = 1.1

func attach(mo: Node3D) -> void:
	super(mo)
	dial = mo.get_node("Dial")
	temp_label = mo.get_node("Temp")
	glow = mo.get_node("Glow")
	smoke = Fx.steam(0.2, true)
	smoke.position = Vector3(0, 0.74, 0.1)
	mo.add_child(smoke)
	_sync_dial()

func rate_mul() -> float: return temp / 180.0
func can_start() -> bool: return temp >= 120
func prep() -> void:
	temp = 180
	_sync_dial()

func slot(i: int, n: int) -> Vector3:
	if n == 1: return Vector3.ZERO
	return Vector3(-0.1 + (i % 2) * 0.2 if n > 2 else -0.09 + i * 0.18, 0, (-0.03 if i < 2 else 0.04) if n > 2 else 0.0)

func preview_scale() -> float: return 1.25

func hint() -> String:
	var s := state_hint()
	if s != "": return s
	return "Set the dial (about 180°) and press <b>Bake</b>" if items.size() else "Bake cakes, cookies, pizza and toast"

func _dial_center() -> Vector2: return screen_of(dial.global_position)

func pointer_down(p: Vector2) -> void:
	var c := _dial_center()
	if p.distance_to(c) < maxf(46.0, screen_radius(dial.global_position, 0.06)):
		drag = true
		_set_from(p)
	elif run and cook >= 0.25:
		var wc := screen_of(contents.global_position)
		if p.distance_to(wc) < screen_radius(contents.global_position, 0.22):
			take()

func pointer_move(p: Vector2, _prev: Vector2) -> void:
	if drag: _set_from(p)

func pointer_up(_p: Vector2) -> void:
	drag = false

func _set_from(p: Vector2) -> void:
	var a := (p - _dial_center()).angle() + PI * 0.5
	a = wrapf(a, -PI, PI)
	a = clampf(a, -PI * 0.75, PI * 0.75)
	temp = int(round((50.0 + (a + PI * 0.75) / (PI * 1.5) * 200.0) / 5.0) * 5.0)
	if absi(temp - last_tick) >= 10:
		last_tick = temp
		Sfx.play("tick")
	_sync_dial()

func _sync_dial() -> void:
	if dial:
		dial.rotation.z = -(-PI * 0.75 + (temp - 50) / 200.0 * PI * 1.5)
	if temp_label:
		temp_label.text = "%d°" % temp

func on_start() -> void:
	glow.light_energy = 0.0

func on_take() -> void:
	glow.light_energy = 0.0
	temp_label.modulate = Color("FFE27A")

func on_items_changed() -> void:
	mood("sleepy" if items.is_empty() else "idle")

func step(dt: float) -> void:
	super(dt)
	if run:
		glow.light_energy = lerpf(glow.light_energy, 1.6 + 0.3 * sin(game.clock * 3.0), minf(1.0, dt * 3.0))
		temp_label.modulate = Color("8FF0C8")
		tick_t -= dt
		if tick_t <= 0.0:
			tick_t = 0.5
			Sfx.play("tick")
	smoke.emitting = run and cook > BURN
