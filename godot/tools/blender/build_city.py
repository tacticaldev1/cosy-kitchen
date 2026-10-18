"""Builds Hoshizora Town (the street outside the café) and exports assets/models/city.glb.

  blender -b -P tools/blender/build_city.py -- <abs path to city.glb>

A row of shop fronts faces the camera along the north side of a cobbled street; the park with
cherry trees, a fountain and benches lies to the south. Exports mark_door_<shop> (standing
point in front of each door), mark_sign_<shop>, mark_spot_<npc>, mark_bench_<i>,
mark_lamp_<i> and obs_* obstacles.
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib import *

OUT = (args() or ["city.glb"])[0]
reset()
root = group("City")
obs_n = [0]
def obstacle(cx, cz, w, d):
    empty("obs_%d_%.2f_%.2f" % (obs_n[0], w, d), (cx, 0, cz), root)
    obs_n[0] += 1

# --------------------------------------------------------------------- ground
box("grass", (0, -0.08, 2), (70, 0.1, 40), "8CCB6E", 0.0, mname="grass_noline", parent=root)
box("road", (0, -0.02, 0), (60, 0.04, 4.0), "B9B2CC", 0.0, mname="road_noline", parent=root)
for i in range(30):
    box("road_line_%d" % i, (-29 + i * 2.0, 0.002, 0), (1.0, 0.01, 0.12), "FFFFFF", 0.0, mname="line_noline", parent=root)
box("walk_n", (0, -0.01, -3.1), (60, 0.06, 2.2), "EDB9A8", 0.0, mname="walk_noline", parent=root)
for i in range(60):
    box("curb_n_%d" % i, (-29.5 + i, 0.03, -2.0), (0.96, 0.08, 0.14), "FFE9DC", 0.004, mname="curb", parent=root)
box("walk_s", (0, -0.01, 2.7), (60, 0.06, 1.4), "EDB9A8", 0.0, mname="walk_noline", parent=root)
for i in range(60):
    box("curb_s_%d" % i, (-29.5 + i, 0.03, 2.0), (0.96, 0.08, 0.14), "FFE9DC", 0.004, mname="curb", parent=root)

# --------------------------------------------------------------------- shop fronts (north side)
SHOPS = [
    ("home", -20.5, 7.0, 7.6, "F7C9B5", "9C86E0", "C3A6FF"),
    ("market", -12.6, 6.0, 4.2, "B8E6CF", "4FA873", "8ED16B"),
    ("homestore", -6.3, 5.6, 4.6, "FCE3A0", "D98A34", "FFC93C"),
    ("cafe", 0.0, 6.6, 5.0, "FFC6D8", "F0628F", "FF8AB0"),
    ("boutique", 6.6, 5.2, 4.6, "D9C9FF", "7563C0", "B49AF5"),
    ("florist", 12.2, 5.2, 4.2, "CDEFC0", "4F9E47", "FF8AB0"),
    ("jeweler", 17.6, 4.6, 4.8, "C6DCFF", "4F72C8", "8DB4FF"),
    ("bookshop", 23.0, 5.4, 4.4, "EED2A8", "93603A", "E0A464"),
]
FZ = -4.2
for sid, x, w, h, wall, roof, awn in SHOPS:
    g = group("grp_" + sid)
    g.parent = root
    box(sid + "_body", (x, h / 2, FZ - 3.0), (w, h, 6.0), wall, 0.03, parent=g)
    box(sid + "_base", (x, 0.25, FZ - 0.02), (w + 0.1, 0.5, 0.12), "E8D2C2", 0.02, parent=g)
    if sid == "home":
        box(sid + "_roof", (x, h + 0.15, FZ - 3.0), (w + 0.3, 0.3, 6.3), roof, 0.04, parent=g)
        for fl in range(3):
            for k in range(4):
                if fl == 0 and k in (1, 2):
                    continue
                wx = x - 2.4 + k * 1.6
                wy = 1.4 + fl * 2.3
                box("%s_win_%d_%d" % (sid, fl, k), (wx, wy, FZ + 0.02), (0.9, 1.1, 0.08), "FFF6D2", 0.02, mname="win_glow", parent=g)
                box("%s_winf_%d_%d" % (sid, fl, k), (wx, wy, FZ + 0.01), (1.04, 1.24, 0.06), "FFFFFF", 0.02, parent=g)
                box("%s_sill_%d_%d" % (sid, fl, k), (wx, wy - 0.62, FZ + 0.12), (1.1, 0.06, 0.24), roof, 0.02, parent=g)
                if fl > 0:
                    box("%s_box_%d_%d" % (sid, fl, k), (wx, wy - 0.52, FZ + 0.18), (0.9, 0.18, 0.2), "C8864E", 0.02, parent=g)
                    for f in range(4):
                        sphere("%s_fl_%d_%d_%d" % (sid, fl, k, f), (wx - 0.3 + f * 0.2, wy - 0.38, FZ + 0.2), 0.07, ["FF7EA6", "FFD24A", "FFFFFF", "C3A6FF"][f], parent=g)
    else:
        # a cute pitched roof
        bpy.ops.mesh.primitive_cylinder_add(vertices=3, radius=1.0, depth=w + 0.5, location=g2b(x, h + 0.55, FZ - 3.0))
        o = bpy.context.active_object
        o.name = sid + "_roof"
        o.scale = (1.0, 1.0, 1.0)
        o.rotation_euler = (0, math.pi / 2, 0)
        bpy.ops.object.transform_apply(rotation=True)
        o.scale = (1.0, 3.6, 0.75)
        bpy.ops.object.transform_apply(scale=True)
        finish(o, mat(roof), 0.03, parent=g)
        # shop window(s)
        for s in (-1, 1):
            wx = x + s * (w * 0.28)
            ww = w * 0.3
            box("%s_shopwin_%d" % (sid, s), (wx, 1.45, FZ + 0.02), (ww, 1.5, 0.08), "BFDDF2", 0.02, mname="shopglass", parent=g)
            box("%s_shopwinf_%d" % (sid, s), (wx, 1.45, FZ + 0.01), (ww + 0.16, 1.66, 0.06), "FFFFFF", 0.02, parent=g)
            for k in range(2):
                box("%s_streak_%d_%d" % (sid, s, k), (wx - ww * 0.18 + k * 0.16, 1.62 - k * 0.1, FZ + 0.065), (0.06 - k * 0.025, 0.7, 0.01), "FFFFFF", 0.0, mname="streak_noline", parent=g, rot=(0, 0, -0.6))
            box("%s_shelf_%d" % (sid, s), (wx, 0.95, FZ + 0.1), (ww, 0.05, 0.16), "FFFFFF", 0.01, parent=g)
            disp = {"market": ["F2545B", "FFE24A", "8ED16B"], "homestore": ["E8B87A", "FF9EBB", "A9C8FF"], "cafe": ["FFC2D6", "FFF4E2", "C8864E"], "boutique": ["C3A6FF", "FF9EBB", "FFFFFF"],
                    "florist": ["FF7EA6", "FFD24A", "FFFFFF"], "jeweler": ["FFD24A", "A9C8FF", "FFFFFF"], "bookshop": ["6A8AD8", "E8504A", "7FD3B8"]}.get(sid, ["FFFFFF"] * 3)
            for k in range(3):
                dx = wx - ww * 0.3 + k * ww * 0.3
                if sid in ("bookshop", "homestore"):
                    box("%s_disp_%d_%d" % (sid, s, k), (dx, 1.1, FZ + 0.12), (0.12, 0.26, 0.1), disp[k], 0.01, parent=g)
                else:
                    sphere("%s_disp_%d_%d" % (sid, s, k), (dx, 1.06, FZ + 0.12), 0.09, disp[k], parent=g)
        # upper window
        box("%s_upwin" % sid, (x, h - 1.0, FZ + 0.02), (1.2, 0.9, 0.08), "FFF6D2", 0.02, mname="win_glow", parent=g)
        box("%s_upwinf" % sid, (x, h - 1.0, FZ + 0.01), (1.34, 1.04, 0.06), "FFFFFF", 0.02, parent=g)
    # door
    box(sid + "_door", (x, 1.05, FZ + 0.03), (1.0, 2.1, 0.1), "C8864E", 0.02, parent=g)
    box(sid + "_doorwin", (x, 1.5, FZ + 0.09), (0.5, 0.6, 0.02), "FFE6B0", 0.01, mname="door_glow", parent=g)
    box(sid + "_doorframe", (x, 1.1, FZ + 0.015), (1.2, 2.3, 0.06), "FFFFFF", 0.02, parent=g)
    sphere(sid + "_knob", (x + 0.35, 1.0, FZ + 0.1), 0.04, GOLD, parent=g)
    # striped awning
    stripes = 8
    aw = w * 0.9
    for i in range(stripes):
        sx = x - aw / 2 + (i + 0.5) * aw / stripes
        box("%s_awn_%d" % (sid, i), (sx, 2.75, FZ + 0.55), (aw / stripes + 0.005, 0.08, 1.15), awn if i % 2 else "FFFFFF", 0.0, parent=g, rot=(0.38, 0, 0))
    for i in range(stripes):
        sx = x - aw / 2 + (i + 0.5) * aw / stripes
        sphere("%s_scal_%d" % (sid, i), (sx, 2.5, FZ + 1.1), aw / stripes * 0.5, awn if i % 2 else "FFFFFF", (1, 0.6, 0.4), parent=g)
    # sign board
    box(sid + "_signb", (x, 3.45 if sid != "home" else 2.6, FZ + 0.06), (min(w - 0.6, 3.4), 0.6, 0.08), "FFFDF6", 0.03, parent=g)
    empty("mark_sign_" + sid, (x, 3.45 if sid != "home" else 2.6, FZ + 0.12), root)
    empty("mark_door_" + sid, (x, 0, FZ + 0.75), root)
    # planters either side of the door
    for s in (-1, 1):
        px = x + s * 1.0
        box("%s_planter_%d" % (sid, s), (px, 0.22, FZ + 0.4), (0.5, 0.44, 0.5), "E8826A", 0.03, parent=g)
        for f in range(5):
            a = f * 1.25
            sphere("%s_bush_%d_%d" % (sid, s, f), (px + math.cos(a) * 0.12, 0.52 + (f % 2) * 0.06, FZ + 0.4 + math.sin(a) * 0.12), 0.13, LEAF if f % 2 else LEAF_D, parent=g)
        sphere("%s_bloom_%d" % (sid, s), (px, 0.66, FZ + 0.42), 0.07, ["FF7EA6", "FFD24A"][s > 0], parent=g)
        obstacle(px, FZ + 0.4, 0.55, 0.55)
    # little extras per shop
    if sid == "market":
        for k in range(3):
            box("crate_%d" % k, (x - 2.0 + k * 0.7, 0.25, FZ + 0.7), (0.6, 0.5, 0.5), "C8864E", 0.02, parent=g)
            for f in range(4):
                sphere("fruit_%d_%d" % (k, f), (x - 2.15 + k * 0.7 + (f % 2) * 0.3, 0.55, FZ + 0.6 + (f // 2) * 0.2), 0.09, ["F2545B", "FF9F2E", "FFE24A"][k], parent=g)
        obstacle(x - 1.3, FZ + 0.7, 2.1, 0.55)
    if sid == "florist":
        for k in range(4):
            cyl("bucket_%d" % k, (x + 1.4 + (k % 2) * 0.4, 0.2, FZ + 0.6 + (k // 2) * 0.35), 0.15, 0.4, "A9C8FF", 0.01, parent=g)
            for f in range(5):
                sphere("fb_%d_%d" % (k, f), (x + 1.4 + (k % 2) * 0.4 + math.cos(f) * 0.08, 0.5, FZ + 0.6 + (k // 2) * 0.35 + math.sin(f) * 0.08), 0.06, ["FF7EA6", "FFFFFF", "FFD24A", "C3A6FF"][k], parent=g)
        obstacle(x + 1.6, FZ + 0.78, 0.9, 0.8)
    if sid == "cafe":
        for s in (-1, 1):
            box("cafe_lantern_%d" % s, (x + s * 0.85, 2.2, FZ + 0.25), (0.22, 0.32, 0.22), "FF6A6A", 0.06, mname="lantern_glow", parent=g)
    if sid == "bookshop":
        box("book_cart", (x + 1.8, 0.4, FZ + 0.7), (0.9, 0.8, 0.5), "A8704A", 0.02, parent=g)
        obstacle(x + 1.8, FZ + 0.7, 0.95, 0.55)

# alleys between shops filled with walls so the row reads as one street
box("backdrop", (0, 4, -10.5), (64, 8, 0.2), "E6D2EE", 0.0, mname="sky_noline", parent=root)

# --------------------------------------------------------------------- street lamps and trees
for i, x in enumerate(range(-26, 28, 6)):
    for side, z in (("n", -2.5), ("s", 2.5)):
        if side == "s" and -11 < x < 11:
            continue
        cyl("lamp_post_%s_%d" % (side, i), (x, 1.5, z), 0.06, 3.0, "3B3550", 0.01, 12, parent=root)
        sphere("lamp_head_%s_%d" % (side, i), (x, 3.08, z), 0.2, "FFF0C8", mname="lamp_glow", parent=root)
        cyl("lamp_cap_%s_%d" % (side, i), (x, 3.28, z), 0.16, 0.08, "3B3550", 0.01, 12, parent=root)
        empty("mark_lamp_%s_%d" % (side, i), (x, 2.9, z), root)
        obstacle(x, z, 0.3, 0.3)

def tree(name, x, z, pink=False, s=1.0):
    cyl(name + "_trunk", (x, 0.9 * s, z), 0.14 * s, 1.8 * s, "A8704A", 0.02, 12, parent=root)
    cols = ["FFC2D6", "FFB0CA", "FFD6E2"] if pink else ["8ED16B", "6BBF59", "A8D888"]
    for k in range(6):
        a = k * 1.05
        sphere(name + "_c%d" % k, (x + math.cos(a) * 0.55 * s, (2.1 + (k % 3) * 0.25) * s, z + math.sin(a) * 0.5 * s), 0.6 * s, cols[k % 3], parent=root)
    sphere(name + "_ct", (x, 2.7 * s, z), 0.7 * s, cols[0], parent=root)
    obstacle(x, z, 0.45 * s, 0.45 * s)

for x in (-25, -16.5, 15.5, 25):
    tree("st_tree_%d" % x, x, 3.4, pink=False, s=0.9)

# --------------------------------------------------------------------- the park
box("park_grass", (0, -0.03, 8.5), (20, 0.04, 9.0), "A3DA86", 0.0, mname="park_noline", parent=root)
box("park_path", (0, -0.01, 8.5), (2.0, 0.04, 9.0), "F0D2B0", 0.0, mname="path_noline", parent=root)
cyl("path_ring", (0, -0.008, 8.5), 2.6, 0.04, "F0D2B0", 0.0, 48, mname="path2_noline", parent=root)
# fountain
cyl("fountain_base", (0, 0.25, 8.5), 1.4, 0.5, "E8E2F2", 0.03, 40, parent=root)
cyl("fountain_water", (0, 0.46, 8.5), 1.25, 0.06, "9BD8F0", 0.0, 40, mname="water_glow", parent=root)
cyl("fountain_mid", (0, 0.9, 8.5), 0.25, 0.9, "E8E2F2", 0.02, 24, parent=root)
cyl("fountain_bowl", (0, 1.35, 8.5), 0.6, 0.15, "E8E2F2", 0.02, 32, r2=0.4, parent=root)
sphere("fountain_top", (0, 1.6, 8.5), 0.18, "9BD8F0", mname="water2_glow", parent=root)
obstacle(0, 8.5, 2.9, 2.9)
empty("mark_fountain", (0, 0, 8.5), root)
# cherry trees + benches
for i, (x, z) in enumerate(((-6, 6.2), (6, 6.2), (-7.5, 10.8), (7.5, 10.8), (-3.5, 12.0), (3.5, 12.0))):
    tree("cherry_%d" % i, x, z, pink=True, s=1.2)
for i, (x, z, yaw) in enumerate(((-3.6, 6.0, 0), (3.6, 6.0, 0), (-4.2, 10.0, 0), (4.2, 10.0, 0))):
    box("bench_seat_%d" % i, (x, 0.45, z), (1.5, 0.08, 0.45), "E8B87A", 0.02, parent=root)
    box("bench_back_%d" % i, (x, 0.75, z - 0.22), (1.5, 0.4, 0.06), "E8B87A", 0.02, parent=root)
    for s in (-1, 1):
        box("bench_leg_%d_%d" % (i, s), (x + s * 0.65, 0.22, z), (0.06, 0.44, 0.4), "3B3550", 0.01, parent=root)
    empty("mark_bench_%d" % i, (x, 0, z), root)
    obstacle(x, z - 0.05, 1.55, 0.5)
# flower beds along the park edge
for i, x in enumerate(range(-9, 10, 3)):
    if abs(x) < 2:
        continue
    box("bed_%d" % i, (x, 0.12, 3.9), (2.2, 0.24, 0.6), "C8864E", 0.02, parent=root)
    for f in range(6):
        sphere("bedfl_%d_%d" % (i, f), (x - 0.9 + f * 0.36, 0.32, 3.9 + (f % 2) * 0.1), 0.12, ["FF7EA6", "FFD24A", "FFFFFF", "C3A6FF", "FFB86A", "FF9EBB"][f], parent=root)
    obstacle(x, 3.9, 2.25, 0.65)
# hedges around the park sides
box("hedge_w", (-10.3, 0.4, 8.5), (0.6, 0.8, 9.0), "6BBF59", 0.15, parent=root)
box("hedge_e", (10.3, 0.4, 8.5), (0.6, 0.8, 9.0), "6BBF59", 0.15, parent=root)
box("hedge_s", (0, 0.4, 13.3), (21.2, 0.8, 0.6), "6BBF59", 0.15, parent=root)
obstacle(-10.3, 8.5, 0.6, 9.0)
obstacle(10.3, 8.5, 0.6, 9.0)
# little touches: vending machine, mailbox, bus stop
box("vending", (-26.5, 0.9, -3.4), (0.9, 1.8, 0.7), "FF9EBB", 0.04, parent=root)
box("vending_win", (-26.5, 1.15, -3.04), (0.7, 0.9, 0.02), "FFF6D2", 0.01, mname="vend_glow", parent=root)
obstacle(-26.5, -3.4, 0.95, 0.75)
cyl("mailbox", (-3.2, 0.55, -3.6), 0.22, 1.1, "E8404A", 0.04, 20, parent=root)
obstacle(-3.2, -3.6, 0.45, 0.45)
box("bus_roof", (19.5, 2.4, 3.1), (3.0, 0.1, 1.2), "A9C8FF", 0.03, parent=root)
for s in (-1, 1):
    cyl("bus_pole_%d" % s, (19.5 + s * 1.3, 1.2, 3.5), 0.05, 2.4, "3B3550", 0.01, 8, parent=root)
box("bus_bench", (19.5, 0.45, 3.4), (2.2, 0.08, 0.45), "E8B87A", 0.02, parent=root)
obstacle(19.5, 3.4, 2.6, 0.55)

# NPC spots (where townsfolk like to hang out)
for nid, p in {"hana": (13.5, -3.1), "ren": (24.5, -3.1), "kai": (-11.0, -3.1), "yuki": (2.2, 6.8)}.items():
    empty("mark_spot_" + nid, (p[0], 0, p[1]), root)
empty("mark_spawn", (0, 0, -2.6), root)

merge_static(root)
export(OUT)
