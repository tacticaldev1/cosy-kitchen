extends Node3D
func _ready() -> void:
	var cafe := Cafe.new()
	add_child(cafe)
	var cam := Camera3D.new()
	cam.fov = 38
	add_child(cam)
	var p := Shot.arg("cam", "0,2.9,4.4,0,0.8,-0.7").split(",")
	cam.look_at_from_position(Vector3(float(p[0]), float(p[1]), float(p[2])), Vector3(float(p[3]), float(p[4]), float(p[5])))
	cafe.set_time_of_day(float(Shot.arg("tod", "0.3")))
	for k in Shot.arg("decor", "").split(",", false):
		cafe.set_decor(k, true)
	Shot.maybe_capture(get_tree(), 20)
