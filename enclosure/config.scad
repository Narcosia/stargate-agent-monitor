// Claude Status Ring — Stargate enclosure configuration
// Single source of truth. Status legend:
//   CONFIRMED   measured on the part / official drawing / proven on coupon
//   PROVISIONAL brief starting value or edelkrone carry-over — not yet proven here
include <BOSL2/std.scad>

// ------------------------------------------------------------ tolerances ---
// CONFIRMED (coupon A, 2026-08-12): re-proven on this project's printer/material
FIT   = 0.25;   // what the printer loses on a hole
CLEAR = 0.15;   // running clearance for parts that must slide
function thru(nominal)   = nominal + FIT + CLEAR;  // something passes through
function pocket(nominal) = nominal + FIT + 0.25;   // something seats, located

FN = 96;        // one $fn for the whole project — every render file sets $fn = FN

// ------------------------------------------------- screen (Waveshare -B) ---
SCREEN_D        = 51.00;  // CONFIRMED official drawing + calipers
SCREEN_T        = 12.10;  // CONFIRMED incl. glass; 12.5 with rear protrusions
TOUCH_AA_D      = 43.76;  // CONFIRMED touch active area
SCREEN_POCKET_D = 51.50;  // CONFIRMED (coupon A, 2026-08-12): puck seats and lifts freely
SCREEN_POCKET_T = 13.20;  // CONFIRMED (coupon A, 2026-08-12)
FRONT_OPEN_D    = 49.75;  // CONFIRMED (coupon A, 2026-08-12): bears on rim, paper slides under lip — glass untouched
// rear-face keep-outs, from the -B dimension drawing (clock: USB-C at 6)
HEADER_ZONE  = [[-21, -14], [-16, 16], 8];  // PROVISIONAL zone bounds derived from the -B drawing offsets
CONN_ZONE    = [[ 14,  23], [-16, 16], 6];  // PROVISIONAL zone bounds derived from the -B drawing offsets
USB_W        = 22;   // PROVISIONAL (was 16, was 12): widened +3/side 2026-08-20
                     // (Narcosia, assembled build): the puck's port doesn't sit
                     // perfectly vertical in the pocket, so the tunnel needs
                     // slack to let the screen's clocking be trimmed a few
                     // degrees without the plug binding. Tunnel cut = USB_W+2
                     // = 24; rim-tick skip (RIM_GROOVE_SKIP) unchanged — the
                     // mouth half-angle at r=55 is asin(12/55)=12.6°, still
                     // only covering the 260/270/280 ticks; REG skip arcs
                     // below derive from USB_W automatically
USB_H        = 10;   // PROVISIONAL (was 7)
// side buttons observed at the viewer's 11 & 1 o'clock, 1.5mm proud (Narcosia,
// physical unit, 2026-08-13) — the Ø51.5 screen-pocket wall would press
// them; [width, radial depth] of the wall relief cut in gate_rear.scad
BTN_RELIEF   = [10, 2.2];

// --------------------------------------------------------------- diffuser ---
// (defined ahead of the LED ring so LED_POCKET_T below can reference DIFF_T —
// OpenSCAD evaluates top-level assignments top-to-bottom, no forward refs)
DIFF_OD = 73.0;   // CONFIRMED (coupon B, 2026-08-12, lit test passed)
DIFF_ID = 59.5;   // CONFIRMED (coupon B, 2026-08-12, lit test passed)
DIFF_T  = 1.0;    // CONFIRMED (coupon B, 2026-08-12, lit test passed)

// --------------------------------------------------------------- LED ring ---
LED_OD          = 72.0;   // CONFIRMED calipers
LED_ID          = 60.0;   // CONFIRMED
LED_T           = 3.5;    // CONFIRMED incl. LED package
N_LED           = 24;     // CONFIRMED
// LED stack pocket — REWORKED after the failed engineering print (2026-08-13):
// one-step annular pocket swallowing ring + diffuser; walls get a full
// millimetre per side (invisible behind the diffuser, clearance is free)
LED_POCKET_OD = 74.0;   // CONFIRMED (coupon C, 2026-08-18) — ring drops in + rotates freely (was 72.6: ring bound)
LED_POCKET_ID = 58.0;   // CONFIRMED (coupon C, 2026-08-18) — island cleared (was 59.5: fouled ring ID 60)
LED_POCKET_T  = LED_T + DIFF_T - 0.2;  // 4.3: diffuser sits on the ring, 0.2 proud → front face preloads it
LEAD_SLOT_W   = 14;     // CONFIRMED (coupon C, 2026-08-18) — leads pass the slot; through-slot for the SIDEWAYS in-plane leads
LEAD_SLOT_R1  = 45;     // slot runs from the pocket wall out to here, then through to the back
LEAD_LEN      = 15;     // CONFIRMED sideways in-plane, radial

// ------------------------------------------------------------- gate front ---
GATE_OD      = 110;    // PROVISIONAL brief
FRONT_T      = 6;      // PROVISIONAL front plate thickness
WINDOW_PITCH = 360 / N_LED;   // 15° — windows aligned 1:1 with LEDs
WINDOW_ARC   = 9.5;    // CONFIRMED (coupon B, 2026-08-12): windowed look + comet legibility passed lit
WINDOW_R0    = DIFF_ID / 2 + 0.75;  // window annulus, sits over the diffuser
WINDOW_R1    = DIFF_OD / 2 - 0.75;
GLYPH_R1     = 48;     // PROVISIONAL glyph track outer radius (decoration plan)
CHEVRON_N    = 9;      // CONFIRMED spec: 40° pitch, one at 6 o'clock —
                       // bottom-dead-centre, aligned with the dock's own
                       // centreline (Narcosia ruling 2026-08-20 from the
                       // assembled build, which he deliberately clocked
                       // this way; supersedes the original one-at-12
                       // decoration-plan spec). Chevron loops use
                       // 270 + k*40, so the top gap is centred at 12.

// -------------------------------------------------------------- gate rear ---
REAR_T   = 14;                  // PROVISIONAL; FRONT_T + REAR_T == gate depth 20
GATE_T   = 20;    // CONFIRMED spec envelope — the sum assert below must bind against this literal

