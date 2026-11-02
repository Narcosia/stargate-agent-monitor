include <config.scad>
use <decor.scad>
$fn = FN;

// PART selects the exported body for the multi-colour AMS export:
//   "all"    (default) - the current full part, unchanged behaviour.
//   "face"   - identical geometry to "all": the face body IS the whole
//              part, with engravings cut exactly as always.
//   "glyphs" - ONLY the coloured "ink" solids (see glyph_ink() below).
// Override via -D 'PART="glyphs"' (Windows PowerShell 5.1 strips embedded
// quotes passed to native processes - build the arg as a variable first,
// see render.ps1's $glyphsParam, same pattern as couponB's $diffParam).
PART = "all";

// v2 decorated face, modelled FACE-UP: z=0 is the rear mating face (prints on
// the bed, support-free), z=FRONT_T is the viewer face, relief rises above it.
// assembly.scad places this with rotate([180,0,180]): the flip mirrors y, and
// Rz(180) restores the window/screw/chevron lattices (all symmetric about 90).
module ring(r0, r1, relief) {   // raised annulus welded into the plate
    rotate_extrude()
        polygon([[r0, FRONT_T - MERGE_OVERLAP], [r1, FRONT_T - MERGE_OVERLAP],
                 [r1, FRONT_T + relief], [r0, FRONT_T + relief]]);
}

module window_cut() {
    rotate([0, 0, -WINDOW_ARC/2]) rotate_extrude(angle = WINDOW_ARC)
        polygon([[WINDOW_R0, -1], [WINDOW_R1, -1],
                 [WINDOW_R1, FRONT_T + RELIEF_MAX + 1],
                 [WINDOW_R0, FRONT_T + RELIEF_MAX + 1]]);
}

module gate_front() {
    difference() {
        union() {
            cylinder(d = GATE_OD, h = FRONT_T);
            ring(BEZEL_RING[0], BEZEL_RING[1], BEZEL_RING[2]);
            ring(TRACK_RING[0], TRACK_RING[1], TRACK_RING[2]);
            ring(OUTER_RING[0], OUTER_RING[1], OUTER_RING[2]);
        }
        // frozen through-cuts
        translate([0, 0, -0.5])
            cylinder(d = FRONT_OPEN_D, h = FRONT_T + RELIEF_MAX + 1);
        for (i = [0 : N_LED - 1])
            rotate([0, 0, 90 + i * WINDOW_PITCH]) window_cut();
        // frozen M2 screws — counterbored from the RAISED outer-ring top
        for (a = [45, 135, 225, 315]) rotate([0, 0, a])
            translate([GATE_OD/2 - 6, 0, 0]) {
                translate([0, 0, -0.5])
                    cylinder(d = M2_CLEAR, h = FRONT_T + OUTER_RING[2] + 1);
                translate([0, 0, FRONT_T + OUTER_RING[2] - CB_DEPTH])
                    cylinder(d = 4.5, h = CB_DEPTH + 1);
            }
        // outer-ring segmentation: radial grooves + one circumferential groove
        for (k = [0 : SEG_N - 1]) rotate([0, 0, k * 360 / SEG_N])
            translate([OUTER_RING[0] - 1, -SEG_GROOVE[0]/2,
                       FRONT_T + OUTER_RING[2] - SEG_GROOVE[1]])
                cube([OUTER_RING[1] - OUTER_RING[0] + 2, SEG_GROOVE[0],
                      SEG_GROOVE[1] + 1]);
        rotate_extrude()
            translate([50.5 - SEG_GROOVE[0]/2,
                       FRONT_T + OUTER_RING[2] - SEG_GROOVE[1]])
                square([SEG_GROOVE[0], SEG_GROOVE[1] + 1]);
        // 24 mullion tick-marks in the track ring (aligned to window gaps)
        for (i = [0 : N_LED - 1]) rotate([0, 0, 90 + 7.5 + i * WINDOW_PITCH])
            translate([TRACK_RING[0] - 1, -0.4,
                       FRONT_T + TRACK_RING[2] - 0.4])
                cube([TRACK_RING[1] - TRACK_RING[0] + 2, 0.8, 0.9]);
        // the glyph band
        glyph_band_cuts();
        // chevron pin holes on the 9 centrelines
        for (k = [0 : CHEVRON_N - 1]) rotate([0, 0, 270 + k * 40  /* chevron BDC, 2026-08-20 */])
            for (r = CHEV_PIN_R)
                translate([r, 0, FRONT_T + OUTER_RING[2] - CHEV_PIN_DEPTH])
                    cylinder(d = CHEV_PIN_D, h = CHEV_PIN_DEPTH + 1);
        // Round 16: rim brickwork continuity — this plate's own cylindrical
        // edge (r = GATE_OD/2) gets the SAME 36 axial grooves as gate_rear's
        // rim, via decor.scad's shared rim_grooves() so the phase can't
        // drift (see gate_rear.scad's own comment for the assembly-
        // transform proof that the shared k*360/SEG_N formula lands on the
        // same world angles here unmodified). No skip — no USB tunnel on
        // this part; cut regardless of the chevron pads overhanging some of
        // these angles (they sit on top, as a separate imported part, and
        // simply hide the tick visually). Gated by the SAME RIM_GROOVES
        // switch as gate_rear/rear_cover so it stays one on/off decision
        // for the whole stack, not three.
        //
        // Round 17 FIX 4 (reviewer DO-NOT-PRINT): height was FRONT_T (6),
        // matching only the plain-plate portion of the rim — but the raised
        // OUTER_RING continues the SAME cylindrical surface up to
        // FRONT_T+OUTER_RING[2] (7.5), and its own top-face radial grooves
        // (the "outer-ring segmentation" cut above) cut down to
        // FRONT_T+OUTER_RING[2]-SEG_GROOVE[1] (6.7). rim_grooves()'s own
        // +1 z-overflow only reached FRONT_T+0.5 (6.5), leaving a 0.2mm
        // membrane (z 6.5..6.7) uncut across all 36 ticks on the visible
        // ring edge. Extending the cut height to the ring's own top
        // (FRONT_T+OUTER_RING[2]) — with the module's own +1 overflow —
        // comfortably clears it.
        if (RIM_GROOVES) rim_grooves(FRONT_T + OUTER_RING[2]);
        // Round 16: registration pin — blind hole in this REAR (mating)
        // face, matched to gate_rear's own pin at the derived
        // REG_PIN_ANG_FRONT = 180 - REG_PIN_ANG_REAR (see config.scad).
        rotate([0, 0, REG_PIN_ANG_FRONT])
            translate([REG_PIN_R, 0, -0.01])
                cylinder(d = REG_PIN_D, h = REG_PIN_DEPTH + 0.01);
    }
}

