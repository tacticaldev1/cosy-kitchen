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

def gable(name, x, zc, w, d, h, rh, roof_col, wall_col, parent, over=0.25):
    """A pitched roof on a box building: two sloped panels plus solid triangular gable ends."""
    half = d / 2 + over
    a = math.atan2(rh, half)
    length = math.hypot(half, rh) + 0.06
    for s, sgn in (("f", 1), ("b", -1)):
        box("%s_roof_%s" % (name, s), (x, h + rh / 2 + 0.05, zc + sgn * half / 2), (w + 0.3, 0.14, length), roof_col, 0.02, parent=parent, rot=(sgn * a, 0, 0))
    for e, ex in (("l", x - w / 2), ("r", x + w / 2)):
        me = bpy.data.meshes.new(name + "_gable_" + e)
        t = 0.06
        verts = []
        for dx in (-t, t):
            for (gz, gy) in ((zc - d / 2, h), (zc + d / 2, h), (zc, h + rh)):
                verts.append(g2b(ex + dx, gy, gz))
        faces = [(0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)]
        me.from_pydata([tuple(v) for v in verts], [], faces)
        me.update()
        ob = bpy.data.objects.new(name + "_gable_" + e, me)
        bpy.context.scene.collection.objects.link(ob)
        finish(ob, mat(wall_col), 0.0, parent=parent)
        bpy.context.view_layer.objects.active = ob
        ob.select_set(True)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.normals_make_consistent(inside=False)
        bpy.ops.object.mode_set(mode="OBJECT")
        ob.select_set(False)
def obstacle(cx, cz, w, d):
    empty("obs_%d_%.2f_%.2f" % (obs_n[0], w, d), (cx, 0, cz), root)
    obs_n[0] += 1

# --------------------------------------------------------------------- ground
box("grass", (0, -0.08, 2), (124, 0.1, 40), "8CCB6E", 0.0, mname="grass_noline", parent=root)
box("road", (0, -0.02, 0), (114, 0.04, 4.0), "B9B2CC", 0.0, mname="road_noline", parent=root)
for i in range(57):
    box("road_line_%d" % i, (-56 + i * 2.0, 0.002, 0), (1.0, 0.01, 0.12), "FFFFFF", 0.0, mname="line_noline", parent=root)
box("walk_n", (0, -0.01, -3.1), (114, 0.06, 2.2), "EDB9A8", 0.0, mname="walk_noline", parent=root)
for i in range(114):
    box("curb_n_%d" % i, (-56.5 + i, 0.03, -2.0), (0.96, 0.08, 0.14), "FFE9DC", 0.004, mname="curb", parent=root)
box("walk_s", (0, -0.01, 2.7), (114, 0.06, 1.4), "EDB9A8", 0.0, mname="walk_noline", parent=root)
for i in range(114):
    box("curb_s_%d" % i, (-56.5 + i, 0.03, 2.0), (0.96, 0.08, 0.14), "FFE9DC", 0.004, mname="curb", parent=root)

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
    ("clinic", -45.0, 6.0, 4.6, "EAF7FF", "5FB8A8", "9FE0D0"),
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
        gable(sid, x, FZ - 3.0, w, 6.0, h, 1.3, roof, wall, g)
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
        # alternate stripes are a touch thicker so neighbouring faces never share a plane (no flicker)
        box("%s_awn_%d" % (sid, i), (sx, 2.75, FZ + 0.55), (aw / stripes + (0.006 if i % 2 else -0.002), 0.08 if i % 2 else 0.068, 1.15 if i % 2 else 1.14), awn if i % 2 else "FFFFFF", 0.0, parent=g, rot=(0.38, 0, 0))
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
box("backdrop", (0, 4, -10.5), (118, 8, 0.2), "E6D2EE", 0.0, mname="sky_noline", parent=root)

# --------------------------------------------------------------------- street lamps and trees
for i, x in enumerate(range(-50, 52, 6)):
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

for x in (-25, -16.5, 15.5, 25, -33, 35.3, -40, 42, -46, 53):
    tree("st_tree_%d" % x, x, 3.4, pink=False, s=0.9)