// ------------------------------------------------- crush ribs (no retainer) ---
// Design ruling 2026-08-12: puck is captured bezel<->floor; three ribs on the
// pocket floor preload the 12.10 case rear rim by ~0.2. Never touches glass.
RIB_R      = 23;    // CONFIRMED (coupon A, 2026-08-12): even 3-point contact, ~0.2 crush
RIB_H      = SCREEN_POCKET_T - SCREEN_T + 0.2;   // 1.3 → 0.2 interference
RIB_L      = 5;     // CONFIRMED (coupon A, 2026-08-12): even 3-point contact, ~0.2 crush
RIB_W      = 1.2;   // CONFIRMED (coupon A, 2026-08-12): even 3-point contact, ~0.2 crush
RIB_ANGLES = [60, 120, 270];  // CONFIRMED calc: |y| = 19.9/19.9/23 > 16 — clear of both rear zones
M2_INSERT_DEPTH = 5;  // CONFIRMED insert practice: hole depth for M2 heat-sets

// ------------------------------------------------------- fasteners (M2) ----
M2_CLEAR   = 2.4;   // screw clearance hole
M2_INSERT  = 3.2;   // CONFIRMED (coupon A, 2026-08-12): insert set flush, 3 screw cycles held
// coupon-A insert-grip test only — no boss exists in any real part
M2_BOSS_D  = 6.0;
M2_BOSS_H  = 5.0;

// ------------------------------------------------------------------ base ---
BASE_W   = 135;  BASE_D = 75;  BASE_H = 30;   // PROVISIONAL brief
BASE_CAV   = [BASE_W - 40, BASE_D - 36];  // PROVISIONAL internal cavity footprint
BASE_SHELF = 5;                            // PROVISIONAL screw shelf around the cavity
BASE_REBATE = [BASE_CAV[0] + 2*BASE_SHELF, BASE_CAV[1] + 2*BASE_SHELF];
BASE_SCREW_XY = [BASE_CAV[0]/2 + 2.5, BASE_CAV[1]/2 + 2.5];
// float above platform — Task 6 Step 11 (Narcosia 2026-08-13): photos of the
// printed assembly show the pedestal crowding the front of the ring
// (bottom windows level with the buttress tops). The brief's 3-6 was a
// pre-visual guess; raised to a real visual gate. GATE_CZ (defined per-file
// in assembly.scad/base_main.scad/interference_check.scad, all identical)
// is meant to hold the ring's lowest point GATE_GAP clear of the sloped
// platform surface DIRECTLY UNDER IT — GATE_CZ = platform_top_at_ring_y +
// GATE_GAP + GATE_OD/2. The ring's outer rim runs the gate stack's full
// depth (world y ~[-7.5,20], front to rear_cover), so the binding case is
// the TALLEST platform point in that range — the sloped front strip (Step
// 11b below) only lowers the platform for y<2 (task-6-report.md hull
// derivation, re-verified numerically Step 11b); for y>=2, incl. the
// REAR_T/2=7 y-band the new cradle lugs sit on, the platform is still the
// flat, un-sloped BASE_H plateau. So platform_top_at_ring_y == BASE_H,
// unchanged, and GATE_CZ == BASE_H + GATE_GAP + GATE_OD/2 stays a correct
// DERIVED value, not a coincidence — everything tied to it (cradle lug/
// pillar/flank placement) follows automatically since they all reference
// GATE_CZ, not a literal. Task 6 Step 11c (Narcosia 2026-08-13, after step11b
// renders): GATE_GAP dialled back 12->8 (closer float) — GATE_CZ re-derives
// to 30+8+55 = 93, no other formula touched.
GATE_GAP = 8;           // PROVISIONAL — Narcosia visual gate; was 12 (Step 11), then 8 (Step 11c)
// HOISTED here (Task 6 Step 11d, review Critical fix, 2026-08-16): GATE_CZ
// used to be redefined identically in assembly.scad/base_main.scad/
// interference_check.scad (a deliberate "computed independently, same
// formula" pattern that was fine until tests.scad also needed to
// machine-check lug geometry against the SAME value base_main.scad builds
// with — two independently-typed copies of a formula is exactly the class
// of drift risk that let the flank-relief bug through undetected). Single
// source now; assembly.scad/base_main.scad/interference_check.scad no
// longer redefine it.
GATE_CZ = BASE_H + GATE_GAP + GATE_OD/2;    // gate centre height above desk
// pedestal top slopes down toward the front by this much (Task 6 Step 11,
// Narcosia 2026-08-13) — the flat top was crowding the lower ring; sloping it
// away opens up the view without lowering the rear (where the new cradle
// lugs + pillars sit, Task 6 Step 11b, and need the full BASE_H height).
PLATFORM_DROP = 8;      // PROVISIONAL — visual gate

