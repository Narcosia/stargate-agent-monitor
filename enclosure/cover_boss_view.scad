// VIEW ONLY — rear_cover interior with the screw guide bosses (decision 26).
// Half the dish is cut away through two boss centrelines so the tubes and
// their bores read clearly. Render (from enclosure/):
//   openscad.com -o ../docs/img/rear-cover-bosses.png --imgsize=1400,1000 \
//     --camera=0,0,4,55,0,140,220 --colorscheme="Tomorrow Night" cover_boss_view.scad
include <config.scad>
$fn = FN;
difference() {
    import("print/rear_cover.stl");
    // cut away the half-space y > x·tan(30°)-ish: a big box rotated so the
    // section plane passes through the 30°/225°-adjacent region, leaving
    // the 315° and 150° bosses whole and sectioning the dish
    rotate([0, 0, 60]) translate([-200, 0, -1]) cube([400, 200, 20]);
}
echo("COVER_BOSS_VIEW_DONE");
