// Spatial invariants. Any violation aborts with ERROR (non-empty assert msg).
include <config.scad>

// screen stack
assert(FRONT_OPEN_D > TOUCH_AA_D + 2, "bezel opening crowds the touch area");
assert(FRONT_OPEN_D < SCREEN_D - 0.8, "bezel too thin to retain the case");
let(g = SCREEN_POCKET_D - SCREEN_D)
    assert(g >= 0.3 && g <= 0.7, "screen pocket clearance out of range");
assert(SCREEN_POCKET_T >= 12.5 + 0.5, "pocket shallower than the real 12.5 puck");
assert(SCREEN_POCKET_T <= REAR_T - 0.8, "screen pocket breaks through rear shell");

// LED stack
assert(N_LED * WINDOW_PITCH == 360, "windows do not close the circle");
assert(WINDOW_ARC < WINDOW_PITCH - 2, "mullions thinner than 2 deg of arc");
assert(LED_POCKET_T >= LED_T + 0.3, "LED pocket crushes the LEDs");
assert(LED_POCKET_OD > LED_OD && LED_POCKET_ID < LED_ID, "LED pocket vs PCB");
assert(DIFF_ID <= LED_ID && DIFF_OD >= LED_OD, "diffuser does not cover LEDs");
assert(WINDOW_R0 >= DIFF_ID/2 && WINDOW_R1 <= DIFF_OD/2,
       "windows overhang the diffuser");
// LED+diffuser pocket — REWORKED after the failed engineering print
// (2026-08-13): the old press-fit assert enshrined the bug (0.4 mm was too
// tight to seat the diffuser at all). Coupon C proves these provisionally.
assert(LED_POCKET_OD >= LED_OD + 1.5 && LED_POCKET_ID <= LED_ID - 1.5,
       "LED pocket walls under 0.75/side — the engineering print bound at 0.3");
assert(LED_POCKET_OD >= DIFF_OD + 0.8, "diffuser cannot drop into the pocket");
assert(LED_POCKET_T >= LED_T + DIFF_T - 0.3 && LED_POCKET_T <= LED_T + DIFF_T,
       "LED+diffuser stack preload outside 0..0.3");
assert(LEAD_SLOT_W >= 12, "lead slot narrower than the 3-wire in-plane bundle");

// gate stack
assert(FRONT_T + REAR_T == GATE_T, "front+rear != gate depth");
assert(GATE_OD/2 > DIFF_OD/2 + 15, "no radial room for glyphs+outer ring");

// 360-degree visibility — THE hard requirement
// supports contact the outer mechanical ring only, and the platform stays
// below the gate by GATE_GAP. Range widened for Task 6 Step 11 (Narcosia
// 2026-08-13): the brief's 3-6 was a pre-visual guess; Narcosia's photos of
// the printed assembly showed the base crowding the ring, so GATE_GAP rose
// to 12 — still bounded here to catch a real typo/regression. (Dialled back
// to 8, Task 6 Step 11c, Narcosia ruling 2026-08-13 — wants the ring closer;
// still well inside this range.)
assert(GATE_GAP >= 3 && GATE_GAP <= 15, "float outside range");
// cradle lugs (Task 6 Step 11b, Narcosia ruling 2026-08-13): replaces the
// deleted buttress/tab-socket support_contact_r check above. The lugs
// contact the outer mechanical ring at ±LUG_ANG off bottom — must stay
// well clear of the window annulus (plan's own worked check: 55*cos(30)=
// 47.6 > 41.75).
assert(GATE_OD/2 * cos(LUG_ANG) > WINDOW_R1 + 6,
       "cradle lug contact encroaches on the window annulus");
// lugs (x ~= +-27.5, footprint half-width (CRADLE_LUG[0]+4)/2=9) must clear
// the 16-wide USB tunnel mouth (x +-(USB_W+2)/2 = +-9) with real margin
assert(GATE_OD/2 * sin(LUG_ANG) - (CRADLE_LUG[0] + 4)/2 > (USB_W + 2)/2 + 1,
       "cradle lug crowds the USB tunnel mouth / platform drop slot");
// lug saddle floor (Task 6 Step 11d, review Critical fix, 2026-08-16): the
// ring's ONLY seat. Round 7's flank-relief cut was a strict superset of the
// lugs' own saddle cut and, applied against the whole base union() instead
// of scoped to the flank solids, silently re-cut this floor from 2.71mm
// down to 0.70mm — invisible to shells/zmin/interference, none of which
// gate on thickness. Machine-check it directly, using the SAME hoisted
// formulas base_main.scad's cradle_lug()/cradle_lug_saddle_cut() build
// geometry with (config.scad: lug_x(), LUG_CONTACT_Z, LUG_SADDLE_R,
// LUG_NUB_BOTTOM_Z) — one source, so geometry and this check cannot drift
// apart the way they did before. lug_x(1) (sign doesn't matter, squared).
saddle_floor = (GATE_CZ - sqrt(pow(LUG_SADDLE_R, 2) - pow(lug_x(1), 2))) - LUG_NUB_BOTTOM_Z;
assert(saddle_floor >= LUG_FLOOR_MIN,
       "lug saddle floor thinner than LUG_FLOOR_MIN — ring seat compromised");
// short-wide-buttress flanks (Task 6 Step 11c, Narcosia ruling 2026-08-13):
// pure cosmetic mass, must stay well clear of the window annulus. FLANK
// top z is DERIVED the same way base_main.scad derives it (never a
// literal; now reads the hoisted GATE_CZ too) so this assert tracks any
// future GATE_GAP/WINDOW_R1/FLANK edit.
flank_top_z = (GATE_CZ - WINDOW_R1) - FLANK[0];
assert(flank_top_z <= (GATE_CZ - WINDOW_R1) - 10,
       "flank top comes within 10mm of the lowest window");