# --------------------------------------------------------------------- the park
box("park_grass", (0, -0.03, 8.5), (20, 0.04, 9.0), "A3DA86", 0.0, mname="park_noline", parent=root)
box("park_path", (0, -0.016, 8.5), (2.0, 0.04, 9.0), "F0D2B0", 0.0, mname="path_noline", parent=root)
cyl("path_ring", (0, -0.002, 8.5), 2.6, 0.04, "F0D2B0", 0.0, 48, mname="path2_noline", parent=root)
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
obstacle(0, 13.3, 21.2, 0.6)
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

# --------------------------------------------------------------------- the townsfolk's cottages
HOUSES = [("hana", -29.5, "FFD6E2", "E8607E"), ("ren", -36.0, "D9E4F5", "5A6E9E"), ("kai", 32.0, "FFE7B8", "D9822B"), ("yuki", 38.5, "E7DCFA", "8B7BC9")]
for hid, x, wall, roof in HOUSES:
    g = group("grp_house_" + hid)
    g.parent = root
    w, h = 5.0, 3.4
    box(hid + "_hbody", (x, h / 2, FZ - 2.5), (w, h, 5.0), wall, 0.03, parent=g)
    box(hid + "_hbase", (x, 0.2, FZ - 0.02), (w + 0.1, 0.4, 0.12), "E8D2C2", 0.02, parent=g)
    gable(hid, x, FZ - 2.5, w, 5.0, h, 1.4, roof, wall, g)
    box(hid + "_chim", (x + 1.4, h + 1.2, FZ - 3.2), (0.4, 1.0, 0.4), "C8864E", 0.02, parent=g)
    box(hid + "_hdoor", (x, 1.0, FZ + 0.03), (0.95, 2.0, 0.1), roof, 0.02, parent=g)
    box(hid + "_hdoorframe", (x, 1.05, FZ + 0.015), (1.15, 2.2, 0.06), "FFFFFF", 0.02, parent=g)
    sphere(hid + "_hknob", (x + 0.33, 1.0, FZ + 0.1), 0.04, GOLD, parent=g)
    cyl(hid + "_hlamp", (x - 0.75, 2.0, FZ + 0.12), 0.09, 0.22, "FFF0C8", 0.02, 12, mname="hlamp_glow", parent=g)
    for s in (-1, 1):
        wx = x + s * 1.65
        box("%s_hwin_%d" % (hid, s), (wx, 1.55, FZ + 0.02), (1.1, 1.0, 0.08), "BFDDF2", 0.02, mname="shopglass", parent=g)
        box("%s_hwinf_%d" % (hid, s), (wx, 1.55, FZ + 0.01), (1.26, 1.16, 0.06), "FFFFFF", 0.02, parent=g)
        box("%s_hwinx_%d" % (hid, s), (wx, 1.55, FZ + 0.065), (0.04, 1.0, 0.02), "FFFFFF", 0.0, parent=g)
        box("%s_hbox_%d" % (hid, s), (wx, 0.98, FZ + 0.16), (1.1, 0.16, 0.22), "C8864E", 0.02, parent=g)
        for f in range(5):
            sphere("%s_hfl_%d_%d" % (hid, s, f), (wx - 0.42 + f * 0.21, 1.1, FZ + 0.18), 0.07, ["FF7EA6", "FFD24A", "FFFFFF", "C3A6FF", "FF9EBB"][f], parent=g)
    box(hid + "_upwin", (x, h - 0.6, FZ + 0.02), (0.8, 0.6, 0.08), "BFDDF2", 0.02, mname="shopglass", parent=g)
    # a little picket fence and a mailbox with the family name
    for s in (-1, 1):
        for k in range(5):
            px = x + s * (0.9 + k * 0.32)
            box("%s_fence_%d_%d" % (hid, s, k), (px, 0.3, FZ + 0.9), (0.08, 0.6, 0.05), "FFFFFF", 0.01, parent=g)
        box("%s_rail_%d" % (hid, s), (x + s * 1.54, 0.42, FZ + 0.9), (1.4, 0.06, 0.04), "FFFFFF", 0.01, parent=g)
        obstacle(x + s * 1.54, FZ + 0.9, 1.5, 0.12)
    box(hid + "_mailbox", (x + 2.25, 0.85, FZ + 0.95), (0.32, 0.28, 0.4), roof, 0.03, parent=g)
    cyl(hid + "_mailpost", (x + 2.25, 0.35, FZ + 0.95), 0.03, 0.7, "FFFFFF", 0.0, 8, parent=g)
    empty("mark_door_house_" + hid, (x, 0, FZ + 0.75), root)
    empty("mark_sign_house_" + hid, (x, 2.45, FZ + 0.1), root)

