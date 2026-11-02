include <config.scad>
use <decor.scad>
$fn = FN;

// One chevron, printed flat (x = radial - CHEV_R0). Print 9 in red.
// Attach: 1.75 mm filament offcuts into the two pin holes + a dab of glue.
difference() {
    union() {
        linear_extrude(CHEV_T) chevron_profile();
        // jewel step on the pad only
        translate([0, 0, CHEV_T - MERGE_OVERLAP])
            linear_extrude(CHEV_JEWEL_T + MERGE_OVERLAP) intersection() {
                offset(delta = -1.4) chevron_profile();
                translate([6, -7]) square([3.4, 14]);
            }
    }
    for (r = CHEV_PIN_R)
        translate([r - CHEV_R0, 0, -0.5])
            cylinder(d = CHEV_PIN_D, h = CHEV_PIN_DEPTH + 0.5);
}
echo("CHEVRON_DONE");