// Round 19 (decision 22, task B): flank-top coursing (DOCK_FLANK_TOP) must
// leave >=1.5mm of material over the flank's own internal void — the
// coaxial Ø(GATE_OD+4) relief cut coaxial with the assembled ring at height
// GATE_CZ. The binding case is the flat pad-top groove nearest the 2mm
// inboard skip zone (Round 20 FIX D folded the old separately-pitched
// flank_top_courses_pos() into base_main.scad's flank_courses_pos()/
// flank_cap_cut() — ONE groove system now, perpendicular-depth cut into the
// cap's own sloping taper: the diagonal outboard region is always farther
// from the ring's own axis, since it slopes away toward the foot).
// flank_top_x()/flank_rim_half_width() duplicated from base_main.scad
// (tests.scad only includes config.scad, this file's established pattern).
flank_rim_half_width_check = sqrt(pow(GATE_OD/2, 2) - pow(GATE_CZ - flank_top_z, 2));
flank_top_x_check   = flank_rim_half_width_check + FLANK[3]/2 + 4;
flank_pad_in_check  = flank_top_x_check - FLANK[3]/2;   // pad's own inboard-top edge
flank_cap_skip_x    = flank_pad_in_check + 2;            // task's own 2mm skip
relief_r_check       = (GATE_OD + 4) / 2;
flank_cap_floor_z    = flank_top_z - DOCK_FLANK_TOP[1];
flank_cap_worst_dist = sqrt(pow(flank_cap_skip_x, 2) + pow(flank_cap_floor_z - GATE_CZ, 2));
assert(flank_cap_worst_dist - relief_r_check >= 1.5,
       "flank-top coursing leaves less than 1.5mm of material over the ring relief void");

// flank foot vs. end-wall taper (Round 13 FIX 1, reviewer Critical): the
// foot's own outboard edge must stay INSIDE the end wall's real tapered
// outer face at every z the foot occupies (z=[FLANK_FOOT_BOTTOM,BASE_H],
// entirely >= BASE_H-2=28, i.e. entirely in the end wall's own narrowest
// region, END_X1) — else the foot cantilevers over open air, exactly the
// bug the reviewer ray-probed (old foot: 60.5 vs END_X1=55.5, a 5mm
// oversail with up to 8.5mm of air beneath). END_X1/FLANK_FOOT_X both
// duplicated here from base_main.scad's own formulas (tests.scad only
// includes config.scad). Round 19: END_X1 now reads HULL_INSET directly
// (was the old strip-derived (BASE_W-24)/2 literal — same numeric value,
// 55.5, since the x inset is unchanged by squaring the corners).
end_x1_check = BASE_W / 2 - HULL_INSET;
flank_foot_x_check = BASE_W / 2 - 24.5;
assert(flank_foot_x_check + FLANK[1] / 2 <= end_x1_check - 0.5,
       "flank foot's outboard edge oversails the end wall's real taper");

// header cavity clearance (brief: 8-10 horizontal, 5-8 vertical)
assert(HEADER_ZONE[0][1] - HEADER_ZONE[0][0] >= 7, "header cavity too narrow");
assert(HEADER_ZONE[2] >= 8, "header cavity too shallow for the plug");

// rim-piercing cuts (Task 6 Step 9, 2026-08-13): the USB tunnel at 6
// o'clock is the designed cable entry and the ONLY cut meant to reach the
// rim — the old button access slot that also broke the rim (the stray
// "see-in" hole on Narcosia's printed cover photo) is deleted. Documents the
// intent so a future edit accidentally extending the lead slot or the
// header/connector zones out to the rim gets caught here.
assert(LEAD_SLOT_R1 < GATE_OD/2 - 3, "lead slot reaches the rim");
header_max_r = sqrt(pow(max(abs(HEADER_ZONE[0][0]), abs(HEADER_ZONE[0][1])), 2)
                   + pow(max(abs(HEADER_ZONE[1][0]), abs(HEADER_ZONE[1][1])), 2));
conn_max_r   = sqrt(pow(max(abs(CONN_ZONE[0][0]), abs(CONN_ZONE[0][1])), 2)
                   + pow(max(abs(CONN_ZONE[1][0]), abs(CONN_ZONE[1][1])), 2));
assert(header_max_r < GATE_OD/2 - 3, "header zone reaches the rim");
assert(conn_max_r < GATE_OD/2 - 3, "connector zone reaches the rim");

// button wall reliefs (Task 6 Step 8, 2026-08-13): groove floor must keep
// >=1mm of island between the screen pocket and the LED pocket ID. Groove
// outer radius = SCREEN_POCKET_D/2 + BTN_RELIEF[1] (the cut's radial
// 1mm-into-the-pocket overshoot cancels against its own -1 in gate_rear.scad
// — see the cube dims there: [1 + BTN_RELIEF[1], BTN_RELIEF[0], ...]).
assert(LED_POCKET_ID/2 - (SCREEN_POCKET_D/2 + BTN_RELIEF[1]) >= 1,
       "button relief breaks into the LED pocket - island too thin");

// rear cover M2 holes (Task 6 Step 8, 2026-08-13): each hole angle clears
// the lead slot (165-195) and the USB tunnel (270) by >=8 deg; also clear
// of the header/connector cavities radially. (Task 6 Step 11c, Narcosia ruling
// 2026-08-13: the two checks that used to guard against the tabs at
// 225/315 deg are DELETED — round 6 deleted the tabs themselves, so nothing
// lives at those angles any more and the checks had gone vacuous; the
// REAR_PILLAR-vs-REAR_COVER_HOLE_ANGLES Cartesian clearance check further
// below is what now guards this hole set's nearest real neighbour.)
function ang_dist(a, b) = min(abs(a - b), 360 - abs(a - b));
function zone_dist(a, lo, hi) = (a >= lo && a <= hi) ? 0 : min(ang_dist(a, lo), ang_dist(a, hi));
assert(min([for (a = REAR_COVER_HOLE_ANGLES) zone_dist(a, 165, 195)]) >= 8,
       "a rear-cover M2 hole is too close to the lead slot");
assert(min([for (a = REAR_COVER_HOLE_ANGLES) ang_dist(a, 270)]) >= 8,
       "a rear-cover M2 hole is too close to the USB tunnel");
