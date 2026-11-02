// VIEW ONLY — never exported for print.
include <config.scad>
use <parts.scad>
use <gate_rear.scad>
$fn = FN;
// GATE_CZ now lives in config.scad (Task 6 Step 11d, review Critical fix,
// 2026-08-16) — was redefined identically here; hoisted to a single source
// so it can never drift from what base_main.scad/tests.scad use.

// base
color("dimgray") import("print/base_main.stl");
// gate stack, stood upright at the gate centre. rotate([90,0,180]), NOT
// [90,0,0] (faces away) or [-90,0,0] (looks right but flips the tabs
// upside-down): Rx(90) stands it up tabs-down, Rz(180) turns the face
// to the viewer.
translate([0, 0, GATE_CZ]) rotate([90, 0, 180]) {
    color("gray")      import("print/gate_rear.stl");
    // v2 front is modelled face-up; Rx(180) flips it onto the gate, Rz(180)
    // restores the y-mirrored lattices (windows/screws/chevrons, all
    // symmetric about 90 deg)
    color("lightgray") rotate([180, 0, 180]) import("print/gate_front.stl");
    // nine chevrons on the face (face-up frame, same transform as the front)
    color("firebrick") rotate([180, 0, 180])
        for (k = [0 : CHEVRON_N - 1]) rotate([0, 0, 270 + k * 40  /* chevron BDC, 2026-08-20 */])
            translate([CHEV_R0, 0, FRONT_T + OUTER_RING[2]])
                import("print/chevron.stl");
    // diffuser sits on top of the ring, at the pocket's front face — fixed
    // 2026-08-13 (review Minor): the old translate(LED_POCKET_T) buried it
    // behind the pocket floor instead of at the front-facing opening
    color("white", 0.5) translate([0, 0, LED_POCKET_T - LED_T - DIFF_T]) import("print/diffuser.stl");
    color("green")     translate([0, 0, 0.2]) screen_puck();
    color("red")       translate([0, 0, LED_POCKET_T - LED_T]) led_ring();
    // rear cover dish, encloses the back (wire zone) — Task 6 Step 8,
    // 2026-08-13; sealed plain dish (no rim notches) per Step 9, 2026-08-13
    // (the tabs live inside gate_rear's own thickness, entirely in front of
    // the cover — a closed dish never reaches them). Printed floor-at-z0
    // opening toward +z; rotate([0,180,0]) (X-axis flip) reverses that to
    // face the gate's back, with its floor becoming the outermost surface.
    // NOT rotate([180,0,0]) (Y-axis flip): the M2-hole angle set is only
    // symmetric under the X flip (verified 2026-08-13, see config.scad's
    // rear-cover comment and task-6-report.md).
    color("dimgray", 0.85)
        translate([0, 0, REAR_T + REAR_COVER_T]) rotate([0, 180, 0])
            import("print/rear_cover.stl");
}
echo("ASSEMBLY_DONE");