// AMS colour "ink": fills the bottom GLYPH_INK_T of each of the 39 glyph
// engravings, z = [FRONT_T-GLYPH_DEPTH, FRONT_T-GLYPH_DEPTH+GLYPH_INK_T],
// leaving the top (GLYPH_DEPTH-GLYPH_INK_T) as a real recess so the glyph
// still reads as engraved AND coloured. Reuses decor.scad's glyph2d(i) with
// the EXACT same per-cell rotate/translate as glyph_band_cuts() so each ink
// body registers precisely inside the void it fills - it never touches the
// face solid (tests.scad asserts GLYPH_INK_T < GLYPH_DEPTH, so the ink
// never reaches the cut's full depth).
//
// Divider lines (the radial cell-boundary notches cut by glyph_band_cuts())
// are left face-coloured on purpose: they read as mechanical segmentation
// between cells, not glyph artwork, so no ink body is generated for them -
// no PART="dividers" was added.
//
// Hook: a PART="grooves" third colour for the segment/track groove floors
// was considered and skipped as non-trivial - the outer-ring radial
// grooves, the outer-ring circumferential groove, and the track mullion
// ticks are three different depths/geometries, so isolating just their
// floor slices cleanly needs its own per-family difference(), not a
// trivial reuse of the cut geometry in gate_front() above.
module glyph_ink() {
    for (i = [0 : GLYPH_N - 1]) rotate([0, 0, i * 360 / GLYPH_N])
        rotate([0, 0, 180 / GLYPH_N])
            translate([GLYPH_BAND[0] + 0.7, 0, FRONT_T - GLYPH_DEPTH])
                linear_extrude(GLYPH_INK_T)
                    glyph2d(i);
}

if (PART == "glyphs")
    glyph_ink();
else
    gate_front();   // "all" and "face" are identical

echo("GATE_FRONT_DONE");
