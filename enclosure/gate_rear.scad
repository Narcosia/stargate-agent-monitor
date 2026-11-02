include <config.scad>
use <parts.scad>
use <decor.scad>
$fn = FN;

// ------------------------------------------------ Task 6 Step 12 rim grooves ---
// Narcosia 2026-08-13 (decoration plan step 12a): 36 axial grooves at SEG_N's own
// 10-deg pitch, running the full height of this file's own clean Ø GATE_OD
// rim (z 0..REAR_T), plus one circumferential groove at mid-depth, so the
// rim reads as the same brick-segmented mechanical ring as the face. Round
// 16: the axial-groove generator itself is hoisted to decor.scad's shared
// rim_grooves(h, skip) (gate_front.scad and rear_cover.scad now call the
// same module for their own rims) — this file just supplies its own height
// and RIM_GROOVE_SKIP (config.scad).
//
// Phase match: gate_front's SEG_N grooves sit at ITS OWN local k*360/SEG_N
// (k=0..35), then the assembly wraps gate_front onto the shared gate-local
// frame (the one this file already sits in) via rotate([180,0,180]) — net
// effect on a point (r cosA, r sinA, z) is (x,y,z)->(-x,y,-z), i.e. shared-
// frame angle = 180-A. So gate_front's k-th groove lands, in this shared
// frame, at 180-10k. Since {10k mod 360 : k=0..35} already enumerates every
// multiple of 10 deg exactly once, so does {180-10k mod 360} — same 36-
// element set, just relabelled. Placing this file's own grooves at the
// IDENTICAL k*360/SEG_N formula (this file carries no extra rotation before
// the shared frame) therefore lands them on the same physical angles
// automatically — no phase offset to add (re-derived from assembly.scad's
// actual transform, not assumed). rear_cover.scad's own placement transform
// and its RIM_GROOVE_SKIP reuse are verified the same way in config.scad's
// comment on RIM_GROOVE_SKIP/REG_SKIP_LO/HI.

// Round 16: rear-cover registration groove — a RECESSED annulus on this
// BACK face (never proud: this face prints face-down, on top, so nothing
// may stand above it — the same constraint Step 11c already killed the
// raised COVER_LIP over). rear_cover.scad's matching lip seats into it.
// Swept everywhere EXCEPT the USB-tunnel arc via "rotate to the gap's far
// edge, then sweep the KEEP arc" — the same partial-rotate_extrude
// technique gate_front.scad's window_cut() uses, just inverted (sweeping
// what stays, not what's cut).
module reg_groove() {
    rotate([0, 0, REG_SKIP_HI])
        rotate_extrude(angle = 360 - (REG_SKIP_HI - REG_SKIP_LO))
            translate([REG_R - REG_W/2, REAR_T - REG_D])
                square([REG_W, REG_D + 0.5]);
}

