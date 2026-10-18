"""Builds the shared shop interior and exports assets/models/shop.glb.

  blender -b -P tools/blender/build_shop.py -- <abs path to shop.glb>

One cosy shop room (counter at the back, a big window, wall shelves, the door on the right)
that the game dresses differently for the market, florist, bookshop, home store, boutique,
jeweller and clinic. Wall and floor surfaces are themable.
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib import *

OUT = (args() or ["shop.glb"])[0]
reset()
root = group("Shop")
X0, X1, Z0, Z1 = -3.8, 3.8, -2.8, 2.4
obs_n = [0]
def obstacle(cx, cz, w, d):
    empty("obs_%d_%.2f_%.2f" % (obs_n[0], w, d), (cx, 0, cz), root)
    obs_n[0] += 1

planks("floor_d", X0, X1, Z0, Z1, ["E8B87A", "E2AE6E", "ECC088", "DDA466"], root)
H = 3.0
WX0, WX1 = -3.2, -0.6
box("wall_back_a", ((X0 + WX0) / 2, H / 2, Z0 - 0.06), (WX0 - X0, H, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_back_b", ((WX1 + X1) / 2, H / 2, Z0 - 0.06), (X1 - WX1, H, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_back_low", ((WX0 + WX1) / 2, 0.5, Z0 - 0.06), (WX1 - WX0, 1.0, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_back_top", ((WX0 + WX1) / 2, (2.2 + H) / 2, Z0 - 0.06), (WX1 - WX0, H - 2.2, 0.12), WALL, 0.0, mname="wall_noline", parent=root)
box("win_glass", ((WX0 + WX1) / 2, 1.6, Z0 + 0.02), (WX1 - WX0, 1.2, 0.01), "D8ECFF", 0.0, mname="window_glass", parent=root)
box("win_sill", ((WX0 + WX1) / 2, 0.97, Z0 + 0.1), (WX1 - WX0 + 0.2, 0.06, 0.2), TRIM, 0.01, parent=root)
box("win_top", ((WX0 + WX1) / 2, 2.23, Z0 + 0.05), (WX1 - WX0 + 0.12, 0.06, 0.08), TRIM, 0.01, parent=root)
box("win_mid", ((WX0 + WX1) / 2, 1.6, Z0 + 0.05), (0.04, 1.2, 0.08), TRIM, 0.01, parent=root)
empty("mark_window", ((WX0 + WX1) / 2, 1.6, Z0 - 0.02), root)
box("wall_left", (X0 - 0.06, H / 2, (Z0 + Z1) / 2), (0.12, H, Z1 - Z0 + 0.12), WALL, 0.0, mname="wall_noline", parent=root)
DZ0, DZ1 = 0.7, 1.7
box("wall_right_a", (X1 + 0.06, H / 2, (Z0 + DZ0) / 2), (0.12, H, DZ0 - Z0), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_right_b", (X1 + 0.06, H / 2, (DZ1 + Z1) / 2), (0.12, H, Z1 - DZ1), WALL, 0.0, mname="wall_noline", parent=root)
box("wall_right_t", (X1 + 0.06, 2.6, 1.2), (0.12, 0.8, DZ1 - DZ0), WALL, 0.0, mname="wall_noline", parent=root)
box("wainscot", (0, 0.45, Z0 + 0.03), (X1 - X0, 0.9, 0.04), PANEL, 0.006, mname="panel_noline", parent=root)
box("wainscot_cap", (0, 0.92, Z0 + 0.05), (X1 - X0, 0.04, 0.07), TRIM, 0.006, parent=root)
box("crown", (0, H - 0.04, Z0 + 0.04), (X1 - X0, 0.08, 0.08), TRIM, 0.015, parent=root)
# counter at the back right, with a till and a little bell
CX, CZ = 1.9, -1.55
box("counter_top", (CX, 0.72, CZ), (2.6, 0.06, 0.7), WOOD_L, 0.02, parent=root)
box("counter_body", (CX, 0.35, CZ), (2.5, 0.7, 0.62), WOOD, 0.02, parent=root)
for i in range(5):
    box("counter_slat_%d" % i, (CX - 1.0 + i * 0.5, 0.35, CZ + 0.315), (0.04, 0.56, 0.02), WOOD_D, 0.005, parent=root)
box("till", (CX + 0.8, 0.85, CZ - 0.05), (0.36, 0.22, 0.3), "FF9EBB", 0.03, parent=root)
box("till_screen", (CX + 0.8, 0.97, CZ + 0.06), (0.24, 0.1, 0.02), "BDEBDD", 0.01, mname="screen_glow", parent=root)
cyl("bell_base", (CX - 0.9, 0.76, CZ + 0.15), 0.06, 0.02, GOLD, 0.005, 16, parent=root)
sphere("bell", (CX - 0.9, 0.8, CZ + 0.15), 0.045, GOLD, (1, 0.8, 1), parent=root)
# a little step behind the counter so the shopkeeper can see over it
box("keeper_step", (CX, 0.17, CZ - 0.62), (2.4, 0.34, 0.55), WOOD_D, 0.02, parent=root)
obstacle(CX, CZ, 2.6, 0.7)
empty("mark_keeper", (CX, 0, CZ - 0.65), root)
empty("mark_counter", (CX, 0, CZ + 0.85), root)
# wall shelves on the back right and the left wall
for k, y in enumerate((1.45, 1.95, 2.45)):
    box("shelf_back_%d" % k, (CX, y, Z0 + 0.16), (2.8, 0.04, 0.28), WOOD, 0.01, parent=root)
    box("shelf_left_%d" % k, (X0 + 0.16, y, -0.6), (0.28, 0.04, 2.6), WOOD, 0.01, parent=root)
    empty("mark_shelf_back_%d" % k, (CX, y + 0.02, Z0 + 0.16), root)
    empty("mark_shelf_left_%d" % k, (X0 + 0.16, y + 0.02, -0.6), root)
# door, mat, lights
for s in (-1, 1):
    box("door_frame_%d" % s, (X1 - 0.02, 1.08, 1.2 + s * 0.53), (0.12, 2.16, 0.08), TRIM, 0.012, parent=root)
box("door_frame_t", (X1 - 0.02, 2.17, 1.2), (0.12, 0.08, 1.12), TRIM, 0.012, parent=root)
box("door_mat", (X1 - 0.45, 0.005, 1.2), (0.55, 0.012, 0.85), "FF9EBB", 0.004, mname="mat_noline", parent=root)
empty("mark_door", (X1 - 0.4, 0, 1.2), root)
empty("mark_spawn", (X1 - 0.8, 0, 1.2), root)
for i, (x, z) in enumerate(((-1.8, -0.4), (1.6, 0.4))):
    cyl("lamp_shade_%d" % i, (x, 2.6, z), 0.28, 0.2, "FFE3D0", 0.02, 32, r2=0.08, parent=root)
    cyl("lamp_cord_%d" % i, (x, 2.85, z), 0.006, 0.3, PLUM, 0.0, 8, parent=root)
    empty("mark_lamp_%d" % i, (x, 2.4, z), root)
# floor display spots the game fills with goods
for i, (x, z) in enumerate(((-2.6, 0.9), (-1.0, 0.9), (0.6, 0.9), (-2.6, -1.2), (-1.0, -1.2), (2.6, 1.6))):
    empty("mark_disp_%d" % i, (x, 0, z), root)

merge_static(root)
export(OUT)