// --------------------------------------------------- pedestal hull (single-sourced) ---
// Round 19 (Narcosia, decision 22): pedestal SQUARED to a true four-sided
// planar taper — replaces the old 3-box hull (bottom slab + separate
// rear/front top strips). The old rear/front strips shared ONE x-width but
// occupied DIFFERENT y-ranges, leaving the END walls effectively vertical
// while front/rear tapered — that mismatch built a diagonal CHAMFER FACET
// bridging a leaning face to a vertical one at each front corner, cutting
// the running-bond courses off mid-brick (Narcosia's screenshot). Fixed by
// hulling the SAME 135x75 footprint slab against ONE sloped top deck
// (front edge lower/z=BASE_H-PLATFORM_DROP, rear edge higher/z=BASE_H),
// inset the SAME HULL_INSET on every side (was two different insets baked
// into the old strip sizes: x 12/side, y an asymmetric ~10/side). The
// front/rear faces stay exactly planar (proven: each is the ruled surface
// between the footprint's own straight edge and the deck's own straight
// edge, both lying in a single y-z-only tilted plane, independent of x —
// true regardless of any offset/size difference between the two edges).
// The END faces ARE genuinely planar (Round 20 FIX A, superseding the
// Round-19 paragraph this used to be): naively reusing HULL_TOP_XHALF on
// BOTH the front and rear deck edges does NOT produce a flat end wall — 3
// distinct z references (footprint z=2, front-deck z=BASE_H-PLATFORM_DROP,
// rear-deck z=BASE_H) can't all sit on one flat quad while the footprint
// stays a true flat rectangle, and hull() of that mismatch triangulates
// each end into two facets meeting at a real diagonal crease (mesh-probed:
// 11.4deg dihedral), not a smooth twist. Fixed at the source by widening
// the deck's FRONT edge to its own half-width, HULL_TOP_XHALF_FRONT (below)
// — chosen so the footprint's two corners plus the deck's front and rear
// corners all land on ONE plane, making every end wall a single flat tilted
// quad (a fixed lean, x independent of y, base_main.scad's one constant
// END_PHI/end_cut()). See HULL_TOP_XHALF_FRONT's own comment for the full
// derivation and coplanarity proof; machine-checked in tests.scad (scalar
// triple product of the four corners) and verified on the real exported
// mesh (task-12-report.md Round 20: one normal cluster per end, dihedral
// 0.00deg).
HULL_INSET = 12;   // PROVISIONAL — x inset unchanged in effect (135->111,
                    // same numeric HULL_TOP_XW as the old design, so
                    // END_X1/FLANK_FOOT_X's own margin check both carry
                    // over unaffected); y inset changes an asymmetric
                    // ~10/side -> a uniform 12/side (the old rear/front
                    // strips' own y-edges sat at 27.5, a leftover of their
                    // independent YS/YC math a single shared inset can't
                    // reproduce exactly) — keeps the new deck's total
                    // y-span (51mm) close to the old one (55mm), the
                    // nearest clean number available per the task's own
                    // "stay close to today's" allowance.
HULL_TOP_XHALF = BASE_W/2 - HULL_INSET;    // 55.5 — same value as before
HULL_TOP_XW    = 2 * HULL_TOP_XHALF;       // 111 — same value as before
HULL_TOP_YHALF = BASE_D/2 - HULL_INSET;    // 25.5 (was an effective 27.5)
HULL_BOT_XW = BASE_W;   HULL_BOT_YW = BASE_D;  HULL_BOT_ZS = 2;  // footprint slab
HULL_BOT_XHALF = HULL_BOT_XW / 2;   // 67.5
HULL_BOT_YHALF = HULL_BOT_YW / 2;   // 37.5
// deck edges — front lower/nearer, rear higher/further (PLATFORM_DROP's own
// front-vs-rear height split, unchanged by the corner-squaring). Names kept
// identical to the old strip-derived HULL_FRONT_Y0/HULL_FRONT_Z1/
// HULL_REAR_Y1/HULL_REAR_Z1 (same MEANING — front/rear deck-edge y and z)
// so front_cut()/rear_cut()/tests.scad's existing taper-aware asserts carry
// over unchanged; the old HULL_*_YC/YS/ZC/ZS/Y1(front)/Y0(rear)/Z0 fields
// are gone — nothing outside config.scad referenced them except the two
// now-obsolete "hull skips a box's inner corner" asserts in tests.scad
// (deleted alongside — there's no more "box" to skip a corner of, the deck
// is a single thin plate by construction).
HULL_FRONT_Y0 = -HULL_TOP_YHALF;          // -25.5 (was -27.5)
HULL_FRONT_Z1 = BASE_H - PLATFORM_DROP;   // 22, unchanged
HULL_REAR_Y1  = HULL_TOP_YHALF;           // 25.5 (was 27.5)
HULL_REAR_Z1  = BASE_H;                   // 30, unchanged
// Round 20 FIX A (reviewer DO-NOT-PRINT, mesh-probed): the END walls built
// from HULL_TOP_XHALF on BOTH the front and rear deck edges were NOT
// planar — hull() of the flat footprint against a deck tilted between two
// DIFFERENT z's triangulates each end into two flat facets meeting along a
// real diagonal crease (dihedral 11.4°), not the smooth per-y "ruled twist"
// Round 19 modelled and cut grooves against (which don't exist on the real
// mesh — grooves ended up buried under a 0.07-0.63mm skin over roughly half
// their length). Fixed at the source: widen the deck's FRONT edge in x so
// its two corners land exactly on the plane already defined by the
// footprint's own two corners and the deck's REAR two corners — then ALL
// FOUR end-wall corners are coplanar and the end wall is genuinely one flat
// tilted quad (a fixed lean, x independent of y — exactly what a constant
// END_PHI models). Geometry: plane through A=(HULL_BOT_XHALF,-HULL_BOT_YHALF,
// HULL_BOT_ZS), B=(HULL_BOT_XHALF,HULL_BOT_YHALF,HULL_BOT_ZS),
// D=(HULL_TOP_XHALF,HULL_REAR_Y1,HULL_REAR_Z1) has zero y-dependence (B-A is
// pure +y, so the plane's own y-coefficient is forced to 0) — solving for x
// at z=HULL_FRONT_Z1 gives this. The rear deck strip's own half-width stays
// HULL_TOP_XHALF (unchanged, D is already on the plane by definition); only
// the FRONT strip widens. 58.93 vs 55.5 = 3.4mm/side, visually nil — the
// deck's own footprint becomes a very slight (117.9 vs 111mm) trapezoid
// rather than a rectangle.
HULL_TOP_XHALF_FRONT = HULL_BOT_XHALF - (HULL_BOT_XHALF - HULL_TOP_XHALF)
                        * (HULL_FRONT_Z1 - HULL_BOT_ZS) / (HULL_REAR_Z1 - HULL_BOT_ZS);  // 58.93

// LOW CRADLE FROM BEHIND (Task 6 Step 11b, Narcosia ruling 2026-08-13):
// raising the gate (Step 11) dragged the tab-anchored buttresses up to the
// ring's mid-height, crowding the 4/8 o'clock chevrons — worse than the
// crowding they fixed. Ruling: delete buttress()/tab_socket()/tab_m2_bore(),
// the tab-drop relief sweep, and gate_rear's two mounting tabs outright —
// gate_rear's outer rim becomes a clean, unbroken cylinder. The gate is now
// carried by two small lugs from below (CRADLE_LUG, contacting the outer
// mechanical ring only, well clear of the window annulus) plus two pillars
// from behind (REAR_PILLAR, the primary retention: 2× M2 driven straight in
// from behind, in shear — no side-driving, no tab/socket to route through).
LUG_ANG = 30;              // PROVISIONAL — degrees off bottom (6 o'clock),
                           // symmetric each side (viewer's 5 & 7 o'clock);
                           // WINDOW_R1 clearance asserted in tests.scad
