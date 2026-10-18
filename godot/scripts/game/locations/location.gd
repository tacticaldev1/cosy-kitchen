## A place you can walk around in: the café, the town or your home. Each location owns its
## room model, walk grid, lights, furniture and the things you can interact with.
class_name Location
extends Node3D

var key := ""
var title := ""
var game: Game
var room: Room
var nav: NavGrid
var furni: FurnitureLayer
var we: WorldEnvironment
var env: Environment
var lights: Node3D
var cam_offset := Vector3(0, 4.0, 5.0)
var cam_look := Vector3(0, 0.6, -0.5)
var cam_bounds := Rect2(-100, -100, 200, 200)
var interacts: Array = []     # [{id, pos, r, label, act: Callable}]
var npcs: Array = []          # Chibi nodes you can talk to (meta: npc, label)
var active := false
var music_mood := "cafe"

func setup(g: Game) -> void:
	game = g
	lights = Node3D.new()
	lights.name = "Lights"
	add_child(lights)

func make_nav(bounds: Rect2, cell := 0.15) -> void:
	nav = NavGrid.new(bounds, cell)
	nav.block_border(0.2)
	if room:
		for o in room.world_obstacles():
			nav.block_rect(o[0].x, o[0].z, o[1], o[2], 0.15)
	nav.freeze_static()

var _reach := PackedByteArray()
var _reach_dirty := true

## Can you walk to p from the entrance? (cached; furniture changes clear the cache)
func reachable(p: Vector3) -> bool:
	if nav == null: return true
	if _reach_dirty or _reach.size() != nav.w * nav.h:
		_reach = NavReport.reach(nav, entry_point("door"))
		_reach_dirty = false
	var c := nav.cell_of(p)
	return nav.free_cell(c) and _reach[c.y * nav.w + c.x] == 1

func activate(on: bool) -> void:
	active = on
	visible = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	if we:
		if on and we.get_parent() == null: add_child(we)
		elif not on and we.get_parent(): remove_child(we)

## Where you appear when arriving through an entry ("door", "start"...).
func entry_point(_entry: String) -> Vector3:
	return Vector3.ZERO

func entry_yaw(_entry: String) -> float:
	return 0.0

func add_interact(id: String, pos: Vector3, r: float, label: String, act: Callable) -> void:
	interacts.append({"id": id, "pos": pos, "r": r, "label": label, "act": act})

func nearest_interact(p: Vector3) -> Dictionary:
	var best := {}
	var bd := INF
	for it in interacts:
		var d := Vector2(p.x, p.z).distance_to(Vector2(it.pos.x, it.pos.z))
		if d < it.r and d < bd:
			bd = d
			best = it
	return best

## Screen-space pick of an interactable near the mouse.
func pick_interact(screen: Vector2, cam: Camera3D) -> Dictionary:
	var best := {}
	var bd := 70.0
	for it in interacts:
		var w: Vector3 = it.pos + Vector3(0, it.get("h", 0.9), 0)
		if not cam.is_position_in_frustum(w): continue
		var d := cam.unproject_position(w).distance_to(screen)
		if d < bd:
			bd = d
			best = it
	return best

## Screen-space pick of a person near the mouse.
func pick_npc(screen: Vector2, cam: Camera3D) -> Chibi:
	var best: Chibi = null
	var bd := 60.0
	for n in npcs:
		if not is_instance_valid(n) or not n.visible: continue
		var head: Vector3 = n.global_position + Vector3(0, 0.55 * n.scale.y, 0)
		if not cam.is_position_in_frustum(head): continue
		var sp := cam.unproject_position(head)
		var r := maxf(36.0, sp.distance_to(cam.unproject_position(head + cam.global_transform.basis.x * 0.3 * n.scale.y)))
		var d := sp.distance_to(screen)
		if d < r and d < bd:
			bd = d
			best = n
	return best

## A townsperson chibi with a name tag for talking.
func make_person(id: String, look: Dictionary, label: String, kind := "adult") -> Chibi:
	var c := Chibi.new()
	add_child(c)
	c.build(look, kind)
	c.speed = 0.9
	c.set_meta("npc", id)
	c.set_meta("label", label)
	npcs.append(c)
	return c

func tick(dt: float) -> void:
	for n in npcs:
		if is_instance_valid(n): n.tick(dt, game.clock)

## hour: 6.0 .. 26.0
func set_hour(_h: float) -> void:
	pass