// header_max_r/conn_max_r already computed above (rim-piercing-cuts block)
rc_hole_inner = REAR_COVER_HOLE_R - REAR_COVER_CSK_D/2;
assert(header_max_r < rc_hole_inner, "rear-cover M2 hole breaches the header cavity");
assert(conn_max_r < rc_hole_inner, "rear-cover M2 hole breaches the connector cavity");
// the hole set must be symmetric about the 90/270 axis (a and 180-a both
// present) - required for rotate([0,180,0]) placement to only permute the
// holes among themselves rather than moving one off the matched set
assert(len([for (a = REAR_COVER_HOLE_ANGLES) if (len([for (b = REAR_COVER_HOLE_ANGLES) if (abs(b - (180 - a)) < 0.01 || abs(b - (180 - a) - 360) < 0.01 || abs(b - (180 - a) + 360) < 0.01) b]) == 0) a]) == 0,
       "rear-cover M2 hole angles are not symmetric about the 90/270 axis - rotate([0,180,0]) would misalign them");

// rear pillar M2 holes (Task 6 Step 11b, Narcosia ruling 2026-08-13): the
// gate's primary retention now that the tabs/sockets are gone. Clear of the
// USB tunnel (270±8.4°) and the rim; clear of the REAR_COVER_HOLE_ANGLES
// holes (5° apart at r 40/45, checked as a real edge-to-edge Cartesian
// distance, not just an angular one, since the two hole sets sit at
// different radii).
assert(min([for (a = REAR_PILLAR_ANG) ang_dist(a, 270)]) >= 8,
       "a rear-pillar M2 hole is too close to the USB tunnel");
assert(REAR_PILLAR_R < GATE_OD/2 - 3, "rear-pillar M2 hole reaches the rim");
rp_rc_min_gap = min([for (a = REAR_PILLAR_ANG) for (b = REAR_COVER_HOLE_ANGLES)
    sqrt(pow(REAR_PILLAR_R*cos(a) - REAR_COVER_HOLE_R*cos(b), 2)
       + pow(REAR_PILLAR_R*sin(a) - REAR_COVER_HOLE_R*sin(b), 2))]);
assert(rp_rc_min_gap > M2_INSERT/2 + M2_INSERT/2 + 1.5,
       "a rear-pillar M2 hole crowds a rear-cover M2 hole");
// pillars (base_main.scad) vs the rear-wall USB cable port, in x — round-6
// review follow-on (Task 6 Step 11c): pillar inner edge = |world X| -
// REAR_PILLAR[0]/2, world X = REAR_PILLAR_R*|cos(a)| (base_main.scad's
// rear_pillar_x(), duplicated here since tests.scad only includes config).
assert(min([for (a = REAR_PILLAR_ANG) REAR_PILLAR_R*abs(cos(a)) - REAR_PILLAR[0]/2])
       >= USB_PORT[0]/2 + 3,
       "a rear pillar crowds the USB rear port");

// (Task 6 Step 10's rear-cover locating bezel is REVERTED, Task 6 Step 11c,
// Narcosia ruling 2026-08-13 — gate_rear prints face-down, a proud ring on
// that face is an overhang needing supports. COVER_LIP and all five of its
// asserts here are deleted; rear_cover is held by 4 screws + 2 pillar
// screws only.)

// rear shell — LED_POCKET_T now covers the whole ring+diffuser stack
// (one-step pocket, Task 6 rework 2026-08-13; DIFF_RECESS_T no longer exists)
assert(LED_POCKET_T < SCREEN_POCKET_T,
       "LED+diffuser stack deeper than the screen pocket");
// crush ribs: touch the 12.10 case rim but never crush more than 0.4,
// and land clear of the header/connector zones (|y| > 16 at rib radius)
assert(RIB_H >= SCREEN_POCKET_T - SCREEN_T,
       "ribs too short to touch the case rim - puck rattles");
assert(RIB_H <= SCREEN_POCKET_T - SCREEN_T + 0.4,
       "rib crush exceeds 0.4 - risks stressing the case");
assert(min([for (a = RIB_ANGLES) abs(RIB_R * sin(a))]) > 16,
       "a rib lands in the header/connector zone");

// front plate clearance
assert(GATE_OD/2 - 6 - M2_BOSS_D/2 > WINDOW_R1 + 2, "front screws foul the window track");

// base — platform vs ring bottom, cover-screw shelf, cavity wall thickness
platform_top = BASE_H;
ring_bottom_z = GATE_CZ - WINDOW_R1;
assert(platform_top < ring_bottom_z - 2, "platform hides the 6 o'clock windows");
assert(BASE_SHELF >= M2_INSERT + 1.5, "cover-screw shelf too narrow for inserts");
assert(BASE_CAV[0] <= BASE_W - 30 && BASE_CAV[1] <= BASE_D - 26,
       "cavity walls thinner than 15/13 per side");
// Dock-decoration CUTS must never eat into the cavity wall's own safety
// margin (re-verified each round with whatever the new deepest cut is).
// Only cuts count — the plinth band (DOCK_PLINTH) ADDS material, so it
// doesn't remove wall thickness (DOCK_COURSE_PROUD/DOCK_KERB DELETED,
// Round 12 — everything decorative is a cut now). Round 12 (2026-08-17)
// swaps the deleted DOCK_DECK[2] for the top-plate brickwork's own groove
// depths (DOCK_JOINT[1]=2.0 on the plateau, DOCK_TOP_GROOVE_SLOPE_DEPTH=1.0
// on the treads — the plateau one already dominated by DOCK_JOINT[1] below,
// so only the plateau value needs adding to the candidate list). The ramp
// staircase's own deepest single cut is re-derived here from the same
// config-level constants base_main.scad uses, matching this file's existing
// duplication pattern (e.g. rear_pillar_x() above) rather than a second
// private copy of MAX_TREAD_CUT going stale. Round 19: the OLD flat formula
// (PLATFORM_DROP - (STEPS-1)*RISER, the "landing riser" the last tread made
// against the OLD flat plateau) no longer applies — the treads now stop at
// TREAD_Y1=-4 (base_main.scad), well short of the deck's own rear edge, so
// re-derived as the real max wedge each tread's own ramp_step_cut() removes.
tread_y0_check = HULL_FRONT_Y0;
tread_y1_check = -4;   // must match base_main.scad's TREAD_Y1
tread_run_check2 = (tread_y1_check - tread_y0_check) / DOCK_RAMP_STEPS;
function ramp_z_check(y) = HULL_FRONT_Z1 + PLATFORM_DROP * (y - HULL_FRONT_Y0) / (HULL_REAR_Y1 - HULL_FRONT_Y0);
max_tread_cut = max([for (i = [0 : DOCK_RAMP_STEPS - 1])
    ramp_z_check(tread_y0_check + (i + 1) * tread_run_check2) - (HULL_FRONT_Z1 + i * DOCK_TREAD_RISER)]);