CRADLE_LUG = [14, 8, 6];   // PROVISIONAL [w, d, h] — saddle nub size, sized
                           // BEFORE the concave Ø(GATE_OD+0.5) cut that lets
                           // the rim (Ø GATE_OD) bed in with 0.25 clearance
// HOISTED lug geometry (Task 6 Step 11d, review Critical fix, 2026-08-16):
// base_main.scad's cradle_lug()/cradle_lug_saddle_cut() and tests.scad's
// machine-checked saddle-floor assert now both read these — previously
// base_main.scad had its own private copies, which is how the flank-relief
// bug (Ø114 relief cutting into the lug's own Ø110.5 saddle, undetected by
// any gate) went unnoticed: no test ever checked the actual surviving
// thickness because nothing shared the formula.
//
// World XZ of the rim contact point at angle LUG_ANG from bottom, side sx
// (+-1): the ring sits in the world X-Z plane centred at (0, GATE_CZ), so a
// point LUG_ANG off its own bottom (6 o'clock) is simply
// (+-GATE_OD/2*sin(LUG_ANG), GATE_CZ - GATE_OD/2*cos(LUG_ANG)).
function lug_x(sx) = sx * GATE_OD/2 * sin(LUG_ANG);
LUG_CONTACT_Z    = GATE_CZ - GATE_OD/2 * cos(LUG_ANG);
LUG_SADDLE_R     = GATE_OD/2 + 0.25;         // saddle-cut radius (Ø(GATE_OD+0.5) cylinder)
LUG_NUB_BOTTOM_Z = LUG_CONTACT_Z - CRADLE_LUG[2]/2;  // nub centred ON the contact
                                                       // height, so its bottom is
                                                       // CRADLE_LUG[2]/2 below it
LUG_FLOOR_MIN = 2.0;   // PROVISIONAL minimum acceptable saddle-floor thickness —
                       // the ring's only seat; machine-checked in tests.scad
REAR_PILLAR     = [12, 10];   // PROVISIONAL [w, t] — width x front-to-back
                              // thickness, primary retention
REAR_PILLAR_R   = 45;         // radius (gate-local) of the M2 target on
                              // gate_rear's back face and rear_cover's
                              // pass-through
REAR_PILLAR_ANG = [245, 295]; // gate-local absolute angle (270 = 6 o'clock,
                              // same convention as REAR_COVER_HOLE_ANGLES),
                              // ±25° — clear of the USB tunnel (270±8.4°),
                              // checked in tests.scad
// MIDDLE-GROUND BASE — short wide buttress flanks (Task 6 Step 11c, Narcosia
// ruling 2026-08-13, after seeing the step11b renders): pure cosmetic/
// stability mass, bringing back the sloped-buttress silhouette but capped
// low and wide-footed — the cradle lugs remain the ring's only seat, the
// rear pillars remain the only retention. [top_z_below_lowest_window,
// foot_w, foot_d, top_w]: each flank is a hull() of a wide foot slab on the
// sloped platform (outboard of the lugs) and a narrow top pad that leans
// inboard toward the ring, capped well below the window annulus. Foot/top
// x-positions and the top pad's z are all DERIVED in base_main.scad from
// this vector + GATE_CZ/WINDOW_R1/GATE_OD — nothing here is a literal
// world coordinate. A dedicated Ø(GATE_OD+4) coaxial relief cut (larger
// than the cradle lugs' own Ø(GATE_OD+0.5) saddle cut) removes any flank
// material that could ever reach the ring, regardless of the hull's exact
// shape — the interference gate is the actual proof, asserted empty.
// FLANK[1] (foot_w) CUT 30->20 (Round 13 FIX 1, reviewer Critical): the old
// 30-wide foot's outboard edge (FLANK_FOOT_X+15=60.5) oversailed the end
// wall's own tapered outer face (only ~55.5 by z=28, the foot's own z-band)
// by up to 5mm — a genuine 90deg cantilever ledge with up to 8.5mm of air
// beneath it (reviewer ray-probe), not a printable groove-lintel case. New
// width + FLANK_FOOT_X (base_main.scad) keep the foot's outboard edge
// inside the end wall's real taper with margin — see FLANK_FOOT_X's own
// comment for the derivation and tests.scad for the machine-checked assert.
FLANK = [15, 20, 34, 14];  // PROVISIONAL
// rear-wall cable port (Task 6 Step 9, Narcosia 2026-08-13): replaces the
// blind USB panel-socket recess — decision 16, DESIGN.md. The cable enters
// here, crosses the cavity, and rises through the platform drop slot into
// the gate's 6 o'clock USB tunnel. [width, depth-into-wall, height].
USB_PORT = [16, 14, 12];

