"""Builds the Cosy Kitchen café room in Blender and exports assets/models/cafe.glb.

Run headless:
  blender -b -P tools/blender/build_cafe.py -- <out.glb> [preview.png]

Conventions read by Godot (Toon.apply_to):
  * material colour = toon albedo
  * material name containing "noline" = no outline, "glass" = glass shader, "glow" = emissive
  * objects named decor_* are optional decorations, hidden until bought
  * empties named mark_* are anchor points (seats, stations, lamps, door...)
Units: metres. Godot's +Y is up; Blender's +Z is up (the glTF exporter converts).
The camera looks from +Y_godot... i.e. from Blender -Y toward +Y? No: glTF converts
Blender (x, y, z) -> Godot (x, z, -y). So Blender -Y is Godot +Z (toward the camera).
"""
import bpy, bmesh, math, sys, random
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "cafe.glb"
PREVIEW = argv[1] if len(argv) > 1 else None
random.seed(4)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

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

# --------------------------------------------------------------------- palette
WALL = "FCE9DE"; WALL2 = "F6D5C6"; PANEL = "F2B9A8"; PANEL_D = "E8A090"
WOOD = "E8B87A"; WOOD_D = "C8864E"; WOOD_L = "F6D29A"; TRIM = "FFF8EE"
MINT = "BDEBDD"; MINT_D = "8FD1BE"; PINK = "FF9EBB"; SAKURA = "FF7EA6"
PLUM = "3B2340"; NAVY = "2C356C"; CREAM = "FFF8EE"; LEAF = "6BBF59"; LEAF_D = "4E9E57"
POT = "E8826A"; GOLD = "FFD24A"

root = group("Cafe")

# --------------------------------------------------------------------- floor & walls
FX0, FX1, FZ0, FZ1 = -3.2, 3.2, -2.3, 2.6
planks = ["E8B87A", "E2AE6E", "ECC088", "DDA466"]
n = 0
z = FZ0
while z < FZ1 - 0.01:
    x = FX0 + (0.0 if n % 2 else -0.6)
    while x < FX1:
        w = min(1.2 + random.random() * 0.6, FX1 - x)
        if w > 0.05:
            box("floor_%d" % n, (x + w / 2, -0.03, z + 0.11), (w - 0.006, 0.06, 0.216), planks[random.randrange(4)], 0.006, mname="toon_floor_%s_noline" % random.randrange(4), parent=root)
        x += w
        n += 1
    z += 0.22

