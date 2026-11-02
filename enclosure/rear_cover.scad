// rear_cover.scad — Task 6 Step 8 (Narcosia 2026-08-13, part count 7->8);
// sealed plain dish, Step 9 (Narcosia 2026-08-13, photo of the printed cover).
// Dish enclosing gate_rear's back: the lead loop (wires ~5mm proud) and the
// header/connector cavities. Supersedes the deleted spine as the answer to
// "protect the wiring". Unscrews for service (header/connector still
// reachable). Printed floor-at-z0, opening toward +z (bed rules from
// coupon A). See config.scad's rear-cover comment block for why the
// assembly placement transform is rotate([0,180,0]) specifically, and why
// the hole angles below are chosen the way they are.
//
// Step 9 (a): the two tab-root rim notches from Step 8 are DELETED. Step 8
// reasoned from the tab's PLAN-VIEW protrusion (tab spans r 48..58, past
// the Ø110/r55 rim) and concluded the cover's rim had to open around it —
// but that reasoning skipped the Z axis. The tabs live entirely INSIDE
// gate_rear's own thickness (gate-local z 0..REAR_T); the cover occupies z
// REAR_T..REAR_T+6, i.e. entirely BEHIND the tabs. The cover's rim (at
// gate-local z=REAR_T, flush against gate_rear's back face) never reaches
// into the tabs' z-range at all, radial protrusion or not — a closed dish
// simply doesn't intersect them. Confirmed by Narcosia's print: both notches
// showed daylight straight into the wire cavity. interference_check.scad
// (cover vs base_main) already proves the cover doesn't foul the buttresses
// either, since the buttresses are what the tabs seat into.
include <config.scad>
use <decor.scad>
$fn = FN;

