"""Flag unsupported downward-facing (overhang) triangles in a binary STL.

Usage: python overhang_check.py part.stl

The part prints flat, bed at z=0 (confirmed by count_shells.py's zmin gate).
For each triangle: compute the unit normal from vertex winding (cross
product of two edges); if that's degenerate (near-zero area triangle) fall
back to the file's own stored normal. A triangle is a "downward candidate"
if its normal z-component < -0.5 (facing more than 30 degrees down from
vertical) AND its lowest vertex is above the bed (min z > 0.5, so the
bed-contact face itself never counts).

Round 13 rewrite (reviewer Critical: the old bbox-only allowlist was BLIND —
a real 90deg cantilever ledge on the flank foot passed clean, and a planted
proud lip inside one of the broad wall-region boxes also passed clean,
because the boxes excluded entire regions by shape/location rather than by
WHY a downward face is actually safe). The gate is now semantic:

1. An explicit bbox allowlist covers ONLY pre-existing INTERNAL ceilings —
   surfaces that are structurally required, invisible in the assembled
   part, and were never "decoration": the cable-cavity ceiling, the
   screw-shelf ring around it, the USB port ceiling, the USB tail-bore
   ceiling, the 4 cover-screw insert-hole floors, and the 2 rear-pillar
   M2 bore ceilings.
2. Everything else that's a downward candidate gets GROUPED with its
   mesh-adjacent, coplanar (same normal) neighbours (union-find over shared
   vertices, keyed by normal so a cube corner where 3 different faces meet
   never merges them) — this is what stops a big ledge that happens to be
   tessellated into many small triangles from sneaking through one
   triangle at a time.
3. Each group's real-world footprint is its XY-projected bounding box; its
   "reach" is the SHORTER side of that bbox (the narrow dimension — for a
   groove/mortar-line lintel this is the cut's own depth, a couple mm; for
   a real cantilevered ledge it's however far the ledge projects, which is
   never thin in both directions). A group passes (is not an overhang) iff
   reach <= 2.5mm — a span FDM bridges trivially. Any larger group is a
   genuine unsupported overhang and every triangle in it is flagged.

Prints:
    overhang_faces=N worst_group_bbox=[xlo,xhi,ylo,yhi,zlo,zhi] worst_group_reach=X
worst_group is the flagged group with the largest reach (ties broken by
triangle count), or "none"/0 if N=0.
"""
import math
import struct
import sys
from collections import defaultdict

# ---------------------------------------------------------------- geometry ---
def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def cross(a, b):
    return (
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    )


def unit(v):
    n = (v[0] ** 2 + v[1] ** 2 + v[2] ** 2) ** 0.5
    if n < 1e-9:
        return None
    return (v[0] / n, v[1] / n, v[2] / n)


def load_tris(path):
    size = __import__("os").path.getsize(path)
    if size < 84:
        sys.exit(f"ERROR: {path}: {size} bytes - too small to be a binary STL")
    with open(path, "rb") as f:
        head = f.read(80)
        n = struct.unpack("<I", f.read(4))[0]
        if size != 84 + 50 * n:
            kind = (
                "ASCII STL - export with --export-format binstl"
                if head.lstrip().startswith(b"solid")
                else "truncated or corrupt binary STL"
            )
            sys.exit(
                f"ERROR: {path}: header claims {n} triangles (needs "
                f"{84 + 50 * n} bytes) but file is {size} bytes - {kind}"
            )
        tris = []
        for _ in range(n):
            data = f.read(50)
            stored_n = struct.unpack_from("<3f", data, 0)
            v0 = struct.unpack_from("<3f", data, 12)
            v1 = struct.unpack_from("<3f", data, 24)
            v2 = struct.unpack_from("<3f", data, 36)
            tris.append((stored_n, (v0, v1, v2)))
        return tris


# ---------------------------------------------------- internal-ceiling allowlist ---
# ONLY pre-existing INTERNAL ceilings (Round 13 FIX 2, reviewer Critical) —
# structural, invisible-in-assembly, never "decoration". Everything that
# used to be a broad wall/flank/lug/ramp region box is DELETED: those hid a
# real overhang (the flank foot's end-wall cantilever) and were proven blind
# to a planted mutation. The semantic reach rule (below) now does that job.
# [xlo, xhi, ylo, yhi, zlo, zhi]. A triangle is excluded only if ALL 3
# vertices lie inside one bbox (small tolerance for float noise).
TOL = 0.15
REACH_LIMIT = 2.5  # mm — the narrow dimension FDM bridges trivially
# Round 18 FIX C (reviewer): two corrections found auditing this script
# against a real 45-deg self-supporting revolved chamfer (rear_cover.scad's
# registration lip shoulder, Round 17/18) that it flagged identically to a
# genuine unsupported overhang.
NZ_CANDIDATE_THRESHOLD = -0.7071  # was -0.5 (30 deg from vertical) — too
                                    # strict. This is the actual FDM 45-deg
                                    # self-support rule: nz=-sin(45deg) for a
                                    # face exactly at the printable limit.
                                    # Anything shallower than 45 deg from
                                    # vertical is self-supporting regardless
                                    # of its group's footprint and should
                                    # never even become a candidate.