deepest_dock_groove = max([DOCK_PANEL_DEPTH, max_tread_cut, DOCK_JOINT[1]]);
min_pedestal_wall = min((BASE_W - BASE_CAV[0])/2, (BASE_D - BASE_CAV[1])/2);
assert(min_pedestal_wall - deepest_dock_groove >= 3,
       "dock decoration depth eats into the pedestal wall's safety margin");

// Top-plate brickwork (Round 12, Directive 2): per-region plate thickness
// (surface z at that y, minus the cavity's own ceiling z=18) minus the
// groove depth cut there must leave >=2.5mm. Tread 0 (the thinnest region,
// RAMP_Z0 = BASE_H-PLATFORM_DROP = 22, thickness 4mm — matches the
// directive's own "front tread 0 is 4mm thick") is why the tread groove
// depth is capped to DOCK_TOP_GROOVE_SLOPE_DEPTH=1.0 rather than the full
// DOCK_JOINT[1]=2.0 the plateau uses.
tread0_z = BASE_H - PLATFORM_DROP;
assert(tread0_z - 18 - DOCK_TOP_GROOVE_SLOPE_DEPTH >= 2.5,
       "top-plate tread groove leaves less than 2.5mm plate thickness");
// Round 20 FIX E (reviewer): the old assert checked BASE_H (the flat
// plateau's own literal height) — but squaring the pedestal's corners
// (decision 22) removed that flat plateau; the deck is now continuously
// sloped, so the REAL thinnest point above the cavity ceiling is wherever
// the deck is LOWEST directly over the cavity, i.e. at the cavity's own
// FRONT edge (y=-BASE_CAV[1]/2, the deck's minimum-z point within the
// cavity's own y-footprint, since ramp_z() rises monotonically with y).
assert(ramp_z_check(-BASE_CAV[1]/2) - 18 - DOCK_JOINT[1] >= 2.5,
       "top-plate groove leaves less than 2.5mm plate thickness over the cavity");

// Top-plate brickwork REGION count-assert (Round 14 FIX B, reviewer
// DO-NOT-PRINT): the old uniform-pitch treatment (Round 13) produced 1
// course + 9 stubs once the lug/pillar/flank-foot/drop-slot exclusions
// were applied to the plateau's genuinely small free area — not machine-
// checked, so it shipped anyway. Machine-check it now: re-derive the SAME
// course/joint survivor-counting logic base_main.scad's
// top_region_courses()/top_brick() use (duplicated here since tests.scad
// only includes config.scad, matching this file's established pattern —
// e.g. rear_pillar_x() above), for the SAME 3 regions, and assert the
// readability floor each must clear: >=2 course lines + >=3 joints for the
// REAR strip and each SIDE apron; >=1 course (by design a single centred
// line, not a pitch-repeated one) + >=3 joints for each tread.
function overlaps2(lo, hi, zlo, zhi) = (hi > zlo && lo < zhi);
function clip_segment2(segs, excl_lo, excl_hi) =
    [for (s = segs) each (
        (excl_hi <= s[0] || excl_lo >= s[1]) ? [s] :
        (excl_lo <= s[0] && excl_hi >= s[1]) ? [] :
        (excl_lo <= s[0]) ? [[excl_hi, s[1]]] :
        (excl_hi >= s[1]) ? [[s[0], excl_lo]] :
        [[s[0], excl_lo], [excl_hi, s[1]]]
    )];
function clip_all2(segs, exclusions, i = 0) =
    (i >= len(exclusions)) ? segs : clip_all2(clip_segment2(segs, exclusions[i][0], exclusions[i][1]), exclusions, i + 1);
function list_sum(L, i = 0) = (i >= len(L)) ? 0 : L[i] + list_sum(L, i + 1);

function count_courses2(y_lo, y_hi, pitch) =
    len([for (y = [y_lo : pitch : y_hi]) if (y > y_lo + 0.5 && y < y_hi - 0.5) y]);

function joint_survivors_at(x, yb_lo, yb_hi, zones) =
    let(excl = [for (zn = zones) if (overlaps2(x - DOCK_JOINT[0]/2, x + DOCK_JOINT[0]/2, zn[0], zn[1])) [zn[2], zn[3]]])
    len([for (s = clip_all2([[yb_lo, yb_hi]], excl)) if (s[1] - s[0] > 2) 1]) > 0 ? 1 : 0;
function joints_in_band2(x_lo, x_hi, yb_lo, yb_hi, offset, pitch, zones) =
    let(n = ceil((x_hi - x_lo) / pitch) + 1)
    list_sum([for (k = [0 : n])
        let(x = x_lo + k * pitch + offset)
        (x > x_lo + 1 && x < x_hi - 1) ? joint_survivors_at(x, yb_lo, yb_hi, zones) : 0
    ]);