// Step 10's locating bezel (gate_rear's back-face COVER_LIP) is REVERTED
// (Task 6 Step 11c, Narcosia 2026-08-13): gate_rear prints face-down, so a
// proud ring on that face is an overhang needing supports. Round 16
// replaces it with a real registration pair: this dish's own open rim edge
// (the TOP of ITS print — floor-down, opening up — where a vertical-wall
// extension is printable) grows a proud LIP (reg_lip() below) that seats
// into a RECESSED groove on gate_rear's back face (gate_rear.scad's
// reg_groove()). Still held by 4 screws + 2 pillar screws; the lip only
// centres/registers, it isn't load-bearing.
//
// Round 18 FIX A (reviewer DO-NOT-PRINT blocker): Round 17's lip design
// flared its OUTER face ABOVE the rim edge to reach a weld foot at r=53.7 —
// which put solid lip material above z0 out at r 53.2..53.5, exactly where
// gate_rear's back face is solid (the FIX-5 "post" between the groove and
// the axial rim-groove tick floor). The cover could not seat (37.2 mm^3
// collision). Redesigned to support the lip from BELOW instead, entirely
// inside this part's own printed height (z <= REAR_COVER_T) so nothing can
// ever reach into gate_rear regardless of angle:
//   reg_shoulder_cut() — an internal 45-deg chamfer carved OUT of the
//     hollow cut itself (a nested difference: subtracted FROM the removal
//     volume, not unioned as new material — sidesteps the coincident-face
//     weld risk entirely, robust regardless of how exactly its boundary
//     lines up with the plain hollow cylinder's own). Only scoped to the
//     lip's own kept arc.
//   reg_lip() — now a PLAIN vertical annulus, lip_id..lip_od, z0..z0+lip_h,
//     nothing tapered, nothing outside lip_od, nothing above z0 beyond it.
//     Sits entirely on the shoulder's own flat top.
// Seating is now a real pipeline gate (tools/seating_check.py, Round 18
// FIX B) — see render.ps1.
//
// Round 16: this outer wall also carries the SAME rim brickwork as
// gate_rear's rim (decor.scad's shared rim_grooves(), full REAR_COVER_T
// height) plus a matching mid-height circumferential groove, so the 26mm
// gate/rear/cover stack reads as one continuous grooved drum. Reuses
// RIM_GROOVE_SKIP as-is (not renegotiated for this part's own placement
// transform) — config.scad's RIM_GROOVE_SKIP/REG_SKIP_LO/HI comment proves
// algebraically that this specific (270-symmetric) skip set lands on the
// SAME world angle as gate_rear's own skip under rear_cover's
// rotate([0,180,0]) placement, not just "some" gap. The registration LIP
// (reg_lip(), below) uses its own wider REG_LIP_SKIP_LO/HI arc (Round 17
// FIX 2b) — same symmetric-about-270 proof applies (it's REG_SKIP_LO/HI
// plus/minus a fixed per-side margin, so the interval is still centred on
// 270 and still maps onto itself) but the lip's arc is deliberately
// narrower than the groove's own gap so the lip's flat end-caps don't bind
// against the groove's end walls.
union() {
    difference() {
        cylinder(d = GATE_OD, h = REAR_COVER_T);
        // hollow the dish, leaving a REAR_COVER_WALL floor + rim. Round 18
        // FIX A: nested difference — subtract the registration shoulder
        // wedge (reg_shoulder_cut(), below) FROM the plain hollow-cylinder
        // cut, so that wedge survives as solid material (never removed),
        // scoped to the lip's own kept arc only. This is a cut-of-a-cut,
        // not a union of new material, so there's no coincident-face weld
        // to get wrong regardless of how the two boundaries line up.
        difference() {
            translate([0, 0, REAR_COVER_WALL])
                cylinder(d = GATE_OD - 2 * REAR_COVER_WALL, h = REAR_COVER_T);
            reg_shoulder_cut();
        }
        // 4x M2 countersunk holes through the floor, matching gate_rear's back-
        // face insert holes at the same radius/angles
        for (a = REAR_COVER_HOLE_ANGLES)
            rotate([0, 0, a]) translate([REAR_COVER_HOLE_R, 0, 0]) {
                // shaft clearance through the floor
                translate([0, 0, -0.5])
                    cylinder(d = M2_CLEAR, h = REAR_COVER_WALL + 1);
                // countersink, flares out toward z=0 (the exterior face, where
                // the screw head sits flush)
                translate([0, 0, -0.5])
                    cylinder(d1 = REAR_COVER_CSK_D, d2 = M2_CLEAR,
                             h = REAR_COVER_CSK_DEPTH + 0.5);
            }
        // rear-pillar pass-through holes (Task 6 Step 11b, Narcosia ruling
        // 2026-08-13): plain Ø M2_CLEAR through the floor at the same
        // REAR_PILLAR_R/ANG as base_main's pillar bores and gate_rear's new
        // insert holes — the floor (this part's exterior face, z=0) is the side
        // closest to the pillars (assembled gate-local z=20, pillars start at
        // 20.25), so the screw passes straight through here, across the dish's
        // open interior, into gate_rear's insert behind it. No countersink: the
        // screw head lands on the pillar side, not here.
        for (a = REAR_PILLAR_ANG)
            rotate([0, 0, a]) translate([REAR_PILLAR_R, 0, -0.5])
                cylinder(d = M2_CLEAR, h = REAR_COVER_WALL + 1);
        // Round 16: rim brick grooves, full wall height, same USB-tunnel-
        // rhythm skip as gate_rear (see the file header comment above).
        // Round 17: bundled with the circumferential groove under the same
        // RIM_GROOVES toggle (matches gate_rear.scad's own gating — the two
        // used to be one bundled call before Round 16 hoisted the axial
        // half out, and gate_rear.scad's own circumferential groove was
        // found dropped entirely in review, FIX 3; gating both here the
        // same way keeps the toggle meaning "the whole rim-brick pass",
        // consistent across both parts).
        if (RIM_GROOVES) {
            rim_grooves(REAR_COVER_T, RIM_GROOVE_SKIP);
            // circumferential groove at this part's own mid-height (world
            // z=17 once assembled == REAR_T + REAR_COVER_T/2 == this part's
            // own local REAR_COVER_T/2, since the placement transform maps
            // "mid" to "mid" regardless of its z-reversing direction) —
            // same radial depth/band convention as gate_rear's own
            // circumferential groove (restored Round 17 FIX 3).
            translate([0, 0, REAR_COVER_T/2 - SEG_GROOVE[0]/2])
                rotate_extrude()
                    translate([GATE_OD/2 - SEG_GROOVE[1], 0])
                        square([SEG_GROOVE[1] + 1, SEG_GROOVE[0]]);
        }
    }
    // Screw guide bosses (decision 26, 2026-08-21): one tube per cover
    // screw, standing on the floor's inside face, continuing the M2 bore
    // across the dish's open interior so the screw can't wander off the
    // hidden insert — and so the CSK head clamps a 5.7mm column instead of
    // the bare 1.8mm floor. Tip stops RC_BOSS_CLR short of the rim plane:
    // seating stays rim/lip-defined (asserted in tests.scad, proven on the
    // mesh by seating_check.py). Base sunk 0.1 into the floor so the union
    // has no coincident-face weld; the 45° base collar widens DOWNWARD
    // (printed floor-down), so nothing here needs support.
    // Six of them: the four cover screws AND the two pillar pass-throughs
    // (2026-08-21 follow-on, Narcosia): the pillar M2x20s are the gate's ONLY
    // retention and their clamp path ran pillar -> 1.8mm floor -> 4.2mm of
    // air -> around through the dish wall, so snugging them bowed the
    // floor; with a boss the deflection stops at RC_BOSS_CLR and the
    // column goes solid. Guidance matters less here (the 10mm pillar bore
    // already aligns the shaft) but the tip still crossed the cavity blind.
    for (pos = concat([for (a = REAR_COVER_HOLE_ANGLES) [a, REAR_COVER_HOLE_R]],
                      [for (a = REAR_PILLAR_ANG)        [a, REAR_PILLAR_R]]))
        rotate([0, 0, pos[0]]) translate([pos[1], 0, REAR_COVER_WALL - 0.1])
            difference() {
                union() {
                    cylinder(d = RC_BOSS_D, h = RC_BOSS_H + 0.1);
                    cylinder(d1 = RC_BOSS_BASE_D, d2 = RC_BOSS_D,
                             h = (RC_BOSS_BASE_D - RC_BOSS_D)/2 + 0.1);
                }
                translate([0, 0, -0.5])
                    cylinder(d = M2_CLEAR, h = RC_BOSS_H + 1);
            }
    // Round 16/18: the registration lip (see file header) — proud, standing
    // from this part's own open rim edge (local z = REAR_COVER_T), fully
    // supported by reg_shoulder_cut() above (subtracted from the hollow cut,
    // not unioned — see that module's own comment).
    reg_lip();
}