REVOLVED_SPAN_DEG = 90.0  # a downward group whose triangle centroids span
                            # more than this much angle about the part's own
                            # Z axis is a REVOLVED feature (a swept taper/
                            # chamfer), not a flat cantilevered ledge — for
                            # those, "reach" means how far the face actually
                            # projects RADIALLY (max_r-min_r), not the XY
                            # bbox short side, which balloons toward the
                            # full part diameter for anything wrapping most
                            # of a circle regardless of how thin the taper
                            # itself is.
ALLOWLIST = [
    # internal cable-cavity ceiling (base_main.scad: BASE_CAV cube, top z=18)
    [-47.5, 47.5, -19.5, 19.5, 17.0, 19.0],
    # screw-shelf ring ceiling (base_main.scad: BASE_REBATE cut, ~z=2.01 —
    # the 5mm-wide BASE_SHELF ring around the cavity, where the bottom-cover
    # screw bosses land)
    [-53.0, 53.0, -25.0, 25.0, 1.9, 2.1],
    # USB port ceiling (base_main.scad: rear-wall USB_PORT cut, ~z=20)
    [-8.0, 8.0, 25.0, 40.0, 7.0, 21.0],
    # USB socket tail-bore ceiling (base_main.scad: cavity-to-port bridge
    # cut, ~z=16)
    [-7.0, 7.0, 17.0, 32.0, 15.5, 16.5],
    # cover-screw M2 insert holes, 4 corners (base_main.scad: BASE_SCREW_XY
    # blind holes, floor at ~z=6.99)
    [47.5, 52.5, 19.5, 24.5, 6.8, 7.1],
    [47.5, 52.5, -24.5, -19.5, 6.8, 7.1],
    [-52.5, -47.5, 19.5, 24.5, 6.8, 7.1],
    [-52.5, -47.5, -24.5, -19.5, 6.8, 7.1],
    # rear-pillar M2 clearance bore ceilings (config.scad:
    # REAR_PILLAR_ANG=[245,295]; pillar A x=+19.02,z=52.22, pillar B
    # x=-19.02,z=52.22 — sin(245)==sin(295), same z for both)
    [16.0, 22.0, 19.0, 32.0, 49.0, 55.5],
    [-22.0, -16.0, 19.0, 32.0, 49.0, 55.5],
]


def in_bbox(tri, bbox):
    xlo, xhi, ylo, yhi, zlo, zhi = bbox
    return all(
        xlo - TOL <= v[0] <= xhi + TOL
        and ylo - TOL <= v[1] <= yhi + TOL
        and zlo - TOL <= v[2] <= zhi + TOL
        for v in tri
    )


def tri_bbox(tri):
    xs = [v[0] for v in tri]
    ys = [v[1] for v in tri]
    zs = [v[2] for v in tri]
    return [min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)]


def merge_bbox(a, b):
    return [
        min(a[0], b[0]), max(a[1], b[1]),
        min(a[2], b[2]), max(a[3], b[3]),
        min(a[4], b[4]), max(a[5], b[5]),
    ]


def vkey(v):
    return tuple(round(c, 4) for c in v)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


# Round 14 FIX C (reviewer Critical): a smoothly CURVED downward surface
# (e.g. a horizontal cylindrical bore through a wall) is triangulated into
# many small facets, each with a normal that differs slightly from its
# neighbour's — none of them share an EXACTLY matching normal, so the old
# exact-match bucketing put every facet in its own tiny group, each
# reporting its own tiny (safe, <=2.5mm) reach and hiding the curved
# surface's real, combined reach entirely. ANGLE_TOL_DEG replaces exact
# matching: two MESH-ADJACENT triangles (sharing a vertex) merge if their
# normals are within this angle of each other, so a gradually curving
# patch merges transitively (each step is small, even though the first and
# last facets in a wide curve could differ by far more) while genuinely
# different faces (e.g. a cube corner, ~90 degrees apart) stay separate.
ANGLE_TOL_DEG = 15.0
COS_ANGLE_TOL = math.cos(math.radians(ANGLE_TOL_DEG))


