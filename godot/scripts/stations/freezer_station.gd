## Freezer: chill ice creams and popsicles. Frost creeps over the window.
class_name FreezerStation
extends Station

var run := false
var p := 0.0
var snd = null
var win: Node3D
var snow: CPUParticles3D
var frost_t := 0.0

func _init() -> void:
	super("freezer", "Freezer", 4)
	item_scale = 1.15

func attach(mo: Node3D) -> void:
	super(mo)
	win = mo.get_node("Window")
	snow = Fx.snow()
	snow.position = Vector3(0, 0.6, 0.0)
	mo.add_child(snow)

func slot(i: int, n: int) -> Vector3:
	if n == 1: return Vector3(0, 0, 0)
	return Vector3(-0.09 + (i % 2) * 0.18, 0.0 if i < 2 else 0.3, 0.0)

func hint() -> String:
	if run: return "Chilling… brrr"
	return "Press <b>Freeze</b> to chill it" if items.size() else "Freeze ice creams and popsicles"

func meter() -> Dictionary: return {"v": p} if run else {}
func busy() -> bool: return run
func btn() -> Dictionary: return {"label": "Freeze", "enabled": true} if items.size() and not run else {}

func on_btn() -> void:
	if items.is_empty() or run: return
	run = true
	p = 0.0
	snd = Sfx.loop("cold")
	Sfx.play("clunk")
	mood("focus")

func auto() -> void:
	if items.is_empty(): return
	if not run: on_btn()
	else:
		p = 1.0
		step(0.0)

func on_items_changed() -> void:
	mood("sleepy" if items.is_empty() else "happy")

func step(dt: float) -> void:
	snow.emitting = run
	Toon.set_param(contents, &"frost", p if run else 0.0)
	if win: Toon.set_param(win, &"frost", p * 0.8 if run else 0.0)
	if not run: return
	p += dt * 0.22
	frost_t -= dt
	if frost_t <= 0.0:
		frost_t = randf_range(0.08, 0.25)
		Sfx.play("frost")
	if p >= 1.0:
		run = false
		if snd: snd.stop()
		snd = null
		Sfx.play("ding")
		var f := G.merge_foods(items, "freeze", 0.0, game.clock)
		items = []
		p = 0.0
		refresh()
		mood("happy", 1.5)
		mood("sleepy")
		produce(f, global_position + Vector3(0, 0.7, 0.3))
