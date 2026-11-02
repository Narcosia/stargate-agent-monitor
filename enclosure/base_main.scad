include <config.scad>
$fn = FN;
// GATE_CZ, lug_x(), LUG_CONTACT_Z, LUG_SADDLE_R, LUG_NUB_BOTTOM_Z all now
// live in config.scad (Task 6 Step 11d, review Critical fix, 2026-08-16) —
// HOISTED so tests.scad's machine-checked saddle-floor assert reads the
// exact same formulas this file builds geometry with, not a second
// independently-typed copy. See config.scad's block comments for the
// derivations (unchanged from Step 11b/11c, just relocated).

// --- sloped front face / whole-pedestal surface (MOVED here, Round 19):
// the cradle lugs' LUG_SURFACE_Z and the rear pillars' REAR_PILLAR_BASE_Z
// (both below) need pedestal_top_z() to seat on the pedestal's real
// surface now that squaring the corners removed the old flat rear
// plateau — OpenSCAD 2021.01 resolves top-level variables in file order,
// so this whole block has to sit before EVERYTHING that reads it, not just
// the flank section it originally (Round 13) only needed to precede.
// Round 13 FIX 4 (reviewer ray-probe, 2026-08-17): RAMP_Y0 was hardcoded
// -23.5, an eyeballed approximation of where the hull's front-strip vertex
// meets the ramp slope — off by 4mm from the REAL hull-derived point,
// leaving a 0.22mm floating fin above tread 0's rear edge and a 1.08mm lip
// in front of it (measured: surface z=25.28 at y=-15.4 vs the old ramp_z's
// 24.54). Round 14 FIX A: RAMP_Y0/Y1/Z0/Z1 now read straight from
// config.scad's single-sourced HULL_* values (was a duplicated formula
// matching FRONT_TAPER_Y1) — same true front-strip hull vertex, now with
// only ONE place it's computed.
// Round 19 (decision 22): RAMP_Y1 now the deck's own REAR edge (was
// HULL_REAR_Y0=2, the OLD flat plateau's own front edge) — squaring the
// pedestal's corners replaced the old "steep front ramp + flat rear
// plateau" 3-box hull with ONE continuously sloped deck (front edge lower,
// rear edge higher, no flat region at all), so the ramp legitimately spans
// the WHOLE deck now, front edge to rear edge. Nothing that reads RAMP_Y0/
// RAMP_Y1/ramp_z() sits inside |x|>HULL_TOP_XHALF (the tread staircase
// itself stays a narrow +-13 column, same as before; lugs/pillars/flank
// foot all sit well inside +-55.5 too), so this widening doesn't collide
// with anything — verified per-feature below, not just asserted.
RAMP_Y0 = HULL_FRONT_Y0;   // -25.5 (was -27.5)
RAMP_Y1 = HULL_REAR_Y1;    // 25.5 (was 2) — the deck's own rear edge
RAMP_Z0 = HULL_FRONT_Z1;   // 22 — front deck edge
RAMP_Z1 = HULL_REAR_Z1;    // 30 — rear deck edge
RAMP_RUN  = RAMP_Y1 - RAMP_Y0;   // 51 (was ~29.5)
RAMP_RISE = RAMP_Z1 - RAMP_Z0;   // 8, unchanged (== PLATFORM_DROP)
RAMP_PHI  = atan(RAMP_RISE / RAMP_RUN);   // ~8.9 deg off horizontal (was ~15.2)

// world Z of the deck's own smooth surface at a given world Y (flat at
// RAMP_Z0 for y<=RAMP_Y0, flat at RAMP_Z1 for y>=RAMP_Y1, linear between —
// the clamped ends are never actually queried in-range by anything below,
// since every caller's own y stays inside [RAMP_Y0,RAMP_Y1]; pedestal_top_z()
// handles the front/rear WALL regions outside that range). Used by
// ramp_step_cut() (below, with the rest of the ramp/tread code) to know how
// much wedge to remove above each tread, AND by the flank foot (FIX 1) to
// know how deep it must embed to land on real solid.
function ramp_z(y) =
    (y <= RAMP_Y0) ? RAMP_Z0 :
    (y >= RAMP_Y1) ? RAMP_Z1 :
    RAMP_Z0 + RAMP_RISE * (y - RAMP_Y0) / RAMP_RUN;

// Round 19: whole-pedestal top-of-material height at a given world Y —
// front-wall taper below RAMP_Y0, the deck itself (ramp_z()) in between,
// rear-wall taper above RAMP_Y1. Used to seat anything that must embed into
// the pedestal's real (now continuously sloped, no flat plateau) surface at
// a y outside the deck's own range — the cradle lugs and rear pillars,
// whose y-positions/footprints reach past RAMP_Y1 into the rear-wall taper
// (the flank foot's own y stays inside the deck's range, so it was already
// safe using ramp_z() directly, unchanged). Only valid for |x| within
// HULL_TOP_XHALF — the front/rear faces are proven independent of x (see
// config.scad's own HULL_INSET comment), so this holds across their ENTIRE
// x-range, well beyond where lugs/pillars (both |x|<28) actually sit.
function pedestal_top_z(y) =
    (y <= RAMP_Y0) ?
        HULL_BOT_ZS + (RAMP_Z0 - HULL_BOT_ZS) * (y + HULL_BOT_YHALF) / (RAMP_Y0 + HULL_BOT_YHALF) :
    (y >= RAMP_Y1) ?
        HULL_BOT_ZS + (RAMP_Z1 - HULL_BOT_ZS) * (HULL_BOT_YHALF - y) / (HULL_BOT_YHALF - RAMP_Y1) :
    ramp_z(y);

// ---------------------------------------------------------- cradle lugs ---
// Task 6 Step 11b (Narcosia ruling 2026-08-13): LOW CRADLE FROM BEHIND —
// buttresses/tabs/sockets deleted (see config.scad's block comment). Two
// small lugs rise from the platform's flat rear plateau and cradle the
// gate's outer mechanical ring at LUG_ANG either side of 6 o'clock (viewer's
// 5 & 7 o'clock), well clear of the window annulus (asserted in tests.scad).
//
// y-band: centred on gate_rear's own clean cylindrical rim (REAR_T/2 = 7,
// same convention the deleted tabs used for their y-centring) — the "gate's
// y-band" the plan calls for. This falls entirely inside the platform's
// flat rear plateau (y in [2,27.5], confirmed by the hull-vertex calc in
// task-6-report.md / re-verified numerically for Step 11b), so the lug's
// own footprint sits on a flat BASE_H surface, no slope to trace.
LUG_Y = REAR_T / 2;

// Round 19: the lug's anchor used to embed against the OLD flat BASE_H=30
// rear plateau (a literal constant, valid since LUG_Y=7 sat inside that
// flat region). Squaring the pedestal's corners replaced that flat region
// with a continuous slope, and the anchor's own Y-footprint (LUG_Y +-
// (CRADLE_LUG[1]+4)/2 = [1,13]) now spans real surface-height variation
// (~26.16 at y=1 to ~28.04 at y=13) — a flat anchor referenced to the
// CENTRE height (~27.1) pokes ~0.9mm proud of the true surface near y=1,
// an unsupported ledge the overhang gate caught (bbox [18.5,33,3.3,10.7,
// 27,28.2] reach=7.41mm, first pipeline run of this round). Fixed by
// referencing the MINIMUM local surface across the anchor's own y-span
// (ramp_z is linear/monotonic here, so the min is always at an endpoint,
// checked directly rather than assumed) — the anchor's flat top then sits
// at or below the true surface everywhere in its footprint, same embedding
// discipline FLANK_FOOT_BOTTOM/REAR_PILLAR_BASE_Z already use.
LUG_ANCHOR_YHALF = (CRADLE_LUG[1] + 4) / 2;
LUG_SURFACE_Z = min(ramp_z(LUG_Y - LUG_ANCHOR_YHALF), ramp_z(LUG_Y + LUG_ANCHOR_YHALF));

module cradle_lug(sx) {
    x = lug_x(sx);
    // tapered saddle: a wide anchor embedded 2mm into the existing sloped-
    // platform solid (guarantees a real manifold union, not a coincident-
    // face graze) hulled up to the CRADLE_LUG-sized nub near the contact
    // point. Nub bottom is the hoisted LUG_NUB_BOTTOM_Z (config.scad); the
    // nub is centred exactly ON the contact height, so its TOP sits
    // CRADLE_LUG[2]/2 = 3mm proud of it — the concave cut below then has
    // real material to carve a groove from. Remaining saddle-floor
    // thickness after the cut is machine-checked in tests.scad
    // (LUG_FLOOR_MIN assert) using these SAME hoisted values — Task 6 Step
    // 11d, review Critical fix: this used to be a hand-derived comment only
    // (~2.71mm), which is exactly how the flank-relief bug that gutted this
    // floor to 0.70mm went undetected by every pipeline gate.
    hull() {
        translate([x, LUG_Y, LUG_SURFACE_Z - 1])
            cube([CRADLE_LUG[0] + 4, CRADLE_LUG[1] + 4, 2], center = true);
        translate([x, LUG_Y, LUG_NUB_BOTTOM_Z + CRADLE_LUG[2] / 2])
            cube([CRADLE_LUG[0], CRADLE_LUG[1], CRADLE_LUG[2]], center = true);
    }
}

// concave saddle cut, shared by both lugs (a single cylinder, symmetric
// about x=0, cuts both at once): Ø(2*LUG_SADDLE_R) coaxial with the
// assembled gate (axis along world y at height GATE_CZ) — the ring's own
// Ø GATE_OD rim beds into the 0.25mm running clearance this leaves, same
// FIT value used everywhere else in this file. ONLY cut applied to the
// lugs — the flank relief (below) is scoped to the flank solids alone as
// of Task 6 Step 11d, precisely so it can never touch this.
module cradle_lug_saddle_cut() {
    translate([0, LUG_Y, GATE_CZ]) rotate([-90, 0, 0])
        cylinder(r = LUG_SADDLE_R, h = 30, center = true);
}

// --------------------------------------------------------- rear pillars ---
// Task 6 Step 11b: primary retention now that the tabs/sockets are gone —
// two narrow pillars rising from the platform behind the gate, each with a
// straight M2 clearance bore (driven in shear, from behind, no side-driving)
// into a matching M2_INSERT hole in gate_rear's back face (gate_rear.scad)
// through a Ø2.4 pass-through in rear_cover (rear_cover.scad).
//
// World XZ of the REAR_PILLAR_R/REAR_PILLAR_ANG target on gate_rear's back
// face: the assembly transform is translate([0,0,GATE_CZ])
// rotate([90,0,180]), which (proven by the Step-5 tab/socket boolean test,
// task-6-report.md) sends gate-local X -> world -X and gate-local Y ->
// world Z-GATE_CZ, for a point built the same way as the existing
// REAR_COVER_HOLE_ANGLES loop (rotate([0,0,a]) translate([R,0,z]), i.e.
// local_X = R*cos(a), local_Y = R*sin(a)):
//   world X = -R*cos(a)
//   world Z = GATE_CZ + R*sin(a)   (same for both angles: sin(245)==sin(295))
function rear_pillar_x(a) = -REAR_PILLAR_R * cos(a);
function rear_pillar_z(a) = GATE_CZ + REAR_PILLAR_R * sin(a);
// gate-local z REAR_T+REAR_COVER_T = 20 (rear_cover's own back face) maps
// 1:1 to world y (no offset — proven Step 8/10 comments); +FIT running
// clearance so the pillar's front face doesn't crowd the cover.
REAR_PILLAR_FRONT_Y = REAR_T + REAR_COVER_T + FIT;   // 20.25
REAR_PILLAR_TOP_Z   = GATE_CZ - 30;                  // "~GATE_CZ-30" per the ruling
                                                       // (=67 at GATE_GAP=12, =63 at
                                                       // GATE_GAP=8, Task 6 Step 11c)

