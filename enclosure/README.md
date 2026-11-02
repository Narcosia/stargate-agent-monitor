# enclosure — 3D-printed housing for the status ring

Parametric CAD-as-code in **OpenSCAD + BOSL2**, following a workflow proven on
an earlier enclosure build: every
dimension lives in `config.scad`, every part is `CONFIRMED` or `PROVISIONAL`,
and nothing gets a full-shell print while anything is still provisional.

Design spec: [DESIGN.md](DESIGN.md). Caliper worksheet: [MEASUREMENTS.md](MEASUREMENTS.md).

## Setup

```powershell
winget install --id OpenSCAD.OpenSCAD
git clone --depth 1 https://github.com/BelfrySCAD/BOSL2.git enclosure/libs/BOSL2
```

`enclosure/libs/` is git-ignored — BOSL2 is fetched, not vendored.

## Rendering

The GUI `openscad.exe` detaches from the console; use **`openscad.com`** for CLI
work so you get exit codes and stderr. OpenSCAD 2021.01 exits 0 even on
assertion failure — check the `.echo` output for `ERROR`, never the exit code
alone (the batch script does this for you).

```bash
export OPENSCADPATH="$PWD/libs"   # run from enclosure/
"/c/Program Files/OpenSCAD/openscad.com" -o renders/iso.png \
    --imgsize=980,700 assembly.scad
```

## Multi-colour print (AMS)

`gate_front`'s 39 glyphs export as a separate coloured solid so a Bambu H2D +
AMS can print them in a different filament from the face, with no manual
painting in Bambu Studio. The pipeline (`render.ps1`) produces
`print/gate_front_ams.3mf`: one assembled object with two named, pre-coloured
parts ("face" grey `#6E6E6E`, "glyphs" black `#000000` by default -
`python tools/make_3mf.py --face-color HEX --glyphs-color HEX` to override).
The glyph geometry itself is unchanged from the single-colour part - it's
the same 0.7 mm engraving, now with its bottom 0.5 mm filled by a second,
separate solid (`GLYPH_INK_T` in `config.scad`) instead of staying empty, so
the top 0.2 mm still reads as a real recess.

**To print it:** File -> Import -> `print/gate_front_ams.3mf`. It should land in
Bambu Studio as one object with 2 parts already carrying their own colours
(3MF core-spec `<basematerials>` + per-object `pid`/`pindex`, verified by
round-tripping the file - see `tools/make_3mf.py`'s docstring); right-click
each part in the object list -> Change Filament to assign it to an AMS
slot. This repo cannot run Bambu Studio itself, so that landing behaviour
is inferred from the 3MF spec and the file's own verified contents, not
browser/app-tested - if Studio doesn't pick the colours up automatically,
the fallback is: import `print/gate_front_face.stl` + `print/gate_front_glyphs.stl`
together, choose "Load as single object with multiple parts" = Yes, then
assign filaments per part manually.

A flush/purge tower will appear regardless of import method. The colour
change is cheap: the ink layers are only the bottom 0.5 mm of each
engraving, so at the standard 0.2 mm layer height the tool change happens
over 2-3 layers near z = 5.3-5.8 mm in the face-up print, not a full-height
swap.

## Files

| File | Purpose |
|---|---|
| `DESIGN.md` | design spec — goals, decisions, open questions |
| `MEASUREMENTS.md` | caliper worksheet — measured hardware dimensions feeding `config.scad` |
| `print/` | every STL/3MF `render.ps1` exports (finished parts, coupons, AMS component STLs) — git-ignored, regenerated each pipeline run, see `print/README.md` |

CAD files (`config.scad`, `parts.scad`, the body files, `tests.scad`, coupons,
`render.ps1`) land once the design conversation has settled the form factor.
`renders/` (PNGs) and `print/` (STLs/3MF) are both git-ignored pipeline
output — nothing the pipeline produces lives loose in `enclosure/` itself.

## The rules

Carried over from an earlier enclosure build, where every one of these was learned the
hard way:

1. **No full shell print while any part is still `provisional`.** Print a
   coupon, physically drop the part in, then promote it to `confirmed`.
2. **Fit-check dynamically, not just statically.** A part that drops in can
   still bind when it moves, turns, or is pressed.
3. **Renders lie.** Real defects were invisible in renders, assertions, and
   manifold checks. Count STL connected components; print coupons.
4. **Assertions must be mutation-tested.** An assertion that cannot fail is
   decoration — break the config on purpose once and watch it catch it.
