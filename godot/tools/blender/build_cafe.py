"""Builds the café interior (walkable) and exports assets/models/cafe.glb.

  blender -b -P tools/blender/build_cafe.py -- <abs path to cafe.glb>

Layout (Godot coords): kitchen on the left (x < -0.7) with a back counter and a cooking
island, a serving pass at x = -0.45 with bar stools on the dining side, the dining room on
the right (tables come from the furniture system) and the street door in the right wall.
Exports:
  mark_<station>           where each appliance stands (counter top or floor)
  mark_bar_<i>             bar seats (customers face -x)
  mark_door / mark_door_out, mark_window, mark_lamp_<i>, mark_spawn
  obs_<i>_<w>_<d>          walk obstacles (rect centred on the empty, w along x, d along z)
Material names: wall / panel / floor_k (kitchen tiles) / floor_d (dining planks) are recoloured
by the café theme at runtime.
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib import *

OUT = (args() or ["cafe.glb"])[0]
reset()
root = group("Cafe")

X0, X1, Z0, Z1 = -4.2, 4.2, -3.0, 2.4
KX = -0.7   # kitchen | dining boundary
obs_n = [0]
def obstacle(cx, cz, w, d):
    empty("obs_%d_%.2f_%.2f" % (obs_n[0], w, d), (cx, 0, cz), root)
    obs_n[0] += 1

# --------------------------------------------------------------------- floors
tiles("floor_k", X0, KX, Z0, Z1, "FFF6EC", "E2F4EC", root, 0.4)
planks("floor_d", KX, X1, Z0, Z1, ["E8B87A", "E2AE6E", "ECC088", "DDA466"], root)
box("floor_trim", (KX, -0.025, (Z0 + Z1) / 2), (0.05, 0.06, Z1 - Z0), WOOD_D, 0.004, parent=root)

# --------------------------------------------------------------------- walls
WX0, WX1, WY0, WY1 = 0.7, 3.5, 1.1, 2.15
box("wall_back_k", ((X0 + WX0) / 2, 1.45, Z0 - 0.06), (WX0 - X0 + 0.12, 2.9, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_back_r", ((WX1 + X1) / 2 + 0.03, 1.45, Z0 - 0.06), (X1 - WX1 + 0.12, 2.9, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_back_b", ((WX0 + WX1) / 2, WY0 / 2, Z0 - 0.06), (WX1 - WX0, WY0, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_back_t", ((WX0 + WX1) / 2, (WY1 + 2.9) / 2, Z0 - 0.06), (WX1 - WX0, 2.9 - WY1, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_left", (X0 - 0.06, 1.45, (Z0 + Z1) / 2), (0.12, 2.9, Z1 - Z0 + 0.12), WALL, 0.0, mname="wall_noline", parent=root)
DZ0, DZ1 = 0.5, 1.5
box("wall_right_a", (X1 + 0.06, 1.45, (Z0 + DZ0) / 2), (0.12, 2.9, DZ0 - Z0), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_right_b", (X1 + 0.06, 1.45, (DZ1 + Z1) / 2), (0.12, 2.9, Z1 - DZ1), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_right_t", (X1 + 0.06, 2.55, 1.0), (0.12, 0.7, DZ1 - DZ0), WALL, 0.0, mname="wall_noline", parent=root)
for i in range(16):
    box("splash_%d" % i, (X0 + 0.15 + i * 0.22, 1.12, Z0 + 0.012), (0.2, 0.36, 0.02), MINT if i % 2 else "DDF3EA", 0.004, parent=root)
for i in range(10):
    x = KX + 0.3 + i * 0.5
    if WX0 - 0.1 < x < WX1 + 0.1 or x > X1 - 0.2:
        continue
    box("wains_b%d" % i, (x, 0.48, Z0 + 0.012), (0.46, 0.8, 0.024), PANEL, 0.008, mname="panel", parent=root)
for i in range(9):
    z = Z0 + 0.3 + i * 0.6
    if DZ0 - 0.25 < z < DZ1 + 0.25:
        continue
    box("wains_r%d" % i, (X1 - 0.012, 0.48, z), (0.024, 0.8, 0.56), PANEL, 0.008, mname="panel", parent=root)
box("rail_b", ((KX + X1) / 2, 0.92, Z0 + 0.03), (X1 - KX, 0.05, 0.06), TRIM, 0.012, parent=root)
box("rail_r", (X1 - 0.03, 0.92, (Z0 + Z1) / 2), (0.06, 0.05, Z1 - Z0), TRIM, 0.012, parent=root)
box("skirt_l", (X0 + 0.025, 0.05, (Z0 + Z1) / 2), (0.05, 0.1, Z1 - Z0), WOOD_D, 0.008, parent=root)
box("crown_b", (0, 2.86, Z0 + 0.04), (X1 - X0, 0.08, 0.08), TRIM, 0.015, parent=root)

# --------------------------------------------------------------------- window + door
box("win_frame_t", ((WX0 + WX1) / 2, WY1 + 0.04, Z0 + 0.05), (WX1 - WX0 + 0.16, 0.08, 0.1), TRIM, 0.015, parent=root)
box("win_frame_b", ((WX0 + WX1) / 2, WY0 - 0.04, Z0 + 0.08), (WX1 - WX0 + 0.24, 0.08, 0.16), TRIM, 0.015, parent=root)
for i, x in enumerate((WX0 - 0.04, WX1 + 0.04, (WX0 + WX1) / 2)):
    box("win_v_%d" % i, (x, (WY0 + WY1) / 2, Z0 + 0.05), (0.06 if i < 2 else 0.035, WY1 - WY0, 0.08), TRIM, 0.01, parent=root)
box("win_h", ((WX0 + WX1) / 2, (WY0 + WY1) / 2 + 0.1, Z0 + 0.04), (WX1 - WX0, 0.035, 0.05), TRIM, 0.008, parent=root)
box("win_glass", ((WX0 + WX1) / 2, (WY0 + WY1) / 2, Z0 + 0.02), (WX1 - WX0, WY1 - WY0, 0.01), "D8ECFF", 0.0, mname="window_glass", parent=root)
empty("mark_window", ((WX0 + WX1) / 2, (WY0 + WY1) / 2, Z0 - 0.02), root)
for s in (-1, 1):
    cx = (WX0 + WX1) / 2 + s * ((WX1 - WX0) / 2 + 0.2)
    for k in range(3):
        cyl("curtain_%d_%d" % (s, k), (cx - 0.08 + k * 0.08, (WY0 + WY1) / 2 + 0.02, Z0 + 0.14), 0.05, WY1 - WY0 + 0.35, "FFD6E2", 0.0, 16, parent=root)
box("curtain_rod", ((WX0 + WX1) / 2, WY1 + 0.2, Z0 + 0.14), (WX1 - WX0 + 0.9, 0.03, 0.03), WOOD_D, 0.01, parent=root)
for i, x in enumerate((WX0 + 0.5, WX1 - 0.5)):
    cyl("sill_pot_%d" % i, (x, WY0 + 0.06, Z0 + 0.12), 0.06, 0.1, POT, 0.006, r2=0.045, parent=root)
    for k in range(5):
        a = k * 1.26
        leaf_obj("sill_leaf_%d_%d" % (i, k), (x, WY0 + 0.12, Z0 + 0.12), (math.cos(a) * 0.5, 1.0, math.sin(a) * 0.5), 0.07, 0.035, LEAF if k % 2 else LEAF_D, parent=root)
box("door_frame_t", (X1 - 0.02, 2.17, 1.0), (0.12, 0.08, 1.12), TRIM, 0.012, parent=root)
for s in (-1, 1):
    box("door_frame_%d" % s, (X1 - 0.02, 1.08, 1.0 + s * 0.53), (0.12, 2.16, 0.08), TRIM, 0.012, parent=root)
for k in range(3):
    bpy.ops.mesh.primitive_plane_add(size=1, location=g2b(X1 - 0.08, 1.86, 0.68 + k * 0.32))
    o = bpy.context.active_object
    o.name = "noren_%d" % k
    o.scale = (0.012, 0.31, 0.48)
    bpy.ops.object.transform_apply(scale=True)
    o.rotation_euler = (0, math.pi / 2, 0)
    bpy.ops.object.transform_apply(rotation=True)
    sol = o.modifiers.new("s", "SOLIDIFY"); sol.thickness = 0.015
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier="s")
    finish(o, mat(NAVY), 0.0, parent=root)
box("noren_rod", (X1 - 0.08, 2.1, 1.0), (0.03, 0.03, 1.0), WOOD_D, 0.01, parent=root)
box("doormat", (X1 - 0.5, 0.005, 1.0), (0.6, 0.012, 0.9), "C8864E", 0.004, mname="mat_noline", parent=root)
empty("mark_door", (X1 - 0.4, 0, 1.0), root)
empty("mark_door_out", (X1 + 0.9, 0, 1.0), root)
empty("mark_spawn", (X1 - 0.8, 0, 1.0), root)

# --------------------------------------------------------------------- kitchen: back counter
BZ = -2.67
box("bc_top", ((-3.38 + -0.72) / 2, 0.89, BZ), (-0.72 + 3.38, 0.06, 0.66), "FFF4E2", 0.02, parent=root)
box("bc_body", ((-3.38 + -0.72) / 2, 0.44, BZ - 0.01), (-0.74 + 3.36, 0.86, 0.6), "FFD6C2", 0.015, parent=root)
for i in range(5):
    x = -3.1 + i * 0.52
    box("bc_door_%d" % i, (x, 0.45, BZ + 0.3), (0.46, 0.7, 0.02), "FFE3D4", 0.01, parent=root)
    sphere("bc_knob_%d" % i, (x + (0.17 if i % 2 else -0.17), 0.62, BZ + 0.315), 0.022, GOLD, parent=root)
for k, x in {"board": -3.0, "bowl": -2.42, "blender": -1.87, "mat": -1.32}.items():
    empty("mark_%s" % k, (x, 0.92, -2.62), root)
empty("mark_fridge", (-3.78, 0.0, -2.62), root)
obstacle(-2.46, -2.66, 3.48, 0.7)
for k, y in enumerate((1.55, 2.0)):
    box("kshelf_%d" % k, (-2.2, y, Z0 + 0.14), (1.8, 0.04, 0.24), WOOD, 0.01, parent=root)
jar_cols = ["FFD24A", "FF9EBB", "BDEBDD", "C3A6FF", "FFB86A"]
for j in range(6):
    jx = -2.95 + j * 0.3
    cyl("kjar_%d" % j, (jx, 1.57 + 0.08, Z0 + 0.14), 0.065, 0.16, jar_cols[j % 5], 0.01, parent=root)
    cyl("kjar_lbl_%d" % j, (jx, 1.57 + 0.07, Z0 + 0.14), 0.067, 0.06, "FFFFFF", 0.004, parent=root)
    cyl("kjar_lid_%d" % j, (jx, 1.57 + 0.17, Z0 + 0.14), 0.07, 0.03, WOOD_D, 0.008, parent=root)
for j in range(4):
    cyl("kcup_%d" % j, (-2.9 + j * 0.16, 2.02 + 0.05, Z0 + 0.14), 0.045, 0.09, ["FFFFFF", "FFC2D6", "BDEBDD", "FFE27A"][j], 0.01, parent=root)
sphere("kteapot", (-1.7, 2.02 + 0.09, Z0 + 0.14), 0.1, "A9C8FF", (1.1, 0.85, 1.0), parent=root)

# --------------------------------------------------------------------- kitchen: cooking island
IZ = -0.95
# the island stops short of the pass so there's a walkway into the back aisle
box("is_top", (-2.38, 0.89, IZ), (1.7, 0.06, 0.74), "FFF4E2", 0.02, parent=root)
box("is_body", (-2.38, 0.44, IZ), (1.64, 0.86, 0.68), "C3A6FF", 0.015, parent=root)
box("is_door", (-1.82, 0.45, IZ + 0.345), (0.42, 0.7, 0.02), "D7C8FF", 0.01, parent=root)
for k, x in {"pot": -2.95, "pan": -2.45, "micro": -1.86}.items():
    empty("mark_%s" % k, (x, 0.92, -0.98), root)
empty("mark_oven", (-2.7, 0.0, IZ + 0.37), root)
empty("mark_freezer", (-3.72, 0.0, -0.95), root)
empty("mark_bin", (-3.75, 0.0, 0.75), root)
obstacle(-2.38, -0.92, 1.72, 0.8)
obstacle(-3.72, -0.95, 0.66, 0.72)
obstacle(-3.75, 0.75, 0.5, 0.5)

# --------------------------------------------------------------------- the pass + bar
PX = -0.45
box("pass_top", (PX, 1.02, -1.66), (0.6, 0.06, 2.7), WOOD_L, 0.02, parent=root)
box("pass_body", (PX, 0.5, -1.66), (0.5, 0.98, 2.64), MINT, 0.02, parent=root)
for i in range(5):
    box("pass_slat_%d" % i, (PX + 0.255, 0.5, -2.75 + i * 0.52), (0.02, 0.8, 0.4), MINT_D, 0.008, parent=root)
box("bar_foot", (PX + 0.32, 0.12, -1.66), (0.04, 0.04, 2.5), GOLD, 0.01, parent=root)
empty("mark_pass", (PX, 1.05, -1.62), root)
obstacle(PX, -1.66, 0.62, 2.72)
for i, z in enumerate((-2.45, -1.75, -1.05)):
    x = PX + 0.62
    cyl("stool_seat_%d" % i, (x, 0.74, z), 0.19, 0.08, PINK, 0.03, parent=root)
    cyl("stool_leg_%d" % i, (x, 0.37, z), 0.035, 0.7, "C8C8D8", 0.005, 16, parent=root)
    cyl("stool_base_%d" % i, (x, 0.02, z), 0.17, 0.04, "C8C8D8", 0.01, parent=root)
    torus("stool_ring_%d" % i, (x, 0.3, z), 0.13, 0.012, "C8C8D8", parent=root)
    empty("mark_bar_%d" % i, (x, 0.0, z), root)
    obstacle(x, z, 0.42, 0.42)

for i, p in enumerate(((PX + 0.3, -1.75), (1.6, -1.4), (2.9, 0.4))):
    cyl("lamp_cord_%d" % i, (p[0], 2.5, p[1]), 0.006, 0.8, PLUM, 0.0, 8, parent=root)
    cyl("lamp_shade_%d" % i, (p[0], 2.02, p[1]), 0.2, 0.2, "FFE3D0" if i != 1 else "FFC2D6", 0.01, 32, r2=0.06, parent=root)
    sphere("lamp_bulb_%d" % i, (p[0], 1.92, p[1]), 0.06, "FFF0C8", mname="lamp_glow", parent=root)
    empty("mark_lamp_%d" % i, (p[0], 1.86, p[1]), root)

box("menu_board", (X1 - 0.04, 1.72, -1.5), (0.04, 0.7, 0.9), "2F3B37", 0.012, parent=root)
box("menu_frame", (X1 - 0.03, 1.72, -1.5), (0.03, 0.78, 0.98), WOOD, 0.012, parent=root)
empty("mark_menu", (X1 - 0.07, 1.72, -1.5), root)
cyl("clock", (X1 - 0.03, 2.2, -0.3), 0.2, 0.05, "FFFFFF", 0.01, 40, axis="x", parent=root)
cyl("clock_rim", (X1 - 0.02, 2.2, -0.3), 0.23, 0.04, SAKURA, 0.01, 40, axis="x", parent=root)
empty("mark_clock", (X1 - 0.065, 2.2, -0.3), root)
cyl("plant_pot", (X1 - 0.35, 0.2, 2.0), 0.2, 0.4, POT, 0.02, r2=0.15, parent=root)
for k in range(9):
    a = k * 0.7
    leaf_obj("plant_leaf_%d" % k, (X1 - 0.35, 0.42, 2.0), (math.cos(a) * 0.6, 1.0 + (k % 3) * 0.4, math.sin(a) * 0.6), 0.22, 0.11, LEAF if k % 2 else LEAF_D, parent=root)
obstacle(X1 - 0.35, 2.0, 0.5, 0.5)

merge_static(root)
export(OUT)