// Round 19: base Z used to be a literal 20, safe under the OLD flat
// BASE_H=30 rear plateau (REAR_PILLAR_FRONT_Y=20.25..30.25 sat entirely
// inside that flat region). Squaring the corners replaced the flat region
// with a continuous slope that, past RAMP_Y1=25.5, is the REAR WALL
// taper — it falls away fast enough that the pillar's own BACK edge
// (y=30.25) now sits over a real surface as low as ~18.9 (pedestal_top_z),
// lower than the old literal base. Re-derived from the true local minimum
// across the pillar's own y-footprint (pedestal_top_z is concave — rises
// across the deck, falls across the rear-wall taper — so its minimum over
// a bounded span is always at one of the two endpoints, checked directly
// rather than assumed) with the same 0.5mm embed margin the flank foot
// uses (FLANK_FOOT_BOTTOM), so the base always lands on real solid
// regardless of which endpoint binds.
REAR_PILLAR_BASE_Z = min(pedestal_top_z(REAR_PILLAR_FRONT_Y),
                          pedestal_top_z(REAR_PILLAR_FRONT_Y + REAR_PILLAR[1])) - 0.5;

module rear_pillar(a) {
    x = rear_pillar_x(a);
    // base at REAR_PILLAR_BASE_Z: comfortably inside the existing pedestal
    // solid across this whole footprint (Round 19: re-derived from the
    // real local surface, not the old flat-plateau assumption — see
    // REAR_PILLAR_BASE_Z's own comment) and clear of both the bottom-cover
    // rebate (z<=2.01) and the internal cavity (y<=19.5, this pillar's own
    // y stays >=20.25 throughout) — union() just merges the pillar into
    // the platform below its own local top, no floating gap.
    translate([x - REAR_PILLAR[0] / 2, REAR_PILLAR_FRONT_Y, REAR_PILLAR_BASE_Z])
        cube([REAR_PILLAR[0], REAR_PILLAR[1], REAR_PILLAR_TOP_Z - REAR_PILLAR_BASE_Z]);
}
module rear_pillar_bore(a) {
    x = rear_pillar_x(a);
    z = rear_pillar_z(a);
    translate([x, REAR_PILLAR_FRONT_Y - 1, z]) rotate([-90, 0, 0])
        cylinder(d = M2_CLEAR, h = REAR_PILLAR[1] + 2);
}

// --- sloped front face: RAMP_Y0/Y1/Z0/Z1/ramp_z()/pedestal_top_z() MOVED
// (Round 19) to the top of the file, right after the includes — LUG_SURFACE_Z
// (cradle lugs, above) and REAR_PILLAR_BASE_Z (rear pillars, above) both
// need pedestal_top_z() too now, and OpenSCAD 2021.01 resolves top-level
// variables in file order, so the whole ramp block has to sit before
// EVERYTHING that reads it, not just the flank section it originally
// (Round 13) only needed to precede.

// ------------------------------------------------------ buttress flanks ---
// Task 6 Step 11c (Narcosia ruling 2026-08-13, after seeing the step11b
// renders): MIDDLE-GROUND BASE — short wide buttress flanks. Pure
// cosmetic/stability mass bringing back the sloped-buttress silhouette,
// capped low and wide-footed. The cradle lugs remain the ring's only seat,
// the rear pillars remain the only retention — flanks carry no load-bearing
// role, confirmed by the interference gate coming back empty, not assumed.
//
// Top pad z: FLANK[0] mm below the lowest visible window (GATE_CZ-WINDOW_R1)
// — a DERIVED expression, not a literal, so it tracks Step 11c's own
// GATE_GAP 12->8 change (and any future one) automatically.
FLANK_TOP_Z = (GATE_CZ - WINDOW_R1) - FLANK[0];
// rim half-width at that height: how far the ring's own Ø GATE_OD circle
// reaches in x at z=FLANK_TOP_Z (Pythagoras on the circle centred at
// (0,GATE_CZ) in the XZ plane) — the top pad leans in to sit just outboard
// of this. Note (GATE_CZ-FLANK_TOP_Z) == WINDOW_R1+FLANK[0], a constant
// independent of GATE_GAP, so this rim half-width (~21.2) and everything
// derived from it don't move when GATE_GAP does either — re-confirmed
// numerically for Step 11c's 12->8 change, not just assumed to still hold.
function flank_rim_half_width(z) = sqrt(pow(GATE_OD/2, 2) - pow(GATE_CZ - z, 2));
function flank_top_x(sx) = sx * (flank_rim_half_width(FLANK_TOP_Z) + FLANK[3]/2 + 4);
// FLANK_FOOT_X moved 45.5->43 (Round 13 FIX 1, reviewer Critical, alongside
// the FLANK[1] 30->20 cut above): outboard edge = FLANK_FOOT_X+FLANK[1]/2 =
// 43+10 = 53, comfortably inside END_X1=(BASE_W-24)/2=55.5 (the end wall's
// own outer taper, flat by z=28 — see "end (side) faces" below) with a 2.5mm
// margin, vs. the old foot's 60.5 which oversailed it by 5mm into open air.
// Machine-checked in tests.scad (re-derives END_X1 the same way tests.scad
// re-derives every other base_main.scad taper formula it needs).
FLANK_FOOT_X = BASE_W/2 - 24.5;   // 43 — inner edge 33 still overlaps the
                                   // lugs' own anchor outer edge (+-36.5) by
                                   // 3.5mm (harmless, both are base_main,
                                   // unions into more fused mass) and stays
                                   // well clear of the USB tunnel mouth
                                   // (x +-9).
FLANK_Y = LUG_Y;                // same y-band as the cradle lugs (REAR_T/2)
// Foot embed depth (Round 13 FIX 1, reviewer Critical): the foot's front
// edge (FLANK_Y-FLANK[2]/2 = -10) reaches well into the sloped ramp region
// (RAMP_Y0=-27.5..RAMP_Y1=2) — the OLD flat BASE_H-2=28 embed only lands on
// real solid there if the ramp surface itself is at or above 28, which it
// ISN'T at y=-10 (ramp_z(-10)=26.75) — up to 1.25mm of air was left under
// the foot's front (reviewer ray-probe: gap 0-1.25mm across x 30.5-55.5,
// y -10..-5.4). Fix: keep the foot's TOP fixed at BASE_H (flush with the
// plateau, unchanged) but extend its BOTTOM down to whichever is DEEPER of
// the old flat embed and the ramp-derived one at the foot's own worst
// (lowest-surface, front-most) y — ramp_z() is monotonic in y, so the
// front edge is always the binding case — with a 0.5mm safety margin, so
// the underside always lands ON solid, ray-probe-verified below.
FLANK_FOOT_Y_LO   = FLANK_Y - FLANK[2] / 2;                       // -10
// Round 15 (Narcosia review, FIX D) ATTEMPTED and REVERTED: widening this
// margin 0.5->2.0 (foot bottom 26.246->24.746, for more clearance on the
// flank's 29.1deg inner face) was tried, but it changed the foot hull's
// silhouette enough to introduce a NEW overhang the pipeline didn't have
// before: overhang_check.py flagged 8 triangles, worst group
// bbox=[30.11,33.00,13.00,19.75,30.50,30.50] reach=2.89mm — right at the
// foot's own inner edge meeting the rear plateau, not present at the old
// 0.5mm margin. Per the task's own accepted fallback ("else leave and
// note"), reverted to 0.5 rather than chase a fix for an optional item
// that breaks the hard overhang-0 gate. Left as-is; flagging for Narcosia if
// the 29.1deg face still needs shallowing — would need a different
// approach than just deepening this margin.
FLANK_FOOT_BOTTOM = min(BASE_H - 2, ramp_z(FLANK_FOOT_Y_LO) - 0.5);
FLANK_FOOT_H      = BASE_H - FLANK_FOOT_BOTTOM;

// hard clearance relief (Task 6 Step 11c; SCOPED to the flank solids only,
// Task 6 Step 11d review Critical fix, 2026-08-16): a coaxial Ø(GATE_OD+4)
// cylinder — larger than the cradle lugs' own Ø(2*LUG_SADDLE_R) saddle cut
// — so any lean-in the flank hull might make toward the ring gets carved
// away regardless of the hull's exact intermediate shape between foot and
// top pad. CRITICAL: this module must ONLY ever be difference()'d against
// the flank's own hull (inside flank(), below), never against the whole
// base — Round 7 originally cut it from the entire base union(), and since
// its radius (57) is a strict superset of the lugs' own saddle-cut radius
// (55.25) and its old height (BASE_D+20) spanned the lugs' y-band too, it
// silently re-cut the lug saddle floor from 2.71mm down to 0.70mm — a
// manifold, shells=1, interference-gate-clean bug invisible to every
// existing pipeline gate (probe-verified in task-6-report.md Round 8).
module flank_relief_cut() {
    translate([0, 0, GATE_CZ]) rotate([-90, 0, 0])
        cylinder(d = GATE_OD + 4, h = BASE_D + 20, center = true);
}

module flank(sx) {
    // relief cut applied HERE, inside the flank's own difference() — never
    // at the top level against the whole base (that was the Round-7 bug).
    // Round 20 FIX D (reviewer): flank_panel_pos() (recessed plaque) DELETED
    // — it occupied the same z-band as flank_courses_pos()'s coursing,
    // reading as a competing decoration on the same face rather than a
    // deliberate inset. flank_courses_pos() is now the ONE groove system for
    // this whole face, folding in what used to be a separate cap-specific
    // module (decision 22 task B) — see that module's own comment.
    difference() {
        hull() {
            // wide foot: TOP fixed flush at BASE_H (unchanged); BOTTOM now
            // reaches down to FLANK_FOOT_BOTTOM (Round 13 FIX 1) instead of
            // a flat BASE_H-2, so the foot's front edge — well into the
            // sloped ramp region — still lands on real solid instead of
            // floating over it. Ray-probe-verified below (Round 13 report).
            translate([sx * FLANK_FOOT_X, FLANK_Y, (FLANK_FOOT_BOTTOM + BASE_H) / 2])
                cube([FLANK[1], FLANK[2], FLANK_FOOT_H], center = true);
            // narrow top pad, leaning inboard toward the ring
            translate([flank_top_x(sx), FLANK_Y, FLANK_TOP_Z - 1])
                cube([FLANK[3], 20, 2], center = true);
        }
        flank_relief_cut();
        if (sx > 0) flank_courses_pos(); else mirror([1, 0, 0]) flank_courses_pos();
        if (sx > 0) flank_face_courses_pos(); else mirror([1, 0, 0]) flank_face_courses_pos();
    }
}

