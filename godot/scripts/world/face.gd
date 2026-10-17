## A kawaii face (eyes, blush, mouth) for appliances and customers. Faces +z.
## Moods: idle, happy, focus, sleepy, wow, yuck. Blinks on its own when idle.
class_name Face
extends Node3D

const MOODS := ["idle", "happy", "focus", "sleepy", "wow", "yuck"]
const PLUM := Color("3B2340")
static var _meshes := {}

var mood := "idle"
var _nodes := {}
var _blink_t := 0.0
var _hold_t := 0.0
var _base_mood := "idle"

func _init(s := 1.0) -> void:
	scale = Vector3(s, s, s)
	for m in MOODS:
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh(m)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = m == "idle"
		add_child(mi)
		_nodes[m] = mi
	var bl := MeshInstance3D.new()
	bl.mesh = _mesh("blink")
	bl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bl.visible = false
	add_child(bl)
	_nodes["blink"] = bl
	_blink_t = randf_range(1.0, 4.0)

func set_mood(m: String, hold := 0.0) -> void:
	if hold > 0.0:
		_hold_t = hold
		_show(m)
		return
	_base_mood = m
	if _hold_t <= 0.0:
		_show(m)

func _show(m: String) -> void:
	if not _nodes.has(m): m = "idle"
	mood = m
	for k in _nodes:
		_nodes[k].visible = k == m

func _process(dt: float) -> void:
	if _hold_t > 0.0:
		_hold_t -= dt
		if _hold_t <= 0.0:
			_show(_base_mood)
		return
	if mood == "idle" or mood == "blink":
		_blink_t -= dt
		if _blink_t <= 0.0 and mood == "idle":
			_show("blink")
			_blink_t = 0.12
		elif _blink_t <= 0.0:
			_show("idle")
			_blink_t = randf_range(2.0, 5.0)

static func _mesh(m: String) -> ArrayMesh:
	if _meshes.has(m):
		return _meshes[m]
	var mb := MB.new()
	build(mb, m)
	var am := FoodArt.finish(mb)
	_meshes[m] = am
	return am

## Draws a face into an MB around the origin, facing +z. ~3.4 cm wide.
static func build(mb: MB, m: String) -> void:
	for k in [-1.0, 1.0]:
		var ex: float = k * 0.0085
		match m:
			"happy":
				_arc(mb, Vector3(ex, 0.0015, 0), 0.0032, PI * 0.15, PI * 0.85, 0.0009)
			"sleepy", "blink":
				mb.col(PLUM, 0.0); mb.tube(PackedVector3Array([Vector3(ex - 0.0034, 0, 0), Vector3(ex + 0.0034, 0, 0)]), 0.0008, 5)
			"focus":
				mb.col(PLUM, 0.0)
				mb.tube(PackedVector3Array([Vector3(ex - 0.003 * k, 0.003, 0), Vector3(ex + 0.0025 * k, 0.0, 0), Vector3(ex - 0.003 * k, -0.003, 0)]), 0.0008, 5)
			"wow":
				mb.col(PLUM, 0.0); mb.at(Vector3(ex, 0, 0)); mb.ellipsoid(0.0034, 0.0042, 0.0012, 12, 6); mb.pop()
				mb.col(Color.WHITE, 0.0)
				for a in 4:
					mb.at(Vector3(ex, 0.0004, 0.0012), Vector3(0, 0, a * PI * 0.25 + PI * 0.125)); mb.ellipsoid(0.0005, 0.0026, 0.0003, 6, 3); mb.pop()
			_:
				mb.col(PLUM, 0.0); mb.at(Vector3(ex, 0, 0)); mb.ellipsoid(0.0026, 0.0034, 0.0012, 12, 6); mb.pop()
				mb.col(Color("E68CCD"), 0.0); mb.at(Vector3(ex, -0.0012, 0.0006)); mb.ellipsoid(0.0019, 0.0016, 0.0008, 8, 4); mb.pop()
				mb.col(Color.WHITE, 0.0); mb.at(Vector3(ex - 0.001, 0.0013, 0.0011)); mb.sphere(0.0009, 6, 4); mb.pop()
				mb.at(Vector3(ex + 0.0009, -0.0016, 0.0011)); mb.sphere(0.00045, 4, 3); mb.pop()
		mb.col(Color("FF8FB0"), 0.0); mb.at(Vector3(k * 0.0148, -0.0045, -0.0002)); mb.ellipsoid(0.0042, 0.0025, 0.0008, 10, 4); mb.pop()
		mb.col(Color.WHITE, 0.0)
		for j in 2:
			mb.tube(PackedVector3Array([Vector3(k * 0.0148 - 0.0012 + j * 0.0022, -0.003, 0.0007), Vector3(k * 0.0148 - 0.0022 + j * 0.0022, -0.0058, 0.0007)]), 0.00035, 4)
	match m:
		"happy", "focus":
			mb.col(Color("C2415E"), 0.0); mb.at(Vector3(0, -0.0042, 0)); mb.ellipsoid(0.0034, 0.0022, 0.0009, 12, 6); mb.pop()
			mb.col(PLUM, 0.0); mb.tube(PackedVector3Array([Vector3(-0.0036, -0.0035, 0.0006), Vector3(0.0036, -0.0035, 0.0006)]), 0.0006, 4)
		"wow":
			mb.col(Color("C2415E"), 0.0); mb.at(Vector3(0, -0.006, 0)); mb.ellipsoid(0.0022, 0.0028, 0.0009, 10, 6); mb.pop()
		"yuck":
			mb.col(PLUM, 0.0)
			var pts := PackedVector3Array()
			for i in 5:
				pts.append(Vector3(-0.004 + i * 0.002, -0.0055 + (0.0012 if i % 2 else 0.0), 0.0004))
			mb.tube(pts, 0.0007, 4)
		_:
			_arc(mb, Vector3(0, -0.0032, 0), 0.0026, PI * 1.15, PI * 1.85, 0.0007)

static func _arc(mb: MB, c: Vector3, r: float, a0: float, a1: float, w: float) -> void:
	var pts := PackedVector3Array()
	for i in 8:
		var a := lerpf(a0, a1, i / 7.0)
		pts.append(c + Vector3(cos(a) * r, sin(a) * r, 0.0004))
	mb.col(PLUM, 0.0)
	mb.tube(pts, w, 5)