// Round 18 FIX A (reviewer DO-NOT-PRINT blocker — replaces the Round-17
// weld-foot/dual-taper design entirely; see the file header for why).
//
// reg_shoulder_cut(): an internal 45-deg chamfer, carved OUT of the hollow
// cut (i.e. this triangle is SUBTRACTED from the removal volume in a nested
// difference(), so it survives as solid material) — never unioned as new
// material, so there is no coincident-face weld to get wrong regardless of
// how exactly this boundary lines up with the plain hollow cylinder's own.
// Triangle (r,z): (wall_r_in, z0-shoulder_run) -> (wall_r_in, z0) ->
// (lip_id, z0) -> close. The hypotenuse (lip_id,z0) -> (wall_r_in,
// z0-shoulder_run) is exactly 45 deg by construction (shoulder_run ==
// wall_r_in-lip_id in both axes) — the wedge WIDENS as z increases toward
// z0, the standard self-supporting overhang direction, at exactly the 45-
// deg limit. Lives entirely at z <= z0 = REAR_COVER_T (inside this part's
// own printed height), so it can never reach into gate_rear regardless of
// angle — the Round-17 blocker was specifically material ABOVE z0.
// Scoped to the lip's own kept arc (REG_LIP_SKIP_LO/HI) — outside that arc
// there's no lip above to support, so the wall stays a plain vertical
// cylinder there, unchanged from the pre-Round-16 part.
shoulder_run = (GATE_OD/2 - REAR_COVER_WALL) - (REG_R - REG_W/2 + REG_LIP_CLR[1]); // 1.2: wall_r_in - lip_id

module reg_shoulder_cut() {
    wall_r_in = GATE_OD/2 - REAR_COVER_WALL;      // 53.2
    lip_id    = REG_R - REG_W/2 + REG_LIP_CLR[1]; // 52.0
    z0 = REAR_COVER_T;
    rotate([0, 0, REG_LIP_SKIP_HI])
        rotate_extrude(angle = 360 - (REG_LIP_SKIP_HI - REG_LIP_SKIP_LO))
            polygon([
                [wall_r_in, z0 - shoulder_run],
                [wall_r_in, z0],
                [lip_id,    z0],
            ]);
}

// reg_lip(): now a PLAIN vertical annulus, lip_id..lip_od, z0..z0+lip_h —
// nothing tapered, nothing outside lip_od, nothing above z0 beyond it (the
// exact statement tests.scad's Round-18 FIX-B assert now machine-checks:
// lip_od <= reg_groove_od - REG_LIP_CLR[0]). Sits entirely on the
// shoulder's own flat top (lip_id..wall_r_in at z0, all solid per
// reg_shoulder_cut() above — lip_od=53.0 < wall_r_in=53.2, so the lip's
// full footprint lands on solid material, not just partially). Welds down
// with the usual MERGE_OVERLAP dip below z0 — a plain rectangular cross-
// section onto already-solid material, the same simple, proven weld this
// codebase uses everywhere else (ring()/window_cut() in gate_front.scad).
module reg_lip() {
    lip_id = REG_R - REG_W/2 + REG_LIP_CLR[1];   // 52.0: non-locating, generous
    lip_od = REG_R + REG_W/2 - REG_LIP_CLR[0];   // 53.0: locates, tighter
    lip_h  = REG_D - 0.3;                         // 1.3: bottoms 0.3 short in the groove
    z0 = REAR_COVER_T;
    rotate([0, 0, REG_LIP_SKIP_HI])
        rotate_extrude(angle = 360 - (REG_LIP_SKIP_HI - REG_LIP_SKIP_LO))
            translate([lip_id, z0 - MERGE_OVERLAP])
                square([lip_od - lip_id, lip_h + MERGE_OVERLAP]);
}
echo("REAR_COVER_DONE");