class UnionFind:
    def __init__(self, n):
        self.parent = list(range(n))

    def find(self, a):
        while self.parent[a] != a:
            self.parent[a] = self.parent[self.parent[a]]
            a = self.parent[a]
        return a

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.parent[rb] = ra


def group_downward_candidates(candidates):
    """candidates: list of (tri, normal). Returns list of groups, each a
    list of triangle indices, grouped by shared-vertex adjacency where
    ADJACENT triangles' normals are within ANGLE_TOL_DEG (a coplanar-OR-
    gently-curved, mesh-connected patch — see ANGLE_TOL_DEG's own comment)."""
    uf = UnionFind(len(candidates))
    by_vertex = defaultdict(list)
    for i, (tri, n) in enumerate(candidates):
        for v in tri:
            by_vertex[vkey(v)].append(i)
    for idxs in by_vertex.values():
        for a in range(len(idxs)):
            for b in range(a + 1, len(idxs)):
                i, j = idxs[a], idxs[b]
                if dot(candidates[i][1], candidates[j][1]) >= COS_ANGLE_TOL:
                    uf.union(i, j)
    groups = defaultdict(list)
    for i in range(len(candidates)):
        groups[uf.find(i)].append(i)
    return list(groups.values())


def check(path):
    tris = load_tris(path)
    candidates = []
    for stored_n, (v0, v1, v2) in tris:
        computed = cross(sub(v1, v0), sub(v2, v0))
        n = unit(computed)
        if n is None:
            n = unit(stored_n)
        if n is None:
            continue  # fully degenerate triangle, nothing to flag
        if n[2] >= NZ_CANDIDATE_THRESHOLD:
            continue
        tri = (v0, v1, v2)
        if min(v0[2], v1[2], v2[2]) <= 0.5:
            continue
        if any(in_bbox(tri, b) for b in ALLOWLIST):
            continue
        candidates.append((tri, n))

    groups = group_downward_candidates(candidates)
    flagged_tris = []
    flagged_groups = []  # (bbox, reach, n_tris)
    for idxs in groups:
        group_tris = [candidates[i][0] for i in idxs]
        bboxes = [tri_bbox(t) for t in group_tris]
        gbbox = bboxes[0]
        for b in bboxes[1:]:
            gbbox = merge_bbox(gbbox, b)
        x_extent = gbbox[1] - gbbox[0]
        y_extent = gbbox[3] - gbbox[2]
        reach = min(x_extent, y_extent)
        # Round 18 FIX C: a group whose centroids wrap more than
        # REVOLVED_SPAN_DEG of angle about the part's own Z axis is a
        # revolved feature (taper/chamfer), not a flat ledge — its XY bbox
        # necessarily approaches the full part diameter regardless of how
        # thin the feature actually is, so bbox-short-side is the wrong
        # "reach" for it. Use radial extent instead.
        centroids = [
            ((t[0][0] + t[1][0] + t[2][0]) / 3.0, (t[0][1] + t[1][1] + t[2][1]) / 3.0)
            for t in group_tris
        ]
        if len(centroids) > 1:
            radii = [math.hypot(x, y) for x, y in centroids]
            angs = sorted(math.degrees(math.atan2(y, x)) % 360 for x, y in centroids)
            gaps = [(angs[(i + 1) % len(angs)] - angs[i]) % 360 for i in range(len(angs))]
            span = 360.0 - max(gaps)
            if span > REVOLVED_SPAN_DEG:
                reach = max(radii) - min(radii)
        if reach <= REACH_LIMIT:
            continue  # thin groove lintel (or thin revolved taper), FDM bridges trivially
        flagged_tris.extend(group_tris)
        flagged_groups.append((gbbox, reach, len(group_tris)))

    return flagged_tris, flagged_groups


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: python overhang_check.py part.stl")
    flagged_tris, flagged_groups = check(sys.argv[1])
    n = len(flagged_tris)
    if n == 0:
        print("overhang_faces=0 worst_group_bbox=none worst_group_reach=0")
    else:
        flagged_groups.sort(key=lambda g: (g[1], g[2]), reverse=True)
        worst_bbox, worst_reach, worst_n = flagged_groups[0]
        bfmt = "[" + ",".join(f"{v:.2f}" for v in worst_bbox) + "]"
        print(f"overhang_faces={n} worst_group_bbox={bfmt} worst_group_reach={worst_reach:.2f}")
        # brief group breakdown for debugging (stderr, doesn't affect the parse)
        for bbox, reach, gn in flagged_groups[:8]:
            bfmt2 = "[" + ",".join(f"{v:.1f}" for v in bbox) + "]"
            print(f"  group n={gn} reach={reach:.2f} bbox={bfmt2}", file=sys.stderr)