// ---------------------------------------------------------------- rear cover ---
// New part (Narcosia 2026-08-13, part count 7->8): dish enclosing gate_rear's
// back (wire zone, header/connector cavities) — supersedes the deleted
// spine as the design's answer to "hide/protect the wiring". Printed
// floor-at-z0, opening toward +z; assembled with rotate([0,180,0]) (an
// X-axis flip — NOT the Y-axis flip a first guess reaches for) because the
// M2 hole set below is only symmetric under that specific flip (verified
// 2026-08-13, see task-6-report.md): a physical part can only be flipped by
// a proper rotation, and 180 deg about a single axis unavoidably negates
// one more axis besides Z, so the hole layout has to be chosen to tolerate
// whichever axis that is. (Step 8 also gave the dish rim-notches over the
// tab roots; Step 9 deleted them — the tabs live entirely inside gate_rear's
// own thickness, in front of the cover, so a plain closed dish never
// reaches them.)
REAR_COVER_T    = 6;      // dish overall depth
REAR_COVER_WALL = 1.8;    // wall/floor thickness
REAR_COVER_HOLE_R = 40;   // M2 hole radius, shared with gate_rear's matching insert holes
// 4 hole angles: symmetric about the 90/270 axis (a and 180-a both present)
// so rotate([0,180,0]) only permutes them among themselves, never off the
// set; each clears the lead slot (165-195) and the USB tunnel (270) by
// >=8 deg (asserted in tests.scad). History: the original 30/90/150/250
// suggestion dropped 90 / added flip-partner 290 to restore the symmetry;
// then 250/290 -> 225/315 (2026-08-20, Narcosia, assembled build): at 250/290
// the countersunk heads sat only ~2.4 deg clear of the rear pillars'
// 245/295 +-7.6 deg footprint, and on the printed build the pillars landed
// ON the heads (photos, docs/img/build-cover-screws-*.jpg). 225/315 are the
// long-deleted tab angles — nothing lives there — and clear the pillars by
// 9.2 deg (~6.4mm at r40) while keeping the flip symmetry (180-225=315)
// and rotational asymmetry (gap pattern 120/75/90/75) intact.
REAR_COVER_HOLE_ANGLES = [30, 150, 225, 315];
REAR_COVER_CSK_D     = 4.4;   // M2 countersink diameter (typical flat-head)
REAR_COVER_CSK_DEPTH = 1.2;   // M2 countersink depth
// Screw guide bosses (decision 26, 2026-08-21, Narcosia): a tube standing on
// the floor's INSIDE face at each REAR_COVER_HOLE_ANGLES position,
// continuing the M2 bore across the dish's open interior. Two jobs:
// (1) guidance — without it the screw tip crosses 4.2mm of open cavity
// blind before finding gate_rear's hidden insert mouth; the boss makes the
// bore captive for the whole crossing; (2) clamp stiffness — the CSK head
// otherwise bears on the bare 1.8mm floor membrane; with the boss the
// clamped column is floor + boss (5.7mm of material). The tip stops
// RC_BOSS_CLR short of gate_rear's back face so SEATING STAYS RIM/LIP-
// DEFINED (couponD's proven flush seat) — the boss must never become the
// contact surface (asserted in tests.scad; seating_check.py proves the
// assembled clearance on the real mesh).
RC_BOSS_D      = 6;                    // boss OD, M2_BOSS_D convention
RC_BOSS_BASE_D = 9;                    // 45° chamfered base collar OD
RC_BOSS_CLR    = 0.3;                  // PROVISIONAL tip clearance to gate_rear
RC_BOSS_H      = REAR_COVER_T - REAR_COVER_WALL - RC_BOSS_CLR;   // 3.9
// COVER_LIP (the Task 6 Step 10 locating bezel) is REVERTED (Task 6 Step
// 11c, Narcosia 2026-08-13): gate_rear prints face-down (back on top), so a
// 1.5mm-proud raised ring on that top surface is an overhang needing
// supports — not worth it for a self-centring convenience the 4 screws +
// 2 pillar screws already handle well enough. Deleted the constant, the
// union in gate_rear.scad, and all of its asserts in tests.scad. rear_cover
// is held by 4 screws + 2 pillar screws only, no self-centring feature.

// -------------------------------------------------------------- reporting ---
MERGE_OVERLAP = 0.5;   // CONFIRMED edelkrone lesson: sub-bodies sink into their parent
                       // abutting exactly exports separate shells
module provisional_report() {
    echo("PROVISIONAL: tolerances(FIT/CLEAR), screen pocket, front opening,");
    echo("PROVISIONAL: LED pocket, diffuser, gate OD/T, windows, rear shell,");
    echo("PROVISIONAL: base, float, supports, USB socket flange, rear cover");
}

// ------------------------------------------------------- decoration (v2) ---
// All PROVISIONAL until the v2 print gate. Raised rings sit ON the frozen
// 6 mm plate; engravings cut INTO it. Nothing here may move frozen geometry.
BEZEL_RING = [25.4, 29.4, 1.0];   // [r0, r1, relief] raised ring around the screen
TRACK_RING = [36.3, 37.9, 0.8];   // raised divider between windows and glyphs
GLYPH_BAND = [38.5, 45.5];        // flat band carrying the engraved glyphs
GLYPH_N     = 39;                 // cells, like the real gate
GLYPH_DEPTH = 0.7;                // spec window 0.5-0.8
GLYPH_INK_T = 0.5;                 // PROVISIONAL AMS "ink" floor filling the bottom of
                                   // each glyph engraving (gate_front.scad PART="glyphs";
                                   // tools/make_3mf.py) - top (GLYPH_DEPTH-GLYPH_INK_T)
                                   // stays a real recess. tests.scad: GLYPH_INK_T < GLYPH_DEPTH
GLYPH_CELL  = [5.6, 4.6];         // radial x tangential artwork size per cell
SEG_N      = 36;                  // outer-ring segment grooves (10 deg pitch)
SEG_GROOVE = [0.9, 0.8];          // groove width, depth
OUTER_RING = [46.2, 54.9, 1.5];   // the raised mechanical ring
RELIEF_MAX = 1.5;                 // tallest relief above the plate
CB_DEPTH   = 2 + OUTER_RING[2];   // screw head sinks below the raised top
CHEV_R0        = 45.5;            // chevron apex radius
CHEV_T         = 2.5;             // chevron body thickness
CHEV_JEWEL_T   = 1.5;             // raised jewel step on the pad
// Round 18 FIX D (reviewer, cosmetic decision): outer pin moved 53.4->53.0.
// At 53.4, Ø2 reaches r=54.4 — past the axial rim-groove tick floor (54.2,
// GATE_OD/2-SEG_GROOVE[1]) at all 9 chevron angles (90+40k are all multiples
// of 10, i.e. tick angles) — a ~1.2mm slot opening the pin hole straight
// into the tick over z 5..7.5, hidden under the chevron pad but still a
// real defect. At 53.0, Ø2 reaches 54.0 < 54.2 (clear); re-checked against
// both existing asserts below: pad-edge 53.0+1.0+0.4=54.4 < CHEV_R0+9.4=
// 54.9 (was 53.4's 54.8, still fine either way but re-verified) and screw-
// clearance 53.0*sin(5deg)=4.62 > 3.75 (was 53.4's 4.66).
CHEV_PIN_R     = [52.0, 53.0];    // pin radii — clear of screws (5 deg away) and pad edge
CHEV_PIN_D     = 2.0;             // 1.75 filament offcut + glue
CHEV_PIN_DEPTH = 2.5;

