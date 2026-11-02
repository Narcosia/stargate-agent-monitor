"""Build a single multi-colour 3MF from gate_front's face + glyph-ink STLs, for
Bambu Studio / AMS: one assembled object, two named parts, each pre-coloured.

Usage: python make_3mf.py [dir] [--face-color HEX] [--glyphs-color HEX]
                           [--out NAME]
  dir           directory whose print/ subdir holds gate_front_face.stl,
                gate_front_glyphs.stl, gate_front.stl (default ".")
  --face-color  hex colour for the face part (default 6E6E6E, mid grey)
  --glyphs-color hex colour for the glyphs part (default 000000, black)
  --out         output 3MF filename, written inside `dir`/print (default gate_front_ams.3mf)

WHY THE HAND-ROLLED XML STEP: trimesh 5.0.0's 3MF exporter
(trimesh/exchange/threemf.py, export_3MF) writes ONLY geometry + object
names — no <basematerials>, no per-object colour, nothing (verified by
reading its source; grep the function for "color" and "material" - zero
hits). Its loader (load_3MF) is symmetric: it never looks for colour either.
So "trimesh writes per-object colour" does not hold for this install. This
script therefore: (1) lets trimesh build the base 3MF (correct geometry,
one named <object> per part, exactly what its exporter is good at), then
(2) post-processes the archive's 3D/3dmodel.model XML to inject a
<basematerials> resource (core 3MF spec, not an extension - Bambu Studio,
PrusaSlicer, and the 3MF core reader in every major slicer all read this)
holding one <base name=... displaycolor=#RRGGBBAA> per part, and gives each
<object> a pid/pindex pair pointing at its entry - the standard "default
object colour" mechanism a 3MF reader applies to every triangle in that
object that doesn't carry its own per-triangle override (none do here).

VERIFICATION, in order:
  1. Reload the written file with trimesh -> exactly 2 geometries, named
     "face" and "glyphs" (trimesh CAN read names+geometry back, just not
     colour - see above).
  2. Re-open the same file's 3D/3dmodel.model XML directly (zipfile + lxml,
     reading the file we just wrote to disk, not the in-memory bytes) and
     confirm the <basematerials> block round-tripped with 2 distinct
     <base displaycolor=...> entries and that "face"/"glyphs" objects carry
     matching pid/pindex. This is what Bambu Studio actually parses, so it
     is a more direct check than trimesh reload for the colour half.
  3. manifold3d boolean intersection(face, glyphs) - prints overlap_mm3=;
     must be <= OVERLAP_LIMIT_MM3 or the script exits non-zero. The limit
     (0.01 mm^3) matches this repo's own precedent in interference_check.py
     (INTERFERENCE_LIMIT_MM3): two meshes that are geometrically flush
     (the ink sits exactly on the engraving floor, gate_front.scad's own
     comment) still return a tiny non-zero manifold3d intersection volume
     from floating-point noise on the coincident boundary, not real overlap
     - the same class of noise that check already tolerates at this size.
  4. Volume bookkeeping: face ~= gate_front.stl (they're the same geometry
     by construction - PART="face" and PART="all" are identical branches in
     gate_front.scad) and union(face, glyphs) ~= face + glyphs (confirms no
     double-counted overlap independent of check 3). All four numbers are
     printed.
"""
import argparse
import io
import sys
import zipfile
from pathlib import Path

import trimesh
from lxml import etree

NS_CORE = "http://schemas.microsoft.com/3dmanufacturing/core/2015/02"
OVERLAP_LIMIT_MM3 = 0.01   # matches interference_check.py's INTERFERENCE_LIMIT_MM3
VOLUME_TOL_MM3 = 0.01      # same-size tolerance for the volume-bookkeeping checks


def _normalize_hex(h):
    h = h.lstrip("#").upper()
    if len(h) == 6:
        h += "FF"   # opaque
    if len(h) != 8:
        raise ValueError(f"colour must be 6 (RRGGBB) or 8 (RRGGBBAA) hex digits: {h}")
    int(h, 16)  # raises if not hex
    return h


def build_3mf(face_path, glyphs_path, face_color, glyphs_color):
    """trimesh builds the geometry+names half; returns raw 3MF bytes with NO
    colour yet (see module docstring for why)."""
    face = trimesh.load(face_path, force="mesh")
    glyphs = trimesh.load(glyphs_path, force="mesh")
    scene = trimesh.Scene()
    scene.add_geometry(face, geom_name="face", node_name="face")
    scene.add_geometry(glyphs, geom_name="glyphs", node_name="glyphs")
    data = scene.export(file_type="3mf")
    return data, face, glyphs


def inject_colors(data, colors):
    """colors: {object name: '#RRGGBBAA'}. Returns new 3MF bytes with a
    <basematerials> resource added and pid/pindex set on each matching
    <object>."""
    zin = zipfile.ZipFile(io.BytesIO(data))
    model_xml = zin.read("3D/3dmodel.model")
    root = etree.fromstring(model_xml)
    ns = {"c": NS_CORE}
    resources = root.find("c:resources", ns)
    objects = resources.findall("c:object", ns)

    used_ids = {int(o.get("id")) for o in objects}
    mat_id = max(used_ids) + 1

    basematerials = etree.Element(f"{{{NS_CORE}}}basematerials", id=str(mat_id))
    name_to_index = {}
    for name, hexcolor in colors.items():
        idx = len(name_to_index)
        name_to_index[name] = idx
        etree.SubElement(basematerials, f"{{{NS_CORE}}}base",
                          name=name, displaycolor=f"#{hexcolor}")
    resources.insert(0, basematerials)  # define before any object references it

    matched = set()
    for obj in objects:
        name = obj.get("name")
        if name in name_to_index:
            obj.set("pid", str(mat_id))
            obj.set("pindex", str(name_to_index[name]))
            matched.add(name)
    missing = set(colors) - matched
    if missing:
        raise RuntimeError(f"no <object> matched name(s) {missing} to colour")

    new_model_xml = etree.tostring(root, xml_declaration=True, encoding="utf-8")

    out = io.BytesIO()
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            content = zin.read(item.filename)
            if item.filename == "3D/3dmodel.model":
                content = new_model_xml
            zout.writestr(item, content)
    return out.getvalue()