# back wall (behind the customers) and left wall
# back wall with an opening for the window (WX=0, WY=1.62, 2.2 x 1.05)
_wl, _wr, _wb, _wt = -1.1, 1.1, 1.62 - 0.525, 1.62 + 0.525
box("wall_back_l", ((FX0 - 0.06 + _wl) / 2, 1.45, FZ0 - 0.06), (_wl - FX0 + 0.06, 2.9, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_back_r", ((FX1 + 0.06 + _wr) / 2, 1.45, FZ0 - 0.06), (FX1 + 0.06 - _wr, 2.9, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_back_b", (0, _wb / 2, FZ0 - 0.06), (_wr - _wl, _wb, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_back_t", (0, (_wt + 2.9) / 2, FZ0 - 0.06), (_wr - _wl, 2.9 - _wt, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_left", (FX0 - 0.06, 1.45, 0.15), (0.12, 2.9, FZ1 - FZ0), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_right", (FX1 + 0.06, 1.45, 0.15), (0.12, 2.9, FZ1 - FZ0), WALL2, 0.0, mname="wall2_noline", parent=root)
for i in range(9):
    z = FZ0 + 0.25 + i * 0.54
    box("wains_r%d" % i, (FX1 - 0.012, 0.48, z), (0.024, 0.8, 0.5), PANEL, 0.008, parent=root)
box("rail_r", (FX1 - 0.03, 0.92, 0.15), (0.06, 0.05, FZ1 - FZ0), TRIM, 0.012, parent=root)
box("skirt_r", (FX1 - 0.025, 0.05, 0.15), (0.05, 0.1, FZ1 - FZ0), WOOD_D, 0.008, parent=root)
# a round clock on the right wall
cyl("clock", (FX1 - 0.03, 2.1, -1.0), 0.22, 0.05, "FFFFFF", 0.01, 40, axis="x", parent=root)
torus("clock_rim", (FX1 - 0.05, 2.1, -1.0), 0.22, 0.025, SAKURA, axis="x", parent=root) if False else cyl("clock_rim", (FX1 - 0.02, 2.1, -1.0), 0.25, 0.04, SAKURA, 0.01, 40, axis="x", parent=root)
empty("mark_clock", (FX1 - 0.065, 2.1, -1.0), root)
# wainscot panels
for i in range(13):
    x = FX0 + 0.25 + i * 0.5
    box("wains_b%d" % i, (x, 0.48, FZ0 + 0.012), (0.46, 0.8, 0.024), PANEL, 0.008, parent=root)
for i in range(9):
    z = FZ0 + 0.25 + i * 0.54
    if -2.05 < z < -0.95:  # the door
        continue
    box("wains_l%d" % i, (FX0 + 0.012, 0.48, z), (0.024, 0.8, 0.5), PANEL, 0.008, parent=root)
box("rail_b", (0, 0.92, FZ0 + 0.03), (FX1 - FX0, 0.05, 0.06), TRIM, 0.012, parent=root)
box("rail_l", (FX0 + 0.03, 0.92, 0.15), (0.06, 0.05, FZ1 - FZ0), TRIM, 0.012, parent=root)
box("skirt_b", (0, 0.05, FZ0 + 0.025), (FX1 - FX0, 0.1, 0.05), WOOD_D, 0.008, parent=root)
box("skirt_l", (FX0 + 0.025, 0.05, 0.15), (0.05, 0.1, FZ1 - FZ0), WOOD_D, 0.008, parent=root)
box("crown_b", (0, 2.86, FZ0 + 0.04), (FX1 - FX0, 0.08, 0.08), TRIM, 0.015, parent=root)

# --------------------------------------------------------------------- window behind the bar
WX, WY, WW, WH = 0.0, 1.62, 2.2, 1.05
box("win_frame_t", (WX, WY + WH / 2 + 0.04, FZ0 + 0.05), (WW + 0.16, 0.08, 0.1), TRIM, 0.015, parent=root)
box("win_frame_b", (WX, WY - WH / 2 - 0.04, FZ0 + 0.08), (WW + 0.24, 0.08, 0.16), TRIM, 0.015, parent=root)
box("win_frame_l", (WX - WW / 2 - 0.04, WY, FZ0 + 0.05), (0.08, WH + 0.16, 0.1), TRIM, 0.015, parent=root)
box("win_frame_r", (WX + WW / 2 + 0.04, WY, FZ0 + 0.05), (0.08, WH + 0.16, 0.1), TRIM, 0.015, parent=root)
for i in (-1, 1):
    box("win_mull_%d" % i, (WX + i * WW / 6, WY, FZ0 + 0.04), (0.035, WH, 0.05), TRIM, 0.008, parent=root)
box("win_mull_h", (WX, WY + 0.08, FZ0 + 0.04), (WW, 0.035, 0.05), TRIM, 0.008, parent=root)
box("win_glass", (WX, WY, FZ0 + 0.02), (WW, WH, 0.01), "D8ECFF", 0.0, mname="window_glass", parent=root)
empty("mark_window", (WX, WY, FZ0 - 0.02), root)
# little plants on the sill
for i, x in enumerate((-0.8, 0.85)):
    cyl("sill_pot_%d" % i, (x, WY - WH / 2 + 0.06, FZ0 + 0.12), 0.06, 0.1, POT, 0.006, r2=0.045, parent=root)
    for k in range(5):
        a = k * 1.26
        leaf_obj("sill_leaf_%d_%d" % (i, k), (x, WY - WH / 2 + 0.12, FZ0 + 0.12), (math.cos(a) * 0.5, 1.0, math.sin(a) * 0.5), 0.07, 0.035, LEAF if k % 2 else LEAF_D, parent=root)
# curtains
for s in (-1, 1):
    cx = WX + s * (WW / 2 + 0.22)
    for k in range(4):
        cyl("curtain_%d_%d" % (s, k), (cx - 0.12 + k * 0.08, WY + 0.02, FZ0 + 0.14), 0.05, WH + 0.35, "FFD6E2", 0.0, 16, parent=root)
box("curtain_rod", (WX, WY + WH / 2 + 0.2, FZ0 + 0.14), (WW + 1.0, 0.03, 0.03), WOOD_D, 0.01, parent=root)

# --------------------------------------------------------------------- shelves on the back wall
for s in (-1, 1):
    sx = s * 2.25
    for k, y in enumerate((1.45, 1.95)):
        box("shelf_%d_%d" % (s, k), (sx, y, FZ0 + 0.14), (1.1, 0.04, 0.24), WOOD, 0.01, parent=root)
        for b in (-0.45, 0.45):
            box("shelf_br_%d_%d_%s" % (s, k, b), (sx + b, y - 0.06, FZ0 + 0.06), (0.03, 0.1, 0.1), WOOD_D, 0.006, parent=root)
    # jars on the lower shelf
    jar_cols = ["FFD24A", "FF9EBB", "BDEBDD", "C3A6FF"]
    for j in range(4):
        jx = sx - 0.36 + j * 0.24
        cyl("jar_%d_%d" % (s, j), (jx, 1.47 + 0.08, FZ0 + 0.14), 0.065, 0.16, jar_cols[(j + (s > 0)) % 4], 0.01, parent=root)
        cyl("jar_label_%d_%d" % (s, j), (jx, 1.47 + 0.07, FZ0 + 0.14), 0.067, 0.06, "FFFFFF", 0.004, parent=root)
        cyl("jar_lid_%d_%d" % (s, j), (jx, 1.47 + 0.17, FZ0 + 0.14), 0.07, 0.03, WOOD_D, 0.008, parent=root)
    # cups and a teapot on the upper shelf
    for j in range(3):
        cyl("cup_%d_%d" % (s, j), (sx - 0.35 + j * 0.13, 1.97 + 0.05, FZ0 + 0.14), 0.045, 0.09, ["FFFFFF", "FFC2D6", "BDEBDD"][j], 0.01, parent=root)
    sphere("teapot_%d" % s, (sx + 0.28, 1.97 + 0.09, FZ0 + 0.14), 0.1, "FFB9A6" if s < 0 else "A9C8FF", (1.1, 0.85, 1.0), parent=root)
    cyl("teapot_lid_%d" % s, (sx + 0.28, 1.97 + 0.18, FZ0 + 0.14), 0.04, 0.03, CREAM, 0.008, parent=root)
    cyl("teapot_spout_%d" % s, (sx + 0.41, 1.97 + 0.12, FZ0 + 0.14), 0.02, 0.12, "FFB9A6" if s < 0 else "A9C8FF", 0.004, 12, axis="x", parent=root)

# menu board on the left wall
box("menu_board", (FX1 - 0.04, 1.72, 0.35), (0.04, 0.7, 0.9), "2F3B37", 0.012, parent=root)
box("menu_frame", (FX1 - 0.03, 1.72, 0.35), (0.03, 0.78, 0.98), WOOD, 0.012, parent=root)
empty("mark_menu", (FX1 - 0.07, 1.72, 0.35), root)

# --------------------------------------------------------------------- door with noren on the left wall
DZ = -1.5
box("door", (FX0 + 0.03, 1.05, DZ), (0.06, 2.1, 0.95), "C8864E", 0.015, parent=root)
box("door_panel_t", (FX0 + 0.07, 1.45, DZ), (0.02, 0.8, 0.7), "D9A066", 0.01, parent=root)
box("door_window", (FX0 + 0.075, 1.5, DZ), (0.01, 0.5, 0.45), "FFE6B0", 0.0, mname="door_glow", parent=root)
box("door_frame_t", (FX0 + 0.05, 2.14, DZ), (0.1, 0.08, 1.11), TRIM, 0.012, parent=root)
for s in (-1, 1):
    box("door_frame_%d" % s, (FX0 + 0.05, 1.07, DZ + s * 0.515), (0.1, 2.14, 0.08), TRIM, 0.012, parent=root)
sphere("door_knob", (FX0 + 0.1, 1.0, DZ + 0.36), 0.03, GOLD, parent=root)
# noren: three cloth panels hanging inside the doorway
for k in range(3):
    bpy.ops.mesh.primitive_plane_add(size=1, location=g2b(FX0 + 0.14, 1.83, DZ - 0.3 + k * 0.3))
    o = bpy.context.active_object
    o.name = "noren_%d" % k
    o.scale = (0.012, 0.29, 0.5)  # will be thickened
    bpy.ops.object.transform_apply(scale=True)
    o.rotation_euler = (0, math.pi / 2, 0)
    bpy.ops.object.transform_apply(rotation=True)
    sol = o.modifiers.new("s", "SOLIDIFY"); sol.thickness = 0.015
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier="s")
    for v in o.data.vertices:
        v.co.x += math.sin(v.co.y * 18.0) * 0.012
    finish(o, mat(NAVY), 0.0, parent=root)
box("noren_rod", (FX0 + 0.14, 2.1, DZ), (0.03, 0.03, 1.0), WOOD_D, 0.01, parent=root)
empty("mark_door", (FX0 + 0.35, 0.0, DZ), root)
empty("mark_sign", (FX0 + 0.12, 1.25, DZ - 0.62), root)

# --------------------------------------------------------------------- bar counter (customers sit behind it)
BZ = -1.15
box("bar_top", (0, 1.02, BZ), (2.9, 0.06, 0.5), WOOD_L, 0.02, parent=root)
box("bar_body", (0, 0.5, BZ), (2.8, 0.98, 0.42), MINT, 0.02, parent=root)
for i in range(7):
    box("bar_slat_%d" % i, (-1.2 + i * 0.4, 0.5, BZ + 0.215), (0.3, 0.8, 0.02), MINT_D, 0.008, parent=root)
box("bar_foot", (0, 0.12, BZ - 0.23), (2.7, 0.04, 0.04), GOLD, 0.01, parent=root)
empty("mark_pass", (0, 1.05, BZ + 0.05), root)
for i, x in enumerate((-0.9, 0.0, 0.9, -1.8, 1.8)):
    empty("mark_seat_%d" % i, (x if i < 3 else x * 0.97, 0.0, BZ - 0.55), root)
# stools
for i, x in enumerate((-0.9, 0.0, 0.9)):
    cyl("stool_seat_%d" % i, (x, 0.74, BZ - 0.55), 0.2, 0.08, PINK, 0.03, parent=root)
    cyl("stool_leg_%d" % i, (x, 0.37, BZ - 0.55), 0.035, 0.7, "C8C8D8", 0.005, 16, parent=root)
    cyl("stool_base_%d" % i, (x, 0.02, BZ - 0.55), 0.18, 0.04, "C8C8D8", 0.01, parent=root)
    torus("stool_ring_%d" % i, (x, 0.3, BZ - 0.55), 0.13, 0.012, "C8C8D8", parent=root)

# pendant lamps above the bar
for i, x in enumerate((-0.9, 0.0, 0.9)):
    cyl("lamp_cord_%d" % i, (x, 2.5, BZ), 0.006, 0.8, PLUM, 0.0, 8, parent=root)
    cyl("lamp_shade_%d" % i, (x, 2.02, BZ), 0.2, 0.2, "FFE3D0" if i != 1 else "FFC2D6", 0.01, 32, r2=0.06, parent=root)
    sphere("lamp_bulb_%d" % i, (x, 1.92, BZ), 0.06, "FFF0C8", mname="lamp_glow", parent=root)
    empty("mark_lamp_%d" % i, (x, 1.86, BZ), root)

# --------------------------------------------------------------------- kitchen work counter (front)
KZ = 0.05
box("counter_top", (0.0, 0.89, KZ), (4.1, 0.06, 0.66), "FFF4E2", 0.02, parent=root)
box("counter_body", (0.0, 0.44, KZ - 0.02), (4.0, 0.86, 0.6), "FFD6C2", 0.015, parent=root)
for i in range(8):
    x = -1.75 + i * 0.5
    box("cab_door_%d" % i, (x, 0.45, KZ + 0.285), (0.44, 0.7, 0.02), "FFE3D4", 0.01, parent=root)
    sphere("cab_knob_%d" % i, (x + (0.16 if i % 2 else -0.16), 0.62, KZ + 0.3), 0.022, GOLD, parent=root)
box("counter_kick", (0.0, 0.04, KZ + 0.24), (4.0, 0.08, 0.02), WOOD_D, 0.006, parent=root)
# tiled backsplash strip behind the counter (a low wall between kitchen and bar)
box("splash", (0.0, 0.97, KZ - 0.3), (4.1, 0.12, 0.06), "F6FFFC", 0.01, parent=root)
for i in range(20):
    box("tile_%d" % i, (-1.95 + i * 0.205, 0.97, KZ - 0.267), (0.19, 0.09, 0.012), MINT if i % 2 else "DDF3EA", 0.004, parent=root)
station_x = {"board": -1.55, "bowl": -1.05, "blender": -0.55, "mat": -0.05, "pot": 0.48, "pan": 0.98, "micro": 1.62}
for k, x in station_x.items():
    empty("mark_%s" % k, (x, 0.92, KZ), root)
empty("mark_oven", (0.73, 0.0, KZ + 0.3), root)
empty("mark_bin", (2.35, 0.0, 0.62), root)
empty("mark_fridge", (-2.62, 0.0, 0.25), root)
empty("mark_freezer", (2.62, 0.0, -0.3), root)

# --------------------------------------------------------------------- ambient decor (always there)
# potted plant by the door
cyl("plant_pot", (2.85, 0.2, -1.9), 0.2, 0.4, POT, 0.02, r2=0.15, parent=root)
for k in range(9):
    a = k * 0.7
    leaf_obj("plant_leaf_%d" % k, (2.85, 0.42, -1.9), (math.cos(a) * 0.6, 1.0 + (k % 3) * 0.4, math.sin(a) * 0.6), 0.22, 0.11, LEAF if k % 2 else LEAF_D, parent=root)
# rug under the stools
cyl("rug", (0, 0.004, BZ - 0.55), 1.0, 0.008, "C3A6FF", 0.0, 48, mname="rug_noline", parent=root)
cyl("rug_inner", (0, 0.009, BZ - 0.55), 0.85, 0.008, "E2D6FF", 0.0, 48, mname="rug2_noline", parent=root)
for o in bpy.data.objects:
    if o.name.startswith("rug"):
        o.scale = (1.7, 0.5, 1.0)
bpy.ops.object.select_all(action="DESELECT")

# --------------------------------------------------------------------- buyable decorations (hidden at start in Godot)
def deco(name):
    g = group("decor_" + name)
    g.parent = root
    return g

d = deco("lucky_cat")   # maneki-neko on the left shelf
cx, cy, cz = -2.0, 1.98, FZ0 + 0.14
sphere("cat_body", (cx, cy + 0.1, cz), 0.1, "FFFFFF", (1.0, 1.1, 0.9), parent=d)
sphere("cat_head", (cx, cy + 0.25, cz + 0.01), 0.085, "FFFFFF", (1.15, 1.0, 1.0), parent=d)
for s in (-1, 1):
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.035, depth=0.06, location=g2b(cx + s * 0.055, cy + 0.33, cz))
    o = bpy.context.active_object; o.name = "cat_ear_%d" % s
    finish(o, mat("FFFFFF"), 0.0, parent=d)
sphere("cat_paw", (cx + 0.09, cy + 0.27, cz + 0.05), 0.035, "FFFFFF", parent=d)
torus("cat_collar", (cx, cy + 0.17, cz + 0.01), 0.075, 0.012, "E8404A", parent=d)
sphere("cat_bell", (cx, cy + 0.15, cz + 0.085), 0.02, GOLD, parent=d)
sphere("cat_coin", (cx - 0.06, cy + 0.12, cz + 0.085), 0.04, GOLD, (1.0, 1.3, 0.3), parent=d)
for s in (-1, 1):
    sphere("cat_eye_%d" % s, (cx + s * 0.032, cy + 0.26, cz + 0.08), 0.012, PLUM, parent=d)
    sphere("cat_blush_%d" % s, (cx + s * 0.055, cy + 0.235, cz + 0.07), 0.014, "FF8FB0", (1, 0.6, 0.4), mname="blush_noline", parent=d)

d = deco("fairy_lights")
for i in range(26):
    t = i / 25.0
    x = -2.9 + t * 5.8
    y = 2.62 - math.sin(t * math.pi * 3) ** 2 * 0.22
    sphere("fl_%d" % i, (x, y, FZ0 + 0.1), 0.028, ["FFE27A", "FF9EBB", "9BE3FF", "C3FFB0"][i % 4], mname="fairy_glow_%d" % (i % 4), parent=d)
cyl("fl_wire", (0, 2.6, FZ0 + 0.1), 0.004, 5.8, PLUM, 0.0, 6, axis="x", parent=d)

d = deco("big_plant")
cyl("bp_pot", (-2.75, 0.25, -0.55), 0.24, 0.5, "FFFFFF", 0.02, r2=0.19, parent=d)
cyl("bp_band", (-2.75, 0.32, -0.55), 0.235, 0.08, SAKURA, 0.01, parent=d)
for k in range(12):
    a = k * 0.55
    leaf_obj("bp_leaf_%d" % k, (-2.75, 0.5 + (k % 4) * 0.18, -0.55), (math.cos(a) * 0.7, 1.0, math.sin(a) * 0.7), 0.3, 0.16, LEAF if k % 2 else LEAF_D, parent=d)

d = deco("flowers")
cyl("vase", (1.25, 1.13, BZ - 0.02), 0.06, 0.18, "A9C8FF", 0.01, r2=0.045, parent=d)
for k in range(6):
    a = k * 1.05
    p = (1.25 + math.cos(a) * 0.05, 1.32 + (k % 2) * 0.04, BZ - 0.02 + math.sin(a) * 0.05)
    cyl("stem_%d" % k, (p[0], 1.24, p[2]), 0.006, 0.16, LEAF_D, 0.0, 6, parent=d)
    sphere("flower_%d" % k, p, 0.04, ["FF7EA6", "FFD24A", "FFFFFF"][k % 3], (1, 0.7, 1), parent=d)
    sphere("flower_c_%d" % k, (p[0], p[1] + 0.022, p[2]), 0.015, "FFB52E", parent=d)

d = deco("record_player")
box("rp_base", (2.25, 1.53, FZ0 + 0.14), (0.42, 0.1, 0.22), "C8864E", 0.015, parent=d)
cyl("rp_disc", (2.18, 1.585, FZ0 + 0.14), 0.13, 0.012, PLUM, 0.003, 40, parent=d)
cyl("rp_label", (2.18, 1.592, FZ0 + 0.14), 0.04, 0.006, SAKURA, 0.001, 24, parent=d)
box("rp_arm", (2.36, 1.6, FZ0 + 0.14), (0.02, 0.02, 0.16), "D8D8E8", 0.005, parent=d)
empty("mark_music", (2.2, 1.7, FZ0 + 0.14), d)

d = deco("cat_bed")
cyl("bed", (2.05, 0.08, -1.85), 0.32, 0.16, "C3A6FF", 0.05, parent=d)
cyl("bed_in", (2.05, 0.13, -1.85), 0.24, 0.08, "F2ECFF", 0.03, parent=d)
sphere("kitty", (2.05, 0.22, -1.85), 0.17, "FFB86A", (1.2, 0.6, 1.0), parent=d)
sphere("kitty_head", (2.23, 0.27, -1.78), 0.1, "FFB86A", parent=d)
for s in (-1, 1):
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.04, depth=0.07, location=g2b(2.23 + s * 0.06, 0.37, -1.78))
    o = bpy.context.active_object; o.name = "kitty_ear_%d" % s
    finish(o, mat("FFB86A"), 0.0, parent=d)
    box("kitty_eye_%d" % s, (2.23 + s * 0.035, 0.28, -1.69), (0.03, 0.006, 0.006), PLUM, 0.002, parent=d)
