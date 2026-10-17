## A little live 3D stage that spins a dish (used on the result card and recipe detail).
class_name Turntable
extends SubViewportContainer

var spec := {}
var pivot: Node3D
var speed := 0.6
var _vp: SubViewport

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	add_child(_vp)
	var root := Node3D.new()
	_vp.add_child(root)
	var we := WorldEnvironment.new()
	we.environment = Studio.environment(Color(0, 0, 0, 0), true)
	root.add_child(we)
	Studio.add_lights(root, 0.85)
	pivot = Node3D.new()
	root.add_child(pivot)
	var food := FoodArt.spec_node(spec)
	pivot.add_child(food)
	var box := FoodArt.aabb_of(food)
	var c := box.get_center()
	food.position = -Vector3(c.x, 0, c.z)
	var r := maxf(box.size.length() * 0.5, 0.02)
	var cam := Camera3D.new()
	cam.fov = 26
	root.add_child(cam)
	var dist := r / sin(deg_to_rad(13.0)) * 0.92
	cam.position = Vector3(0, c.y, 0) + Vector3(0, sin(deg_to_rad(30.0)), cos(deg_to_rad(30.0))) * dist
	cam.look_at(Vector3(0, c.y * 0.9, 0))
	pivot.scale = Vector3.ONE * 0.6
	var tw := pivot.create_tween()
	tw.tween_property(pivot, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(dt: float) -> void:
	if pivot: pivot.rotation.y += dt * speed
