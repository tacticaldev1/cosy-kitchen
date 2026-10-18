"""Builds your apartment interior and exports assets/models/home.glb.

  blender -b -P tools/blender/build_home.py -- <abs path to home.glb>

A cosy studio flat: a little kitchenette on the back wall, a big window with the town at
night, a bathroom door, and an empty floor for the furniture you buy.
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib import *

OUT = (args() or ["home.glb"])[0]
reset()
root = group("Home")
X0, X1, Z0, Z1 = -3.6, 3.6, -2.7, 2.4
obs_n = [0]
def obstacle(cx, cz, w, d):
    empty("obs_%d_%.2f_%.2f" % (obs_n[0], w, d), (cx, 0, cz), root)
    obs_n[0] += 1

planks("floor_d", X0, X1, Z0, Z1, ["E8B87A", "E2AE6E", "ECC088", "DDA466"], root)
WX0, WX1, WY0, WY1 = -0.6, 2.4, 1.0, 2.15
box("wall_back_l", ((X0 + WX0) / 2, 1.4, Z0 - 0.06), (WX0 - X0 + 0.12, 2.8, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_back_r", ((WX1 + X1) / 2, 1.4, Z0 - 0.06), (X1 - WX1 + 0.12, 2.8, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_back_b", ((WX0 + WX1) / 2, WY0 / 2, Z0 - 0.06), (WX1 - WX0, WY0, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_back_t", ((WX0 + WX1) / 2, (WY1 + 2.8) / 2, Z0 - 0.06), (WX1 - WX0, 2.8 - WY1, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_left", (X0 - 0.06, 1.4, (Z0 + Z1) / 2), (0.12, 2.8, Z1 - Z0 + 0.12), WALL, 0.0, mname="wall_noline", parent=root)
DZ0, DZ1 = 0.7, 1.7
box("wall_right_a", (X1 + 0.06, 1.4, (Z0 + DZ0) / 2), (0.12, 2.8, DZ0 - Z0), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_right_b", (X1 + 0.06, 1.4, (DZ1 + Z1) / 2), (0.12, 2.8, Z1 - DZ1), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_right_t", (X1 + 0.06, 2.5, 1.2), (0.12, 0.6, DZ1 - DZ0), WALL, 0.0, mname="wall_noline", parent=root)
box("skirt_b", (0, 0.05, Z0 + 0.025), (X1 - X0, 0.1, 0.05), TRIM, 0.008, parent=root)
box("skirt_l", (X0 + 0.025, 0.05, (Z0 + Z1) / 2), (0.05, 0.1, Z1 - Z0), TRIM, 0.008, parent=root)
box("crown", (0, 2.76, Z0 + 0.04), (X1 - X0, 0.08, 0.08), TRIM, 0.015, parent=root)
# window with the town view
for i, x in enumerate((WX0 - 0.04, WX1 + 0.04, (WX0 + WX1) / 2)):
    box("win_v_%d" % i, (x, (WY0 + WY1) / 2, Z0 + 0.05), (0.06 if i < 2 else 0.035, WY1 - WY0, 0.08), TRIM, 0.01, parent=root)
box("win_t", ((WX0 + WX1) / 2, WY1 + 0.03, Z0 + 0.05), (WX1 - WX0 + 0.12, 0.06, 0.08), TRIM, 0.01, parent=root)
box("win_b", ((WX0 + WX1) / 2, WY0 - 0.03, Z0 + 0.09), (WX1 - WX0 + 0.2, 0.06, 0.18), TRIM, 0.01, parent=root)
box("win_glass", ((WX0 + WX1) / 2, (WY0 + WY1) / 2, Z0 + 0.02), (WX1 - WX0, WY1 - WY0, 0.01), "D8ECFF", 0.0, mname="window_glass", parent=root)
empty("mark_window", ((WX0 + WX1) / 2, (WY0 + WY1) / 2, Z0 - 0.02), root)
for s in (-1, 1):
    cx = (WX0 + WX1) / 2 + s * ((WX1 - WX0) / 2 + 0.2)
    for k in range(3):
        cyl("curtain_%d_%d" % (s, k), (cx - 0.08 + k * 0.08, (WY0 + WY1) / 2, Z0 + 0.14), 0.05, WY1 - WY0 + 0.4, "C3A6FF", 0.0, 16, parent=root)
# kitchenette on the back-left
box("kit_top", (-2.5, 0.89, -2.4), (2.0, 0.06, 0.62), "FFF4E2", 0.02, parent=root)
box("kit_body", (-2.5, 0.44, -2.41), (1.96, 0.86, 0.58), "BDEBDD", 0.015, parent=root)
box("kit_sink", (-2.0, 0.9, -2.4), (0.5, 0.04, 0.4), "C8C8D8", 0.01, parent=root)
cyl("kit_tap", (-2.0, 1.05, -2.6), 0.02, 0.3, "C8C8D8", 0.005, 8, parent=root)
box("kit_hob", (-3.0, 0.925, -2.4), (0.6, 0.02, 0.45), "3B3550", 0.01, parent=root)
box("kit_shelf", (-2.5, 1.7, Z0 + 0.14), (1.8, 0.04, 0.24), WOOD, 0.01, parent=root)
for j in range(5):
    cyl("kit_jar_%d" % j, (-3.2 + j * 0.35, 1.8, Z0 + 0.14), 0.06, 0.16, ["FFD24A", "FF9EBB", "BDEBDD", "C3A6FF", "FFB86A"][j], 0.01, parent=root)
cyl("kit_kettle", (-2.9, 1.0, -2.4), 0.1, 0.16, "FF9EBB", 0.03, 20, parent=root)
obstacle(-2.5, -2.42, 2.05, 0.7)
empty("mark_kitchen", (-2.5, 0, -1.8), root)
# bathroom door on the left wall
box("bath_door", (X0 + 0.04, 1.0, -0.4), (0.06, 2.0, 0.9), "FFE3D4", 0.02, parent=root)
box("bath_frame", (X0 + 0.03, 1.05, -0.4), (0.05, 2.12, 1.04), TRIM, 0.02, parent=root)
sphere("bath_knob", (X0 + 0.1, 1.0, -0.05), 0.035, GOLD, parent=root)
# front door + coat hooks
box("door_frame_t", (X1 - 0.02, 2.17, 1.2), (0.12, 0.08, 1.12), TRIM, 0.012, parent=root)
for s in (-1, 1):
    box("door_frame_%d" % s, (X1 - 0.02, 1.08, 1.2 + s * 0.53), (0.12, 2.16, 0.08), TRIM, 0.012, parent=root)
box("door_mat", (X1 - 0.45, 0.005, 1.2), (0.55, 0.012, 0.85), "FF9EBB", 0.004, mname="mat_noline", parent=root)
empty("mark_door", (X1 - 0.4, 0, 1.2), root)
empty("mark_spawn", (X1 - 0.8, 0, 1.2), root)
for k in range(3):
    sphere("hook_%d" % k, (X1 - 0.04, 1.6, -0.4 + k * 0.25), 0.03, GOLD, parent=root)
# pictures on the wall
for i, (x, c) in enumerate(((-1.5, "FFC2D6"), (2.95, "BDEBDD"))):
    box("pic_%d" % i, (x, 1.75, Z0 + 0.03), (0.6, 0.5, 0.03), "FFFFFF", 0.01, parent=root)
    box("pic_in_%d" % i, (x, 1.75, Z0 + 0.05), (0.48, 0.38, 0.01), c, 0.0, parent=root)
cyl("ceiling_lamp", (0.5, 2.6, -0.2), 0.3, 0.18, "FFE3D0", 0.02, 32, r2=0.1, parent=root)
empty("mark_lamp_0", (0.5, 2.4, -0.2), root)

merge_static(root)
export(OUT)