cyl("kitty_tail", (1.85, 0.2, -1.75), 0.025, 0.25, "FFB86A", 0.01, 12, axis="x", parent=d)
empty("mark_kitty", (2.23, 0.3, -1.78), d)

d = deco("poster")
box("poster_frame", (FX0 + 0.04, 1.72, 1.3), (0.03, 0.66, 0.5), "FFFFFF", 0.01, parent=d)
box("poster_art", (FX0 + 0.06, 1.72, 1.3), (0.01, 0.56, 0.4), "FFC2D6", 0.0, parent=d)
sphere("poster_sun", (FX0 + 0.07, 1.82, 1.3), 0.09, "FFE27A", (0.2, 1, 1), parent=d)
box("poster_hill", (FX0 + 0.07, 1.56, 1.3), (0.01, 0.16, 0.38), "8ED16B", 0.02, parent=d)

d = deco("lanterns")
for i, z in enumerate((-1.6, -0.6, 0.6, 1.6)):
    sphere("lantern_%d" % i, (FX0 + 0.4, 2.45, z), 0.13, "FF6A6A" if i % 2 else SAKURA, (1, 1.25, 1), mname="lantern_glow_%d" % (i % 2), parent=d)
    cyl("lantern_cap_%d" % i, (FX0 + 0.4, 2.62, z), 0.06, 0.04, PLUM, 0.005, parent=d)
    cyl("lantern_bot_%d" % i, (FX0 + 0.4, 2.28, z), 0.06, 0.04, PLUM, 0.005, parent=d)

