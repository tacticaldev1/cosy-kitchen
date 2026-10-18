## You! A chibi cook you steer with WASD/arrow keys or by clicking the floor.
class_name Player
extends Chibi

var nav: NavGrid
var input_dir := Vector3.ZERO
var on_arrive: Callable = Callable()
var frozen := false

func setup_from_save() -> void:
	var lk: Dictionary = Save.player_look.duplicate()
	if lk.is_empty(): lk = Chibi.random_look()
	build(lk, "adult")
	speed = 2.0
	name = "Player"

func go_to(target: Vector3, then: Callable = Callable()) -> void:
	on_arrive = then
	if nav:
		walk_path(nav.path(global_position, target))
	else:
		walk_path(PackedVector3Array([target]))
	if not walking:
		_arrive()

func _arrive() -> void:
	var cb := on_arrive
	on_arrive = Callable()
	if cb.is_valid(): cb.call()

func tick(dt: float, clock: float) -> void:
	if frozen:
		_animate(dt, clock)
		return
	# keyboard movement overrides any click-to-walk path
	if input_dir.length() > 0.1:
		path = PackedVector3Array()
		on_arrive = Callable()
		walking = true
		var dir := input_dir.normalized()
		var step := dir * speed * dt
		var nxt := global_position + step
		if nav == null or nav.is_free(nxt):
			global_position = nxt
		elif nav.is_free(global_position + Vector3(step.x, 0, 0)):
			global_position += Vector3(step.x, 0, 0)
		elif nav.is_free(global_position + Vector3(0, 0, step.z)):
			global_position += Vector3(0, 0, step.z)
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), minf(1.0, dt * 14.0))
		_animate(dt, clock)
		return
	var was := walking and path.size() > 0
	if walking and path.is_empty():
		walking = false
	super(dt, clock)
	if was and not walking:
		_arrive()
