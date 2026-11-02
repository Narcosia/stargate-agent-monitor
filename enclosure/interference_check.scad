// MANUAL/EXPLORATORY TOOL ONLY — NOT part of the automated pipeline (Round
// 15, Narcosia review). render.ps1 no longer invokes this file: OpenSCAD's
// CGAL Nef-polyhedron boolean permanently errors on the decorated
// base_main mesh ("CGAL error ... e_below", every run, not a fluke — Round
// 14 FIX C), costing ~53s and a WARNING for zero information every pipeline
// run. tools/interference_check.py (trimesh + manifold3d, a real polygon
// mesh boolean that doesn't share CGAL's Nef fragility here) is the sole
// authoritative interference gate now — see render.ps1's
// Invoke-InterferenceCheck. This file is kept only as a documented manual
// check: it still works correctly by hand on simpler, non-decorated
// geometry (e.g. after temporarily stripping the dock decoration), useful
// for spot-checking with OpenSCAD's own preview/CGAL view.
//
// Original framing (still accurate as a description of INTENT, just no
// longer the enforcement mechanism): boolean intersection of the printed
// base against the fully assembled gate (rear + front + 9 chevrons + rear
// cover), using assembly.scad's EXACT transforms. An empty result (no
// triangles) means the two bodies don't touch — a non-empty result is real
// interference the physical parts would hit on assembly. This is what
// caught the buttress heads striking the gate disc by ~7,400 mm^3 (review
// Critical, 2026-08-13): invisible in every render because gate_front
// visually covers gate_rear from the same viewing angles the renders used,
// and invisible to the shells/zmin gates because each part is
// independently manifold.
include <config.scad>
$fn = FN;
// GATE_CZ now lives in config.scad (Task 6 Step 11d, review Critical fix,
// 2026-08-16) — was redefined identically here; hoisted to a single source
// so it can never drift from what base_main.scad/tests.scad use.

intersection() {
    import("print/base_main.stl");
    // exact copy of assembly.scad's gate-stack transform
    translate([0, 0, GATE_CZ]) rotate([90, 0, 180]) {
        import("print/gate_rear.stl");
        rotate([180, 0, 180]) import("print/gate_front.stl");
        rotate([180, 0, 180])
            for (k = [0 : CHEVRON_N - 1]) rotate([0, 0, 90 + k * 40])
                translate([CHEV_R0, 0, FRONT_T + OUTER_RING[2]])
                    import("print/chevron.stl");
        // rear cover dish (Task 6 Step 8) — same placement as assembly.scad
        translate([0, 0, REAR_T + REAR_COVER_T]) rotate([0, 180, 0])
            import("print/rear_cover.stl");
    }
}
echo("INTERFERENCE_CHECK_DONE");