// -------------------------------------------- Task 6 Step 12 dock styling ---
// Narcosia 2026-08-13 (decoration plan step 12b), after Step 11's massing was
// approved with one note: the flank-foot/lug/platform intersections read as
// accidental overlapping edges. Everything below is relief/engraving ONLY
// (<=1.2mm deep) — no load path, seat, clearance, cavity, or hole moves.
// DOCK_* config, all PROVISIONAL pending the print gate.

// --- sloped front face -----------------------------------------------------
// RAMP_Y0/RAMP_Z0/ramp_z() etc. MOVED (Round 13) to just above the
// "buttress flanks" section — FIX 1 needs ramp_z() to seat the flank foot on
// real solid, so the ramp geometry now has to exist before the flank does.
// See that block for the full derivation and history.

// cut a groove flush with the sloped face: x0/xlen run straight across
// (world X, unaffected by the Y/Z tilt), s0/slen run ALONG the slope
// (distance from RAMP_Y0, measured along the surface), depth cuts inward.
module ramp_cut(x0, xlen, s0, slen, depth) {
    translate([x0, RAMP_Y0, RAMP_Z0])
        rotate([RAMP_PHI, 0, 0])
            translate([-xlen/2, s0 - slen/2, -depth])
                cube([xlen, slen, depth + 0.5]);
}

// 3 REAL stepped treads cut into the sloped front (dock-relief-boldening
// pass, 2026-08-17: Narcosia ruled engraved lines too subtle — wants an actual
// staircase), stopping at x=+-13 (2mm clear of the USB drop slot's own
// x -11..11; outside |x|>13 the original smooth ramp is untouched). Each
// tread is a FLAT platform, DOCK_TREAD_RISER taller than the one before it,
// anchored flush with the ramp's own front edge (tread 0 ties into z=RAMP_Z0
// exactly, no gap) — front-anchored rather than top-anchored because the
// front edge/drop-slot area is the natural start of a staircase.
//
// Round 19: the tread staircase's OWN y-span (TREAD_Y0/TREAD_Y1) is now
// DECOUPLED from RAMP_Y0/RAMP_Y1 (which widened to the deck's FULL depth,
// front edge to rear edge, for the general surface reference pedestal_top_z()
// and deck_courses() need). Extending the physical/decorative tread span to
// match was tried first and broke: the drop slot's own y-band (base_main.scad
// top_brick()'s drop_slot_zone, y -2..16) then swallowed tread 1's ENTIRE
// centre course line (its centre landed inside the drop-slot's y-range,
// leaving only two <2mm slivers either side of the excluded x-range — below
// the survival threshold, 0 courses, caught by tests.scad's per-tread
// count-assert). The OLD 3-box hull's own tread/landing split (y=2) had
// enough margin against the drop slot by construction; there's no equivalent
// natural boundary any more, so TREAD_Y1 is chosen directly against the
// drop slot's real y-start (-2) with a safety margin, verified (not just
// asserted) via the same per-tread count-assert.
TREAD_Y0 = RAMP_Y0;   // -25.5, same front edge as the deck
TREAD_Y1 = -4;         // PROVISIONAL — stops short of the drop-slot's y=-2
                        // start with margin (checked: tread 2's own course-
                        // line centre lands at y=-6.75, its +-0.75mm width
                        // stays clear of -2 by >4mm)
TREAD_RUN = (TREAD_Y1 - TREAD_Y0) / DOCK_RAMP_STEPS;
module ramp_step_cut(y_lo, y_hi, flat_z) {
    // remove the wedge between the OLD smooth ramp surface and the new flat
    // tread: cut from flat_z up to (and past) the smooth surface's own
    // highest point in this y-span (its back edge, y_hi) — the smooth
    // surface rises monotonically with y, so that's a safe upper bound
    // regardless of exactly how much wedge there is at any given y.
    z_top = ramp_z(y_hi) + 0.5;
    translate([-13, y_lo, flat_z])
        cube([26, y_hi - y_lo, z_top - flat_z]);
}
module ramp_treads() {
    for (i = [0 : DOCK_RAMP_STEPS - 1]) {
        y_lo = TREAD_Y0 + i * TREAD_RUN;
        y_hi = TREAD_Y0 + (i + 1) * TREAD_RUN;
        flat_z = RAMP_Z0 + i * DOCK_TREAD_RISER;
        ramp_step_cut(y_lo, y_hi, flat_z);
    }
}
// deepest single cut the tread staircase makes relative to the original
// smooth ramp, for tests.scad's wall-thickness safety margin. Round 19: the
// treads no longer reach anywhere close to RAMP_Y1/RAMP_Z1 (they stop at
// TREAD_Y1=-4, well short of the deck's own rear edge), so the old flat
// "RAMP_RISE - (STEPS-1)*RISER" formula (which assumed the last tread met
// the OLD flat BASE_H landing) no longer describes the real worst case —
// re-derived directly as the max, over all 3 treads, of the wedge
// ramp_step_cut() actually removes (ramp_z(that tread's own y_hi) -
// that tread's own flat_z), the same quantity ramp_step_cut() itself computes.
// tests.scad re-derives this from the same config-level constants since it
// only includes config.scad, per this project's existing pattern.
function tread_cut_at(i) = ramp_z(TREAD_Y0 + (i + 1) * TREAD_RUN) - (RAMP_Z0 + i * DOCK_TREAD_RISER);
MAX_TREAD_CUT = max([for (i = [0 : DOCK_RAMP_STEPS - 1]) tread_cut_at(i)]);

// Round 11 (Narcosia, 2026-08-17): the ramp steps read as intentional masonry
// (confirmed good, unchanged) — but the small flanking panels beside them
// read as an afterthought (single square per face). DELETED (ramp_panel()
// and its call); the vertical wall BELOW the ramp (z 0..~20, previously
// undecorated — the pedestal's real "front face", distinct from the sloped
// ramp/steps above it) gets the new running-bond course treatment instead
// (front_courses(), below the taper section).

// --- front wall taper (the pedestal's actual front face, BELOW the ramp) ---
// Round 14 FIX A (reviewer Critical): Y0/Y1/Z0/Z1 now read straight from
// config.scad's single-sourced HULL_* values — Z1 corrected 20->22 (the
// front strip's own TOP edge, not its bottom; same class of fix as
// RAMP_Y0 in Round 13). front_cut() itself REBUILT: the old version reused
// rear_cut()'s exact code structure, but front's Y INCREASES with Z where
// rear's DECREASES (front tapers -37.5->-27.5, rear tapers 37.5->27.5) —
// that sign flip made FRONT_BETA come out NEGATIVE, and the identical
// translate/rotate recipe silently cut in the wrong local direction: only
// the +0.5mm safety-overshoot ever reached the real surface, so front
// grooves came out 0.7-1.5mm deep instead of the intended 2.0 (reviewer
// finding). Fixed by mirroring the WHOLE problem through y=0 first: build
// the cut with rear_cut()'s exact proven-correct positive-beta recipe
// (front's taper, once mirrored, has the identical shape as rear's — a
// wall anchored at a wide |Y0| tapering to a narrower |Y1| as Z increases),
// then mirror the result back into place.
FRONT_TAPER_Y0 = -HULL_BOT_YHALF;    // -37.5
FRONT_TAPER_Y1 = HULL_FRONT_Y0;      // -25.5 (was -27.5, Round 19 HULL_INSET)
FRONT_TAPER_Z0 = HULL_BOT_ZS;  FRONT_TAPER_Z1 = HULL_FRONT_Z1;   // 2..22
FRONT_TAPER_Y0M = -FRONT_TAPER_Y0;   // 37.5 — mirrored (positive) taper, same
FRONT_TAPER_Y1M = -FRONT_TAPER_Y1;   // 27.5   shape/sign convention as REAR

FRONT_BETA = atan((FRONT_TAPER_Y0M - FRONT_TAPER_Y1M) / (FRONT_TAPER_Z1 - FRONT_TAPER_Z0));  // positive, ~26.6 deg

// "depth" convention (Round 14 FIX A follow-up, found while ray-probing the
// fix): DOCK_JOINT[1] is used identically for flat top-plate grooves (a
// plain world-Z depth, no tilt) and these tilted wall grooves — and
// tests.scad's own wall-thickness safety assert (wall_at_z20_front/_rear)
// already subtracts DOCK_JOINT[1] straight from a WORLD-Y wall-thickness
// figure. So "depth" here means depth measured along the SAME world axis a
// probe/caliper would use (world Y for these walls), not the wall's own
// tilted normal — local_depth() converts that into the local (wall-normal)
// cut needed to achieve it: local = depth*cos(BETA) (the two differ because
// the local Y-axis, after rotate([BETA,0,0]), is the wall's true normal,
// tilted BETA off world Y).
//
// Z-margin — REMOVED (Round 15, Narcosia review): the margin above was built
// on the premise that a finite-height notch cut into a tilted surface gets
// clipped short of full depth away from its own band centre, so lzlen was
// padded by 2*cut_margin() (=2*depth*sin(BETA)) to compensate. Reviewer
// Z-scan proved that premise was a measurement artefact, not a real
// defect: the padding's actual effect was to inflate the MOUTH the groove
// exposes at the wall's own outer surface to 1.5 + 4*sin(BETA)*cos(BETA) ≈
// 2.8-3.1mm — roughly double the intended DOCK_JOINT[0]=1.5 — while depth
// stayed correct with or without it (local_depth() alone already delivers
// the intended world-axis depth at the surface). Margin deleted from all
// three cut modules below; local_depth()/lz0 unchanged, still correct.
function local_depth(depth, beta) = depth * cos(beta);

// world Y of the front wall's own taper at a given Z (mirrors rear_wall_y()
// below) — Round 19: needed by end_courses_pos() to find the TRUE front
// corner position at each course height (see that module's own comment).
function front_wall_y(z) =
    (z <= FRONT_TAPER_Z0) ? FRONT_TAPER_Y0 :
    (z >= FRONT_TAPER_Z1) ? FRONT_TAPER_Y1 :
    FRONT_TAPER_Y0 + (FRONT_TAPER_Y1 - FRONT_TAPER_Y0) * (z - FRONT_TAPER_Z0) / (FRONT_TAPER_Z1 - FRONT_TAPER_Z0);

module front_cut(x0, xlen, z0, zlen, depth) {
    ldepth = local_depth(depth, FRONT_BETA);
    lz0    = (z0 - FRONT_TAPER_Z0) / cos(FRONT_BETA);
    lzlen  = zlen / cos(FRONT_BETA);
    mirror([0, 1, 0])
        translate([x0, FRONT_TAPER_Y0M, FRONT_TAPER_Z0])
            rotate([FRONT_BETA, 0, 0])
                translate([-xlen/2, -ldepth, lz0 - lzlen/2])
                    cube([xlen, ldepth + 0.5, lzlen]);
}

