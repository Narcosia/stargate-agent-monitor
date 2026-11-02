// diffuser.scad — print in translucent PETG, frost 400-600 grit
include <config.scad>
$fn = FN;
difference() {
    cylinder(d = DIFF_OD, h = DIFF_T);
    translate([0, 0, -0.5]) cylinder(d = DIFF_ID, h = DIFF_T + 1);
}
echo("DIFFUSER_DONE");
