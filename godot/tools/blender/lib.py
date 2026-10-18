"""Shared helpers for the Blender build scripts (café, town, apartment).

Coordinates passed to helpers are GODOT coordinates (x right, y up, z toward the camera);
g2b converts them to Blender's (x, -z, y). Material-name flags read by Toon.apply_to in
Godot: "noline" (no outline), "glass", "glow"/"emit". Empties named mark_* are anchors.
"""
import bpy, bmesh, math, sys, random
from mathutils import Vector

def args():
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    random.seed(4)
    _mats.clear()

# --------------------------------------------------------------------- helpers
_mats = {}
def mat(hexcol, name=None):
    key = (hexcol, name)
    if key in _mats:
        return _mats[key]
    h = hexcol.lstrip("#")
    srgb = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb]
    m = bpy.data.materials.new(name or ("toon_" + h))
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*lin, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.8
    _mats[key] = m
    return m

def g2b(x, y, z):
    """Godot coordinates -> Blender coordinates."""
    return Vector((x, -z, y))

def finish(obj, m, bevel=0.0, segs=3, smooth=True, parent=None):
    obj.data.materials.clear()
    obj.data.materials.append(m)
    if bevel > 0:
        md = obj.modifiers.new("bevel", "BEVEL")
        md.width = bevel
        md.segments = segs
        md.limit_method = "ANGLE"
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=md.name)
    if smooth:
        for p in obj.data.polygons:
            p.use_smooth = True
    if parent:
        obj.parent = parent
    return obj

def box(name, center, size, color, bevel=0.01, mname=None, parent=None, rot=(0, 0, 0)):
    """center/size in Godot coords (x, y, z) = (right, up, toward camera)."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=g2b(*center))
    o = bpy.context.active_object
    o.name = name
    o.scale = (size[0], size[2], size[1])
    o.rotation_euler = (rot[0], -rot[2], rot[1])
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return finish(o, mat(color, mname), bevel, parent=parent)

def cyl(name, center, r, h, color, bevel=0.006, verts=32, mname=None, parent=None, axis="y", r2=None):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=g2b(*center))
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=h, location=g2b(*center))
    o = bpy.context.active_object
    o.name = name
    if axis == "x":
        o.rotation_euler = (0, math.pi / 2, 0)
    elif axis == "z":
        o.rotation_euler = (math.pi / 2, 0, 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return finish(o, mat(color, mname), bevel, parent=parent)

def sphere(name, center, r, color, scale=(1, 1, 1), mname=None, parent=None, segs=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segs, ring_count=segs // 2, radius=r, location=g2b(*center))
    o = bpy.context.active_object
    o.name = name
    o.scale = (scale[0], scale[2], scale[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(o, mat(color, mname), 0.0, parent=parent)

def torus(name, center, R, r, color, mname=None, parent=None, axis="y"):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=40, minor_segments=12, location=g2b(*center))
    o = bpy.context.active_object
    o.name = name
    if axis == "z":
        o.rotation_euler = (math.pi / 2, 0, 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return finish(o, mat(color, mname), 0.0, parent=parent)

def empty(name, pos, parent=None):
    o = bpy.data.objects.new(name, None)
    o.location = g2b(*pos)
    bpy.context.scene.collection.objects.link(o)
    if parent:
        o.parent = parent
    return o

def group(name):
    o = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(o)
    return o

def leaf_obj(name, base, direction, length, width, color, parent=None):
    """A thick, curved leaf as a flattened, bent UV sphere."""
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=1.0)
    o = bpy.context.active_object
    o.name = name
    o.scale = (width, length, width * 0.18)
    bpy.ops.object.transform_apply(scale=True)
    me = o.data
    for v in me.vertices:
        t = (v.co.y / length)
        v.co.z += (t * t) * length * -0.25 + length * 0.12
    me.update()
    d = Vector(direction).normalized()
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = Vector((0, 1, 0)).rotation_difference(g2b(*d))
    o.location = g2b(*base) + g2b(*d) * length
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return finish(o, mat(color), 0.0, parent=parent)


def join(objs, name, parent):
    objs = [o for o in objs if o.type == "MESH"]
    if len(objs) < 2:
        return objs[0] if objs else None
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    j = bpy.context.view_layer.objects.active
    j.name = name
    j.parent = parent
    return j

def merge_static(root):
    """Joins each decor_*/bld_* group's meshes and the remaining static meshes under root."""
    for g in [o for o in bpy.data.objects if o.name.startswith(("decor_", "grp_"))]:
        join([c for c in g.children if c.type == "MESH"], g.name + "_mesh", g)
    join([o for o in root.children if o.type == "MESH"], root.name + "_static", root)

def export(path):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True, export_yup=True, export_extras=False, export_lights=False, export_cameras=False)
    print("EXPORTED", path, len(bpy.data.objects), "objects")

def planks(prefix, x0, x1, z0, z1, cols, parent, y=-0.03, plank=0.22):
    n = 0
    z = z0
    while z < z1 - 0.01:
        x = x0 + (0.0 if n % 2 else -0.6)
        while x < x1:
            w = min(1.2 + random.random() * 0.6, x1 - x)
            xs = max(x, x0)
            w = min(w, x1 - xs)
            if w > 0.05:
                k = random.randrange(len(cols))
                box("%s_%d" % (prefix, n), (xs + w / 2, y, z + plank / 2), (w - 0.006, 0.06, plank - 0.004), cols[k], 0.006, mname="%s_%d_noline" % (prefix, k), parent=parent)
            x = xs + w
            n += 1
        z += plank

def tiles(prefix, x0, x1, z0, z1, c1, c2, parent, size=0.4, y=-0.03):
    i = 0
    x = x0
    while x < x1 - 0.01:
        z = z0
        j = 0
        while z < z1 - 0.01:
            w = min(size, x1 - x); d = min(size, z1 - z)
            box("%s_%d_%d" % (prefix, i, j), (x + w / 2, y, z + d / 2), (w - 0.008, 0.06, d - 0.008), c1 if (i + j) % 2 else c2, 0.004, mname="%s_%d_noline" % (prefix, (i + j) % 2), parent=parent)
            z += size; j += 1
        x += size; i += 1

# palette
WALL = "FCE9DE"; WALL2 = "F6D5C6"; PANEL = "F2B9A8"; PANEL_D = "E8A090"
WOOD = "E8B87A"; WOOD_D = "C8864E"; WOOD_L = "F6D29A"; TRIM = "FFF8EE"
MINT = "BDEBDD"; MINT_D = "8FD1BE"; PINK = "FF9EBB"; SAKURA = "FF7EA6"
PLUM = "3B2340"; NAVY = "2C356C"; CREAM = "FFF8EE"; LEAF = "6BBF59"; LEAF_D = "4E9E57"
POT = "E8826A"; GOLD = "FFD24A"