// X half-width taper. Round 20 FIX A: front now tapers to its OWN, WIDER
// endpoint (HULL_TOP_XHALF_FRONT ~58.93, not the rear's HULL_TOP_XHALF
// 55.5) — the deck's front edge was widened so all 4 end-wall corners are
// coplanar (config.scad's own comment); rear keeps the narrower END_X1
// (defined below) since only the front strip changed.
function front_x_half(z) =
    (z <= FRONT_TAPER_Z0) ? END_X0 :
    (z >= FRONT_TAPER_Z1) ? HULL_TOP_XHALF_FRONT :
    END_X0 + (HULL_TOP_XHALF_FRONT - END_X0) * (z - FRONT_TAPER_Z0) / (FRONT_TAPER_Z1 - FRONT_TAPER_Z0);

// --- rear wall (also tapers, per the cable-port-cut derivation above: "the
// pedestal hull tapers linearly in y from 37.5 (at z=2) to 27.5 (at z=30)")
// Round 14 FIX A: Y0/Y1/Z0/Z1 now read straight from the single-sourced
// HULL_* values — Z1 corrected 28->30 (the rear strip's own TOP edge).
REAR_TAPER_Y0 = HULL_BOT_YHALF;      // 37.5, bottom slab's own edge
REAR_TAPER_Y1 = HULL_REAR_Y1;        // 25.5, deck's own rear edge (was 27.5)
REAR_TAPER_Z0 = HULL_BOT_ZS;  REAR_TAPER_Z1 = HULL_REAR_Z1;   // 2..30

function rear_wall_y(z) =
    (z <= REAR_TAPER_Z0) ? REAR_TAPER_Y0 :
    (z >= REAR_TAPER_Z1) ? REAR_TAPER_Y1 :
    REAR_TAPER_Y0 + (REAR_TAPER_Y1 - REAR_TAPER_Y0) * (z - REAR_TAPER_Z0) / (REAR_TAPER_Z1 - REAR_TAPER_Z0);
REAR_BETA = atan((REAR_TAPER_Y0 - REAR_TAPER_Y1) / (REAR_TAPER_Z1 - REAR_TAPER_Z0));   // ~19.7 deg

module rear_cut(x0, xlen, z0, zlen, depth) {
    ldepth = local_depth(depth, REAR_BETA);
    lz0    = (z0 - REAR_TAPER_Z0) / cos(REAR_BETA);
    lzlen  = zlen / cos(REAR_BETA);
    translate([x0, REAR_TAPER_Y0, REAR_TAPER_Z0])
        rotate([REAR_BETA, 0, 0])
            translate([-xlen/2, -ldepth, lz0 - lzlen/2])
                cube([xlen, ldepth + 0.5, lzlen]);
}
function rear_x_half(z) =
    (z <= REAR_TAPER_Z0) ? END_X0 :
    (z >= REAR_TAPER_Z1) ? END_X1 :
    END_X0 + (END_X1 - END_X0) * (z - REAR_TAPER_Z0) / (REAR_TAPER_Z1 - REAR_TAPER_Z0);

// --- shared running-bond course pattern (Round 11) ----------------------
// 2 horizontal course lines at z=DOCK_COURSE_H/2*DOCK_COURSE_H divide a
// wall into up to 3 bands; vertical joints at DOCK_JOINT_PITCH alternate
// offset between bands (classic running bond). course_bands() clamps each
// band to a face's own top_z so a shorter wall (the front's own 20mm) just
// gets a degenerate (zero-height, filtered out below) top band instead of
// invalid geometry.
function course_bands(top_z) = [
    [0, min(DOCK_COURSE_H, top_z)],
    [min(DOCK_COURSE_H, top_z), min(2*DOCK_COURSE_H, top_z)],
    [min(2*DOCK_COURSE_H, top_z), top_z]
];

// Running-bond wall courses on the pedestal's actual front face (the
// vertical wall below the ramp, z 0..FRONT_TAPER_Z1) — REPLACES the deleted
// ramp_panel() flanking panels. 2 horizontal lines run the FULL face width
// (front_x_half(), no skip); vertical joints skip the central x+-13 ramp/
// lug zone per the plan, so nothing crowds the steps above.
// Round 19 (Task A): horizontal course lines now run CORNER_EXT past each
// face's own true edge (hw) instead of stopping exactly at it — so they
// overlap end_courses()'s own cuts at the corner rather than meeting it
// edge-to-edge (any tiny modelling mismatch there would otherwise leave a
// hairline uncut sliver right at the fold — Task A's own "extend >=2mm past
// its corner so the two meet cleanly").
// Round 22 FIX 1 (reviewer): a horizontal course-line cut is a uniform
// extrusion along the ONE world axis its own face's rotation doesn't touch
// (world X for front_cut()/rear_cut(), world Y for end_cut()) — correct on
// its own face, but CORNER_EXT/END_CORNER_EXT deliberately overshoots each
// line past its own true corner so it overlaps the ADJACENT face's own cut
// there. The adjacent face's real surface tilts about a DIFFERENT axis, so
// as the overshoot crosses into its territory the cut's local-frame plane
// and that surface's real plane diverge — the groove mouth sinks
// 0.72-0.88mm below the nominal z0+-DOCK_JOINT[0]/2 band over the 2mm
// nearest each corner (a visible dark wedge at all 16 corner crossings).
// FIX (a) as first tried (clip the WHOLE cut to a world-Z slab) and FIX (b)
// (shrink CORNER_EXT alone) BOTH failed empirically: (a) flattens the cut's
// natural, wall-tilt-following, self-supporting "roof" for its ENTIRE
// width/length, not just near the corner (the uniform-extrusion property
// that causes the wedge also means the cross-section is IDENTICAL
// everywhere) — 34 new overhang triangles, worst reach 13.73mm, an order of
// magnitude past the 2.5mm thin-lintel allowlist. (b) shrinking CORNER_EXT
// to 0.5 barely moved the wedge's own reach (still ~0.65-0.75mm drop out to
// o=2mm on the real mesh) — because front_x_half(z)/end_x(z) are already
// near-coincident by construction (Round 20's coplanarity fix), so the two
// faces' cuts already overlap near the corner almost regardless of
// CORNER_EXT; the wedge's reach along the adjacent face turns out to be set
// by the cut DEPTH/tilt-angle relationship, not the overshoot length.
// FIX actually used: keep CORNER_EXT at its original reliable-overlap value
// (2.5) for a plain, unclipped MAIN cut spanning only the wall's own TRUE
// width (no overshoot, so its natural cross-section is untouched — no new
// overhang) PLUS a small, SEPARATE world-Z-slab-clipped PATCH cut covering
// just the CORNER_EXT-wide overshoot strip on each end (small enough to
// stay under the overhang gate's own thin-lintel allowlist). The patch is
// what actually overlaps the adjacent face near the corner, and clipping
// ONLY the patch to the flat z0+-DOCK_JOINT[0]/2 band removes the wedge at
// its source without touching the cut's real cross-section anywhere else —
// verified empirically (review-r21-probe2.py mouth z-range now flat at
// every offset; overhang_check.py back to 0).
module z_slab_clip(z0, zlen) {
    intersection() {
        children();
        translate([-1000, -1000, z0 - zlen/2])
            cube([2000, 2000, zlen]);
    }
}
CORNER_EXT = 2.5;
module front_courses() {
    bands = course_bands(FRONT_TAPER_Z1);
    for (z0 = [DOCK_COURSE_H, 2 * DOCK_COURSE_H])
        if (z0 < FRONT_TAPER_Z1 - 0.01) {
            hw_true = front_x_half(z0);
            front_cut(0, 2 * hw_true, z0, DOCK_JOINT[0], DOCK_JOINT[1]);
            for (s = [-1, 1])
                z_slab_clip(z0, DOCK_JOINT[0])
                    front_cut(s * (hw_true + CORNER_EXT/2), CORNER_EXT, z0, DOCK_JOINT[0], DOCK_JOINT[1]);
        }
    for (b = [0 : 2]) {
        z_lo = bands[b][0];  z_hi = bands[b][1];
        if (z_hi - z_lo > 0.5) {
            // Round 15: band 2's own z_hi is FRONT_TAPER_Z1 exactly, the
            // wall's real top edge where it meets the flat/sloped surface
            // above — cut geometry clipped 0.5mm shy of it (see
            // rear_courses()'s matching comment for the full reasoning) so
            // the joint groove can never bite into that surface.
            z_hi_cut = min(z_hi, FRONT_TAPER_Z1 - 0.5);
            zc = (z_lo + z_hi_cut)/2;  zlen = z_hi_cut - z_lo;
            hw = front_x_half(z_hi);
            offset = (b % 2 == 0) ? 0 : DOCK_JOINT_PITCH/2;
            // Round 21 FIX 3: n was derived from hw alone, so `[-n:n]` with a
            // nonzero offset produced an x-range NOT symmetric about 0 (runs
            // -n*PITCH+offset .. n*PITCH+offset) — offset bands silently
            // dropped the negative-side joint nearest -hw (e.g. x=-52.5 in
            // band 1) while keeping its +52.5 mirror, leaving a full-width
            // corner brick on -X and a normal one on +X. `[-n-1:n]` restores
            // the missing extreme; the existing hw/13 filters below drop
            // whatever the extra k produces if it doesn't belong.
            n = floor(hw / DOCK_JOINT_PITCH);
            for (k = [-n - 1 : n]) {
                x = k * DOCK_JOINT_PITCH + offset;
                // Round 21 FIX 1: margin 1.5->4.0 (a corner brick under 4mm
                // reads as a sliver, not a brick — same rule now applied
                // uniformly across front/rear/end joint generators).
                if (abs(x) < hw - 4.0 && abs(x) > 13)
                    front_cut(x, DOCK_JOINT[0], zc, zlen, DOCK_JOINT[1]);
            }
        }
    }
}

// Round 20 FIX C (reviewer): rear pillars' own footprint, x-only (used to
// keep rear_courses()'s cuts off the pillars' protruding lower body — see
// that module below). +1mm margin per side, same convention as the other
// keepout zones in this file. rear_pillar_x() is defined earlier in this
// file (rear-pillars section); referencing it here is safe regardless of
// file order since this is a plain top-level assignment evaluated only
// once, after rear_pillar_x() itself is already defined above it.
REAR_PILLAR_X_ZONES = [
    [rear_pillar_x(REAR_PILLAR_ANG[0]) - REAR_PILLAR[0]/2 - 1, rear_pillar_x(REAR_PILLAR_ANG[0]) + REAR_PILLAR[0]/2 + 1],
    [rear_pillar_x(REAR_PILLAR_ANG[1]) - REAR_PILLAR[0]/2 - 1, rear_pillar_x(REAR_PILLAR_ANG[1]) + REAR_PILLAR[0]/2 + 1],
];