def verify_reload(path):
    """Check 1: trimesh can reload the file and sees exactly the 2 expected
    named geometries (trimesh does not read colour back - see docstring)."""
    scene = trimesh.load(path, force="scene")
    names = sorted(scene.geometry.keys())
    if names != ["face", "glyphs"]:
        raise RuntimeError(f"trimesh reload: expected geometries [face, glyphs], got {names}")
    print(f"reload_geometries={names}")


def verify_colors_on_disk(path, expected_colors):
    """Check 2: parse the file we actually wrote (from disk) and confirm the
    basematerials block + pid/pindex survived intact - this is what a slicer
    reads, independent of trimesh's own (colour-blind) loader."""
    with zipfile.ZipFile(path) as z:
        root = etree.fromstring(z.read("3D/3dmodel.model"))
    ns = {"c": NS_CORE}
    bases = root.findall(".//c:basematerials/c:base", ns)
    found_colors = {b.get("name"): b.get("displaycolor") for b in bases}
    for name, hexcolor in expected_colors.items():
        want = f"#{hexcolor}"
        got = found_colors.get(name)
        if got != want:
            raise RuntimeError(f"basematerials[{name}]: expected {want}, got {got}")
    if len(set(found_colors.values())) != len(found_colors):
        raise RuntimeError(f"basematerials colours are not distinct: {found_colors}")
    objs = {o.get("name"): (o.get("pid"), o.get("pindex")) for o in root.findall(".//c:object", ns)}
    if objs.get("face") == objs.get("glyphs"):
        raise RuntimeError(f"face and glyphs point at the same pid/pindex: {objs}")
    print(f"3mf_colors={found_colors}")
    print(f"3mf_object_pid_pindex={objs}")


def check_geometry(dir_path, face, glyphs):
    """Checks 3+4: overlap and volume bookkeeping via manifold3d booleans."""
    gate_front_path = dir_path / "print" / "gate_front.stl"
    gate_front = trimesh.load(gate_front_path, force="mesh")

    inter = trimesh.boolean.intersection([face, glyphs], engine="manifold", check_volume=False)
    overlap = 0.0 if inter.is_empty else abs(inter.volume)
    print(f"overlap_mm3={overlap:.6f}")

    union = trimesh.boolean.union([face, glyphs], engine="manifold", check_volume=False)
    face_vol = face.volume
    glyphs_vol = glyphs.volume
    gate_front_vol = gate_front.volume
    union_vol = union.volume
    sum_vol = face_vol + glyphs_vol

    print(f"face_volume_mm3={face_vol:.4f}")
    print(f"glyphs_volume_mm3={glyphs_vol:.4f}")
    print(f"gate_front_stl_volume_mm3={gate_front_vol:.4f}")
    print(f"union_volume_mm3={union_vol:.4f}")
    print(f"sum_face_plus_glyphs_mm3={sum_vol:.4f}")

    ok = True
    if overlap > OVERLAP_LIMIT_MM3:
        print(f"FAIL: overlap_mm3={overlap:.6f} exceeds limit {OVERLAP_LIMIT_MM3}")
        ok = False
    if abs(face_vol - gate_front_vol) > VOLUME_TOL_MM3:
        print(f"FAIL: face volume {face_vol:.4f} != gate_front.stl volume {gate_front_vol:.4f}")
        ok = False
    if abs(union_vol - sum_vol) > VOLUME_TOL_MM3:
        print(f"FAIL: union volume {union_vol:.4f} != face+glyphs {sum_vol:.4f}")
        ok = False
    return ok


def parse_args(argv):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("dir", nargs="?", default=".", help="directory containing the input STLs")
    p.add_argument("--face-color", default="6E6E6E", help="hex colour for the face part")
    p.add_argument("--glyphs-color", default="000000", help="hex colour for the glyphs part")
    p.add_argument("--out", default="gate_front_ams.3mf", help="output 3MF filename")
    return p.parse_args(argv)


def main(argv):
    args = parse_args(argv)
    d = Path(args.dir)
    face_color = _normalize_hex(args.face_color)
    glyphs_color = _normalize_hex(args.glyphs_color)
    colors = {"face": face_color, "glyphs": glyphs_color}

    face_path = d / "print" / "gate_front_face.stl"
    glyphs_path = d / "print" / "gate_front_glyphs.stl"
    out_path = d / "print" / args.out

    raw, face, glyphs = build_3mf(face_path, glyphs_path, face_color, glyphs_color)
    colored = inject_colors(raw, colors)
    out_path.write_bytes(colored)
    print(f"wrote {out_path} ({len(colored)} bytes)")

    verify_reload(out_path)
    verify_colors_on_disk(out_path, colors)
    ok = check_geometry(d, face, glyphs)
    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
