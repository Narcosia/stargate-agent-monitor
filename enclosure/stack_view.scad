// VIEW ONLY — throwaway render helper (Round 16). assembly.scad's gate-
// stack block, minus the base_main import: renders/stack_edge.png needs the
// rim drum visible edge-on across gate_front/gate_rear/rear_cover without
// the pedestal in the way. Not a printable part, not gated by tests.scad.
include <config.scad>
use <parts.scad>
$fn = FN;

translate([0, 0, GATE_CZ]) rotate([90, 0, 180]) {
    color("lightgray") import("print/gate_rear.stl");
    color("gray") rotate([180, 0, 180]) import("print/gate_front.stl");
    color("firebrick") rotate([180, 0, 180])
        for (k = [0 : CHEVRON_N - 1]) rotate([0, 0, 90 + k * 40])
            translate([CHEV_R0, 0, FRONT_T + OUTER_RING[2]])
                import("print/chevron.stl");
    color("dimgray", 0.85)
        translate([0, 0, REAR_T + REAR_COVER_T]) rotate([0, 180, 0])
            import("print/rear_cover.stl");
}
echo("STACK_VIEW_DONE");
