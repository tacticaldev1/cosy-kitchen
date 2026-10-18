"""Builds the house you can buy (a roomy two-room home) and exports assets/models/house.glb.

  blender -b -P tools/blender/build_house.py -- <abs path to house.glb>

A living room with a kitchen along the back, a bedroom behind a half wall on the left, two
big windows, a fireplace nook and the front door on the right.
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib import *

OUT = (args() or ["house.glb"])[0]
reset()
root = group("House")
X0, X1, Z0, Z1 = -5.2, 5.2, -3.4, 3.0
obs_n = [0]
def obstacle(cx, cz, w, d):
    empty("obs_%d_%.2f_%.2f" % (obs_n[0], w, d), (cx, 0, cz), root)
    obs_n[0] += 1

planks("floor_d", X0, X1, Z0, Z1, ["E8B87A", "E2AE6E", "ECC088", "DDA466"], root)
H = 2.9
# back wall with two windows
WINS = [(-3.4, -1.6), (0.6, 3.0)]
edges = [X0] + [x for w in WINS for x in w] + [X1]
for i in range(0, len(edges), 2):
    a, b = edges[i], edges[i + 1]
    box("wall_back_%d" % i, ((a + b) / 2, H / 2, Z0 - 0.06), (b - a + 0.02, H, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
for k, (a, b) in enumerate(WINS):
    box("wall_back_low_%d" % k, ((a + b) / 2, 0.5, Z0 - 0.06), (b - a, 1.0, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
    box("wall_back_top_%d" % k, ((a + b) / 2, (2.2 + H) / 2, Z0 - 0.06), (b - a, H - 2.2, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
    box("win_glass_%d" % k, ((a + b) / 2, 1.6, Z0 + 0.02), (b - a, 1.2, 0.01), "D8ECFF", 0.0, mname="window_glass", parent=root)
    box("win_sill_%d" % k, ((a + b) / 2, 0.98, Z0 + 0.09), (b - a + 0.2, 0.06, 0.18), TRIM, 0.01, parent=root)
    box("win_top_%d" % k, ((a + b) / 2, 2.23, Z0 + 0.05), (b - a + 0.12, 0.06, 0.08), TRIM, 0.01, parent=root)
    box("win_mid_%d" % k, ((a + b) / 2, 1.6, Z0 + 0.05), (0.04, 1.2, 0.08), TRIM, 0.01, parent=root)
    for s in (-1, 1):
        box("win_side_%d_%d" % (k, s), ((a + b) / 2 + s * (b - a) / 2, 1.6, Z0 + 0.05), (0.06, 1.26, 0.08), TRIM, 0.01, parent=root)
        for c in range(3):
            cyl("curtain_%d_%d_%d" % (k, s, c), ((a + b) / 2 + s * ((b - a) / 2 + 0.18) - 0.07 + c * 0.07, 1.6, Z0 + 0.14), 0.045, 1.6, "FFC2D6", 0.0, 14, parent=root)
    empty("mark_window_%d" % k, ((a + b) / 2, 1.6, Z0 - 0.02), root)
box("wall_left", (X0 - 0.06, H / 2, (Z0 + Z1) / 2), (0.12, H, Z1 - Z0 + 0.12), WALL, 0.0, mname="wall_noline", parent=root)
DZ0, DZ1 = 1.2, 2.2
box("wall_right_a", (X1 + 0.06, H / 2, (Z0 + DZ0) / 2), (0.12, H, DZ0 - Z0), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_right_b", (X1 + 0.06, H / 2, (DZ1 + Z1) / 2), (0.12, H, Z1 - DZ1), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_right_t", (X1 + 0.06, 2.55, 1.7), (0.12, 0.7, DZ1 - DZ0), WALL, 0.0, mname="wall_noline", parent=root)
# half wall between living room and bedroom (with a doorway)
PX = -1.3
box("part_a", (PX, 1.1, (Z0 + -0.4) / 2), (0.12, 2.2, -0.4 - Z0), "FFE3D4", 0.01, mname="panel_noline", parent=root)
box("part_b", (PX, 1.1, (0.8 + Z1) / 2 - 0.2), (0.12, 2.2, Z1 - 0.8 - 0.4), "FFE3D4", 0.01, mname="panel_noline", parent=root)
box("part_cap", (PX, 2.22, (Z0 + Z1) / 2 - 0.2), (0.16, 0.05, Z1 - Z0 - 0.4), TRIM, 0.01, parent=root)
obstacle(PX, (Z0 + -0.4) / 2, 0.14, -0.4 - Z0)
obstacle(PX, (0.8 + Z1) / 2 - 0.2, 0.14, Z1 - 0.8 - 0.4)
box("skirt_b", (0, 0.05, Z0 + 0.025), (X1 - X0, 0.1, 0.05), TRIM, 0.008, parent=root)
box("crown", (0, H - 0.04, Z0 + 0.04), (X1 - X0, 0.08, 0.08), TRIM, 0.015, parent=root)
# kitchen along the back right
KX0, KX1 = 3.2, 5.1
box("kit_top", (4.8, 0.89, -1.4), (0.62, 0.06, 2.6), "FFF4E2", 0.02, parent=root)
box("kit_body", (4.81, 0.44, -1.4), (0.58, 0.86, 2.56), "BDEBDD", 0.015, parent=root)
box("kit_sink", (4.8, 0.9, -0.7), (0.4, 0.04, 0.5), "C8C8D8", 0.01, parent=root)
box("kit_hob", (4.8, 0.925, -2.0), (0.45, 0.02, 0.6), "3B3550", 0.01, parent=root)
cyl("kit_kettle", (4.8, 1.0, -2.2), 0.1, 0.16, "FF9EBB", 0.03, 20, parent=root)
obstacle(4.8, -1.4, 0.7, 2.65)
empty("mark_kitchen", (4.1, 0, -1.4), root)
# fireplace nook on the back wall
box("fire_body", (-0.4, 0.6, Z0 + 0.25), (1.4, 1.2, 0.5), "E8D2C2", 0.03, parent=root)
box("fire_hole", (-0.4, 0.45, Z0 + 0.5), (0.8, 0.6, 0.02), "3B2340", 0.0, mname="hole_noline", parent=root)
box("fire_mantel", (-0.4, 1.25, Z0 + 0.3), (1.6, 0.08, 0.6), WOOD, 0.02, parent=root)
for k in range(3):
    sphere("fire_flame_%d" % k, (-0.6 + k * 0.2, 0.32, Z0 + 0.4), 0.09, ["FFB84A", "FF7E4A", "FFD24A"][k], (1, 1.4, 1), mname="flame_glow", parent=root)
empty("mark_fire", (-0.4, 0.5, Z0 + 0.6), root)
obstacle(-0.4, Z0 + 0.25, 1.5, 0.55)
# front door, coat hooks, pictures, lamps
for s in (-1, 1):
    box("door_frame_%d" % s, (X1 - 0.02, 1.08, 1.7 + s * 0.53), (0.12, 2.16, 0.08), TRIM, 0.012, parent=root)
box("door_mat", (X1 - 0.45, 0.005, 1.7), (0.55, 0.012, 0.85), "FF9EBB", 0.004, mname="mat_noline", parent=root)
empty("mark_door", (X1 - 0.4, 0, 1.7), root)
empty("mark_spawn", (X1 - 0.8, 0, 1.7), root)
for i, (x, c) in enumerate(((-4.4, "FFC2D6"), (-2.4, "BDEBDD"), (1.6, "FFE89A"))):
    box("pic_%d" % i, (x, 1.75 if x > -3 else 1.9, Z0 + 0.03), (0.55, 0.45, 0.03), "FFFFFF", 0.01, parent=root)
    box("pic_in_%d" % i, (x, 1.75 if x > -3 else 1.9, Z0 + 0.05), (0.44, 0.34, 0.01), c, 0.0, parent=root)
for i, (x, z) in enumerate(((1.5, -0.3), (-3.3, 0.0))):
    cyl("ceiling_lamp_%d" % i, (x, H - 0.25, z), 0.3, 0.18, "FFE3D0", 0.02, 32, r2=0.1, parent=root)
    empty("mark_lamp_%d" % i, (x, H - 0.45, z), root)

merge_static(root)
export(OUT)
