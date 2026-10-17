## Photo: renders 3D food into icon textures for the UI (fridge, counter, recipe book,
## order tickets). request() returns an ImageTexture right away; it fills in a frame or two
## later. Results are cached by key.
extends Node

const POOL := 4
const ELEVATION := 42.0
const FOV := 24.0

var _ports: Array = []
var _queue: Array = []
var _cache := {}
var _rendering := false
var enabled := true

signal idle

func _ready() -> void:
	enabled = DisplayServer.get_name() != "headless"
	if not enabled:
		return
	for i in POOL:
		_ports.append(_make_port())

func _make_port() -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(256, 256)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.msaa_3d = Viewport.MSAA_4X
	add_child(vp)
	var root := Node3D.new()
	root.name = "Root"
	vp.add_child(root)
	var we := WorldEnvironment.new()
	we.environment = Studio.environment(Color(0, 0, 0, 0), true)
	root.add_child(we)
	Studio.add_lights(root, 0.8)
	var cam := Camera3D.new()
	cam.name = "Cam"
	cam.fov = FOV
	cam.near = 0.01
	cam.far = 20.0
	root.add_child(cam)
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	root.add_child(pivot)
	return vp

func busy() -> bool:
	return _rendering or not _queue.is_empty()

func cached(key: String) -> Texture2D:
	return _cache.get(key, null)

## builder() -> Node3D. opts: {elev: degrees, yaw: radians, zoom: float}
func request(key: String, builder: Callable, size := 256, opts := {}) -> ImageTexture:
	if key != "" and _cache.has(key):
		return _cache[key]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var tex := ImageTexture.create_from_image(img)
	if key != "":
		_cache[key] = tex
	if enabled:
		_queue.append({"builder": builder, "tex": tex, "size": size, "opts": opts})
	return tex

func ingredient(key: String, size := 256) -> ImageTexture:
	return request("ing:%s:%d" % [key, size], func() -> Node3D: return FoodArt.ingredient_node(key), size)

func spec(sp: Dictionary, size := 256) -> ImageTexture:
	var s := sp.duplicate()
	s.erase("steam")
	return request("spec:%s:%d" % [G.spec_key(s), size], func() -> Node3D: return FoodArt.spec_node(s), size)

func recipe(rid: int, size := 256) -> ImageTexture:
	return request("recipe:%d:%d" % [rid, size], func() -> Node3D: return FoodArt.spec_node(G.recipe_spec(G.RECIPES[rid])), size)

func food(f: Dictionary, size := 160) -> ImageTexture:
	return spec(G.food_spec(f), size)

func _process(_dt: float) -> void:
	if _rendering or _queue.is_empty() or _ports.is_empty():
		return
	_render_batch()

func _render_batch() -> void:
	_rendering = true
	var batch: Array = []
	for vp in _ports:
		if _queue.is_empty():
			break
		var job: Dictionary = _queue.pop_front()
		var node: Node3D = job.builder.call()
		var v := vp as SubViewport
		v.size = Vector2i(job.size, job.size)
		var pivot: Node3D = v.get_node("Root/Pivot")
		pivot.add_child(node)
		_frame(v.get_node("Root/Cam"), node, job.opts)
		v.render_target_update_mode = SubViewport.UPDATE_ONCE
		batch.append([v, job, node])
	await RenderingServer.frame_post_draw
	for b in batch:
		var v: SubViewport = b[0]
		var img := v.get_texture().get_image()
		(b[1].tex as ImageTexture).set_image(img)
		(b[2] as Node).queue_free()
	_rendering = false
	if _queue.is_empty():
		idle.emit()

func _frame(cam: Camera3D, node: Node3D, opts: Dictionary) -> void:
	var box := FoodArt.aabb_of(node)
	var center := box.get_center()
	var radius := maxf(box.size.length() * 0.5, 0.01)
	var elev := deg_to_rad(float(opts.get("elev", ELEVATION)))
	var yaw := float(opts.get("yaw", 0.0))
	var dist := radius / sin(deg_to_rad(FOV) * 0.5) * float(opts.get("zoom", 1.0)) * 0.96
	var dir := Vector3(sin(yaw) * cos(elev), sin(elev), cos(yaw) * cos(elev))
	cam.position = center + dir * dist
	cam.look_at(center, Vector3.UP)

## Waits until every queued render has finished.
func flush() -> void:
	while busy():
		await get_tree().process_frame
