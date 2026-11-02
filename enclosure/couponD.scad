include <config.scad>
use <decor.scad>
use <gate_rear.scad>    // reg_groove()          — the REAL groove generator
use <rear_cover.scad>   // reg_shoulder_cut(), reg_lip() — the REAL lip generators
$fn = FN;
// Coupon D — cover-lip / rear-groove MATING fit coupon (Round 18, reviewer).
// The registration pair (decisions 20/21) is the one interface in the gate
// stack that has never touched plastic: REG_LIP_CLR = [0.2, 0.4] radial
// clearance, the 45-deg internal shoulder, the 1.0mm post between the
// groove OD and the axial rim-tick floor on BOTH parts. Rule 1 (README):
// no full-shell print while an interface is still provisional — so this
// plate carries two 60-deg SECTORS, both cut from origin-centred annuli of
// the REAL radii, printed exactly as the real parts print, that mate the
// way the real parts mate:
//
//   (a) gate_rear's back-face region: annulus r CD_R_IN..GATE_OD/2, CD_A_T
//       thick, its TOP face (z = CD_A_T) standing in for gate_rear's back
//       face (z = REAR_T) — the true reg_groove() cut into it (shifted down
//       by REAR_T-CD_A_T so its floor/walls are the real ones), plus ONE
//       axial rim tick at the sector's mid-angle so the 1.0mm groove-OD/
//       tick-floor post (Round 17 FIX 5) is part of the test. gate_rear
//       prints face-DOWN (back face on top), so groove-up here IS the real
//       print orientation of that face.
//   (b) rear_cover's rim: the wall (r GATE_OD/2-REAR_COVER_WALL..GATE_OD/2,
//       height REAR_COVER_T) on a CD_FLOOR floor stub so it stands, with the
//       shoulder + lip built by the SAME reg_shoulder_cut()/reg_lip() the
//       real cover uses (nested-difference + union, same as rear_cover.scad
//       — not a re-typed copy), plus ONE axial rim tick at ITS mid-angle.
//       Printed dish-up (floor at z=0, lip pointing up at z REAR_COVER_T..
//       REAR_COVER_T+1.3) — exactly as the real cover prints.
//
// Angular windows: (a) spans world CD_A_LO..CD_A_HI (0..60). rear_cover is
// placed by rotate([0,180,0]) in the assembly, which maps its own local
// angle A to world 180-A (config.scad's REG_SKIP proof) — so (b) is cut at
// LOCAL 180-CD_A_HI..180-CD_A_LO (120..180): under the real placement flip
// it lands on world 0..60, i.e. on top of (a), and its tick (local 150)
// lands on world 30, on top of (a)'s tick. On the plate the two sectors
// therefore sit 60 deg apart (0..60 and 120..180) — same origin, same
// radii, no overlap. Neither window goes anywhere near the USB-tunnel skip
// arcs (groove skip ~258..282, lip skip ~256.5..283.5 — asserted below), so
// the skip end-caps are NOT exercised by this coupon; only the plain
// lip-in-groove fit is.
//
// What the print proves (all by hand, no force):
//   1. flip (b) over and drop its lip into (a)'s groove — it should DROP in
//      under its own weight, tick over tick;
//   2. it should seat FLUSH: (b)'s rim edge flat on (a)'s top face, no rock
//      (the lip tip stops 0.3mm short of the groove floor, so only the rim
//      edge should touch);
//   3. it should lift straight back out. Rotation within the groove is
//      free here (no skip arc in the window) — that's expected, not a fault.
// If it won't drop in: the 0.2mm outer clearance is too tight for this
// printer/material — bump REG_LIP_CLR[0]. If it rocks: a burr on the lip
// tip or the shoulder printed proud — check the shoulder's flat top at the
// rim edge. If the tick-side post breaks off either body: the 1.0mm post
// needs more.
CD_A_LO = 0;      CD_A_HI = 60;                       // (a)'s world window
CD_B_LO = 180 - CD_A_HI;  CD_B_HI = 180 - CD_A_LO;  // (b)'s LOCAL window (120..180), DERIVED
CD_A_TICK = (CD_A_LO + CD_A_HI) / 2;                // 30 — on the SEG_N 10-deg grid
CD_B_TICK = 180 - CD_A_TICK;                        // 150 local -> world 30 under the flip
CD_R_IN   = 48;    // inner radius of both sectors (real groove ID is 51.6, lip ID 52.0)
CD_A_T    = 4;     // (a)'s thickness; its top face plays gate_rear's back face
CD_FLOOR  = 2;     // (b)'s floor stub thickness (real cover floor is REAR_COVER_WALL)
CD_R_OUT  = GATE_OD / 2;

// derived from config, same formulas as rear_cover.scad/tests.scad
cd_groove_id = REG_R - REG_W/2;             // 51.6
cd_groove_od = REG_R + REG_W/2;             // 53.2
cd_lip_id    = cd_groove_id + REG_LIP_CLR[1];   // 52.0
cd_lip_od    = cd_groove_od - REG_LIP_CLR[0];   // 53.0
cd_tick_floor = GATE_OD/2 - SEG_GROOVE[1];  // 54.2

// --- asserts (mutation-tested by construction: each reads config directly)
assert(CD_A_LO >= 0 && CD_A_HI <= 180 && CD_A_HI > CD_A_LO,
       "couponD: (a)'s window must sit in 0..180 so (b)'s mirrored window is disjoint on the plate");
