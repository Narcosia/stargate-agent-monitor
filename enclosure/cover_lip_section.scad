// VIEW ONLY — throwaway verification helper (Round 17). Reviewer's own
// method: intersect the exported rear_cover.stl with a thin radial box at
// one angle (world +X, where the lip is present — well inside the kept
// arc) so the lip's cross-section (including the 45-deg chamfer lead-in)
// is visible edge-on. Not a printable part, not gated by tests.scad.
intersection() {
    import("print/rear_cover.stl");
    translate([50, -0.5, -1]) cube([7, 1, 10]);
}
echo("COVER_LIP_SECTION_DONE");