# --------------------------------------------------------------------- merge for speed
# Join the static room into one mesh and each decoration into one mesh, so Godot draws a
# handful of objects (one surface per material) instead of hundreds.
def join(objs, name, parent):
    objs = [o for o in objs if o.type == "MESH"]
    if len(objs) < 2:
        return
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    j = bpy.context.view_layer.objects.active
    j.name = name
    j.parent = parent
for g in [o for o in bpy.data.objects if o.name.startswith("decor_")]:
    join([c for c in g.children], g.name + "_mesh", g)
join([o for o in root.children if o.type == "MESH"], "cafe_static", root)

# --------------------------------------------------------------------- export
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_apply=True, export_yup=True, export_extras=False, export_lights=False, export_cameras=False)
print("EXPORTED", OUT, len(bpy.data.objects), "objects")

if PREVIEW:
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    scene.collection.objects.link(cam)
    cam.location = g2b(0, 3.0, 4.6)
    cam.rotation_euler = (math.radians(62), 0, 0)
    cam.data.lens = 28
    scene.camera = cam
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.rotation_euler = (math.radians(50), math.radians(20), math.radians(-30))
    sun.data.energy = 3
    scene.collection.objects.link(sun)
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = 1280, 720
    scene.render.filepath = PREVIEW
    bpy.ops.render.render(write_still=True)