# --------------------------------------------------------------------- the house for sale (east end)
g = group("grp_forsale")
g.parent = root
HX, HW, HH = 47.5, 7.2, 5.4
box("fs_body", (HX, HH / 2, FZ - 3.2), (HW, HH, 6.4), "FFF1E0", 0.03, parent=g)
box("fs_base", (HX, 0.25, FZ - 0.02), (HW + 0.1, 0.5, 0.12), "E8D2C2", 0.02, parent=g)
gable("fs", HX, FZ - 3.2, HW, 6.4, HH, 1.8, "D9527E", "FFF1E0", g)
box("fs_door", (HX, 1.1, FZ + 0.03), (1.1, 2.2, 0.1), "8B5A3C", 0.02, parent=g)
box("fs_doorframe", (HX, 1.15, FZ + 0.015), (1.3, 2.4, 0.06), "FFFFFF", 0.02, parent=g)
sphere("fs_knob", (HX + 0.4, 1.05, FZ + 0.1), 0.045, GOLD, parent=g)
box("fs_porch", (HX, 0.06, FZ + 0.6), (2.6, 0.12, 1.0), "E8B87A", 0.01, parent=g)
for s in (-1, 1):
    cyl("fs_pillar_%d" % s, (HX + s * 1.15, 1.35, FZ + 0.95), 0.07, 2.6, "FFFFFF", 0.01, 12, parent=g)
box("fs_porchroof", (HX, 2.7, FZ + 0.6), (2.8, 0.1, 1.2), "D9527E", 0.02, parent=g)
for fl in range(2):
    for s in (-1, 1):
        for k in range(2 if fl == 0 else 3):
            wx = HX + s * (1.9 + k * 1.1) if fl == 0 else HX + (k - 1) * 2.2
            if fl == 1 and s > 0: continue
            wy = 1.6 + fl * 2.4
            box("fs_win_%d_%d_%d" % (fl, s, k), (wx, wy, FZ + 0.02), (0.9, 1.1, 0.08), "BFDDF2", 0.02, mname="shopglass", parent=g)
            box("fs_winf_%d_%d_%d" % (fl, s, k), (wx, wy, FZ + 0.01), (1.04, 1.24, 0.06), "FFFFFF", 0.02, parent=g)
            box("fs_box_%d_%d_%d" % (fl, s, k), (wx, wy - 0.6, FZ + 0.15), (0.9, 0.14, 0.2), "C8864E", 0.02, parent=g)
            for f in range(4):
                sphere("fs_fl_%d_%d_%d_%d" % (fl, s, k, f), (wx - 0.3 + f * 0.2, wy - 0.48, FZ + 0.17), 0.065, ["FF7EA6", "FFD24A", "FFFFFF", "C3A6FF"][f], parent=g)
# a picket fence with a gap for the path, and the realtor's sign
for s in (-1, 1):
    for k in range(7):
        box("fs_fence_%d_%d" % (s, k), (HX + s * (1.6 + k * 0.32), 0.3, FZ + 1.4), (0.08, 0.6, 0.05), "FFFFFF", 0.01, parent=g)
    box("fs_rail_%d" % s, (HX + s * 2.56, 0.42, FZ + 1.4), (2.0, 0.06, 0.04), "FFFFFF", 0.01, parent=g)
    obstacle(HX + s * 2.56, FZ + 1.4, 2.1, 0.12)
cyl("fs_signpost", (HX + 2.4, 0.6, FZ + 1.75), 0.04, 1.2, "8B5A3C", 0.0, 8, parent=g)
box("fs_signboard", (HX + 2.4, 1.15, FZ + 1.78), (0.9, 0.55, 0.05), "FFFDF6", 0.02, parent=g)
obstacle(HX + 2.4, FZ + 1.75, 0.2, 0.2)
empty("mark_door_forsale", (HX, 0, FZ + 0.85), root)
empty("mark_sign_forsale", (HX + 2.4, 1.15, FZ + 1.82), root)

# NPC spots (where townsfolk like to hang out)
for nid, p in {"hana": (13.5, -3.1), "ren": (24.5, -3.1), "kai": (-11.0, -3.1), "yuki": (2.2, 6.8)}.items():
    empty("mark_spot_" + nid, (p[0], 0, p[1]), root)
empty("mark_spawn", (0, 0, -2.6), root)

merge_static(root)
export(OUT)