function count_joints2(x_lo, x_hi, y_lo, y_hi, course_pitch, joint_pitch, zones) =
    let(interior_ys = [for (y = [y_lo : course_pitch : y_hi]) if (y > y_lo + 0.5 && y < y_hi - 0.5) y])
    let(band_ys = concat([y_lo], interior_ys, [y_hi]))
    list_sum([for (b = [0 : len(band_ys) - 2])
        (band_ys[b+1] - band_ys[b] > 0.5) ?
            joints_in_band2(x_lo, x_hi, band_ys[b], band_ys[b+1], (b % 2 == 0) ? 0 : joint_pitch/2, joint_pitch, zones)
          : 0
    ]);

// same zones top_brick() builds, re-derived from config-level constants
rp_front_y = REAR_T + REAR_COVER_T + FIT;
rp_pillar_half = REAR_PILLAR[0]/2 + 1;
rp0x = -REAR_PILLAR_R * cos(REAR_PILLAR_ANG[0]);
rp1x = -REAR_PILLAR_R * cos(REAR_PILLAR_ANG[1]);
pillar_zones2 = [
    [rp0x - rp_pillar_half, rp0x + rp_pillar_half, rp_front_y, rp_front_y + REAR_PILLAR[1]],
    [rp1x - rp_pillar_half, rp1x + rp_pillar_half, rp_front_y, rp_front_y + REAR_PILLAR[1]],
];
flank_y_check = REAR_T / 2;
flank_foot_zones2 = [
    [flank_foot_x_check - FLANK[1]/2, flank_foot_x_check + FLANK[1]/2, flank_y_check - FLANK[2]/2, flank_y_check + FLANK[2]/2],
    [-(flank_foot_x_check + FLANK[1]/2), -(flank_foot_x_check - FLANK[1]/2), flank_y_check - FLANK[2]/2, flank_y_check + FLANK[2]/2],
];
// Round 19: lug footprint, re-derived the same way base_main.scad's
// top_brick() now does (lug_x()/CRADLE_LUG/LUG_ANCHOR_YHALF, all
// config/base_main single-sourced) — the SIDE strip below now reaches the
// lugs' own y-band (unlike the old flat "REAR strip", which started behind
// them at y=13), so it needs the same exclusion base_main.scad added after
// the first pipeline run flagged an overhang there.
// LUG_Y == flank_y_check (both REAR_T/2 in base_main.scad) — reused rather
// than re-declared, same duplication-avoidance this file's other re-derived
// values already follow.
lug_anchor_yhalf_check = (CRADLE_LUG[1] + 4) / 2;
lug_zones2 = [
    [lug_x(1) - (CRADLE_LUG[0]+4)/2 - 1, lug_x(1) + (CRADLE_LUG[0]+4)/2 + 1, flank_y_check - lug_anchor_yhalf_check - 1, flank_y_check + lug_anchor_yhalf_check + 1],
    [lug_x(-1) - (CRADLE_LUG[0]+4)/2 - 1, lug_x(-1) + (CRADLE_LUG[0]+4)/2 + 1, flank_y_check - lug_anchor_yhalf_check - 1, flank_y_check + lug_anchor_yhalf_check + 1],
];
drop_slot_zone2 = [-12, 12, -2, 16];

// Round 19 (decision 22): the OLD flat "REAR strip" (behind the lugs, flat
// z=BASE_H) no longer exists — squaring the pedestal's corners replaced it
// with a continuous sloped deck. Re-derives base_main.scad's new SIDE strip
// region (x [13,40], full deck depth RAMP_Y0..RAMP_Y1) — count_courses2()/
// count_joints2() don't care whether the underlying cut follows a flat or
// sloped surface (they only count SURVIVING x/y regions after exclusion
// clipping, identical either way — deck_courses() just remaps y to its own
// S=y-RAMP_Y0 internally before cutting, a coordinate shift that doesn't
// change which regions survive).
side_courses_n = count_courses2(HULL_FRONT_Y0, HULL_REAR_Y1, DOCK_TOP_COURSE);
side_joints_n  = count_joints2(13, 40, HULL_FRONT_Y0, HULL_REAR_Y1, DOCK_TOP_COURSE, DOCK_TOP_JOINT, concat(pillar_zones2, flank_foot_zones2, lug_zones2));
assert(side_courses_n >= 2, str("SIDE strip: only ", side_courses_n, " course line(s), need >=2"));
assert(side_joints_n >= 3, str("SIDE strip: only ", side_joints_n, " joint(s), need >=3"));

// Round 19: tread_y0_check/tread_y1_check/tread_run_check2 (matching
// base_main.scad's TREAD_Y0/TREAD_Y1/TREAD_RUN) already declared above,
// near max_tread_cut's own re-derivation — reused here rather than
// re-declared.
tread_zones2 = concat(pillar_zones2, flank_foot_zones2, [drop_slot_zone2]);
for (i = [0 : DOCK_RAMP_STEPS - 1]) {
    ty_lo = tread_y0_check + i * tread_run_check2;
    ty_hi = tread_y0_check + (i + 1) * tread_run_check2;
    tyc = (ty_lo + ty_hi) / 2;
    t_course_excl = [for (zn = tread_zones2) if (overlaps2(tyc - DOCK_JOINT[0]/2, tyc + DOCK_JOINT[0]/2, zn[2], zn[3])) [zn[0], zn[1]]];
    t_course_n = len([for (s = clip_all2([[-13, 13]], t_course_excl)) if (s[1] - s[0] > 2) 1]);
    t_n = floor(13 / DOCK_TREAD_JOINT);
    t_joints_n = list_sum([for (k = [-t_n : t_n])
        let(x = k * DOCK_TREAD_JOINT)
        (abs(x) < 12) ? joint_survivors_at(x, ty_lo + 0.3, ty_hi - 0.3, tread_zones2) : 0
    ]);
    assert(t_course_n >= 1, str("tread ", i, ": ", t_course_n, " course line(s), need >=1"));
    assert(t_joints_n >= 3, str("tread ", i, ": only ", t_joints_n, " joint(s), need >=3"));
}

