include <config.scad>
$fn = FN;
// Bed rules learned the hard way: every body's bottom sits EXACTLY at z=0
// (part (c) once straddled z=0 centred — the slicer floated the whole plate
// 2.9 mm and it "peeled" twice), and every body gets snap-off mouse ears.
module ear(px, py) { translate([px, py, 0]) cylinder(d = BRIM_D, h = BRIM_T); }

// (a) screen pocket + bezel coupon
difference() {
    cylinder(d = 60, h = 8);
    translate([0, 0, 2]) cylinder(d = SCREEN_POCKET_D, h = 7);   // diameter-fit proxy: 6 mm-deep pocket, 2 mm floor
    translate([0, 0, -0.5]) cylinder(d = FRONT_OPEN_D, h = 3);
}
for (a = [0, 90, 180, 270]) ear(34 * cos(a), 34 * sin(a));

// (b) M2 insert-grip boss coupon
translate([55, 0, 0]) difference() {
    cylinder(d = M2_BOSS_D + 4, h = M2_BOSS_H);
    translate([0, 0, -0.5]) cylinder(d = M2_INSERT, h = M2_BOSS_H + 1);
}
for (p = [[64, 0], [55, 9], [55, -9]]) ear(p[0], p[1]);

// (c) LED pocket arc coupon — pocket OPENS through the top face, and the
// block is LIFTED so its bottom sits on the bed (never straddle z=0)
translate([55, 30, (LED_POCKET_T + 2) / 2]) difference() {
    cube([30, 14, LED_POCKET_T + 2], center = true);
    translate([0, 0, 1.5]) cube([26, 12.6, LED_POCKET_T + 1], center = true);
}
for (p = [[36, 30], [74, 30]]) ear(p[0], p[1]);

// (d) rib crush plate — press the puck's rear rim onto the ribs
// (ribs sunk MERGE_OVERLAP into the plate so they weld into one shell;
// protrusion above the surface stays exactly RIB_H)
translate([-80, 0, 0]) {
    cylinder(d = 54, h = 2);
    for (a = RIB_ANGLES) rotate([0, 0, a])
        translate([RIB_R - RIB_L/2, -RIB_W/2, 2 - MERGE_OVERLAP])
            cube([RIB_L, RIB_W, RIB_H + MERGE_OVERLAP]);
}
for (p = [[-49, 0], [-80, 31], [-80, -31], [-111, 0]]) ear(p[0], p[1]);
echo("COUPON_A_DONE");
