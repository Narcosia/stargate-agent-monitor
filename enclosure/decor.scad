// Shared 2D decoration artwork. Consumed by gate_front.scad and chevron.scad.
include <config.scad>

// --- glyphs: deterministic pseudo-runes from 8 stroke primitives ------------
// unit cell 0..1 x 0..1; strokes >= 0.15 units wide so the narrowest printed
// line is 0.15 * GLYPH_CELL[1] = 0.69 mm (spec floor 0.6)
module glyph_stroke(s) {
    if (s == 0)      polygon([[0.15,0.05],[0.30,0.05],[0.30,0.95],[0.15,0.95]]);
    else if (s == 1) polygon([[0.70,0.05],[0.85,0.05],[0.85,0.95],[0.70,0.95]]);
    else if (s == 2) polygon([[0.05,0.80],[0.95,0.80],[0.95,0.95],[0.05,0.95]]);
    else if (s == 3) polygon([[0.05,0.05],[0.95,0.05],[0.95,0.20],[0.05,0.20]]);
    else if (s == 4) polygon([[0.05,0.42],[0.95,0.42],[0.95,0.58],[0.05,0.58]]);
    else if (s == 5) polygon([[0.05,0.05],[0.20,0.05],[0.95,0.80],[0.80,0.95]]);
    else if (s == 6) polygon([[0.05,0.95],[0.20,0.95],[0.95,0.20],[0.80,0.05]]);
    else             translate([0.5, 0.5]) circle(d = 0.30);
}

module glyph2d(i) {   // 2-3 strokes, deterministic per cell index
    scale([GLYPH_CELL[0], GLYPH_CELL[1]]) translate([0, -0.5]) {
        glyph_stroke(i % 8);
        glyph_stroke((i * 3 + 1) % 8);
        if (i % 2 == 0) glyph_stroke((i * 5 + 2) % 8);
    }
}

// world-frame engraving cuts for the whole glyph band: 39 cells, each a
// radial divider line + a glyph, cut GLYPH_DEPTH into the flat band surface
// at z = FRONT_T (the v2 face-up front's viewer face)
module glyph_band_cuts() {
    for (i = [0 : GLYPH_N - 1]) rotate([0, 0, i * 360 / GLYPH_N]) {
        translate([GLYPH_BAND[0], -0.3, FRONT_T - 0.5])
            cube([GLYPH_BAND[1] - GLYPH_BAND[0], 0.6, 0.5 + RELIEF_MAX + 1]);
        rotate([0, 0, 180 / GLYPH_N])
            translate([GLYPH_BAND[0] + 0.7, 0, FRONT_T - GLYPH_DEPTH])
                linear_extrude(GLYPH_DEPTH + RELIEF_MAX + 1)
                    glyph2d(i);
    }
}

// --- chevron -----------------------------------------------------------------
// local frame: x = radial distance from CHEV_R0, y = tangential, centreline y=0.
// Narrow stem (4.0 wide) through the screw zone, wide pad riding the rim.
module chevron_profile() {
    polygon([
        [0.0,  0.0],     // apex tip at r = CHEV_R0
        [5.5,  2.0],     // stem widens to 4.0 by r 51
        [6.0,  6.5],     // pad inner corner, r 51.5
        [9.4,  5.5],     // pad outer corner, r 54.9 (flush with OUTER_RING)
        [9.4, -5.5],
        [6.0, -6.5],
        [5.5, -2.0]
    ]);
}

// --- rim brickwork: shared by gate_rear/gate_front/rear_cover (Round 16) ---
// 36 axial grooves at SEG_N's own k*360/SEG_N pitch, cut into the outer
// Ø GATE_OD cylindrical surface, running the caller's own z-height h (each
// part supplies its own h — REAR_T/FRONT_T/REAR_COVER_T all differ). ONE
// module for all three parts so the pattern can't drift out of phase the
// way three hand-copied loops could; gate_rear.scad used to keep this
// privately (Task 6 Step 12a) — hoisted here now that rear_cover.scad and
// gate_front.scad need the identical formula too.
module rim_grooves(h, skip = []) {
    for (k = [0 : SEG_N - 1])
        let (a = k * 360 / SEG_N)
        if (len([for (s = skip) if (abs(a - s) < 0.01) s]) == 0)
            rotate([0, 0, a])
                translate([GATE_OD/2 - SEG_GROOVE[1], -SEG_GROOVE[0]/2, -0.5])
                    cube([SEG_GROOVE[1] + 1, SEG_GROOVE[0], h + 1]);
}

echo("DECOR_LOADED");
