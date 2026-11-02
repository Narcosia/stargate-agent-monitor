// VIEW ONLY — insert/pin location maps for docs/ (never exported for print).
// Each VIEW is a straight-on orthographic "drawing" of one face with a
// colour-coded marker disc standing on every hole, so the four M2 heat-set
// groups and the two filament-pin groups can be told apart at a glance.
// Positions come from the same config constants the parts use, so the map
// can't drift from the geometry.
//
//   VIEW = "rear_front"  gate_rear FRONT face (as seen assembled, from the front)
//   VIEW = "rear_back"   gate_rear BACK face  (as seen from behind)
//   VIEW = "front_face"  gate_front FRONT face
//   VIEW = "base_under"  base_main upside down (bottom-cover rebate)
//
// Render (from enclosure/):
//   openscad.com -D VIEW=\"rear_front\" -o ../docs/img/inserts-rear-front.png \
//     --projection=o --camera=0,0,0,0,0,0,150 --imgsize=1200,1200 \
//     --colorscheme="Tomorrow Night" insert_map.scad
include <config.scad>
$fn = FN;
VIEW = "rear_front";

// marker colours (also the legend in docs/index.html)
C_FRONT  = [0, 1, 1];        // A  front-plate inserts      (gate_rear front, ×4)
C_COVER  = [1, 0, 1];        // B  rear-cover inserts       (gate_rear back,  ×4)
C_PILLAR = [1, 0.55, 0];     // C  pillar-retention inserts (gate_rear back,  ×2)
C_BASE   = [0, 1, 0.3];      // D  bottom-cover inserts     (base_main,       ×4)
C_PIN    = [0.6, 0.3, 1];    // P  filament pins, glued     (reg pin + chevron pins)

MK_D = 6;  MK_H = 1.6;   // marker disc
module mk(c, d = MK_D) color(c) cylinder(d = d, h = MK_H);

if (VIEW == "rear_front") {
    // assembly.scad's front-view frame: rotate([180,0,180]) puts the front
    // face on top with gate-local 90° at 12 o'clock and 270° (USB) at 6.
    rotate([180, 0, 180]) {
        color("gray") import("print/gate_rear.stl");
        // A: 4 front-plate inserts, front face z=0, marker stands out to -z
        for (a = [45, 135, 225, 315]) rotate([0, 0, a])
            translate([GATE_OD/2 - 6, 0, -MK_H]) mk(C_FRONT);
        // P: registration pin (Ø2×3, glued) at REG_PIN_ANG_REAR
        rotate([0, 0, REG_PIN_ANG_REAR]) translate([REG_PIN_R, 0, -MK_H]) mk(C_PIN, 4);
    }
} else if (VIEW == "rear_back") {
    color("gray") import("print/gate_rear.stl");
    // B: 4 rear-cover inserts, back face z=REAR_T
    for (a = REAR_COVER_HOLE_ANGLES) rotate([0, 0, a])
        translate([REAR_COVER_HOLE_R, 0, REAR_T]) mk(C_COVER);
    // C: 2 pillar-retention inserts
    for (a = REAR_PILLAR_ANG) rotate([0, 0, a])
        translate([REAR_PILLAR_R, 0, REAR_T]) mk(C_PILLAR);
} else if (VIEW == "front_face") {
    // v2 front is modelled face-up; its own frame == the assembled front view
    color("lightgray") import("print/gate_front.stl");
    ztop = FRONT_T + OUTER_RING[2];
    // A (pass-through): the 4 counterbored screw holes over the front inserts
    for (a = [45, 135, 225, 315]) rotate([0, 0, a])
        translate([GATE_OD/2 - 6, 0, ztop]) mk(C_FRONT);
    // P: 18 chevron pins, two per chevron centreline
    for (k = [0 : CHEVRON_N - 1]) rotate([0, 0, 270 + k * 40  /* chevron BDC, 2026-08-20 */])
        for (r = CHEV_PIN_R) translate([r, 0, ztop]) mk(C_PIN, 3.2);
} else if (VIEW == "base_under") {
    // flipped toward the viewer: rear wall lands at the bottom of the image
    rotate([180, 0, 0]) {
        color("dimgray") import("print/base_main.stl");
        // D: 4 bottom-cover inserts, drilled up from the rebate ceiling (z=2)
        for (sx = [-1, 1]) for (sy = [-1, 1])
            translate([sx * BASE_SCREW_XY[0], sy * BASE_SCREW_XY[1], 2 - MK_H]) mk(C_BASE);
    }
}
echo("INSERT_MAP_DONE");