// Running-bond wall courses on the rear wall — REPLACES the deleted
// rear_panel() (which had the unreadable nested checkerboard, Narcosia's
// concern #4 last round). Same pattern as front_courses(), clipping both
// the horizontal lines and the vertical joints around the cable-port
// keepout (x -10..10, z 6..22) AND (Round 20 FIX C) the rear pillars' own
// footprint — reviewer found the z=20 course line cutting straight through
// each pillar's protruding lower body (y 27.8-30.25, z 18.8-20.6, 2.4mm
// reach: the SAME "pillar sits outboard of the wall's own taper" condition
// Round 19 already measured and accepted, now also being CUT INTO by the
// wall's own decoration, not just overlapping it). overlaps()/clip_all()
// (defined below, with top_brick()) are functions — safe to call here
// despite being defined later in the file (they're not evaluated until
// rear_courses() itself is instantiated, by which point the whole file's
// top-level definitions already exist).
module rear_courses() {
    bands = course_bands(REAR_TAPER_Z1);
    port_x = [-10, 10];  port_z = [6, 22];
    for (z0 = [DOCK_COURSE_H, 2 * DOCK_COURSE_H]) {
        hw_true = rear_x_half(z0);   // Round 22 FIX 1: main cut no longer carries
                                       // the CORNER_EXT overshoot itself — see the
                                       // small clipped patch below and
                                       // front_courses()'s own comment for why.
        excl = (z0 >= port_z[0] && z0 <= port_z[1]) ? concat([port_x], REAR_PILLAR_X_ZONES) : REAR_PILLAR_X_ZONES;
        // Round 21 FIX 4: min surviving segment 2->5mm. The old >2 filter
        // admitted the 2.02mm sliver left between the port keepout's own
        // edge (x=+-10) and the adjacent pillar zone's edge (x=+-12.02) —
        // not a real course-line segment, just a stub dash flanking the
        // port at z=10/20. A 2mm dash isn't a brick; 5mm is the shortest
        // run this pattern should ever print as a deliberate line.
        for (s = clip_all([[-hw_true, hw_true]], excl))
            if (s[1] - s[0] > 5)
                rear_cut((s[0] + s[1]) / 2, s[1] - s[0], z0, DOCK_JOINT[0], DOCK_JOINT[1]);
        // Round 19: small corner-overshoot patches so this face's cut still
        // overlaps the end walls' own cut at the corner. Round 22 FIX 1:
        // world-Z-slab-clipped (front_courses()'s own comment has the full
        // reasoning) — the pillar/port exclusions never reach this far out
        // (x~60+), so the patches don't need clip_all() themselves.
        for (s = [-1, 1])
            z_slab_clip(z0, DOCK_JOINT[0])
                rear_cut(s * (hw_true + CORNER_EXT/2), CORNER_EXT, z0, DOCK_JOINT[0], DOCK_JOINT[1]);
    }
    for (b = [0 : 2]) {
        z_lo = bands[b][0];  z_hi = bands[b][1];
        if (z_hi - z_lo > 0.5) {
            // Round 15 (reviewer probe (45,26.5): top read 27.2 instead of
            // 30 — a band-2 vertical joint reaching REAR_TAPER_Z1=30, the
            // wall's real top edge where it meets the flat plateau,
            // punched a ~2mm notch up into that plateau's underside. The
            // tilt/depth coupling that local_depth()/lz0 rely on shifts
            // world Z as the cut goes deeper into the material (the same
            // coupling the deleted cut_margin() over-corrected for at
            // BOTH band ends); right at a band's own top edge that shift
            // has nothing above it to stay clear of — it exits into
            // whatever surface sits above top_z. Clip the cut's own z_hi
            // 0.5mm shy of the true edge so the deepest part of the cut
            // still lands inside the wall, never past it.
            z_hi_cut = min(z_hi, REAR_TAPER_Z1 - 0.5);
            zc = (z_lo + z_hi_cut)/2;  zlen = z_hi_cut - z_lo;
            hw = rear_x_half(z_hi);
            offset = (b % 2 == 0) ? 0 : DOCK_JOINT_PITCH/2;
            // Round 21 FIX 3 (same asymmetry as front_courses(), see that
            // module's own comment): `[-n-1:n]` restores the offset-band
            // joint nearest -hw that `[-n:n]` was silently dropping.
            n = floor(hw / DOCK_JOINT_PITCH);
            crosses_port = (z_hi > port_z[0] && z_lo < port_z[1]);
            for (k = [-n - 1 : n]) {
                x = k * DOCK_JOINT_PITCH + offset;
                // Round 21 FIX 1: margin 1.5->4.0, same corner-sliver rule
                // as front_courses()/end_courses_pos().
                skip = (abs(x) >= hw - 4.0) || (crosses_port && x > port_x[0] - 1 && x < port_x[1] + 1)
                       || (x > REAR_PILLAR_X_ZONES[0][0] && x < REAR_PILLAR_X_ZONES[0][1])
                       || (x > REAR_PILLAR_X_ZONES[1][0] && x < REAR_PILLAR_X_ZONES[1][1]);
                if (!skip)
                    rear_cut(x, DOCK_JOINT[0], zc, zlen, DOCK_JOINT[1]);
            }
        }
    }
}

// --- end (side) faces --------------------------------------------------
// Round 20 FIX A (reviewer DO-NOT-PRINT, mesh-probed, review-r19-
// planarity.py): Round 19's per-y "ruled twist" model (end_phi_local()/
// end_course_line(), a smooth per-y taper) does NOT match the real hull()
// output — hull() of the flat footprint against a deck tilted between two
// DIFFERENT z's actually triangulates each end into TWO FLAT FACETS meeting
// along a real diagonal crease (dihedral 11.4°, mesh normal clusters at
// (0.919,0,0.394) and (0.831,-0.086,0.549)), not a smooth twist. Grooves
// cut against the fitted-but-nonexistent smooth surface were buried under a
// 0.07-0.63mm skin over roughly half their length and over-cut elsewhere.
// FIXED AT THE SOURCE (config.scad's HULL_TOP_XHALF_FRONT): the deck's
// FRONT edge is now wider, landing its corners exactly on the plane already
// defined by the footprint's own corners + the deck's REAR corners — all 4
// end-wall corners are now genuinely coplanar, a single flat plane, FIXED
// lean, x independent of y. end_phi_local()/end_course_line() DELETED;
// end_cut() reverted to one constant END_PHI (the pre-Round-19 shape,
// verified correct this time via review-r19-planarity.py: one normal
// cluster, and review-r19-endprobe.py: groove depth ~2.0 and OPEN along the
// whole length at z=10/20 — task-12-report.md Round 20).
END_X0 = HULL_BOT_XHALF;   END_X1 = HULL_TOP_XHALF;   // 67.5 -> 55.5
END_Z0 = HULL_BOT_ZS;      END_Z1 = HULL_REAR_Z1;      // 2 -> 30
END_PHI = atan((END_X0 - END_X1) / (END_Z1 - END_Z0));   // ~23.2 deg

// builds the +X end's geometry only; callers mirror([1,0,0]) for -X.
// Same local_depth() convention as front_cut()/rear_cut(): "depth" means
// world-X depth (the axis a probe/caliper would use on this wall).
module end_cut(y0, ylen, z0, zlen, depth) {
    ldepth = local_depth(depth, END_PHI);
    lz0    = (z0 - END_Z0) / cos(END_PHI);
    lzlen  = zlen / cos(END_PHI);
    translate([END_X0, 0, END_Z0])
        rotate([0, -END_PHI, 0])
            translate([-ldepth, y0 - ylen/2, lz0 - lzlen/2])
                cube([ldepth + 0.5, ylen, lzlen]);
}

// Round 20 FIX B (reviewer): running-bond joints WRAP the corner instead of
// landing at a random <2mm phase (the old fixed y-exclusion produced a
// "phantom joint" ~0.2mm inside the real front corner at z~10, a ragged
// notch). The end wall's own joint sequence is now DERIVED from the front
// face's own LAST surviving joint before the corner, continued at +1 pitch
// around the corner — an ordinary running-bond continuation, so the corner
// brick ends up whatever a normal stagger gives (not engineered to an exact
// width). The REAR corner is left to FLOAT (not independently re-phased) —
// stretching the pitch to force both ends to land neatly would need a
// second, band-dependent pitch correction for a cosmetic gain not worth the
// extra complexity here; chosen over re-phasing because the front corner is
// the one in Narcosia's own screenshot.
// last_joint_x(): the rightmost x=k*PITCH+offset that survives
// front_courses()' own exclusion (x < hw-4.0, Round 21 FIX 1 margin) —
// closed-form so end_courses_pos() can derive the SAME position
// front_courses() itself cuts.
function last_joint_x(hw, offset) =
    floor((hw - 4.0 - offset) / DOCK_JOINT_PITCH) * DOCK_JOINT_PITCH + offset;