// Taper-aware dock-wall assert (Round 12, Directive 2 — upgrades the flat
// min_pedestal_wall approximation above with the REAL wall position where
// front_courses()/rear_courses() actually cut). Round 14 FIX A: now reads
// straight from config.scad's single-sourced HULL_* values (was a second
// independently-typed copy of the taper formula using the OLD, wrong z=20/
// z=28 endpoints — exactly the kind of drift that buried grooves under a
// skin). At z=20, the front wall is now mid-taper (HULL_FRONT_Z1=22, not
// "done" the way the old z=20-endpoint assumption had it), so its real y
// position is -28.5 (interpolated), giving MORE wall margin (9.0mm) than
// the old formula's 8.0 — strictly safer, not just different.
front_wall_y20 = -HULL_BOT_YHALF + (HULL_FRONT_Y0 + HULL_BOT_YHALF) * (20 - HULL_BOT_ZS) / (HULL_FRONT_Z1 - HULL_BOT_ZS);
rear_wall_y20 = HULL_BOT_YHALF + (HULL_REAR_Y1 - HULL_BOT_YHALF) * (20 - HULL_BOT_ZS) / (HULL_REAR_Z1 - HULL_BOT_ZS);
wall_at_z20_front = abs(front_wall_y20) - BASE_CAV[1]/2;
wall_at_z20_rear  = abs(rear_wall_y20)  - BASE_CAV[1]/2;
assert(wall_at_z20_front - DOCK_JOINT[1] >= 3,
       "front wall thickness at z=20 (taper-aware) fails the dock-groove margin");
assert(wall_at_z20_rear - DOCK_JOINT[1] >= 3,
       "rear wall thickness at z=20 (taper-aware) fails the dock-groove margin");

// Round 20 FIX E (reviewer): taper-aware END-wall assert, alongside the
// front/rear ones above — didn't exist before (Round 19's end wall wasn't a
// simple fixed taper, so there was no equivalent single-plane formula to
// check against). Now that FIX A (decision 22 addendum) makes the end wall
// one flat plane (X0=HULL_BOT_XHALF at Z0=HULL_BOT_ZS to X1=HULL_TOP_XHALF
// at Z1=HULL_REAR_Z1, a FIXED lean, x independent of y — config.scad's own
// HULL_TOP_XHALF_FRONT comment), re-derive base_main.scad's END_PHI-based
// taper at z=18 (the cavity ceiling) the same way tests.scad re-derives
// every other base_main.scad formula it needs.
end_x_z18 = HULL_BOT_XHALF - (HULL_BOT_XHALF - HULL_TOP_XHALF) * (18 - HULL_BOT_ZS) / (HULL_REAR_Z1 - HULL_BOT_ZS);
wall_at_z18_end = end_x_z18 - BASE_CAV[0]/2;
assert(wall_at_z18_end - DOCK_JOINT[1] >= 3,
       "end wall thickness at z=18 (taper-aware) fails the dock-groove margin");

// Round 20 FIX E (reviewer): assert-by-construction that the end wall's 4
// defining corners (A,B = footprint's own two corners at HULL_BOT_ZS; C =
// the deck's WIDENED front corner, HULL_TOP_XHALF_FRONT; D = the deck's
// rear corner, HULL_TOP_XHALF) are genuinely COPLANAR — the scalar triple
// product (B-A)."(C-A)x(D-A) must be ~0. This is the actual geometric claim
// HULL_TOP_XHALF_FRONT's own formula makes (config.scad); machine-checking
// it directly (not just trusting the algebra) means a future edit to any of
// these HULL_* values that breaks planarity — reintroducing Round 19's
// buried-groove bug — fails HERE instead of only showing up as a mesh-
// probed defect down the line. Analogous in spirit to Round 14 FIX A's own
// "taper endpoint must be the strip's own TOP edge" assert-by-construction
// (deleted in Round 19 when the box-strip construction it guarded no longer
// existed) — this is Round 20's equivalent for the new plane construction.
ba_end = [0, 2 * HULL_BOT_YHALF, 0];
ca_end = [HULL_TOP_XHALF_FRONT - HULL_BOT_XHALF, HULL_FRONT_Y0 + HULL_BOT_YHALF, HULL_FRONT_Z1 - HULL_BOT_ZS];
da_end = [HULL_TOP_XHALF - HULL_BOT_XHALF, HULL_REAR_Y1 + HULL_BOT_YHALF, HULL_REAR_Z1 - HULL_BOT_ZS];
cross_cd_end = [ca_end[1]*da_end[2] - ca_end[2]*da_end[1],
                ca_end[2]*da_end[0] - ca_end[0]*da_end[2],
                ca_end[0]*da_end[1] - ca_end[1]*da_end[0]];
triple_end = ba_end[0]*cross_cd_end[0] + ba_end[1]*cross_cd_end[1] + ba_end[2]*cross_cd_end[2];
assert(abs(triple_end) < 1.0,
       "end-wall corners (A,B,C,D) are not coplanar - HULL_TOP_XHALF_FRONT formula drifted");

// Assert-by-construction (Round 14 FIX A, reviewer Critical) DELETED Round
// 19: it machine-checked that the wall taper's TRUE endpoint was always a
// strip's own TOP edge (HULL_*_Z1), never its bottom (HULL_*_ZC-HULL_*_ZS/2)
// — a real risk when the hull was built from 3 separate boxes with their
// own YC/YS/ZC/ZS fields. Squaring the pedestal's corners (config.scad's
// HULL_INSET comment) replaced that construction with a single thin deck
// plate defined directly by its own edges (HULL_FRONT_Y0/Z1, HULL_REAR_Y1/
// Z1) — there is no more "box" for a future edit to quietly derive a
// bottom-edge z from, so the failure mode this assert guarded against no
// longer exists. Replaced with a construction sanity pair instead: the
// deck must actually rise from front to rear (not zero-height or inverted)
// and HULL_INSET must leave a positive deck on both axes.
assert(HULL_FRONT_Z1 < HULL_REAR_Z1, "deck front edge must sit below its rear edge (PLATFORM_DROP > 0)");
assert(HULL_TOP_XHALF > 0 && HULL_TOP_YHALF > 0,
       "HULL_INSET too large — leaves no deck at all");

