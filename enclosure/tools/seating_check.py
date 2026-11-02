"""Manifold mesh-boolean SEATING check (Round 18 FIX B, reviewer): rear_cover
and gate_front, each placed exactly per assembly.scad's relative nesting,
against gate_rear. Non-zero volume means the two parts collide and cannot
seat flush — this is the gate that would have caught the Round-17 lip-flare
blocker (37.2 mm^3 collision, 0.86mm proud) before it shipped, instead of
relying on a reviewer's by-hand boolean.

Usage: python seating_check.py [dir] [--cover-dz MM]
  dir         directory containing config.scad, with STLs under dir/print/
              (default ".")
  --cover-dz  offset (mm) applied to rear_cover's axial placement — negative
              moves it CLOSER to gate_rear. Control-test hook: at 0 the real
              geometry must read 0.000 mm^3; at e.g. -0.5 it must read
              nonzero (proving the gate can actually detect a collision,
              not just pass by construction). Never written to any file.

Transforms are gate-local ONLY (no outer translate([0,0,GATE_CZ])
rotate([90,0,180]) — that's a single rigid transform applied to the WHOLE
gate-rear/gate-front/rear-cover group in assembly.scad, so it cannot affect
their RELATIVE collision with each other; omitting it changes nothing about
whether they intersect, and avoids needing GATE_CZ at all here):
  gate_front placed: rotate([180,0,180])                      (gate_rear's own frame)
  rear_cover placed: translate([0,0,REAR_T+REAR_COVER_T]) rotate([0,180,0])
REAR_T/REAR_COVER_T read from config.scad by regex (same drift-guard pattern
as tools/interference_check.py), not hardcoded.
"""
import argparse
import re
import sys
from pathlib import Path

import numpy as np
import trimesh
from trimesh.transformations import rotation_matrix as R, translation_matrix as T

SEATING_LIMIT_MM3 = 0.01  # exit non-zero above this, for either part


def _literal(text, name):
    m = re.search(rf'\b{name}\s*=\s*(-?\d+\.?\d*)\s*;', text)
    if not m:
        raise RuntimeError(f"{name}: no plain-literal assignment found in config.scad")
    return float(m.group(1))


def _strip_comments(text):
    return "\n".join(line.split("//", 1)[0] for line in text.splitlines())


def load_config(config_path):
    text = _strip_comments(Path(config_path).read_text())
    return {
        "REAR_T": _literal(text, "REAR_T"),
        "REAR_COVER_T": _literal(text, "REAR_COVER_T"),
    }


def rot(a, b, c):
    """OpenSCAD rotate([a,b,c]) == Rz(c) @ Ry(b) @ Rx(a)."""
    return R(np.radians(c), [0, 0, 1]) @ R(np.radians(b), [0, 1, 0]) @ R(np.radians(a), [1, 0, 0])


def load(d, name):
    # STLs live under print/ (2026-08-18); config.scad stays in d itself.
    return trimesh.load(f"{d}/print/{name}.stl", force="mesh")


def collision_volume(a, b):
    if (a.bounds[0] > b.bounds[1]).any() or (a.bounds[1] < b.bounds[0]).any():
        return 0.0, None
    inter = trimesh.boolean.intersection([a, b], engine="manifold", check_volume=False)
    v = 0.0 if inter.is_empty else abs(inter.volume)
    bbox = inter.bounds.round(3).tolist() if v > 1e-6 else None
    return v, bbox


def check(d=".", cover_dz=0.0):
    cfg = load_config(Path(d) / "config.scad")
    rear = load(d, "gate_rear")
    front = load(d, "gate_front").copy()
    front.apply_transform(rot(180, 0, 180))
    cover = load(d, "rear_cover").copy()
    cover.apply_transform(
        T([0, 0, cfg["REAR_T"] + cfg["REAR_COVER_T"] + cover_dz]) @ rot(0, 180, 0)
    )
    v_cover, bbox_cover = collision_volume(cover, rear)
    v_front, bbox_front = collision_volume(front, rear)
    return v_cover, bbox_cover, v_front, bbox_front


def parse_args(argv):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("dir", nargs="?", default=".", help="directory containing the STLs + config.scad")
    p.add_argument("--cover-dz", type=float, default=0.0, dest="cover_dz",
                   help="offset (mm) applied to rear_cover's axial placement — control-test hook")
    return p.parse_args(argv)


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    v_cover, bbox_cover, v_front, bbox_front = check(args.dir, args.cover_dz)
    print(f"seating_cover_mm3={v_cover:.4f}")
    if bbox_cover:
        print(f"  collision bbox={bbox_cover}")
    print(f"seating_front_mm3={v_front:.4f}")
    if bbox_front:
        print(f"  collision bbox={bbox_front}")
    if v_cover > SEATING_LIMIT_MM3 or v_front > SEATING_LIMIT_MM3:
        sys.exit(1)
