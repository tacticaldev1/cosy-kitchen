## Edit mode for the café dining room and your apartment: pick up furniture, move it, turn it,
## put it back in storage, or place new things you've bought.
class_name EditMode
extends Node

const SNAP := 0.25

var game: Game
var active := false
var layer: FurnitureLayer
var cam_pos := Vector3.ZERO
var cam_look := Vector3.ZERO
var held := {}            # {id, rot, item (existing dict or {}), node}
var _foot: MeshInstance3D
var _foot_mat: StandardMaterial3D
var _at := Vector3.ZERO
var _ok := false

func start() -> bool:
	var l := game.loc
	if l == null or l.furni == null or not l.editable:
		game.toast("You can only decorate your café and your home")
		return false
	if l == game.cafe and game.shop.open:
		game.toast("Close the café before rearranging the furniture")
		return false
	game.leave_station()
	game.drop_carry()
	layer = l.furni
	active = true
	var a := layer.area
	var c := Vector3(a.get_center().x, 0, a.get_center().y)
	cam_pos = c + Vector3(0, maxf(a.size.x, a.size.y) * 1.05 + 1.5, maxf(a.size.x, a.size.y) * 0.75 + 1.0)
	cam_look = c + Vector3(0, 0, -0.2)
	if _foot == null:
		_foot = MeshInstance3D.new()
		_foot.mesh = PlaneMesh.new()
		_foot_mat = StandardMaterial3D.new()
		_foot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_foot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_foot.material_override = _foot_mat
		game.add_child(_foot)
	_foot.visible = false
	game.hud.edit_ui(true)
	Sfx.play("pop")
	return true

func stop() -> void:
	if not active: return
	cancel()
	active = false
	if _foot: _foot.visible = false
	game.hud.edit_ui(false)
	var p := game.player
	if game.loc and game.loc.nav: p.global_position = game.loc.nav.nearest_free(p.global_position)
	if game.loc is HomeLocation: (game.loc as HomeLocation).refresh_family()
	Save.save()

## Take a new item out of storage and start placing it.
func hold_new(id: String) -> void:
	cancel()
	held = {"id": id, "rot": 0, "item": {}, "node": Furni.node(id)}
	layer.add_child(held.node)
	_at = cam_look
	_update_ghost(cam_look)

func _pick_up(it: Dictionary) -> void:
	held = {"id": it.id, "rot": it.rot, "item": it, "node": Furni.node(it.id)}
	it.node.visible = false
	layer.add_child(held.node)
	_update_ghost(Vector3(it.x, 0, it.z))
	Sfx.play("pop", 0.8, 1.2)

func cancel() -> void:
	if held.is_empty(): return
	if held.item.size() and is_instance_valid(held.item.node): held.item.node.visible = true
	if is_instance_valid(held.node): held.node.queue_free()
	held = {}
	if _foot: _foot.visible = false
	game.hud.edit_changed()

func rotate() -> void:
	if held.is_empty(): return
	held.rot = (int(held.rot) + 1) % 4
	_update_ghost(_at)
	Sfx.play("tick")

## Put the held item (or nothing) back into storage.
func store() -> void:
	if held.is_empty(): return
	if held.item.size():
		layer.remove(held.item)
	Save.furni_inv[held.id] = int(Save.furni_inv.get(held.id, 0)) + 1
	if is_instance_valid(held.node): held.node.queue_free()
	held = {}
	_foot.visible = false
	Save.save()
	Sfx.play("fwip" if Sfx.has("fwip") else "pop")
	game.hud.edit_changed()

func _place() -> void:
	if held.is_empty() or not _ok:
		if not held.is_empty(): Sfx.play("sad" if Sfx.has("sad") else "tick")
		return
	var placed: Dictionary
	var old := {}
	if held.item.size():
		old = {"x": held.item.x, "z": held.item.z, "rot": held.item.rot}
		held.item.node.visible = true
		layer.move(held.item, _at.x, _at.z, held.rot)
		placed = held.item
	else:
		placed = layer.add(held.id, _at.x, _at.z, held.rot)
	# never let furniture wall off a door, a station, the bed or part of the room
	if blocks_paths():
		if old.size(): layer.move(placed, old.x, old.z, old.rot)
		else: layer.remove(placed)
		if held.item.size(): held.item.node.visible = false
		game.toast("That would block the way! Leave room to walk around")
		Sfx.play("sad" if Sfx.has("sad") else "tick")
		return
	if old.is_empty():
		Save.furni_inv[held.id] = int(Save.furni_inv.get(held.id, 0)) - 1
		if Save.furni_inv[held.id] <= 0: Save.furni_inv.erase(held.id)
	held.node.queue_free()
	held = {}
	_foot.visible = false
	game.life.flag("placed")
	game.burst(_at + Vector3(0, 0.3, 0), [Color.WHITE, Color("FFD24A")], 8)
	Sfx.play("plunk")
	Save.save()
	game.hud.edit_changed()

## True if the room has spots you can't walk to (checked after every placement).
func blocks_paths() -> bool:
	var l := game.loc
	var pts := {}
	for it in l.interacts: pts[it.id] = it.pos
	if l is CafeLocation:
		for k in (l as CafeLocation).stand: pts["stand_" + k] = (l as CafeLocation).stand[k]
	pts["you"] = game.player.global_position
	var problems := NavReport.check(l, l.entry_point("door"), pts).filter(func(p): return not String(p).contains("free cells"))
	return problems.size() > 0

func _update_ghost(p: Vector3) -> void:
	if held.is_empty(): return
	var s := FurnitureLayer.size_of(held.id, held.rot)
	# snap so the footprint edges sit on the grid
	var x := snappedf(p.x - s.x * 0.5, SNAP) + s.x * 0.5
	var z := snappedf(p.z - s.y * 0.5, SNAP) + s.y * 0.5
	# keep it flush inside the room when you drag it against a wall
	var a := layer.area
	x = clampf(x, a.position.x + s.x * 0.5, a.end.x - s.x * 0.5)
	z = clampf(z, a.position.y + s.y * 0.5, a.end.y - s.y * 0.5)
	_at = Vector3(x, 0, z)
	held.node.position = layer.to_local(_at)
	held.node.rotation.y = held.rot * PI * 0.5
	_ok = layer.can_place(held.id, x, z, held.rot, held.item)
	_foot.visible = true
	(_foot.mesh as PlaneMesh).size = s
	_foot.global_position = _at + Vector3(0, 0.015, 0)
	_foot_mat.albedo_color = Color(0.4, 0.9, 0.6, 0.45) if _ok else Color(1.0, 0.35, 0.4, 0.5)

func handle(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_R: rotate()
			KEY_X, KEY_DELETE: store()
			KEY_ESCAPE:
				if held.is_empty(): stop()
				else: cancel()
			KEY_ENTER, KEY_E: stop()
		return
	if e is InputEventMouseMotion and held.size():
		var w = game.floor_point(e.position)
		if w != null: _update_ghost(w)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_RIGHT:
			if held.size(): rotate()
			return
		if e.button_index != MOUSE_BUTTON_LEFT: return
		var w = game.floor_point(e.position)
		if w == null: return
		if held.size():
			_update_ghost(w)
			_place()
		else:
			var it := layer.pick(w)
			if it.size(): _pick_up(it)
		game.hud.edit_changed()
