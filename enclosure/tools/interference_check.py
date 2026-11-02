"""Manifold mesh-boolean interference check: base_main.stl vs. the fully
assembled gate stack (rear + front + 9 chevrons + rear cover).

Usage: python interference_check.py [dir] [--gate-dz MM]
  dir        directory containing config.scad, with STLs under dir/print/
             (default ".")
  --gate-dz  offset (mm) applied to GATE_CZ — control-test hook, simulates a
             mis-seated gate without editing any file

Round 14 FIX C (reviewer Critical): interference_check.scad's own
import()+intersection() approach silently PASSES on the decorated mesh —
CGAL's Nef-polyhedron boolean throws an internal error ("CGAL error ...
e_below") on this geometry, OpenSCAD prints "Current top level object is
empty" (its normal message for a GENUINELY empty intersection too), and
Invoke-InterferenceCheck's old empty-file check reads that as a clean PASS.
Same failure mode, opposite conclusion: no interference gets reported as no
interference. Replaced with a real polygon-mesh boolean (trimesh +
manifold3d), which doesn't share CGAL's Nef fragility on this mesh.
render.ps1 no longer runs the OpenSCAD/CGAL half at all (Round 15) — this
script is the sole gate.

Transforms below are an EXACT copy of interference_check.scad's own
intersection() block (itself a copy of assembly.scad's gate-stack
placement) — see that file for the OpenSCAD source these mirror.

Round 15 (Narcosia review): GATE_CZ, CHEV_R0, REAR_T, REAR_COVER_T, FRONT_T,
and RELIEF_MAX are now read from config.scad by regex at RUNTIME instead of
hardcoded — a drift guard, so a future config.scad edit to any of these
values is picked up automatically instead of silently going stale here.
GATE_CZ is a derived expression (BASE_H + GATE_GAP + GATE_OD/2), not a
literal — its own inputs are extracted as literals first and the expression
evaluated with those, mirroring how config.scad itself derives it.
CHEVRON_N is left hardcoded (not in the drift-guard list): a loop-count,
not a geometric placement value, and not asked for.
RELIEF_MAX substitutes for the old OUTER_RING_RELIEF (OUTER_RING[2], an
array element harder to regex cleanly): tests.scad asserts OUTER_RING[2] <=
RELIEF_MAX, so RELIEF_MAX is always a real value here or higher — never an
under-count.
"""
import argparse
import re
import sys
from pathlib import Path

import numpy as np
import trimesh
from trimesh.transformations import rotation_matrix as R, translation_matrix as T

CHEVRON_N = 9          # CHEVRON_N — loop count, not a drift-guarded placement value
INTERFERENCE_LIMIT_MM3 = 0.01  # exit non-zero above this


def _literal(text, name):
    m = re.search(rf'\b{name}\s*=\s*(-?\d+\.?\d*)\s*;', text)
    if not m:
        raise RuntimeError(f"{name}: no plain-literal assignment found in config.scad")
    return float(m.group(1))


def _expr(text, name):
    m = re.search(rf'\b{name}\s*=\s*([^;]+);', text)
    if not m:
        raise RuntimeError(f"{name}: no assignment found in config.scad")
    return m.group(1).strip()


def _strip_comments(text):
    """Drop everything from // to end of line — config.scad's own prose
    (e.g. "GATE_CZ = platform_top_at_ring_y + GATE_GAP + GATE_OD/2." inside
    a block comment, well before the real assignment) would otherwise match
    the assignment regexes below just as readily as the real code."""
    return "\n".join(line.split("//", 1)[0] for line in text.splitlines())


def load_config(config_path):
    text = _strip_comments(Path(config_path).read_text())
    base_h = _literal(text, "BASE_H")
    gate_gap = _literal(text, "GATE_GAP")
    gate_od = _literal(text, "GATE_OD")
    gate_cz_expr = _expr(text, "GATE_CZ")   # "BASE_H + GATE_GAP + GATE_OD/2"
    gate_cz = eval(gate_cz_expr, {"__builtins__": {}},
                   {"BASE_H": base_h, "GATE_GAP": gate_gap, "GATE_OD": gate_od})
    return {
        "GATE_CZ": gate_cz,
        "CHEV_R0": _literal(text, "CHEV_R0"),
        "REAR_T": _literal(text, "REAR_T"),
        "REAR_COVER_T": _literal(text, "REAR_COVER_T"),
        "FRONT_T": _literal(text, "FRONT_T"),
        "RELIEF_MAX": _literal(text, "RELIEF_MAX"),
    }


def rot(a, b, c):
    """OpenSCAD rotate([a,b,c]) == Rz(c) @ Ry(b) @ Rx(a)."""
    return R(np.radians(c), [0, 0, 1]) @ R(np.radians(b), [0, 1, 0]) @ R(np.radians(a), [1, 0, 0])


def load(d, name):
    # STLs live under print/ (2026-08-18); config.scad stays in d itself.
    return trimesh.load(f"{d}/print/{name}.stl", force="mesh")


def gate_parts(d, cfg, gate_dz=0.0):
    """(name, world_transform) for every gate-stack part, matching
    interference_check.scad's translate([0,0,GATE_CZ]) rotate([90,0,180])
    { ... } block exactly. gate_dz shifts GATE_CZ only — a control-test
    hook (e.g. --gate-dz -1 simulates the gate lowered 1mm), never written
    to any file."""
    gate_cz = cfg["GATE_CZ"] + gate_dz
    outer = T([0, 0, gate_cz]) @ rot(90, 0, 180)
    parts = [
        ("gate_rear", outer),
        ("gate_front", outer @ rot(180, 0, 180)),
    ]
    for k in range(CHEVRON_N):
        parts.append((
            f"chevron{k}",
            outer @ rot(180, 0, 180) @ rot(0, 0, 90 + k * 40)
            @ T([cfg["CHEV_R0"], 0, cfg["FRONT_T"] + cfg["RELIEF_MAX"]]),
        ))
    parts.append(("rear_cover", outer @ T([0, 0, cfg["REAR_T"] + cfg["REAR_COVER_T"]]) @ rot(0, 180, 0)))
    return parts


def check(d=".", gate_dz=0.0):
    cfg = load_config(Path(d) / "config.scad")
    base = load(d, "base_main")
    total_vol = 0.0
    worst = None
    for name, M in gate_parts(d, cfg, gate_dz):
        fn = "chevron" if name.startswith("chevron") else name
        m = load(d, fn).copy()
        m.apply_transform(M)
        if (m.bounds[0] > base.bounds[1]).any() or (m.bounds[1] < base.bounds[0]).any():
            continue  # bbox-disjoint, definitely no interference
        inter = trimesh.boolean.intersection([base, m], engine="manifold", check_volume=False)
        v = 0.0 if inter.is_empty else abs(inter.volume)
        total_vol += v
        if v > 1e-6 and (worst is None or v > worst[1]):
            worst = (name, v, inter.bounds.round(2).tolist())
    return total_vol, worst


def parse_args(argv):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("dir", nargs="?", default=".", help="directory containing the STLs + config.scad")
    p.add_argument("--gate-dz", type=float, default=0.0, dest="gate_dz",
                   help="offset (mm) applied to GATE_CZ — control-test hook")
    return p.parse_args(argv)


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    total_vol, worst = check(args.dir, args.gate_dz)
    print(f"interference_mm3={total_vol:.4f}")
    if worst:
        print(f"worst_part={worst[0]} vol={worst[1]:.4f} bbox={worst[2]}")
    if total_vol > INTERFERENCE_LIMIT_MM3:
        sys.exit(1)
