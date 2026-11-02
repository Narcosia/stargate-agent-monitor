include <config.scad>
$fn = FN;
module wedge(r_out) { rotate_extrude(angle = 90) square([r_out, 100]); }
WEDGE_R = GATE_OD/2;
PART = "front";   // -D PART="diff" for the diffuser arc
// DIFF_RECESS_T was deleted from config.scad in the Task 6 pocket rework
// (2026-08-13, the two-step pocket+recess collapsed to one annular cut);
// this pre-existing, already-printed coupon keeps its own local copy of the
// arithmetic so its geometry is unaffected by that config change.
DIFF_RECESS_T_LOCAL = DIFF_T + 0.2;

if (PART == "front") intersection() {
    translate([0, 0, -1]) wedge(WEDGE_R);
    // front plate wedge with 6 windows + its rear LED/diffuser pockets
    difference() {
        cylinder(d = GATE_OD, h = FRONT_T + LED_POCKET_T + DIFF_RECESS_T_LOCAL);
        for (i = [0 : 5]) rotate([0, 0, i * WINDOW_PITCH + WINDOW_PITCH/2])
            rotate([0, 0, -WINDOW_ARC/2]) rotate_extrude(angle = WINDOW_ARC)
                polygon([[WINDOW_R0, -1], [WINDOW_R1, -1],
                         [WINDOW_R1, FRONT_T + 1], [WINDOW_R0, FRONT_T + 1]]);
        // diffuser recess + LED pocket behind the windows
        translate([0, 0, FRONT_T]) difference() {
            cylinder(d = DIFF_OD + 0.4, h = DIFF_RECESS_T_LOCAL + LED_POCKET_T + 1);
            translate([0, 0, -0.5]) cylinder(d = DIFF_ID - 0.4, h = 20);
        }
    }
}
if (PART == "diff") intersection() {
    translate([0, 0, -1]) wedge(WEDGE_R);
    difference() {
        cylinder(d = DIFF_OD, h = DIFF_T);
        translate([0, 0, -0.5]) cylinder(d = DIFF_ID, h = DIFF_T + 1);
    }
}
echo("COUPON_B_DONE");