// Running-bond wall courses on both ends — REPLACES the deleted single-
// square end_panel_pos()/end_panels(). Course-line y-extent uses the TRUE
// per-z0 corner (front_wall_y(z0)/rear_wall_y(z0), Round 19 — still
// correct, kept) extended CORNER_EXT past it so this face's cuts overlap
// front_courses()/rear_courses()'s own cuts at the corner. The wall is now
// genuinely flat (Round 20 FIX A), so END_Z1 is one constant top edge —
// course_bands()/course-line reuse the SAME machinery front/rear already use.
END_CORNER_EXT = 2.5;
module end_courses_pos() {
    for (z0 = [DOCK_COURSE_H, 2 * DOCK_COURSE_H]) {
        y_lo_true = front_wall_y(z0);  y_hi_true = rear_wall_y(z0);
        end_cut((y_lo_true + y_hi_true) / 2, y_hi_true - y_lo_true, z0, DOCK_JOINT[0], DOCK_JOINT[1]);
        // Round 22 FIX 1: small corner-overshoot patches, world-Z-slab-
        // clipped (front_courses()'s own comment has the full reasoning) —
        // replaces the old plain END_CORNER_EXT widening of the main cut
        // itself, which carried the wedge defect into the main cut's own
        // (previously self-supporting) cross-section.
        z_slab_clip(z0, DOCK_JOINT[0])
            end_cut(y_lo_true - END_CORNER_EXT/2, END_CORNER_EXT, z0, DOCK_JOINT[0], DOCK_JOINT[1]);
        z_slab_clip(z0, DOCK_JOINT[0])
            end_cut(y_hi_true + END_CORNER_EXT/2, END_CORNER_EXT, z0, DOCK_JOINT[0], DOCK_JOINT[1]);
    }
    bands = course_bands(END_Z1);
    y_hi_all = rear_wall_y(0) + END_CORNER_EXT;   // widest possible reach, for the joint loop's own upper bound
    for (b = [0 : 2]) {
        z_lo = bands[b][0];  z_hi = bands[b][1];
        if (z_hi - z_lo > 0.5) {
            // FIX B: this band's corner phase, derived from front_courses()'s
            // OWN joint sequence in the SAME band (front_x_half(z_hi) is the
            // exact hw front_courses() itself cuts against there).
            front_offset = (b % 2 == 0) ? 0 : DOCK_JOINT_PITCH / 2;
            hw_front = front_x_half(z_hi);
            f_last = last_joint_x(hw_front, front_offset);
            y_first = front_wall_y(z_hi) + (f_last + DOCK_JOINT_PITCH - hw_front);
            // Round 21 FIX 1 (reviewer): the OLD corner-exclusion evaluated
            // "clears both corners by >=1.5mm" at the band's own BOTTOM z —
            // the LEAST binding height, since both front_wall_y()/
            // rear_wall_y() move the corner INWARD (toward y=0) as z rises,
            // so a joint that clears comfortably at z_lo can end up sitting
            // right on the real corner near z_hi. Fixed: evaluate at each
            // corner's own BINDING z within the band — front's corner only
            // tightens up to HULL_FRONT_Z1 (flat beyond, so z stops getting
            // more binding there), rear's tightens all the way to END_Z1
            // (==REAR_TAPER_Z1), so z_hi alone is always its binding point.
            // Margin raised 1.5->4.0 (a corner brick under 4mm is a sliver,
            // not a brick); violating joints are DROPPED (skip, not shifted)
            // — same loop structure as before.
            z_front_bind = min(z_hi, HULL_FRONT_Z1);
            y_lo_wall = front_wall_y(z_front_bind) + 4.0;
            y_hi_wall = rear_wall_y(z_hi) - 4.0;
            n = floor((y_hi_all - y_first) / DOCK_JOINT_PITCH) + 1;
            for (k = [0 : n]) {
                y = y_first + k * DOCK_JOINT_PITCH;
                if (y - DOCK_JOINT[0]/2 > y_lo_wall && y + DOCK_JOINT[0]/2 < y_hi_wall) {
                    // Round 21 FIX 2: each joint's own top is now clipped to
                    // the LOCAL sloped deck edge (ramp_z(y)) instead of the
                    // band's flat END_Z1 top — band-2 end joints run up
                    // through the deck's own C->D slope (z 22..30, not a
                    // flat top at 30), so a band-wide z_hi_cut=END_Z1-0.5
                    // let the groove's top float 0.2-1.0mm above real
                    // material near the front, opening it into the air
                    // under the sloped deck side edge. HULL_REAR_Z1 caps it
                    // in case ramp_z(y) ever exceeds the wall's own top
                    // (it can't by construction, kept for safety); z_hi
                    // still caps it to this band's own boundary as before.
                    // Margin is 1.0, not the usual 0.5 front/rear/end bands
                    // use at their own flat top edge: end_cut()'s rotated
                    // frame couples depth into the cut with a world-Z shift
                    // (the same tilt/depth coupling documented at
                    // front_cut()/rear_cut()'s own Z-margin history) — ray-
                    // probed on the real mesh, 0.5 left the groove's ceiling
                    // still ~0.15mm shy of clearing a 1mm-deep probe near the
                    // surface; 1.0 clears it with margin (probe solid at
                    // depth 1.0 through dz=1.0 below the deck top, all 3
                    // surviving band-2 joints).
                    z_hi_cut = min(z_hi, min(ramp_z(y), HULL_REAR_Z1) - 1.0);
                    if (z_hi_cut - z_lo > 0.5) {
                        zc = (z_lo + z_hi_cut) / 2;  zlen = z_hi_cut - z_lo;
                        end_cut(y, DOCK_JOINT[0], zc, zlen, DOCK_JOINT[1]);
                    }
                }
            }
        }
    }
}
module end_courses() {
    end_courses_pos();
    mirror([1, 0, 0]) end_courses_pos();
}

// --- flank vertical face / cap coursing --------------------------------
// Scoped INSIDE flank(sx)'s own difference() (see flank(), above) — never
// at top level — for the same reason flank_relief_cut() had to move there
// in Step 11d: a cut that's a superset of the lug/saddle footprint, applied
// to the whole base union(), silently gutted the ring's seat once already.
// flank_outer_edge() (Round 12-19: shared by the old flank_courses_pos()
// notch and flank_panel_pos()) DELETED Round 20 FIX D alongside
// flank_panel_pos() — flank_cap_x0()/flank_cap_x1() (below) are its
// replacement, used by the folded single coursing system.

// builds the +X flank's geometry only; flank(-1) mirrors it.
// Round 20 FIX D (reviewer): the flank used to carry TWO independently-
// pitched groove systems on the SAME physical taper surface —
// flank_courses_pos()'s own 2 flat world-X notches (at z0=BASE_H+band,
// BASE_H+2*band, both already inside the cap's own z-range) and Round 19's
// separate flank_top_courses_pos() (an S-parametrized crossing-line system
// plus a lengthwise spine) — reading as a crossed grille, not stacked
// stone. FOLDED into ONE system here: the SAME 2 band positions, now cut
// with a proper rotated PERPENDICULAR-depth groove (flank_cap_cut(), below)
// instead of a flat notch, extended the full flank width; short, staggered
// running-bond joints replace the deleted lengthwise spine.
// flank_outer_edge()/flank_panel_pos() (recessed plaque) DELETED alongside
// — flank_panel_pos() occupied the SAME z-band as this coursing (it read as
// a competing decoration on the same face, per the reviewer) and
// flank_outer_edge() had no other caller once flank_panel_pos() was gone;
// DOCK_PANEL_FRAME/DOCK_PANEL_DEPTH (config.scad) are now unused, left
// defined per this project's own established pattern for orphaned PROVISIONAL
// constants rather than deleted outright.
function flank_cap_x0(sx) = sx * (FLANK_FOOT_X + FLANK[1]/2);   // foot's outboard-top corner
function flank_cap_x1(sx) = flank_top_x(sx) + sx * FLANK[3]/2;  // pad's outboard-top corner
FLANK_CAP_Z0 = BASE_H;         // 30
FLANK_CAP_Z1 = FLANK_TOP_Z;    // ~42.25

// generic groove in the +X flank's cap frame: y0/ylen run straight across
// (world Y, unaffected by the tilt), s0/slen run ALONG the taper (distance
// from the foot's own outboard-top corner). Round 20 FIX D (reviewer): depth
// here is the TRUE surface-normal (perpendicular) depth, used DIRECTLY as
// the local-frame cut length — NOT run through local_depth()'s cos(phi)
// world-axis conversion (that convention, used by front_cut()/rear_cut()/
// end_cut(), targets a WORLD-axis depth; on this ~42deg face the same
// depth=1.5 call was only reaching ~1.0-1.1mm perpendicular to the real
// surface, reviewer-measured). The local frame's own X-axis, after
// rotate([0,-phi,0]), IS the surface normal by construction, so the local
// cut length equals the perpendicular depth with no further scaling.
module flank_cap_cut(y0, ylen, s0, slen, depth) {
    x0 = flank_cap_x0(1);  x1 = flank_cap_x1(1);
    phi = atan((x0 - x1) / (FLANK_CAP_Z1 - FLANK_CAP_Z0));
    translate([x0, 0, FLANK_CAP_Z0])
        rotate([0, -phi, 0])
            translate([-depth, y0, s0])
                cube([depth + 0.5, ylen, slen]);
}

// --- flank FRONT/REAR face coursing (2026-08-21, Narcosia: "bring the
// brickwork right around") -----------------------------------------------
// Each face is a planar trapezoid leaning from the foot's top edge
// (y = FLANK_Y +- FLANK[2]/2 at BASE_H) to the pad's edge (y = FLANK_Y +-
// FLANK_FACE_PAD_YHALF at FLANK_TOP_Z) — planar because both edges run
// parallel to X (any two X-parallel lines share a plane; the Round-19
// "hull faces aren't the smooth surface you fitted" trap doesn't apply).
// Uses the SAME fractional band boundaries as the cap system, so the
// course lines land at the same heights on every face and the pattern
// wraps cap -> arris -> face continuously; cuts overshoot 2mm past the
// shared edges so they meet (the walls' own corner convention). Cut depth
// is TRUE surface-normal, same as flank_cap_cut. Only ever instantiated
// inside flank()'s own difference() (the Step-11d scoping rule), so the
// overshoot can't reach the pillars, lugs, or deck.
FLANK_FACE_PAD_YHALF = 10;    // the pad hull cube is 20 deep
FLANK_FACE_X_LO = flank_top_x(1) - FLANK[3]/2 - 2;   // pad inboard edge - 2
FLANK_FACE_X_HI = FLANK_FOOT_X + FLANK[1]/2 + 2;     // foot outboard edge + 2
module flank_face_cut_front(x0, xlen, s0, slen, depth) {
    phi = atan((FLANK[2]/2 - FLANK_FACE_PAD_YHALF) / (FLANK_CAP_Z1 - FLANK_CAP_Z0));
    translate([0, FLANK_Y - FLANK[2]/2, FLANK_CAP_Z0])
        rotate([-phi, 0, 0])
            translate([x0, -0.5, s0])
                cube([xlen, depth + 0.5, slen]);
}
module flank_face_courses_front() {
    phi = atan((FLANK[2]/2 - FLANK_FACE_PAD_YHALF) / (FLANK_CAP_Z1 - FLANK_CAP_Z0));
    run = (FLANK_CAP_Z1 - FLANK_CAP_Z0) / cos(phi);
    s_bounds = [for (i = [0 : DOCK_STEP[0]]) run * i / DOCK_STEP[0]];
    for (i = [1 : DOCK_STEP[0] - 1])
        flank_face_cut_front(FLANK_FACE_X_LO, FLANK_FACE_X_HI - FLANK_FACE_X_LO,
                             s_bounds[i] - DOCK_JOINT[0]/2, DOCK_JOINT[0], DOCK_FLANK_TOP[1]);
    for (b = [0 : DOCK_STEP[0] - 1]) {
        offset = (b % 2 == 0) ? -4 : 4;
        xj = (FLANK_FACE_X_LO + FLANK_FACE_X_HI)/2 + offset;
        flank_face_cut_front(xj - DOCK_JOINT[0]/2, DOCK_JOINT[0],
                             s_bounds[b] + 0.5, s_bounds[b + 1] - s_bounds[b] - 1,
                             DOCK_FLANK_TOP[1]);
    }
}
// both faces: the flank is symmetric about y = FLANK_Y (foot and pad share
// that centre), so the rear face is the front system mirrored in place.
module flank_face_courses_pos() {
    flank_face_courses_front();
    translate([0, FLANK_Y, 0]) mirror([0, 1, 0]) translate([0, -FLANK_Y, 0])
        flank_face_courses_front();
}

module flank_courses_pos() {
    x0 = flank_cap_x0(1);  x1 = flank_cap_x1(1);
    run = sqrt(pow(x0 - x1, 2) + pow(FLANK_CAP_Z1 - FLANK_CAP_Z0, 2));  // slope distance foot->pad
    band = (FLANK_TOP_Z - BASE_H) / DOCK_STEP[0];
    y_lo = FLANK_Y - FLANK[2]/2 - 2;  ylen = FLANK[2] + 4;
    // course lines: same 2 internal DOCK_STEP band boundaries as before,
    // converted from z (the taper is linear in z, so s scales directly)
    // to s, cut perpendicular via flank_cap_cut() instead of a flat notch.
    s_bounds = [for (i = [0 : DOCK_STEP[0]])
        run * ((BASE_H + i * band) - FLANK_CAP_Z0) / (FLANK_CAP_Z1 - FLANK_CAP_Z0)];
    for (i = [1 : DOCK_STEP[0] - 1])
        flank_cap_cut(y_lo, ylen, s_bounds[i] - DOCK_JOINT[0]/2, DOCK_JOINT[0], DOCK_FLANK_TOP[1]);
    // running-bond joints: one short, staggered joint per band (alternating
    // offset either side of centre) — replaces the deleted lengthwise spine.
    for (b = [0 : DOCK_STEP[0] - 1]) {
        s_b_lo = s_bounds[b];  s_b_hi = s_bounds[b + 1];
        if (s_b_hi - s_b_lo > 2) {
            offset = (b % 2 == 0) ? -4 : 4;
            flank_cap_cut(FLANK_Y + offset - DOCK_JOINT[0]/2, DOCK_JOINT[0],
                          s_b_lo + 0.5, s_b_hi - s_b_lo - 1, DOCK_FLANK_TOP[1]);
        }
    }
}