// ------------------------------------------------ decoration (Task 6 Step 12) ---
// Dock/rim decoration pass (Narcosia 2026-08-13, decoration plan step 12): after
// Step 11's massing was approved, Narcosia's one note was that the flank-foot/
// lug/platform intersections read as accidental overlapping edges — this
// block's job is to make those joins read as DELIBERATE coursing. Relief/
// engraving ONLY: nothing here moves a load path, seat, clearance, cavity,
// or hole. All PROVISIONAL pending the print gate.
RIM_GROOVES = true;   // gate_rear outer-rim brick grooves, phase-matched to
                       // gate_front's SEG_N/SEG_GROOVE face pattern
// flank stepped courses: [band count, band depth] cut into each flank's
// OUTER skin only (x beyond lug_x+9, so the lug/relief/saddle-floor are
// never touched) — evenly spaced z from the foot's own top (BASE_H, where
// it meets the platform) to the top pad's own top (FLANK_TOP_Z, right where
// the cradle-lug nub begins) so the end bands land ON those two existing
// junctions instead of floating mid-face — the overlaps read as ledges.
DOCK_STEP = [3, 1.2];
DOCK_RAMP_STEPS = 3;    // engraved tread grooves across the sloped front
DOCK_TREAD = [0.8, 0.7];         // [width, depth]
DOCK_PANEL = [0.6, 0.8];         // [width, depth] OLD thin groove outline —
                                  // superseded by DOCK_PANEL_DEPTH below
                                  // (dock-relief-boldening pass, 2026-08-17:
                                  // Narcosia ruled the 0.6-0.8mm engraving too
                                  // subtle at desk distance); left defined,
                                  // unreferenced by the current geometry
DOCK_INSET = 6;                  // panel border inset from each face's edge
DOCK_BLOCK = 12;                 // rear-face checkerboard-block pitch
// Bolder-relief pass (Narcosia 2026-08-17, dock-relief-boldening): same DOCK_*
// layout as Step 12, just deeper/taller. Recessed panels are now true 3D
// pockets (proud frame + sunken interior) instead of thin outline grooves;
// flank courses and the rear block grid are now PROUD (added material)
// instead of grooved.
DOCK_PANEL_DEPTH  = 2.0;   // recessed-panel interior drop
DOCK_PANEL_FRAME  = 3;     // proud frame width left around each panel
// DOCK_COURSE_PROUD / DOCK_BLOCK_PROUD DELETED (Round 12, overhang-removal
// pass, 2026-08-17): every proud feature makes an unsupported underside on
// this flat-printed part (Narcosia, from the sliced-print photo). Flank courses
// are now flush + recessed grooves (DOCK_JOINT, below) — see base_main.scad
// flank_courses_pos(). DOCK_BLOCK_PROUD was already orphaned (Round 11
// replaced the checkerboard it drove with rear_courses()); deleted alongside.
DOCK_TREAD_RISER  = 1.5;   // ramp real-step riser height
// Pedestal-treatment pass (Narcosia Round 11, 2026-08-17): the ramp steps and
// flank courses read as intentional masonry (confirmed good, kept as-is) —
// but the pedestal's front face, sloped end faces, and top plate were still
// blank slabs. This block treats the whole pedestal as an SGC stone dock:
// a proud plinth band at the foot, recessed running-bond stone courses on
// front/end/rear walls (replacing the single-square recessed panels there —
// those read as an afterthought), a deck-plate grid + kerb on the top
// plateau, and a chamfer tidying up the flank's own proud-course shelf.
DOCK_PLINTH      = [4, 1.5];    // [height, proud] base course around the foot
                                 // — KEPT proud (Round 12 ruling): it sits at
                                 // the bed and flares WIDER at z=0 tapering
                                 // to normal footprint by z=4, so its only
                                 // non-vertical face is the flare itself,
                                 // which narrows going up (outward+upward
                                 // normal) — self-supporting by construction,
                                 // not an overhang. Verified by the overhang
                                 // gate passing with the plinth present, not
                                 // just argued geometrically.
DOCK_COURSE_H    = 10;          // wall-course line spacing (z=10,20)
DOCK_JOINT_PITCH = 15;          // running-bond vertical-joint pitch
DOCK_JOINT       = [1.5, 2.0];  // [width, depth] course-line/joint groove
// flank-top coursing (Round 19, decision 22, task B): continues the
// flank's own side coursing OVER its cap (the flat pad top at
// FLANK_TOP_Z and the sloping hull top from pad down to foot) —
// [width, depth, pitch]. Shallower than the side grooves (DOCK_JOINT[1]
// =2.0) since the pad is only 2mm thick over the hull (see FLANK[3]'s own
// top-pad cube) — 1.5 deep would leave <0.5mm, breaching it; 1.5 keeps
// >=0.5mm even at the pad's own worst (thinnest) point, machine-checked in
// tests.scad against the flank hull's real local thickness, not assumed.
DOCK_FLANK_TOP = [1.5, 1.5, 6];  // PROVISIONAL [w, d, pitch]
// DOCK_DECK / DOCK_KERB / DOCK_CHAMFER DELETED (Round 12, overhang-removal
// pass, 2026-08-17): DOCK_KERB (top_kerb()) was a proud strip on a flat
// upward-facing surface — Narcosia ruled it out unconditionally ("DELETE the
// kerb strip entirely"), no analysis needed since deletion was explicit.
// DOCK_CHAMFER (chamfer_cut()/flank_chamfer_pos()) chamfered the top-outboard
// shelf edge of the now-deleted proud flank course — with the shelf gone
// there is nothing left to chamfer, so the module and its constant are dead
// code and removed together. DOCK_DECK (top_deck()'s 1mm grid) is replaced
// by the top-plate running-bond brickwork below (DOCK_TOP_*), which reuses
// DOCK_JOINT for its groove dimensions instead of a separate constant.
// DOCK_TOP_COURSE_PITCH/DOCK_TOP_JOINT_PITCH RENAMED + TIGHTENED (Round 13
// FIX 3, reviewer): 15/20mm pitch produced 1 course + 4 joints — slots, not
// stone. Round 14 FIX B (reviewer DO-NOT-PRINT): even the Round 13 8/12mm
// pitch, once the lug/pillar/flank-foot/drop-slot exclusions are applied to
// the plateau's genuinely small FREE area, still only yielded 1 course +
// 9 stubs. Tightened again AND the plateau split into 3 real regions (REAR
// strip, 2 SIDE aprons, TREADS — base_main.scad's top_brick()) so each
// region's own free footprint is dense enough on ITS OWN to read as
// running bond; tests.scad machine-counts >=2 courses + >=3 joints per
// region rather than trusting the pitch numbers alone. Round 15: the SIDE
// apron region itself deleted (base_main.scad top_brick()) — its islands
// read as a "pi" glyph at that size, not running bond; left plain instead.
// DOCK_APRON_JOINT (its dedicated tighter joint pitch) deleted alongside,
// now unused.
DOCK_TOP_COURSE = 6;                // top-plate course-line pitch (Y) — REAR strip
DOCK_TOP_JOINT  = 10;                // top-plate staggered-joint pitch (X) — REAR strip
DOCK_TREAD_JOINT = 8;                // tread joint pitch (X) — treads get their own single
                                      // centred course instead of a pitch-repeated one (see top_brick())
