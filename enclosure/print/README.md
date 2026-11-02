# print/ — pipeline exports

Every STL/3MF `render.ps1` produces lands here (2026-08-18). Regenerated on
every pipeline run — nothing in this directory is hand-edited, and the
whole directory is git-ignored (`enclosure/print/` in `../../.gitignore`).

## Finished print set

The parts that make up the actual assembled enclosure:

| File | Part |
|---|---|
| `gate_rear.stl` | gate back plate |
| `base_main.stl` | pedestal body |
| `rear_cover.stl` | dish enclosing gate_rear's wiring |
| `gate_front_ams.3mf` | gate front, multi-colour (face + glyph ink), for Bambu Studio/AMS |
| `chevron.stl` | one chevron — print ×9 |
| `base_bottom.stl` | pedestal bottom cover |
| `diffuser.stl` | LED diffuser disc |

## Test coupons

Fit/verification coupons, not part of the final assembly — see `DESIGN.md`'s
verification ladder and `MEASUREMENTS.md` for what each one proved:

| File | Coupon |
|---|---|
| `couponA.stl` | screen pocket + M2 insert boss |
| `couponB.stl` / `couponB_diff.stl` | LED window/diffuser wedge (lit test) |
| `couponC.stl` | annular LED pocket + lead slot fit |
| `couponD.stl` | cover-lip / rear-groove mating fit |

## AMS component STLs

Single-colour building blocks used to construct `gate_front_ams.3mf` (via
`tools/make_3mf.py`) — not printed on their own:

| File | Role |
|---|---|
| `gate_front_face.stl` | face body, coloured separately in the 3MF |
| `gate_front_glyphs.stl` | glyph "ink" solids, coloured separately in the 3MF |
| `gate_front.stl` | single-colour fallback — same geometry as face+glyphs combined, for printers without an AMS |