// chamfer_cut()/flank_chamfer_pos() DELETED (Round 12, overhang-removal
// pass, 2026-08-17): existed only to tidy the top-outboard shelf edge of
// flank_terrace_pos()'s proud course — that shelf (and the module that
// carved it) is gone, so there is no corner left to chamfer.

// --- plinth band (Round 11, item 1): proud base course around the whole
// pedestal foot. A hull of a slightly wider slab at the very bottom (grows
// the bed footprint by DOCK_PLINTH[1] per side — 135x75 -> 138x78, matching
// the plan's own stated number) tapering back to the pedestal's own normal
// footprint by z=DOCK_PLINTH[0] — the hull keeps it a clean flared lip
// rather than a stepped shelf, and it blends into the existing bottom-slab
// hull vertex above it (both are BASE_W x BASE_D at that height).
// plinth() DELETED (2026-08-21, Narcosia, slicer review of the v2 STL): the
// flared 138x78 base course read as a lip; the wall now runs straight to
// the bed at the plain 135x75 footprint. DOCK_PLINTH (config.scad) is left
// defined per this project's orphaned-PROVISIONAL-constant convention.

// --- top-plate deck (Round 11, item 3): the flat z=BASE_H rear plateau
// (between/behind the flanks, where the lugs + pillars sit) was blank.
// Deck-plate grid grooves at DOCK_DECK pitch, both directions, CLIPPED
// (split into surviving sub-segments) around the lug footprints, pillar
// feet, and drop slot — a first version used whole-line skip (matching the
// rear-wall courses' own simpler skip pattern) but that's wrong here: the
// lug zone is a NARROW y-band (3..11, only 8mm tall) yet wide in x
// (+-36.5), so skipping an entire ~25mm-tall VERTICAL line just because it
// crosses that x-range at some point wiped out almost the whole grid
// (checked numerically: 0 of 2 horizontal, 2 of 6 vertical lines survived)
// — real bug, not a simplification. Proper interval clipping fixes it.
function overlaps(lo, hi, zlo, zhi) = (hi > zlo && lo < zhi);
// clip a list of [lo,hi] segments against one exclusion [lo,hi] interval
function clip_segment(segs, excl_lo, excl_hi) =
    [for (s = segs) each (
        (excl_hi <= s[0] || excl_lo >= s[1]) ? [s] :
        (excl_lo <= s[0] && excl_hi >= s[1]) ? [] :
        (excl_lo <= s[0]) ? [[excl_hi, s[1]]] :
        (excl_hi >= s[1]) ? [[s[0], excl_lo]] :
        [[s[0], excl_lo], [excl_hi, s[1]]]
    )];
function clip_all(segs, exclusions, i = 0) =
    (i >= len(exclusions)) ? segs : clip_all(clip_segment(segs, exclusions[i][0], exclusions[i][1]), exclusions, i + 1);

// --- top-plate brickwork (Round 12, 2026-08-17): REPLACES top_deck() (a
// bare 1mm grid Narcosia called out as invisible/unconvincing — "the top plate
// is BARE") and top_kerb() (a proud strip, deleted outright per Directive 1).
// Same running-bond course pattern as the walls (course lines + staggered
// joints), cut into every flat horizontal surface up here: the rear
// plateau AND the 3 ramp treads, so the pedestal reads as continuous stone
// floor rather than a decorated wedge with a blank top. Every cut here goes
// straight DOWN into an upward-facing horizontal surface — floor faces up
// (safe), side walls are vertical (zero z-component, safe), no lintel like
// the vertical-wall grooves can ever form; verified by the overhang gate,
// not just argued.
//
// top_flat_courses()/top_region_courses() (Round 12/Round 14 FIX B: flat-
// surface course cutters for the old flat rear plateau) DELETED Round 19 —
// squaring the pedestal's corners removed the flat plateau entirely (see
// config.scad's HULL_INSET comment), so nothing calls a flat-surface cutter
// any more; deck_courses() (below) is their sloped-surface replacement.

// Round 19 (decision 22): the OLD flat "REAR strip" (behind the lugs, flat
// z=BASE_H) no longer exists — squaring the pedestal's corners replaced the
// flat rear plateau with ONE continuous slope, so the whole deck outboard
// of the tread column is sloped too. Replaced with deck_courses() (below),
// the SAME course-line+staggered-joint algorithm cut FLUSH with the slope
// via ramp_cut()'s rotated frame — applied to 2 side strips (x [13,40] and
// its mirror) flanking the tread column, spanning the DECK'S OWN FULL DEPTH
// (RAMP_Y0..RAMP_Y1) so this pattern also wraps to the front/rear corners,
// same as the walls. Round 14 FIX B / Round 15 history (why the old uniform
// pitch failed, why SIDE aprons were deleted) is otherwise unchanged; TREADS
// (below) are unchanged in logic, now automatically spanning the same full
// depth since RAMP_Y0/RAMP_Y1 were widened at their own definition.
// jx_lo/jx_hi (2026-08-21, Narcosia: deck brickwork to the side edges): the
// COURSE LINES may overshoot the deck's side arris (their boxes notch
// through it and die against the end wall's own coursing — the same
// "cuts extend past their own corner so adjacent faces' cuts meet"
// convention the walls use), but the JOINT lines must stay on the deck:
// a y-running joint outboard of the arris would gouge a lengthwise trench
// along the end wall's top corner instead of a crossing notch. Defaults
// keep the old behaviour (joints bounded by the course field).
module deck_courses(x_lo, x_hi, y_lo, y_hi, course_pitch, joint_pitch, zones, jx_lo = undef, jx_hi = undef) {
    jlo = (jx_lo == undef) ? x_lo : jx_lo;
    jhi = (jx_hi == undef) ? x_hi : jx_hi;
    s_lo = y_lo - RAMP_Y0;  s_hi = y_hi - RAMP_Y0;
    if (s_hi - s_lo > 0.5 && x_hi - x_lo > 0.5) {
        for (s = [s_lo : course_pitch : s_hi])
            if (s > s_lo + 0.5 && s < s_hi - 0.5) {
                y = RAMP_Y0 + s;
                excl = [for (zn = zones) if (overlaps(y - DOCK_JOINT[0]/2, y + DOCK_JOINT[0]/2, zn[2], zn[3])) [zn[0], zn[1]]];
                for (seg = clip_all([[x_lo, x_hi]], excl))
                    if (seg[1] - seg[0] > 2)
                        ramp_cut((seg[0] + seg[1]) / 2, seg[1] - seg[0], s, DOCK_JOINT[0], DOCK_JOINT[1]);
            }
        interior_s = [for (s = [s_lo : course_pitch : s_hi]) if (s > s_lo + 0.5 && s < s_hi - 0.5) s];
        band_s = concat([s_lo], interior_s, [s_hi]);
        for (b = [0 : len(band_s) - 2]) {
            sb_lo = band_s[b];  sb_hi = band_s[b + 1];
            if (sb_hi - sb_lo > 0.5) {
                offset = (b % 2 == 0) ? 0 : joint_pitch / 2;
                n = ceil((jhi - jlo) / joint_pitch) + 1;
                for (k = [0 : n]) {
                    x = jlo + k * joint_pitch + offset;
                    if (x > jlo + 1 && x < jhi - 1) {
                        excl = [for (zn = zones) if (overlaps(x - DOCK_JOINT[0]/2, x + DOCK_JOINT[0]/2, zn[0], zn[1])) [zn[2] - RAMP_Y0, zn[3] - RAMP_Y0]];
                        for (seg = clip_all([[sb_lo, sb_hi]], excl))
                            if (seg[1] - seg[0] > 2)
                                ramp_cut(x, DOCK_JOINT[0], (seg[0] + seg[1]) / 2, seg[1] - seg[0], DOCK_JOINT[1]);
                    }
                }
            }
        }
    }
}

module top_brick() {
    p0x = rear_pillar_x(REAR_PILLAR_ANG[0]);  p1x = rear_pillar_x(REAR_PILLAR_ANG[1]);
    pillar_half = REAR_PILLAR[0]/2 + 1;
    pillar_zones = [
        [p0x - pillar_half, p0x + pillar_half, REAR_PILLAR_FRONT_Y, REAR_PILLAR_FRONT_Y + REAR_PILLAR[1]],
        [p1x - pillar_half, p1x + pillar_half, REAR_PILLAR_FRONT_Y, REAR_PILLAR_FRONT_Y + REAR_PILLAR[1]],
    ];
    // INBOARD margin grown 0 -> 4 (2026-08-21, overhang-gate catch): the
    // flank hull's inboard face leans inboard with height (foot edge x=33
    // at its bottom -> pad edge ~25 at the top), so it OVERHANGS the deck
    // by ~1.5mm in the first couple of mm above the foot's embed. The deck
    // joints' rephasing (jx bounds, same change) landed a y-running joint
    // at x~31.5 — under that lean — and its groove ceiling became a 2.84mm
    // shelf (gate reading). The zone now covers the lean's shadow.
    flank_foot_zones = [
        [FLANK_FOOT_X - FLANK[1]/2 - 4, FLANK_FOOT_X + FLANK[1]/2, FLANK_Y - FLANK[2]/2, FLANK_Y + FLANK[2]/2],
        [-(FLANK_FOOT_X + FLANK[1]/2), -(FLANK_FOOT_X - FLANK[1]/2) + 4, FLANK_Y - FLANK[2]/2, FLANK_Y + FLANK[2]/2],
    ];
    // Round 19: lug footprint (anchor's own X/Y extent, +1mm margin) — the
    // SIDE strips below now reach the lugs' own y-band (they span the
    // deck's FULL depth, where the old flat "REAR strip" started behind
    // the lugs at y=13) — first pipeline run cut a groove right through
    // the anchor's own embed region, flagged by the overhang gate (bbox
    // [18.5,33,3.3,10.7,27,28.2] reach=7.41mm: a shelf where the cut
    // undermined the anchor's solid). Excluded here, same as pillars/feet.
    lug_zones = [
        [lug_x(1) - (CRADLE_LUG[0] + 4)/2 - 1, lug_x(1) + (CRADLE_LUG[0] + 4)/2 + 1, LUG_Y - LUG_ANCHOR_YHALF - 1, LUG_Y + LUG_ANCHOR_YHALF + 1],
        [lug_x(-1) - (CRADLE_LUG[0] + 4)/2 - 1, lug_x(-1) + (CRADLE_LUG[0] + 4)/2 + 1, LUG_Y - LUG_ANCHOR_YHALF - 1, LUG_Y + LUG_ANCHOR_YHALF + 1],
    ];
    drop_slot_zone = [-12, 12, -2, 16];