// (Task 6 Step 11b, Narcosia ruling 2026-08-13: the buttress-head/window-
// annulus check above is deleted along with the buttress heads themselves.
// The cradle-lug equivalent is the LUG_ANG assert near the top of this
// file; the rear pillars sit entirely behind the gate stack in world y
// (proven in base_main.scad's comments), so they share no y-range with the
// disc at all and cannot foul the window annulus by construction — no
// front-projection check needed for them.)

// decoration zones stay inside their lanes and off the frozen geometry
assert(BEZEL_RING[0] >= FRONT_OPEN_D/2 + 0.4, "bezel ring crowds the screen opening");
assert(BEZEL_RING[1] < WINDOW_R0 - 0.5, "bezel ring touches the window annulus");
assert(TRACK_RING[0] > WINDOW_R1 + 0.4, "track ring touches the window annulus");
assert(TRACK_RING[1] < GLYPH_BAND[0] - 0.4, "track ring runs into the glyph band");
assert(GLYPH_BAND[1] < OUTER_RING[0] - 0.5, "glyph band runs under the outer ring");
assert(OUTER_RING[1] <= GATE_OD/2, "outer ring past the gate rim");
assert(BEZEL_RING[2] <= RELIEF_MAX && TRACK_RING[2] <= RELIEF_MAX
       && OUTER_RING[2] <= RELIEF_MAX, "relief taller than RELIEF_MAX");
// chevron pins clear the frozen screw counterbores (nearest screw is 5 deg off)
assert(min([for (r = CHEV_PIN_R) r * sin(5)]) > CHEV_PIN_D/2 + 4.5/2 + 0.5,
       "chevron pin fouls a screw counterbore");
assert(0.15 * GLYPH_CELL[1] >= 0.6, "glyph strokes below the 0.6 mm print floor");
assert(GLYPH_INK_T < GLYPH_DEPTH, "glyph AMS ink floor must sit strictly inside the engraving depth");
assert(CHEV_PIN_R[1] + CHEV_PIN_D/2 + 0.4 < CHEV_R0 + 9.4,
       "outer pin hole breaks through the chevron pad edge");

// ------------------------------------------ gate-stack registration (Round 16/17) ---
// Recessed groove (gate_rear back face) / proud lip (rear_cover rim edge),
// plus one off-grid front filament pin. Machine-check the geometry every
// module reads from config.scad's REG_* constants (rear_cover.scad's own
// wall_r_in/lip_id/lip_od/lip_h/chamfer formulas duplicated here, matching
// this file's established pattern of re-deriving simple values rather than
// including the part files themselves).
reg_groove_id = REG_R - REG_W/2;
reg_groove_od = REG_R + REG_W/2;
assert(GATE_OD/2 - reg_groove_od >= 1.0,
       "registration groove leaves less than 1mm of gate_rear's outer rim wall");
// Round 17 FIX 5 (reviewer DO-NOT-PRINT): the OLD outer-wall assert above
// only checked clearance to the true OD — it stayed green even when the
// groove's OD (53.8, at the old REG_R=53.0) left just 0.4mm to the axial
// rim-groove floor (GATE_OD/2-SEG_GROOVE[1]=54.2) at all 33 surviving
// ticks, because that floor sits INSIDE the OD, not at it. Assert the real
// binding constraint directly.
assert(GATE_OD/2 - SEG_GROOVE[1] - reg_groove_od >= 1.0,
       "registration groove leaves less than 1mm to the axial rim-groove floor - ticks would open into the groove");
reg_wall_r_in  = GATE_OD/2 - REAR_COVER_WALL;                    // 53.2
reg_lip_id     = REG_R - REG_W/2 + REG_LIP_CLR[1];               // 52.0: non-locating, generous
reg_lip_od     = REG_R + REG_W/2 - REG_LIP_CLR[0];               // 53.0: locates, tighter
reg_lip_h      = REG_D - 0.3;                                    // 1.3
reg_shoulder_run = reg_wall_r_in - reg_lip_id;                   // 1.2: the internal 45-deg shoulder's run
assert(reg_wall_r_in > reg_lip_id,
       "registration shoulder's inner target is already outboard of the cover wall - shoulder not needed, formula assumption broken");
// Round 18 FIX A (reviewer DO-NOT-PRINT blocker): the Round-17 lip design
// (a taper that flared ABOVE the rim edge to reach a weld foot) is GONE —
// replaced by an internal 45-deg SHOULDER carved into the wall's own hollow
// cut, entirely at z <= REAR_COVER_T, topped by a PLAIN vertical lip with
// nothing above the rim edge outside its own OD. These asserts machine-
// check that "nothing above z0 outside the groove's own OD" claim directly,
// re-deriving rear_cover.scad's reg_lip()/reg_shoulder_cut() formulas
// independently from config.scad constants only (this file's established
// duplication pattern) so a future edit can't silently reintroduce the
// Round-17 shape.
assert(reg_lip_od <= reg_groove_od - REG_LIP_CLR[0],
       "registration lip OD exceeds the groove OD minus its own outer clearance - nothing may sit proud outside the groove's own footprint");
assert(reg_lip_od <= reg_wall_r_in,
       "registration lip OD exceeds the cover wall's own inner face - the lip would not land fully on the shoulder");
assert(reg_shoulder_run <= REAR_COVER_T - REAR_COVER_WALL,
       "registration shoulder reaches below the wall's own floor-to-rim height - it would dig into or past the floor");
// FIX 2(a): radial clearance is asymmetric on purpose (locate on the OD,
// generous/non-locating on the ID) - both directions must actually open a
// real gap, not close one
assert(REG_LIP_CLR[0] > 0 && REG_LIP_CLR[1] > 0,
       "registration lip clearance must be a real positive gap on both faces");
assert(reg_lip_od < reg_groove_od && reg_lip_id > reg_groove_id,
       "registration lip does not sit strictly inside the groove band");
