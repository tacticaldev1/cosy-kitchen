## The bin: tap food on the counter to throw it away.
class_name BinStation
extends Station

var lid: Node3D
var fed := -9.0

func _init() -> void:
	super("bin", "Bin", 0)

func attach(mo: Node3D) -> void:
	super(mo)
	lid = mo.get_node("Lid")

func hint() -> String: return "Tap food on the counter to throw it away"
func accepts() -> bool: return false

func eat() -> void:
	fed = game.clock
	Sfx.play("trash")
	game.puff(global_position + Vector3(0, 0.5, 0.1))
	mood("happy", 1.2)

func step(_dt: float) -> void:
	if lid:
		var k := game.clock - fed
		lid.rotation.x = -sin(clampf(k / 0.5, 0.0, 1.0) * PI) * 1.1 if k < 0.5 else 0.0
	if model:
		var k2 := game.clock - fed
		model.rotation.z = sin(k2 * 20.0) * 0.05 * maxf(0.0, 1.0 - k2 * 2.0) if k2 < 0.5 else 0.0