assert(CD_A_HI < REG_SKIP_LO || CD_A_LO > REG_SKIP_HI,
       "couponD: (a)'s window overlaps the groove's USB-tunnel skip arc - coupon would test the skip end-caps, not the plain fit");
assert(CD_B_HI < REG_LIP_SKIP_LO || CD_B_LO > REG_LIP_SKIP_HI,
       "couponD: (b)'s local window overlaps the lip's skip arc");
assert(CD_B_LO >= CD_A_HI,
       "couponD: the two sectors overlap on the plate (same origin, same radii) - they must occupy disjoint windows");
assert(abs(CD_A_TICK / (360 / SEG_N) - round(CD_A_TICK / (360 / SEG_N))) < 1e-9,
       "couponD: (a)'s tick angle is not on the SEG_N rim-tick grid");
assert(CD_R_IN < cd_groove_id - 2 && CD_R_IN < cd_lip_id - 2,
       "couponD: sector inner radius too close to the groove/lip - leaves no material inboard");
assert(CD_A_T - REG_D >= 2,
       "couponD: (a) too thin under the groove floor (want >=2mm)");
assert(CD_FLOOR + (GATE_OD/2 - REAR_COVER_WALL - cd_lip_id) <= REAR_COVER_T,
       "couponD: (b)'s floor stub reaches up into the shoulder run");
assert(cd_tick_floor - cd_groove_od >= 1.0 && cd_tick_floor - (GATE_OD/2 - REAR_COVER_WALL) >= 1.0,
       "couponD: the tick-floor post is thinner than 1.0mm on one of the two bodies");

// a 60-deg annular wedge r0..r1, z z0..z1, swept from angle a0 to a1 (a1 > a0)
module wedge(a0, a1, r0, r1, z0, z1)
    rotate([0, 0, a0])
        rotate_extrude(angle = a1 - a0)
            translate([r0, z0]) square([r1 - r0, z1 - z0]);

module ear(px, py) { translate([px, py, 0]) cylinder(d = BRIM_D, h = BRIM_T); }
// mouse ears for a sector a0..a1: one tab hanging off each radial end edge
// (centred mid-band, pushed BRIM_D/2-2 tangentially outward so 2mm of the
// disc is welded into the body — coupon A's rule), plus two on the outer arc
// at the quarter points (never at the tick angle: an ear there would fill
// the tick's bottom BRIM_T).
module sector_ears(a0, a1) {
    rm = (CD_R_IN + CD_R_OUT) / 2;
    t  = BRIM_D/2 - 2;
    rotate([0, 0, a0]) ear(rm, -t);
    rotate([0, 0, a1]) ear(rm,  t);
    for (a = [a0 + (a1 - a0)/4, a0 + 3*(a1 - a0)/4])
        rotate([0, 0, a]) ear(CD_R_OUT + BRIM_D/2 - 2, 0);
}

// (a) — gate_rear back-face sector, groove face UP
module body_a() {
    difference() {
        wedge(CD_A_LO, CD_A_HI, CD_R_IN, CD_R_OUT, 0, CD_A_T);
        // the REAL groove, its z reference moved from REAR_T (gate_rear's
        // back face) to CD_A_T (this body's top)
        translate([0, 0, CD_A_T - REAR_T]) reg_groove();
        // ONE real axial rim tick (decor.scad's shared generator, every
        // other grid angle skipped) at the sector's mid-angle
        rim_grooves(CD_A_T, [for (k = [0 : SEG_N - 1]) if (abs(k * 360 / SEG_N - CD_A_TICK) > 0.01) k * 360 / SEG_N]);
    }
    sector_ears(CD_A_LO, CD_A_HI);
}

// (b) — rear_cover rim sector, dish-up (floor at z=0), lip pointing up.
// Same boolean structure as rear_cover.scad's own body: outer solid minus
// (hollow minus shoulder wedge), unioned with reg_lip(); minus ONE rim tick;
// all clipped to the sector window and to r >= CD_R_IN.
module body_b() {
    intersection() {
        difference() {
            union() {
                difference() {
                    cylinder(d = GATE_OD, h = REAR_COVER_T);
                    difference() {
                        translate([0, 0, CD_FLOOR])
                            cylinder(d = GATE_OD - 2 * REAR_COVER_WALL, h = REAR_COVER_T);
                        reg_shoulder_cut();
                    }
                }
                reg_lip();
            }
            rim_grooves(REAR_COVER_T, [for (k = [0 : SEG_N - 1]) if (abs(k * 360 / SEG_N - CD_B_TICK) > 0.01) k * 360 / SEG_N]);
        }
        wedge(CD_B_LO, CD_B_HI, CD_R_IN, CD_R_OUT + 1, -1, REAR_COVER_T + REG_D + 1);
    }
    sector_ears(CD_B_LO, CD_B_HI);
}

body_a();
body_b();

echo(str("couponD: (a) world ", CD_A_LO, "..", CD_A_HI, " tick@", CD_A_TICK,
         "; (b) local ", CD_B_LO, "..", CD_B_HI, " tick@", CD_B_TICK,
         " -> world ", 180 - CD_B_HI, "..", 180 - CD_B_LO, " tick@", 180 - CD_B_TICK,
         "; groove r ", cd_groove_id, "..", cd_groove_od, " lip r ", cd_lip_id, "..", cd_lip_od,
         " (clr out ", REG_LIP_CLR[0], " / in ", REG_LIP_CLR[1], ")"));
echo("COUPON_D_DONE");