DOCK_TOP_GROOVE_SLOPE_DEPTH = 1.0;  // capped groove depth on the thin sloped/
                                     // tread region (tread 0 is only 4mm
                                     // thick above the z=18 cavity ceiling;
                                     // the full DOCK_JOINT[1]=2.0 plateau
                                     // depth would leave <2.5mm there)

// -------------------------------------------- rim brickwork (Round 16) ---
// gate_rear's rim grooves (Task 6 Step 12) get a shared module
// (decor.scad's rim_grooves()) so gate_front/gate_rear/rear_cover all read
// the SAME SEG_N/SEG_GROOVE formula and can't drift out of phase.
// RIM_GROOVE_SKIP moved here (was private to gate_rear.scad) because
// rear_cover.scad now reuses it identically for its own axial grooves —
// see the REG_SKIP_LO/HI comment below for why reusing this literal value
// (rather than transforming it) still lands on the correct world angles.
RIM_GROOVE_SKIP = [260, 270, 280];   // USB tunnel mouth, discrete 10-deg
                                      // ticks omitted (gate_rear.scad's own
                                      // local/shared frame; reused as-is by
                                      // rear_cover.scad — symmetric about
                                      // 270 so it survives rear_cover's own
                                      // angle-negating placement transform
                                      // unchanged, same proof as REG_SKIP
                                      // below)

// -------------------------------------- gate-stack registration (Round 16) ---
// Narcosia 2026-08-17, two asks: (1) rear cover + front face carry the SAME
// rim brickwork as gate_rear's rim, phase-matched so the 26mm stack reads
// as one continuous grooved drum; (2) cover<->rear attachment needs real
// centring, not just the 4+2 screws. All PROVISIONAL pending the print gate.
//
// REGISTRATION: a RECESSED locating groove on gate_rear's BACK face (never
// proud — that face prints face-down, on top, the same constraint that
// killed Step 10's COVER_LIP) mates with a proud LIP standing from
// rear_cover's open rim edge (the TOP of ITS print, where a vertical-wall
// extension is printable). Round 17 (reviewer DO-NOT-PRINT, FIX 5): REG_R
// moved inboard from 53.0 to 52.4 — at 53.0 the groove's own OD (53.8) left
// only 0.4mm of material to the axial rim-groove floor (GATE_OD/2-
// SEG_GROOVE[1]=54.2) at all 33 surviving ticks, a single-nozzle-width post
// the slicer could drop, opening the registration groove straight into
// every rim tick. REG_R=52.4/REG_W=1.6 restores a full 1.0mm there — see
// the new tick-floor-clearance assert in tests.scad, which reads this
// exact relationship, not a hand-checked number.
//
// Round 18 FIX A (reviewer DO-NOT-PRINT blocker): the Round-17 lip's OUTER
// face flared from a weld foot (53.7) down to lip_od (53.0) — a taper that
// crossed ABOVE the rim edge (z0) while still outside the groove's own OD
// (53.2) until z~6.8, exactly where gate_rear's back face is SOLID (the
// FIX-5 "post" this same comment describes above). Manifold boolean of the
// placed cover against gate_rear: 37.2 mm^3 collision, cover sitting 0.86mm
// proud — it could not seat. Root cause: once REG_R moved inboard (FIX 5),
// the lip band (52.0..53.0) sits entirely INBOARD of the cover wall's own
// inner face (53.2), so there was nothing directly under the lip, and the
// old design reached OUTWARD for support ABOVE the mating plane — exactly
// where it could never be allowed to reach. Redesigned in rear_cover.scad
// (reg_shoulder_cut()/reg_lip()) to support the lip from BELOW instead: an
// internal 45-deg shoulder carved into the wall's own hollow cut, entirely
// at z <= REAR_COVER_T (inside this part's own printed height, so it can
// never touch gate_rear regardless of angle), topped by a PLAIN vertical
// lip annulus with nothing proud outside lip_od and nothing above the rim
// edge beyond it. See tests.scad's `reg_lip_od <= reg_groove_od -
// REG_LIP_CLR[0]` assert (Round 18 FIX B) — the geometric statement of
// "nothing above z0 outside the groove's own OD," now machine-checked, not
// just eyeballed off a diagram. Actual manifold seating is verified by
// tools/seating_check.py (Round 18 FIX B), wired into render.ps1 as a real
// pipeline gate — the interference-by-eye failure mode that let this
// blocker through once is now impossible to repeat silently.
REG_R = 52.4;   // CONFIRMED (coupon D, 2026-08-18) groove/lip pitch radius (Round 17 FIX 5)
REG_W = 1.6;    // CONFIRMED (coupon D, 2026-08-18) band width -> groove r 51.6..53.2; outer wall
                 // beyond it on gate_rear's rim = GATE_OD/2-(REG_R+REG_W/2)
                 // = 1.8, asserted >=1.0 in tests.scad (superseded as the
                 // binding constraint by the tick-floor-clearance assert,
                 // FIX 5, which is now the tighter of the two)
