include <config.scad>
$fn = FN;
difference() {
    translate([0, 0, 1])
        cube([BASE_REBATE[0] - FIT - CLEAR, BASE_REBATE[1] - FIT - CLEAR, 2], center = true);
    for (sx = [-1, 1]) for (sy = [-1, 1])
        translate([sx * BASE_SCREW_XY[0], sy * BASE_SCREW_XY[1], -0.5])
            cylinder(d = M2_CLEAR, h = 3);
    for (sx = [-1, 1]) for (sy = [-1, 1])                       // feet recesses
        translate([sx * (BASE_CAV[0]/2 - 6), sy * (BASE_CAV[1]/2 - 6), -0.01])
            cylinder(d = 10, h = 1);
}
echo("BASE_BOTTOM_DONE");