// FIX 2(b): the lip's own skip arc must be WIDER than the groove's (i.e.
// the lip's angular presence is SHORTER), so its flat end-caps stop short
// of the groove's own end walls instead of binding against them
assert(REG_LIP_SKIP_LO < REG_SKIP_LO && REG_LIP_SKIP_HI > REG_SKIP_HI,
       "registration lip skip arc is not wider than the groove's - the lip would bind at the arc ends");
// lip/groove band stays well clear of the cover's own M2 hole sets (task
// calls this "trivial" — checked anyway, this project's asserts are cheap
// and the whole point is nothing gets to rely on eyeballing)
assert(reg_groove_id > REAR_COVER_HOLE_R + REAR_COVER_CSK_D/2,
       "registration groove/lip crowds the rear-cover M2 holes");
// rear-pillar holes cut into gate_rear's back face are M2_INSERT (heat-set,
// 3.2mm) at that location, not M2_CLEAR (2.4mm, only used for rear_cover's
// own pass-through) - matches the actual gate_rear.scad geometry
assert(reg_groove_id > REAR_PILLAR_R + M2_INSERT/2,
       "registration groove/lip crowds the rear-pillar insert holes");
assert(REG_SKIP_LO > 0 && REG_SKIP_HI < 360 && REG_SKIP_LO < REG_SKIP_HI,
       "registration skip arc out of the sane 0-360 range");
assert(REG_LIP_SKIP_LO > 0 && REG_LIP_SKIP_HI < 360,
       "registration lip skip arc out of the sane 0-360 range");
// missing assert flagged in review: rear_cover's outer wall must survive
// both the axial rim grooves AND the circumferential groove at the same
// depth (SEG_GROOVE[1]) - same margin gate_rear's own (much thicker) rim
// never needed to check, but this 1.8mm wall does
assert(REAR_COVER_WALL - SEG_GROOVE[1] >= 0.9,
       "rear_cover's outer wall leaves less than 0.9mm beyond the rim-groove depth");
// the skip arc must actually cover the tunnel's real angular footprint at
// the groove's worst-case (inner) radius, plus the stated 2 deg margin —
// true by construction (REG_SKIP_HALF IS that formula) but asserted here
// too so a future hand-edit of REG_SKIP_LO/HI back to a literal can't
// silently undershoot it again
assert(REG_SKIP_HI - REG_SKIP_LO >= 2 * (REG_TUNNEL_HALFANG + 2) - 0.01,
       "registration skip arc undershoots the USB tunnel's angular footprint + margin");
// front registration pin: off the SEG_N grid (so it never lands exactly on
// a rim-groove tick) and clear of the front-plate M2 inserts (r=GATE_OD/2-6
// @ 45/135/225/315) with real edge-to-edge margin, not just an angular one
assert(len([for (k = [0 : SEG_N - 1]) if (abs(REG_PIN_ANG_REAR - k*360/SEG_N) < 0.01) k]) == 0,
       "front registration pin sits exactly on a rim-groove tick");
assert(len([for (a = [45, 135, 225, 315]) if (abs(REG_PIN_ANG_REAR - a) < 0.01) a]) == 0,
       "front registration pin sits exactly on a front-plate screw angle");
reg_pin_insert_min_gap = min([for (a = [45, 135, 225, 315])
    sqrt(pow(REG_PIN_R*cos(REG_PIN_ANG_REAR) - (GATE_OD/2-6)*cos(a), 2)
       + pow(REG_PIN_R*sin(REG_PIN_ANG_REAR) - (GATE_OD/2-6)*sin(a), 2))]);
assert(reg_pin_insert_min_gap > REG_PIN_D/2 + M2_INSERT/2 + 1.5,
       "front registration pin crowds a front-plate M2 insert");
assert(REG_PIN_R + REG_PIN_D/2 < GATE_OD/2 - 1,
       "front registration pin reaches the gate rim");
assert(REG_PIN_ANG_FRONT == 180 - REG_PIN_ANG_REAR,
       "front pin angle drifted from its derived gate_front-local value");

// rear-cover screw guide bosses (decision 26, 2026-08-21): the boss tip
// must stop short of the rim plane — if it reaches it, the bosses become
// the cover's contact surface and the couponD-proven rim/lip seat is lost.
assert(RC_BOSS_H < REAR_COVER_T - REAR_COVER_WALL,
       "rear-cover guide boss reaches gate_rear's back face - seating would go boss-defined");
assert(RC_BOSS_CLR >= 0.2, "rear-cover guide boss tip clearance below print tolerance");
// boss base collar clear of the cover's own wall (r 40 + 4.5 vs wall inner 53.2)
assert(REAR_COVER_HOLE_R + RC_BOSS_BASE_D/2 < GATE_OD/2 - REAR_COVER_WALL - 0.5,
       "rear-cover guide boss base collides with the cover wall");
// the pillar pass-throughs now carry their OWN bosses (2026-08-21
// follow-on) — so the check is collar-vs-collar between the two boss sets
// (nearest pair 225 vs 245 deg at r 40/45, real Cartesian centre distance):
// collars must not merge into one blob
rc_boss_pillar_gap = min([for (a = REAR_PILLAR_ANG) for (b = REAR_COVER_HOLE_ANGLES)
    sqrt(pow(REAR_PILLAR_R*cos(a) - REAR_COVER_HOLE_R*cos(b), 2)
       + pow(REAR_PILLAR_R*sin(a) - REAR_COVER_HOLE_R*sin(b), 2))]);
assert(rc_boss_pillar_gap > RC_BOSS_BASE_D + 0.5,
       "adjacent rear-cover guide boss collars merge");
// pillar bosses clear the cover wall and the registration groove region on
// gate_rear's back face (collar outer r 49.5 vs wall inner 53.2 / groove ID 51.6)
assert(REAR_PILLAR_R + RC_BOSS_BASE_D/2 < GATE_OD/2 - REAR_COVER_WALL - 0.5,
       "pillar guide boss base collides with the cover wall");
assert(REAR_PILLAR_R + RC_BOSS_D/2 < REG_R - REG_W/2 - 1,
       "pillar guide boss tip reaches the registration groove region");

provisional_report();
echo("TESTS_COMPLETE");
