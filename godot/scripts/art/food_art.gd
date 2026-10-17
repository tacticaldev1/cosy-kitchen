## Turns ingredient keys and food specs into 3D nodes, caching the built meshes.
class_name FoodArt
extends RefCounted

static var _ing_mesh := {}
static var _piece_mesh := {}
static var _spec_mesh := {}

static func ingredient_mesh(key: String) -> ArrayMesh:
	if not _ing_mesh.has(key):
		var mb := MB.new()
		IngArt.build(mb, key)
		_ing_mesh[key] = finish(mb)
	return _ing_mesh[key]

static func piece_mesh(key: String) -> ArrayMesh:
	if not _piece_mesh.has(key):
		var mb := MB.new()
		IngArt.piece(mb, key)
		_piece_mesh[key] = finish(mb)
	return _piece_mesh[key]

## Builds the opaque layer (toon, vertex colours) and the glass layer into one ArrayMesh.
static func finish(mb: MB) -> ArrayMesh:
	var m := ArrayMesh.new()
	mb.layer(0)
	if not mb.is_empty():
		mb.build(m)
		m.surface_set_material(m.get_surface_count() - 1, Toon.vc())
	mb.layer(1)
	if not mb.is_empty():
		mb.build(m)
		m.surface_set_material(m.get_surface_count() - 1, Toon.glass())
	mb.layer(0)
	return m

static func mesh_node(mesh: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	return mi

static func ingredient_node(key: String) -> Node3D:
	var n := Node3D.new()
	n.add_child(mesh_node(ingredient_mesh(key)))
	return n

## The look of a spec. Dishes are added by DishArt; anything it can't draw falls back to raw art.
static func spec_mesh(sp: Dictionary) -> ArrayMesh:
	var key: String = G.spec_key(sp) + ("|bare" if sp.get("bare", false) else "")
	if _spec_mesh.has(key):
		return _spec_mesh[key]
	var mb := MB.new()
	if sp.get("art", "") == "raw" and sp.has("ing"):
		IngArt.build(mb, sp.ing)
	else:
		DishArt.bare = sp.get("bare", false)
		DishArt.build(mb, sp)
		DishArt.bare = false
	var m := finish(mb)
	_spec_mesh[key] = m
	return m

static func spec_node(sp: Dictionary) -> Node3D:
	var n := Node3D.new()
	n.name = "Food"
	var mi := mesh_node(spec_mesh(sp))
	n.add_child(mi)
	if sp.get("burnt", false):
		mi.set_instance_shader_parameter("cook", 1.45)
	return n

static func food_node(food: Dictionary, now := 0.0) -> Node3D:
	return spec_node(G.food_spec(food, now))

## Combined AABB of every mesh below node, in node's space.
static func aabb_of(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if not m.mesh: continue
		var t := node.global_transform.affine_inverse() * m.global_transform if node.is_inside_tree() else _rel(node, m)
		var b := t * m.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

static func _rel(root: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = n
	while cur and cur != root:
		if cur is Node3D:
			t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t