    // --- SIDE strips: outboard of the tread column (|x|>13), full deck
    // depth (RAMP_Y0..RAMP_Y1), sloped/flush with the deck via deck_courses().
    // Side strips now run to the deck's side arris and 2mm past it
    // (2026-08-21, Narcosia): course lines overshoot the edge (max half-width
    // is the FRONT deck edge, HULL_TOP_XHALF_FRONT) so their notches wrap
    // the arris and meet the end walls' own coursing; joints are capped
    // 0.5 inside the REAR half-width (the arris' narrowest point) so no
    // joint ever runs along the wall top — see deck_courses() header.
    deck_courses(13, HULL_TOP_XHALF_FRONT + 2, RAMP_Y0, RAMP_Y1,
                 DOCK_TOP_COURSE, DOCK_TOP_JOINT,
                 concat(pillar_zones, flank_foot_zones, lug_zones),
                 13, HULL_TOP_XHALF - 0.5);
    deck_courses(-(HULL_TOP_XHALF_FRONT + 2), -13, RAMP_Y0, RAMP_Y1,
                 DOCK_TOP_COURSE, DOCK_TOP_JOINT,
                 concat(pillar_zones, flank_foot_zones, lug_zones),
                 -(HULL_TOP_XHALF - 0.5), -13);

    // --- TREADS: ONE course centred on each tread (not offset from the
    // riser) + joints at DOCK_TREAD_JOINT pitch across the tread's own
    // +-13 width (>=3 joints per tread) — capped DOCK_TOP_GROOVE_SLOPE_DEPTH
    // (tread 0 is only 4mm thick above the cavity ceiling, asserted in
    // tests.scad). Kept as its own pattern (not top_region_courses()) since
    // "one course at the centre" isn't a pitch-repeated line.
    tread_zones = concat(pillar_zones, flank_foot_zones, [drop_slot_zone]);
    for (i = [0 : DOCK_RAMP_STEPS - 1]) {
        y_lo = TREAD_Y0 + i * TREAD_RUN;  y_hi = TREAD_Y0 + (i + 1) * TREAD_RUN;
        yc = (y_lo + y_hi) / 2;
        flat_z = RAMP_Z0 + i * DOCK_TREAD_RISER;
        excl_y = [for (zn = tread_zones) if (overlaps(yc - DOCK_JOINT[0]/2, yc + DOCK_JOINT[0]/2, zn[2], zn[3])) [zn[0], zn[1]]];
        for (s = clip_all([[-13, 13]], excl_y))
            if (s[1] - s[0] > 2)
                translate([s[0], yc - DOCK_JOINT[0]/2, flat_z - DOCK_TOP_GROOVE_SLOPE_DEPTH])
                    cube([s[1] - s[0], DOCK_JOINT[0], DOCK_TOP_GROOVE_SLOPE_DEPTH + 0.5]);
        n = floor(13 / DOCK_TREAD_JOINT);
        for (k = [-n : n]) {
            x = k * DOCK_TREAD_JOINT;
            if (abs(x) < 12) {
                excl_x = [for (zn = tread_zones) if (overlaps(x - DOCK_JOINT[0]/2, x + DOCK_JOINT[0]/2, zn[0], zn[1])) [zn[2], zn[3]]];
                for (s = clip_all([[y_lo + 0.3, y_hi - 0.3]], excl_x))
                    if (s[1] - s[0] > 2)
                        translate([x - DOCK_JOINT[0]/2, s[0], flat_z - DOCK_TOP_GROOVE_SLOPE_DEPTH])
                            cube([DOCK_JOINT[0], s[1] - s[0], DOCK_TOP_GROOVE_SLOPE_DEPTH + 0.5]);
            }
        }
    }
}

difference() {
    union() {
        // trapezoidal pedestal (engineering massing) — sloped top (Task 6
        // Step 11, Narcosia 2026-08-13): Narcosia's photos of the printed
        // assembly showed the flat top slab crowding the front of the
        // ring. Round 19 (decision 22, Narcosia): SQUARED to a true four-sided
        // planar taper — hull() of the 135x75 footprint slab against ONE
        // sloped top deck (rear edge at full BASE_H, front edge
        // PLATFORM_DROP lower), instead of the old 3-box hull (bottom slab
        // + separate rear/front top strips sharing one x-width but
        // DIFFERENT y-ranges). The old strips left the END walls
        // effectively vertical while front/rear tapered — that mismatch
        // built a diagonal CHAMFER FACET at each front corner, bridging a
        // leaning face to a vertical one and cutting the running-bond
        // courses off mid-brick (Narcosia's screenshot). The deck is
        // represented as 2 negligible-thickness (0.1mm) strips at its own
        // front/rear edges — hull() treats them as the 4 corner points the
        // task calls for; real (if tiny) volume avoids any CGAL degenerate-
        // face edge case a literal zero-thickness quad could hit. Round 20
        // FIX A (reviewer DO-NOT-PRINT): the front strip is now WIDER
        // (HULL_TOP_XHALF_FRONT, not HULL_TOP_XHALF) — see config.scad's own
        // comment for the derivation. This makes all 4 end-wall corners
        // truly coplanar (Round 19's "ruled twist" model didn't match the
        // real triangulated mesh — mesh-probed and reverted); front/rear
        // faces stay exactly planar as before, end faces are now ALSO one
        // flat plane, not an approximation.
        hull() {
            translate([0, 0, HULL_BOT_ZS / 2]) cube([HULL_BOT_XW, HULL_BOT_YW, HULL_BOT_ZS], center = true);
            translate([0, HULL_REAR_Y1, HULL_REAR_Z1])
                cube([HULL_TOP_XW, 0.1, 0.1], center = true);
            translate([0, HULL_FRONT_Y0, HULL_FRONT_Z1])
                cube([2 * HULL_TOP_XHALF_FRONT, 0.1, 0.1], center = true);
        }
        cradle_lug(-1); cradle_lug(1);
        for (a = REAR_PILLAR_ANG) rear_pillar(a);
        flank(-1); flank(1);
    }
    // internal cable cavity — opens to the rebate below, top stays closed.
    // Shortened (Task 6 Step 11, Narcosia 2026-08-13): the sloped top's lowest
    // point (the front edge, z=BASE_H-PLATFORM_DROP=22) needs >=3mm of
    // material above the cavity ceiling; z 2..18 keeps 4mm under 22 (the
    // rear side, where the top stays at BASE_H=30, keeps a full 12mm —
    // comfortably clear).
    translate([0, 0, (BASE_H - PLATFORM_DROP - 6)/2 + 2])
        cube([BASE_CAV[0], BASE_CAV[1], BASE_H - PLATFORM_DROP - 6], center = true);
    // bottom-cover rebate, 2 deep, leaving a BASE_SHELF-wide screw shelf
    translate([0, 0, 1]) cube([BASE_REBATE[0], BASE_REBATE[1], 2.02], center = true);
    // cover-screw insert holes, up into the shelf
    for (sx = [-1, 1]) for (sy = [-1, 1])
        translate([sx * BASE_SCREW_XY[0], sy * BASE_SCREW_XY[1], 1.99])
            cylinder(d = M2_INSERT, h = M2_INSERT_DEPTH);
    // cradle lug saddle cut (Task 6 Step 11b): carves the concave groove
    // that lets the gate's outer rim bed into both lugs at once (single
    // cylinder, symmetric about x=0).
    cradle_lug_saddle_cut();
    // rear pillar M2 clearance bores (Task 6 Step 11b): straight through
    // each pillar along world y, in line with gate_rear's matching
    // M2_INSERT holes and rear_cover's pass-through holes.
    for (a = REAR_PILLAR_ANG) rear_pillar_bore(a);
    // (Task 6 Step 11d, review Critical fix, 2026-08-16: the flank relief
    // cut used to be applied HERE, against the whole base union() —
    // including the lugs. Since it's a strict superset of the lugs' own
    // saddle cut, that silently re-cut the lug saddle floor from 2.71mm to
    // 0.70mm. It is now applied INSIDE flank(sx) instead (see that module,
    // above) — scoped to the flank solids only, so it can never touch
    // anything else in the union.)
    // USB straight-through drop slot (Narcosia 2026-08-13): base cavity ->
    // platform -> gate's USB tunnel -> puck port, one straight vertical
    // line. Pierces the pedestal top plate into the cavity below, under
    // the gate's 6 o'clock USB mouth. Z-span redone (Task 6 Step 11,
    // 2026-08-13): the old z 24..32 assumed the flat top at BASE_H-6=24;
    // with the slope, the sloped top under this slot's footprint (y -1..15)
    // runs ~29..30 (interpolated between the hull's (y=RAMP_Y0,z=22) and
    // (y=2,z=30) vertices, then flat at 30 past y=2 — RAMP_Y0 corrected in
    // Round 13 FIX 4 from -23.5 to the true hull-derived -27.5, but the
    // conclusion for THIS slot's y=-1..15 footprint is unaffected either
    // way, since -1 sits well inside the sloped region under both values)
    // — the old span no longer reaches the new cavity ceiling (18) at
    // its bottom OR clears the sloped top at its top. New span starts
    // 0.5mm below the cavity ceiling (clean breakthrough) and runs to
    // z=33.5, comfortably above the sloped top's highest point in this
    // footprint (30, so 3.5mm to spare) — verified with a render, not just
    // this derivation.
    translate([-11, -1, BASE_H - PLATFORM_DROP - 6 + 2 - 0.5])
        cube([22, 16, PLATFORM_DROP + 8]);
    // USB socket tail bore into the cavity — bridges the cavity to the rear
    // port below (y 17.5..31.5, overlaps the port's 25.5..39.5)
    translate([-6, BASE_CAV[1]/2 - 2, 8])
        cube([12, BASE_D/2 - 6 - BASE_CAV[1]/2 + 2, 8]);
    // rear-wall cable port (Task 6 Step 9, Narcosia 2026-08-13): a direct
    // through-hole in the pedestal's rear wall into the cavity, sized for a
    // USB-C plug housing to pass — replaces the deleted blind panel-socket
    // recess (decision 16, DESIGN.md). Cable enters here, crosses the
    // cavity via the tail bore above, and rises through the platform drop
    // slot into the gate's 6 o'clock tunnel.
    // Verified the y-span clears the trapezoidal taper's outer face rather
    // than landing inboard of it: the pedestal hull tapers linearly in y
    // from 37.5 (at z=2, the bottom slab's top) to 27.5 (at z=28, the top
    // slab's bottom); across this cut's z=8..20 the outer face runs
    // 35.19..30.58, always well inside the cube's y=39.5 max — confirmed
    // exiting the exterior with 4+mm to spare (also checked in a render).
    translate([-USB_PORT[0]/2, BASE_D/2 - 12, 8])
        cube([USB_PORT[0], USB_PORT[1], USB_PORT[2]]);
    // Dock styling — ramp steps + running-bond wall courses (front/rear/
    // ends) + top-plate brickwork (plateau + treads). flank() courses/panel
    // are scoped inside flank()'s own difference() above, not here;
    // instead of here. top_kerb() DELETED (Directive 1, Round 12).
    ramp_treads();
    front_courses();
    rear_courses();
    end_courses();
    top_brick();
}
echo("BASE_MAIN_DONE");
