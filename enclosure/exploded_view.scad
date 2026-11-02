// VIEW ONLY — exploded assembly for docs/ (never exported for print).
// Mirrors assembly.scad's placement transforms exactly, then slides each
// part along the gate's local z axis so the stacking order reads at a glance.
// Render (from enclosure/, dark background to match docs/index.html):
//   openscad.com -o ../docs/img/assembly-exploded.png --imgsize=1600,1200 \
//     --camera=0,-20,95,65,0,55,520 --colorscheme="Tomorrow Night" exploded_view.scad
include <config.scad>
use <parts.scad>
$fn = FN;
E = 26;   // explode pitch (mm)

color("dimgray") import("print/base_main.stl");

translate([0, 0, GATE_CZ + 40]) rotate([90, 0, 180]) {
    // gate_rear stays put (reference)
    color("gray") import("print/gate_rear.stl");
    // front-side parts slide toward the viewer (local -z)
    color("lightgray") translate([0, 0, -2.6*E]) rotate([180, 0, 180]) import("print/gate_front.stl");
    color("firebrick") translate([0, 0, -3.5*E]) rotate([180, 0, 180])
        for (k = [0 : CHEVRON_N - 1]) rotate([0, 0, 270 + k * 40  /* chevron BDC, 2026-08-20 */])
            translate([CHEV_R0, 0, FRONT_T + OUTER_RING[2]])
                import("print/chevron.stl");
    color("white", 0.6) translate([0, 0, LED_POCKET_T - LED_T - DIFF_T - 1.7*E]) import("print/diffuser.stl");
    color("red")   translate([0, 0, LED_POCKET_T - LED_T - 1.1*E]) led_ring();
    color("green") translate([0, 0, 0.2 - 0.6*E]) screen_puck();
    // rear cover slides back (local +z)
    color("dimgray", 0.9)
        translate([0, 0, REAR_T + REAR_COVER_T + 1.2*E]) rotate([0, 180, 0])
            import("print/rear_cover.stl");
}
echo("EXPLODED_DONE");