module gate_rear() {
    difference() {
        // Task 6 Step 11b (Narcosia ruling 2026-08-13): the two mounting tabs
        // (and their buttress sockets in base_main.scad) are DELETED — the
        // gate is now carried by low cradle lugs from below plus two rear
        // pillars from behind (see config.scad/base_main.scad). The outer
        // rim is a clean, unbroken Ø GATE_OD cylinder — no union() needed.
        cylinder(d = GATE_OD, h = REAR_T);
        // screen pocket, from front face
        translate([0, 0, -0.01]) cylinder(d = SCREEN_POCKET_D, h = SCREEN_POCKET_T);
        // button wall reliefs (Task 6 Step 8, Narcosia 2026-08-13): the puck's
        // side buttons sit at the viewer's 11 & 1 o'clock, 1.5mm proud — the
        // pocket wall presses them. Two reliefs at gate-local 60/120 deg,
        // full pocket depth, hidden behind the bezel.
        for (a = [60, 120])
            rotate([0, 0, a]) translate([SCREEN_POCKET_D/2 - 1, -BTN_RELIEF[0]/2, -0.5])
                cube([1 + BTN_RELIEF[1], BTN_RELIEF[0], SCREEN_POCKET_T + 0.5]);
        // LED+diffuser pocket, ONE annular cut, from front face (reworked after
        // the failed engineering print: was a two-step pocket+recess pair that
        // bound the ring on a full circle and press-fit the diffuser too tight)
        translate([0, 0, -0.01]) difference() {
            cylinder(d = LED_POCKET_OD, h = LED_POCKET_T);
            translate([0, 0, -0.5])
                cylinder(d = LED_POCKET_ID, h = LED_POCKET_T + 1);
        }
        // radial through-slot for the SIDEWAYS in-plane leads — AMENDED
        // 2026-08-13: gate-local -x side (viewer's 3 o'clock after the
        // assembly mirror), the same side as the 8-pin header cavity for the
        // shortest lead loop. Pocket wall out to LEAD_SLOT_R1, full gate
        // depth. NO rear channel: leads loop free across the open back
        // straight into the adjacent header cavity.
        translate([-LEAD_SLOT_R1, -LEAD_SLOT_W/2, -0.5])
            cube([LEAD_SLOT_R1 - LED_POCKET_ID/2 + 2, LEAD_SLOT_W, REAR_T + 1]);
        // header cavity (rear side)
        translate([(HEADER_ZONE[0][0]+HEADER_ZONE[0][1])/2,
                   (HEADER_ZONE[1][0]+HEADER_ZONE[1][1])/2, REAR_T])
            cube([HEADER_ZONE[0][1]-HEADER_ZONE[0][0],
                  HEADER_ZONE[1][1]-HEADER_ZONE[1][0],
                  2 * HEADER_ZONE[2]], center = true);
        // MX1.25 connector cavity (rear side)
        translate([(CONN_ZONE[0][0]+CONN_ZONE[0][1])/2,
                   (CONN_ZONE[1][0]+CONN_ZONE[1][1])/2, REAR_T])
            cube([CONN_ZONE[0][1]-CONN_ZONE[0][0],
                  CONN_ZONE[1][1]-CONN_ZONE[1][0],
                  2 * CONN_ZONE[2]], center = true);
        // USB-C plug channel: dead-straight radial run, no elbow, from the
        // puck edge at 6 o'clock out through the rim. Depth padded (was 30,
        // centred the same as before): the original span landed 0.5 mm short
        // of GATE_OD/2 and left a sealed membrane at the rim (found verifying
        // this cut per the Task 6 amendment — same invisible-defect class as
        // the diffuser press-fit bug). Overlaps the button access slot near
        // the rim; accepted per Narcosia 2026-08-13 (improves button access).
        translate([0, -(SCREEN_D/2 + 14) - 1.5, SCREEN_T/2 + 1])
            cube([USB_W + 2, 33, USB_H + 2], center = true);
        // (Task 6 Step 9, 2026-08-13): the hidden button access slot is
        // DELETED — buttons are at 11 & 1 o'clock, served by the pocket
        // wall reliefs above, not this bottom slot. Its rim break was the
        // stray "see-in" hole visible on Narcosia's printed rear cover photo.
        // The USB tunnel above is now the ONLY rim-piercing cut (asserted
        // in tests.scad).
        // M2 heat-set insert holes for the front-plate screws, cut into the
        // front face (the disc is solid here — free-standing bosses would be
        // swallowed by the union and their holes filled)
        for (a = [45, 135, 225, 315])
            rotate([0, 0, a]) translate([GATE_OD/2 - 6, 0, -0.01])
                cylinder(d = M2_INSERT, h = M2_INSERT_DEPTH);
        // Round 16: ONE off-grid filament pin, front face — breaks the
        // front plate's 4-fold M2 symmetry (see config.scad's REG_PIN
        // comment) so the front can only fit one way, matched by a blind
        // hole at REG_PIN_ANG_FRONT in gate_front.scad's own rear face.
        rotate([0, 0, REG_PIN_ANG_REAR])
            translate([REG_PIN_R, 0, -0.01])
                cylinder(d = REG_PIN_D, h = REG_PIN_DEPTH + 0.01);
        // M2 heat-set insert holes for the rear pillars (Task 6 Step 11b,
        // 2026-08-13): the tab-underside holes above are deleted along with
        // the tabs; these replace them as the gate's primary retention.
        // Drilled into the BACK face going forward, at REAR_PILLAR_R/ANG —
        // same style + radius convention as the REAR_COVER_HOLE_ANGLES loop
        // below, so a straight M2 screw driven along world y from each rear
        // pillar (base_main.scad) passes through a matching hole in
        // rear_cover.scad and seats here. Clearance from the USB tunnel
        // (270±8.4°) and the REAR_COVER_HOLE_ANGLES holes themselves (5°
        // apart at r 40/45 but >3mm edge-to-edge, checked by hand) all
        // asserted in tests.scad.
        for (a = REAR_PILLAR_ANG)
            rotate([0, 0, a]) translate([REAR_PILLAR_R, 0, REAR_T - M2_INSERT_DEPTH])
                cylinder(d = M2_INSERT, h = M2_INSERT_DEPTH + 0.5);
        // M2 heat-set insert holes for rear_cover.scad (Task 6 Step 8,
        // 2026-08-13), cut into the BACK face going forward (toward the
        // front). Same REAR_COVER_HOLE_R/ANGLES as rear_cover's own
        // clearance holes, so the two line up when the cover is placed with
        // rotate([0,180,0]) (see config.scad's rear-cover comment for why
        // that specific flip and this angle set). Clear of the header/
        // connector cavities — asserted in tests.scad.
        for (a = REAR_COVER_HOLE_ANGLES)
            rotate([0, 0, a]) translate([REAR_COVER_HOLE_R, 0, REAR_T - M2_INSERT_DEPTH])
                cylinder(d = M2_INSERT, h = M2_INSERT_DEPTH + 0.5);
        // Task 6 Step 12a: rim brick grooves (decor.scad's shared
        // rim_grooves(), Round 16) — RIM_GROOVE_SKIP already keeps this
        // clear of the USB tunnel mouth above; the tabs it also used to
        // dodge are long gone (decision 17).
        if (RIM_GROOVES) {
            rim_grooves(REAR_T, RIM_GROOVE_SKIP);
            // Round 17 FIX 3 (reviewer DO-NOT-PRINT): the mid-depth
            // circumferential groove was SILENTLY DROPPED when the axial-
            // groove generator was hoisted into decor.scad's shared
            // rim_grooves() (Round 16) — the old private module bundled
            // both, this file only kept the axial call. DESIGN.md/
            // MEASUREMENTS.md never stopped claiming it exists (they were
            // right); restored here so the geometry matches the docs again.
            // Same radial depth as the axial grooves (SEG_GROOVE[1]), band
            // thickness SEG_GROOVE[0] — matches rear_cover.scad's own
            // circumferential groove convention exactly.
            translate([0, 0, REAR_T/2 - SEG_GROOVE[0]/2])
                rotate_extrude()
                    translate([GATE_OD/2 - SEG_GROOVE[1], 0])
                        square([SEG_GROOVE[1] + 1, SEG_GROOVE[0]]);
        }
        // Round 16: the cover-registration locating groove (see reg_groove()
        // above) — recessed, back face, gap over the USB tunnel arc.
        reg_groove();
    }
    // crush ribs (design ruling): rise from the pocket floor, preload the
    // case rear rim by ~0.2 when gate_front screws down — glass untouched
    for (a = RIB_ANGLES)
        rotate([0, 0, a])
            translate([RIB_R - RIB_L/2, -RIB_W/2, SCREEN_POCKET_T - RIB_H])
                cube([RIB_L, RIB_W, RIB_H]);
    // (Task 6 Step 10's rear-cover locating bezel — a raised annulus on this
    // back face — is REVERTED (Task 6 Step 11c, Narcosia 2026-08-13): gate_rear
    // prints face-down (back on top), so a proud ring on this top surface is
    // an overhang needing supports. rear_cover is held by its 4 screws + the
    // 2 pillar screws only, no self-centring feature. See config.scad's
    // COVER_LIP comment.)
}

gate_rear();
echo("GATE_REAR_DONE");