REG_D = 1.6;    // CONFIRMED (coupon D, 2026-08-18) groove depth (Round 17 FIX 5: 1.5->1.6, so the
                 // cover lip — which must now reach further in, chamfer run
                 // 1.2mm, see REG_LIP_CLR below — still bottoms 0.3mm short:
                 // lip_h = REG_D-0.3 = 1.3 >= chamfer 1.2), cut from
                 // gate_rear's back face (z REAR_T-REG_D .. REAR_T, i.e.
                 // 12.4..14)
// Round 17 FIX 2(a): lip/groove radial clearance was a symmetric FIT/2
// (0.125mm/side) — too tight for FDM, and after FIX 5's inward shift the
// groove ID face only has ~0.325mm of straight wall before the chamfer
// eats it entirely. Locate on the OD (the face that actually centres the
// cover) and leave the ID generous/non-locating: [outer, inner] clearance
// per side. CONFIRMED (coupon D, 2026-08-18) — cover lip drops in without
// force, seats flush no rock, lifts out.
REG_LIP_CLR = [0.2, 0.4];   // [outer 0.2/side, inner 0.4/side]
// USB tunnel skip: the tunnel's own top (SCREEN_T/2+1+(USB_H+2)/2 = 13.05)
// sits ABOVE the groove floor (REAR_T-REG_D = 12.5), so a full-circle
// groove would open a slit straight into the tunnel ceiling at 270 deg.
// Skip the groove (and the cover's matching lip) over an arc centred on
// 270; half-angle DERIVED from the tunnel's real angular footprint at the
// groove's worst-case (inner, smallest-r) radius, +2 deg margin — assert-
// by-construction, not a hand-picked pair of round numbers with an
// unverified margin.
// Round 18 FIX E (reviewer hygiene): the ~9.93/258.07/281.93/256.57/283.43
// deg approximations that used to sit in these comments were computed back
// when REG_R was still 53.0 (Round 16) — the FORMULAS below always read the
// current REG_R correctly (never stale), but Round 17 FIX 5 moved REG_R to
// 52.4 without anyone recomputing these hand-written approximations, so the
// comments quietly went wrong while the actual geometry stayed right.
// Recomputed at REG_R=52.4: ~10.05/257.95/282.05/256.45/283.55.
REG_TUNNEL_HALFANG = asin(((USB_W + 2) / 2) / (REG_R - REG_W/2));  // ~10.05 deg
REG_SKIP_HALF = REG_TUNNEL_HALFANG + 2;                             // ~12.05 deg
REG_SKIP_LO   = 270 - REG_SKIP_HALF;   // ~257.95
REG_SKIP_HI   = 270 + REG_SKIP_HALF;   // ~282.05
// This arc is symmetric about 270, so — exactly like RIM_GROOVE_SKIP above
// — it maps to ITSELF under rear_cover's rotate([0,180,0]) placement (net
// angle map A -> 180-A, the same map gate_front.scad's own header already
// derives and proves for its rotate([180,0,180])): 180-257.95=-77.95=
// 282.05 mod 360, 180-282.05=-102.05=257.95 mod 360 — the interval's
// endpoints swap, so the interval maps onto itself. The cover's lip gap
// therefore lands at the SAME world angle as gate_rear's groove gap, not
// merely "a" gap at some other angle — verified algebraically, not assumed.
//
// Round 17 FIX 2(b): the lip's own skip arc used to equal the groove's
// exactly — zero angular clearance at the arc ends, so the lip's own flat
// end-caps would bind against the groove's end walls on assembly. Widen the
// LIP's skip (i.e. shrink the lip's own angular presence) by a fixed margin
// per side, so it stops short of where the groove's solid material starts
// on each side.
REG_LIP_SKIP_MARGIN = 1.5;                          // deg, per side
REG_LIP_SKIP_LO = REG_SKIP_LO - REG_LIP_SKIP_MARGIN; // ~256.45
REG_LIP_SKIP_HI = REG_SKIP_HI + REG_LIP_SKIP_MARGIN; // ~283.55
//
// Rotational lock: the front-plate screw set (45/135/225/315, 4-fold
// symmetric) does NOT stop a 90-deg misfit — which would carry the
// chevron pin holes (9-fold, 40-deg pitch, no shared symmetry with 90) off
// the true chevron/glyph positions even though the SEG_N=36 rim ticks
// (10-deg pitch, divides 90 evenly) would still land fine either way. One
// off-grid Ø REG_PIN_D filament pin (not on a 10-deg groove tick) breaks
// that symmetry. rear_cover's own REAR_COVER_HOLE_ANGLES=[30,150,250,290]
// is already NOT symmetric under any non-zero rotation (no a+k has a+k in
// the set for any single non-zero k that works for all a) — the existing
// screw pattern is its own rotational key there, so no extra pin is added
// for the cover (documented; there is no new geometry to assert against).
REG_PIN_D     = 2.0;   // 1.75mm filament offcut + glue, same convention as CHEV_PIN_D
REG_PIN_DEPTH = 3;
REG_PIN_R     = 52;
REG_PIN_ANG_REAR  = 95;                     // gate_rear-local == shared frame
REG_PIN_ANG_FRONT = 180 - REG_PIN_ANG_REAR; // gate_front-local frame, DERIVED
                                             // from its own proven shared-
                                             // angle map (180 - local), not
                                             // a second hand-picked literal

// -------------------------------------------------------------- print aids ---
BRIM_D = 12;   // CONFIRMED practice: mouse-ear tab diameter (snap off after print)
BRIM_T = 0.6;  // CONFIRMED practice: 3 first-layers thick

echo("CONFIG_LOADED");
