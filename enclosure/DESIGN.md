# Enclosure design spec

**Status: WHOLE BUILD PRINTED, ASSEMBLED AND RUNNING (2026-08-20) — ring live on the LAN, puck screen showing session state (photos: `../docs/img/build-*.jpg`, writeup: `../docs/index.html`). Field findings from the first assembly became decisions 23–27; those parts were reprinted and the build runs on them.** Dimensions live in `MEASUREMENTS.md`; both feed `config.scad`, the single source of truth.

Requirements came from a private design brief; every ruling that mattered is
in the decision ledger below. The look was inspired by a 220 mm Stargate lamp
model (reference only: no geometry from it is used, everything here is
parametric). Screen dimensions come from Waveshare's official drawing on the
[Waveshare wiki](https://www.waveshare.com/wiki/ESP32-S3-Touch-AMOLED-1.75); it is not redistributed here.

## The concept

A miniature Stargate standing on an SGC-style dock. The **Waveshare
ESP32-S3-Touch-AMOLED-1.75-B** (Ø51 round touchscreen) is the gate's centre,
the **72 mm LED status ring** is the gate's illuminated inner track behind 24
individual windows, and the gate floats above the base so the full 360° of
LEDs stays visible — including 6 o'clock. Layered front, centre out: screen →
inner bezel → LED window track over a continuous diffuser → glyph track →
outer mechanical ring → nine chevrons.

## Decisions

| # | Decision | Choice | Why | Date |
|---|---|---|---|---|
| 1 | Theme | Stargate | Narcosia's call; a glowing ring wants to be a gate | 2026-08-12 |
| 2 | Placement | Desktop — upright gate on an SGC-style dock | peripheral vision; base houses wiring | 2026-08-12 |
| 3 | Brain | The round touchscreen replaces the Keyestudio WROOM for this build; ring plugs into its rear 8-pin headers | screen becomes the gate centre; one device | 2026-08-12 |
| 4 | Requirements | Narcosia's dimensioned brief adopted wholesale | complete and self-consistent | 2026-08-12 |
| 5 | Diffuser | Continuous translucent PETG ring under the front face, frosted | brief preference; decouples front style from diffusion | 2026-08-12 |
| 6 | Workflow | Parametric OpenSCAD + coupon-first verification (edelkrone workflow) | proven; brief demands the same staging | 2026-08-12 |
| 7 | Screen identified | Waveshare ESP32-S3-Touch-AMOLED-1.75-B (SKU 31262); official DWG/PDF from the Waveshare wiki | Ø51.00 × 12.10 confirmed against Narcosia's calipers | 2026-08-12 |
| 8 | Puck clocking | Cased screen rotated so USB-C points at 6 o'clock | screen image rotates in software; cable drops invisibly into the base | 2026-08-12 |
| 9 | Decoration method | Fully parametric from scratch; donor STLs and renders are visual reference only | detail designed at 110 mm print scale, guaranteed printable, no licence question | 2026-08-12 |
| 10 | Front style | 24 individual LED windows, aligned 1:1 with the LEDs | each LED wholly owns a window; pulses read as gate-track segments; open-ring fallback is only a front-face reprint | 2026-08-12 |
| 11 | Rear spine | Yes — hidden spine from base to gate rear | stiffest against touchscreen pokes; conduit for LED + USB cables | 2026-08-12 |
| 12 | Base extras | None — no power switch, no reset button | USB is the switch; a hidden slot covers the puck's own buttons | 2026-08-12 |
| 13 | Screen retention | Crush ribs on the pocket floor; `screen_retainer` part deleted | the floored pocket + rear retainer contradicted each other (bosses landed on the LED pocket wall; floor left the plate nothing to press); bezel↔floor already captures the puck, ribs kill the 0.7 mm rattle | 2026-08-12 |
| 14 | Chevron mount | Surface-mounted on the outer ring, 2× Ø2 filament pins each, no seat recess | a recess would collide with the two screws sitting 5° off chevron centrelines; the body bridges over and hides them | 2026-08-12 |
| 15 | Rear spine deleted | Removed (superseded decision 11) — no tower, no internal duct | vestigial: USB routes through the base's straight-through drop slot, leads never reach the base; a new `rear_cover` dish now covers the wiring instead, unscrewable for service | 2026-08-13 |
| 16 | Direct rear-port cable path | Removed (superseded decision 8's panel-socket half) — a plain through-hole in the pedestal's rear wall (`base_main`'s USB_PORT cut) replaces the blind panel-mount USB-C socket recess; cable crosses the cavity and rises through the existing platform drop slot into the gate's 6 o'clock tunnel | the panel-socket recess was dead weight once the platform drop slot already carried the cable the rest of the way — one fewer part (`usb_retainer` cut, part count 8→7), no flange/screw-spacing dependency on a part not yet in hand | 2026-08-13 |
| 17 | Low cradle + rear pillars replace buttresses/tabs/sockets | Removed (supersedes the buttress/tab-socket half of decisions 2/11) — `buttress()`, `tab_socket()`, `tab_m2_bore()`, the gate drop-sweep relief, and gate_rear's two mounting tabs all deleted; `gate_rear`'s outer rim is now a clean, unbroken cylinder. Replaced by two low `CRADLE_LUG` saddles rising from the platform's flat rear plateau (cradle the outer ring at ±30° off bottom, concave-cut to the ring's own radius) plus two `REAR_PILLAR` posts rising from behind, each carrying an M2 screw straight through `rear_cover` into a new insert in `gate_rear`'s back face | Step 11 (decision-row-adjacent, raising `GATE_GAP`) dragged the tab-anchored buttresses up to the ring's mid-height, crowding the 4/8 o'clock chevrons — worse than the crowding it fixed. Narcosia's ruling: keep the front reading clean (ring floating over the sloped platform) and carry the gate from below-and-behind instead. The brief's hard requirement "screw assembly, no glue; gate removable from base" is now satisfied by 2× M2 driven straight in from behind (shear, no side-driving) rather than through a buttress underside | 2026-08-13 |
| 18 | Cover bezel reverted; short-wide-buttress flanks; GATE_GAP 8 | `COVER_LIP` (the Task 6 Step 10 locating bezel) removed entirely — `rear_cover` reverts to held by 4 screws + 2 pillar screws only, no self-centring. Added two `FLANK` masses — short, wide-footed, capped well below the window annulus, hard-cut clear of the ring by a coaxial Ø(GATE_OD+4) relief — bracketing the ring's lowest arc; cosmetic/stability only, the cradle lugs remain the ring's sole seat and the rear pillars remain the sole retention. `GATE_GAP` 12→8 (`GATE_CZ` 97→93) | gate_rear prints face-down (back on top) — the 1.5mm-proud `COVER_LIP` ring on that top-facing back surface is a support-requiring overhang, not worth it for a self-centring convenience the screws already cover. Narcosia reviewed the step11b renders and wanted a middle ground between the bare cradle-lug look and the original chunky buttresses — the flanks restore an SGC-dock silhouette without reintroducing any load path; and the ring sitting closer to the platform (8 vs 12mm) reads better than the wider float | 2026-08-13 |
| 19 | Decoration pass: gate-rim brick grooves + SGC dock styling | `gate_rear`'s outer Ø110 rim gets 36 axial grooves (`RIM_GROOVES`, `SEG_N`/`SEG_GROOVE`, phase-matched to `gate_front`'s own face grooves so the brick pattern wraps continuously face→rim) plus one circumferential groove at mid-depth, skipping the USB tunnel mouth (260/270/280°). `base_main`'s pedestal gets a `DOCK_*` relief/engraving pass, all scoped so the flank-relief-cut lesson (Step 11d) can't repeat: 3 stepped terrace courses cut into each flank's OUTER skin only (`DOCK_STEP`, scoped inside `flank()`'s own `difference()`, x beyond lug_x+9); 3 ramp-tread grooves across the sloped front stopping at x=±13 (`DOCK_RAMP_STEPS`/`DOCK_TREAD`, re-spaced off the naive full-ramp spread after a numeric check found treads #1/#3 within 0.3mm of the panel border — close enough to physically fuse); recessed 2×1 panel-line grids on the front/back faces and 1×1 outlines on each end (`DOCK_PANEL`/`DOCK_INSET`); a `DOCK_BLOCK`-pitch stone-block grid on the rear face, explicitly clipped around the cable-port keepout | Narcosia approved Step 11's massing with one note: the flank-foot/lug/platform intersections read as *accidental* overlapping edges. This pass makes those joins read as deliberate coursing — relief/engraving only (0.6–1.2mm), no load path, seat, clearance, cavity, or hole touched; every existing gate (manifold/shells/interference/asserts) stayed green through the whole pass, plus one new assert (`min_pedestal_wall - deepest_dock_groove >= 3`) | 2026-08-17 |
| 20 | Gate-stack registration: recessed groove/proud lip + one front pin; rim brickwork extended to gate_front and rear_cover | `gate_rear`'s back face gets a RECESSED locating groove (`REG_R`/`REG_W`/`REG_D`) instead of a raised bezel; `rear_cover`'s open rim edge grows a matching proud LIP that seats into it. Both skip the same arc over the USB tunnel (`REG_SKIP_LO`/`REG_SKIP_HI`, derived from the tunnel's real angular footprint + 2° margin, not hand-picked) — proven algebraically to land on the SAME world angle under `rear_cover`'s placement flip, not just "a" gap. Rotational lock: the existing screw patterns already do the job (front-plate 45/135/225/315 is 4-fold symmetric and does NOT lock rotation on its own, so ONE off-grid Ø2 filament pin (`REG_PIN_*`) is added between gate_rear's front face and gate_front's rear face; `rear_cover`'s own 4-hole set is already asymmetric under rotation, so it needs no extra pin). Separately: `gate_front`'s own cylindrical rim and `rear_cover`'s outer wall both now carry the SAME 36-groove `SEG_N`/`SEG_GROOVE` brickwork as `gate_rear`'s rim, generated from ONE shared `rim_grooves()` module in `decor.scad` so the three parts' grooves can't drift out of phase — the 26mm assembled stack reads as one continuous grooved drum. **Exact lip cross-section geometry superseded twice more — see decision 21.** | Narcosia's two asks: (1) the stack should read as one continuous drum, not three visually-disconnected rims; (2) cover↔rear needed real centring, not just the 4+2 screws (which were doing double duty as both retention and de-facto alignment). `COVER_LIP`'s Step 10 attempt failed because it stood proud on gate_rear's face-down back face (an overhang); this reverses which part carries the proud feature (rear_cover, whose rim edge is the printable TOP of its own print) and which carries the recess (gate_rear, whose back-face constraint is unchanged) | 2026-08-17 |
| 21 | Registration lip redesigned twice more (review rounds 17/18): moved inboard, chamfer bug fixed, then supported from BELOW on an internal shoulder; seating boolean gate added; overhang tool fixed; chevron pin moved | Round 17 review found: (a) the lip's chamfer height formula was backwards (`zc=z1-chamfer` instead of `z0+chamfer`), producing a 69.6° unsupported face instead of 45° — fixed; (b) `REG_R`=53.0 left only 0.4mm between the groove OD and the axial rim-groove tick floor at all 33 ticks — moved to `REG_R`=52.4/`REG_D`=1.6, restoring 1.0mm, with a new assert reading that exact relationship; (c) lip/groove radial clearance loosened + made asymmetric (`REG_LIP_CLR=[0.2,0.4]`, outer/inner) and the lip's own skip arc widened 1.5°/side past the groove's (`REG_LIP_SKIP_LO/HI`) so the lip's flat end-caps don't bind. Round 18 review then found the Round-17 fix itself introduced a NEW blocker: the lip's outer face flared ABOVE the rim edge to reach a weld foot, landing solid lip material at r 53.2–53.5 exactly where gate_rear's back face is solid (the very "post" (b) had just protected) — 37.2mm³ collision, cover sitting 0.86mm proud, unable to seat. **Redesigned entirely**: `reg_shoulder_cut()` — an internal 45° chamfer carved OUT of the hollow cut itself (a nested `difference()`, not a union, so there's no coincident-face weld risk), living entirely at z ≤ `REAR_COVER_T` so it can never reach gate_rear regardless of angle; `reg_lip()` — now a PLAIN vertical annulus with nothing tapered and nothing above the rim edge outside its own OD, sitting fully on the shoulder's flat top. `tools/seating_check.py` (new, wired into `render.ps1`) makes manifold-boolean seating a real pipeline gate — rear_cover/gate_front (each placed exactly per `assembly.scad`) against gate_rear, both must be 0.000mm³ — instead of relying on a reviewer's by-hand check. `tools/overhang_check.py` corrected: candidate threshold was -0.5 (30° from vertical, too strict) → -0.7071 (the real FDM 45° self-support rule); a downward group spanning >90° of angle about the part's Z axis (a revolved taper, not a flat ledge) now measures "reach" as radial extent, not XY-bbox short side, which otherwise balloons toward the full part diameter for any feature wrapping most of a circle regardless of how thin it actually is. `CHEV_PIN_R` outer moved 53.4→53.0: at 53.4 the Ø2 pin hole reached r=54.4, past the axial rim-groove tick floor (54.2) at all 9 chevron angles (all on the 10° tick grid) — a hidden slot into the tick; at 53.0 it reaches 54.0, clear | The seating collision was invisible to every existing gate (manifold/shells/`interference_check.py` — which checks base_main vs. the WHOLE assembled stack, not parts WITHIN the stack against each other) — found only because a reviewer ran a by-hand boolean. `tools/seating_check.py` makes that check permanent and automatic. The overhang-tool blind spot (angle-blind reach heuristic flagging a correctly-executed 45° taper identically to a real cantilever) was found auditing the tool against this same lip fix, and is now provably fixed against both a synthetic 45°-vs-30° control pair and the real parts | 2026-08-17/18 |
| 22 | Pedestal squared to a four-sided planar taper; running-bond courses wrap the corners in a proper stagger; flank-top coursing folded into one system | Replaced the old 3-box hull (bottom slab + separate rear/front top strips, sharing one x-width but DIFFERENT y-ranges) with `hull()` of the SAME 135×75 footprint slab against ONE sloped top deck (front edge at `BASE_H-PLATFORM_DROP`, rear edge at `BASE_H`), inset driven by `HULL_INSET=12`. **Round 19's first attempt modelled the END walls as a smooth per-y "ruled twist" (`end_phi_local()`) — reviewer mesh-probing (review-r19-planarity.py) found the real hull() output does NOT twist smoothly: it triangulates into TWO FLAT FACETS meeting at a real diagonal crease (11.4° dihedral), so grooves cut against the fitted-but-nonexistent smooth surface were buried under a 0.07-0.63mm skin over roughly half their length.** Round 20 fixed this AT THE SOURCE: `HULL_TOP_XHALF_FRONT` (config.scad) widens the deck's FRONT edge in x so all 4 end-wall corners land exactly on one plane (a coplanarity machine-checked in tests.scad via the scalar triple product, not just derived) — the end wall is now genuinely ONE flat plane, a fixed lean (`END_PHI`, x independent of y), same construction as before Round 19 but this time provably correct. Running-bond joints on the end walls are DERIVED from the front face's own last surviving joint before the corner (+1 pitch), instead of a fixed-offset exclusion that once left a ~1.5mm phantom-joint sliver at the corner; the rear corner is left to float rather than independently re-phased. Course-line cuts on all four faces extend ≥2mm past their own true corner (`front_wall_y()`/`rear_wall_y()` give the real, z-dependent corner position) so adjacent faces' cuts overlap and meet cleanly. `rear_courses()` now excludes the rear pillars' own footprint (they read as plain buttresses, not decorated). Cradle lugs, rear pillars, the flank foot, and the top-plate brickwork (`deck_courses()`, replacing the old flat "REAR strip") all re-seat against the continuously-sloped deck via `pedestal_top_z()`/`ramp_z()`; the tread staircase's own span is deliberately SHORTER than the full deck (`TREAD_Y1=-4`) to avoid the USB drop-slot swallowing a tread's whole course line. Separately (task B): each flank's TOP is now ONE groove system (folded — Round 19 had briefly stacked a separate cap-crossing system on top of the existing side-coursing notches, reading as a crossed grille) — `DOCK_FLANK_TOP=[1.5,1.5,6]` cut as a true surface-NORMAL depth (not the world-axis convention the wall cuts use, which under-delivered ~1.0mm on this ~42° face), with short staggered running-bond joints replacing a deleted lengthwise spine; `flank_panel_pos()` (a recessed plaque that overlapped this same coursing) deleted. Verified via `mesh.contains()`/ray probes (review-r19-*.py) plus the standard manifold/overhang/interference/seating gates, all green. | Narcosia's screenshot showed the running-bond courses cutting off mid-brick at each front pedestal corner — the old hull's vertical end walls meeting the tapered front/rear faces at a diagonal chamfer facet. A true four-sided taper removes that facet. Round 19's own fix, while visually clean and gate-passing, turned out to model a surface that doesn't physically exist on the real mesh (a reviewer with independent mesh-probing tools caught it); Round 20 re-derives the SAME goal from the actual convex-hull geometry instead of an assumed smooth model | 2026-08-18 |
| 23 | Chevron at bottom-dead-centre | Chevron pattern rotated 180°: all four chevron loops (`gate_front.scad` pin holes, `assembly.scad`, `exploded_view.scad`, `insert_map.scad`) now use `270 + k*40`, so the pinned clocking puts one chevron exactly at 6 o'clock on the dock's centreline and centres the top gap at 12. Registration pin unchanged (95°/85°) | Narcosia assembled the first build with the front deliberately clocked chevron-down and ruled it the design: align the bottom chevron to the bottom of the base. The drawn one-at-12 layout would have fought the pin; rotating the pattern makes chevron-at-BDC the registered orientation | 2026-08-20 |
| 24 | USB tunnel widened +3 mm/side | `USB_W` 16 → 22 (tunnel cut = 24 wide). `RIM_GROOVE_SKIP` unchanged (mouth half-angle at r 55 = 12.6°, still only the 260/270/280 ticks); REG skip arcs derive from `USB_W` automatically; the lug-vs-tunnel assert passes with margin (18.5 > 13) | On the assembled build the puck's port doesn't sit perfectly vertical, so the plug bound in the 16 mm tunnel with no room to trim the screen's clocking a few degrees | 2026-08-20 |
| 25 | Rear-cover screws moved off the pillars | `REAR_COVER_HOLE_ANGLES` [30, 150, 250, 290] → [30, 150, 225, 315] — the long-deleted tab angles. Flip symmetry (180−225 = 315) and rotational asymmetry (gap pattern 120/75/90/75) both preserved, so the placement math and one-way fit are untouched; gate_rear's matching inserts move with the shared constant | The printed pillars (245/295° ± 7.6°) landed ON the 250/290° countersunk heads — only ~2.4° of clearance on paper, none in the flesh (photos in `../docs/img/`). 225/315 clears by 9.2° ≈ 6.4 mm at r 40 | 2026-08-20 |
| 26 | Rear-cover screw guide bosses | SIX Ø6 tubes (Ø9 45° base collars) stand on the cover floor's inside face — the four `REAR_COVER_HOLE_ANGLES` positions AND the two `REAR_PILLAR_ANG`/`REAR_PILLAR_R` pass-throughs (2026-08-21 follow-on: the pillar M2×20s are the gate's only retention, and their clamp path ran pillar → 1.8 mm floor → 4.2 mm of air, so snugging them bowed the floor) — continuing each M2 bore across the dish's 4.2 mm open interior; tip stops `RC_BOSS_CLR` = 0.3 short of gate_rear's back face so seating stays rim/lip-defined (new tests.scad asserts, mutation-tested; seating_check.py proves 0 mm³ on the mesh) | Guidance + clamp stiffness: the screw otherwise crosses the cavity blind before finding the hidden insert, and the countersunk head bears on the bare 1.8 mm floor membrane — with the boss the clamped column is 5.7 mm and the bore is captive for the whole crossing. Zero support cost (printed floor-down, collar widens downward) | 2026-08-21 |
| 27 | Pedestal styling pass (slicer review of the v2 STL) | (a) `plinth()` DELETED — the flared 138×78 base course read as a lip; the wall now runs straight to the bed at the plain footprint (`DOCK_PLINTH` left as an orphaned PROVISIONAL constant). (b) Deck side strips extended from x ±40 to the side arris + 2 mm past it (`HULL_TOP_XHALF_FRONT + 2`): course lines notch through the arris and meet the end walls' own coursing — the walls' "cuts extend past their own corner" convention applied vertically; JOINT lines stay capped 0.5 inside the rear half-width (`deck_courses()` grew `jx_lo`/`jx_hi` params) because a y-running joint outboard of the arris would gouge a lengthwise trench along the wall top. (c) Flank FRONT/REAR faces get the same band-and-staggered-joint coursing as the cap (`flank_face_courses_pos()`) — each face is a planar trapezoid (both bounding edges run parallel to X), bands at the same fractional heights as the cap so the pattern wraps cap → arris → face; cuts overshoot 2 mm past shared edges and are scoped inside `flank()`'s own difference per the Step-11d rule. Inboard face left plain (it is relief-carved by the Ø114 cylinder). First pipeline run FAILED the overhang gate (worst reach 2.84): the joint rephasing landed a y-running deck joint at x≈31.5, under the flank hull's inboard lean (which overhangs the deck ~1.5 mm just above the foot's embed) — its groove ceiling became a shelf. Fixed by growing `flank_foot_zones`' INBOARD margin 0 → 4 to cover the lean's shadow; second run ALL CHECKS PASSED | Narcosia, 2026-08-21, from the slicer: remove the bottom lip; take the top brickwork to the side of the top and around, linking up with the wall brickwork; bring the flank brickwork right around | 2026-08-21 |

## Hard requirements (from the brief)

- LED ring visible for the complete 360° — base, supports, chevrons must not
  interrupt it. Gate floats 4–5 mm above the platform.
- Raw LED PCB hidden behind the continuous diffuser.
- Screen removable, retained on the case body — nothing bears on glass.
- Rear 8-pin headers accessible internally; open cavity, not a tight shroud.
- USB-C usable via internal extension → recessed female panel socket in the
  base rear wall.
- ~15 mm LED cable section routes rearward immediately, never visible.
- Screw assembly (M2 + heat-set inserts), no glue; gate removable from base.
- Chevrons separate prints (×9, red).
- Base is a Stargate dock: trapezoidal pedestal, buttresses, front steps below
  the ring, internal cable cavity, removable bottom cover, feet recesses.
- Practical FDM: 0.4 mm nozzle, glyph depth 0.5–0.8 mm, lines ≥ 0.6 mm.

## Part architecture (7 printable parts)

| Part | Role |
|---|---|
| `gate_front` | decorative face: retaining bezel, 24-window LED track, glyph track, outer mechanical ring, 9 chevron seats; v2: face-up print orientation, layered relief + engraved glyph band. Cylindrical rim (full `FRONT_T` height) carries the shared 36-groove rim brickwork (decision 20); rear (mating) face carries one off-grid registration pin hole |
| `gate_rear` | structural shell: screen pocket with crush ribs + button wall reliefs, LED PCB pocket, header cavity, cable channels, M2 heat-set bosses, rear_cover mounting holes, rear-pillar mounting holes (Task 6 Step 11b, decision 17). Outer rim is a clean, unbroken cylinder segmented with 36 axial brick grooves + one circumferential groove (decision 19), phase-matched to gate_front's own rim grooves and rear_cover's — no mounting tabs (deleted, decision 17). USB tunnel at 6 o'clock is the only rim-piercing cut (Task 6 Step 9). Back face carries the RECESSED rear-cover registration groove (decision 20, gapped over the USB tunnel arc) and the front face carries one off-grid registration pin (decision 20) |
| `diffuser` | continuous translucent PETG ring, OD ~73 / ID ~59.5 / ~1.0 mm, frosted 400–600 grit |
| `chevron` ×9 | separate red prints, pin-on (decision 14) |
| `rear_cover` | plain closed dish enclosing gate_rear's back (wire zone, header/connector cavities); 4× M2 countersunk; supersedes the deleted rear spine (decision 15). No rim notches (Task 6 Step 9 — the tabs live entirely inside gate_rear's own thickness, never reaching the cover). Held by 4 screws + 2 pillar screws, each cover screw guided by an internal Ø6 boss continuing the bore across the dish interior (decision 26); centred/registered (not retained) by a plain vertical LIP on its open rim edge, supported by an internal 45° shoulder carved into the wall's own hollow cut (nothing proud outside the lip's own OD, nothing above the rim edge beyond it — decision 21), seating into gate_rear's recessed groove (decision 20, supersedes the reverted Step 10 `COVER_LIP`). Seating verified by `tools/seating_check.py` (decision 21). Outer wall carries the shared rim brickwork (full `REAR_COVER_T` height + one mid-depth circumferential groove, decision 20) |
| `base_main` | SGC dock: a true four-sided planar-taper pedestal (decision 22 — squared from the old 3-box hull so running-bond courses wrap the corners instead of cutting off mid-brick), two low cradle lugs carrying the gate's outer ring from below, two rear pillars carrying it from behind with M2 clearance bores (decision 17), two short-wide-buttress `FLANK` masses bracketing the ring's lowest arc — cosmetic/stability only, hard-cut clear of the ring (decision 18) — internal cable cavity, USB straight-through drop slot, rear-wall cable port (decision 16). Dock-styling relief pass (decision 19, reworked for the squared corners in decision 22): running-bond course grooves on front/rear/end walls and the top-plate deck (all continuous across the four corners), ramp-tread grooves on the sloped front, and — new in decision 22 — coursing continuing up and over each flank's own top cap |
| `base_bottom` | cover on 4× M2 heat-sets, rubber-feet recesses |

## Gate front — radial layout

Centre outward (starting values; `config.scad` owns the numbers):

1. Screen opening Ø49.5–50 (≥ Ø43.76 touch area + margin; bezel bears on case rim)
2. Inner bezel out to ~Ø59.5
3. **LED window track Ø59.5–73** — 24 windows at 15° pitch, aligned 1:1 with
   LEDs; mullions land on the dark gaps between LEDs
4. Glyph track to ~Ø96 (engraved 0.5–0.8 mm deep, lines ≥ 0.6 mm)
5. Outer mechanical ring to Ø110
6. Chevrons overlaid at 40° pitch, one at 6 o'clock on the dock's centreline (decision 23; was one at 12), clear of the windows

Gate ~20 mm deep overall (front + rear stack).

## Mounting, routing, dock

- **Clocking:** USB-C at 6 o'clock, the gate's only rim opening. Side
  power/boot buttons sit at the viewer's 11 & 1 o'clock (Narcosia, physical
  unit, corrects the earlier "adjacent to USB-C" drawing impression) —
  served by wall reliefs cut into the screen pocket, hidden behind the
  bezel; not exposed, no separate access slot.
- **Screen:** pocket 51.4–51.6 × 13–13.5 deep in `gate_rear`; puck captured
  bezel↔floor, with three ~0.2 mm crush ribs on the pocket floor preloading
  the case rear rim so it cannot rattle (decision 13 — replaces the earlier
  retainer-plate idea, which contradicted the floored pocket).
- **Header cavity:** open region behind the 8-pin header (offset ~14.7–18.7 mm
  from centre; exact coords from the Waveshare DWG during CAD), 8–10 mm
  horizontal / 5–8 mm vertical clearance; connector reachable with rear off.
- **LED ring:** pocket OD ~72.6 / ID ~59.5, depth = PCB thickness + 0.3 (PCB
  thickness pending calipers); cable notch at 6 o'clock, recessed channel
  bending rearward immediately.
- **Supports (decision 17, Task 6 Step 11b; decision 18, Task 6 Step 11c):**
  two low cradle lugs rise from the platform's flat rear plateau and contact
  the outer mechanical ring from below at ±30° off bottom-dead-centre — a
  concave cut matching the ring's own radius, 0.25 mm running clearance.
  Two rear pillars rise from behind, flush against `rear_cover`'s back, each
  carrying an M2 screw driven straight in (shear, no side-driving) through
  `rear_cover`'s pass-through into a new heat-set insert in `gate_rear`'s
  back face — the primary retention, replacing the deleted buttress/
  tab-socket pair (superseded from decision 2/11). Two `FLANK` masses
  (decision 18) bracket the ring's lowest arc from outside, short and
  wide-footed, capped well below the window annulus and hard-cut clear of
  the ring — cosmetic/stability only, no load path; the lugs and pillars are
  still the only things that actually touch or retain the gate. Rear spine
  remains deleted as vestigial (decision 15).
- **Base:** ~135 × 75 × 30 dock; steps stop well below the ring; a direct
  rear-wall cable port (decision 16) opens into the internal cavity, which
  the cable crosses before rising through the platform drop slot into the
  gate's 6 o'clock tunnel — no panel-mount socket, no strain-relief post.

## CAD structure

`config.scad` (all dimensions/tolerances/flags, each `CONFIRMED` or
`PROVISIONAL`) · `parts.scad` (component models for cuts + assembly checks) ·
one export file per printable part · `assembly.scad` (view only, never
printed) · `tests.scad` (spatial invariants that abort the render — fits,
fouling, cavity clearances, and a **360°-visibility assert**: no support/base
geometry may intersect the window annulus in front projection) · `render.ps1`
(hardened pipeline from edelkrone: stale-artifact deletion, `.echo`
ERROR/marker checks, CGAL manifold check).

## Verification ladder

1. **Coupons:** ① screen-pocket wedge (fit; bezel on case, glass untouched),
   ② LED-pocket + window/diffuser wedge, **lit with the real ring** (frost
   level + segmented look judged before committing), ③ M2 heat-set boss,
   ④ coupon C (real annular LED pocket + lead slot fit, Task 6) —
   **PASSED 2026-08-18**: ring drops in + rotates freely, diffuser sits on
   top, leads pass the slot,
   ⑤ coupon D (`couponD.scad`, Round 18): cover-lip / rear-groove MATING fit —
   two 60° sectors (gate_rear's grooved back-face region + rear_cover's rim
   with the real shoulder/lip, both printed as the real parts print); flip
   one onto the other: drops in, seats flush, lifts out — before either
   shell reprints with decision 20/21's registration pair — **PASSED
   2026-08-18**: groove/tick post printed clean, lip drops in without force,
   seats flush no rock, lifts out.
2. **Engineering print:** undecorated gate front + rear + plain base. Confirms
   screen fit + rib preload, header plug-in, LED fit + cable path, USB routing,
   full 360° visibility, base stability against presses.
3. **Freeze** the electronics geometry in `config.scad`; then decoration-only
   passes: glyphs, chevrons, dock detailing, colour prints.
4. Assertions mutation-tested once (break the config deliberately; watch them
   catch it).

No full decorated print while any part is `PROVISIONAL`.

## Purchases / physical checks (Narcosia)

- ~~Ring checks~~ **done 2026-08-12**: 24 LEDs confirmed; flying leads;
  PCB + LED stack 3.5 mm → pocket 3.8 mm.
- ~~USB-C part chosen 2026-08-12~~ **SUPERSEDED 2026-08-13 (decision 16)**:
  the 90° panel-mount USB-C extension (AliExpress 1005010641105986,
  screw-flange female into the base rear wall) is no longer needed — the
  rear wall is now a plain through-port, not a flange-mount recess. Still
  want a right-angle male-to-female USB-C extension cable (0.3 m) for the
  puck-to-port run; just no flange/screw-spacing dims to measure on
  arrival. (The bare right-angle desk cable straight into the puck is still
  dropped for the same reason as before: it transmits cable tugs to the
  puck's soldered connector and stops the gate separating from the base.)
- M2 heat-set inserts + M2 screws, if not in the drawer.

## Out of scope (tracked, not lost)

- **Firmware port:** `main.py`/`ring.py` target the Keyestudio WROOM
  (`GPIO13`). Driving the ring from the AMOLED puck's ESP32-S3 — and putting
  anything on the round screen — is a separate software project.
- **Speaker:** the puck has an MX1.25 speaker output; a kawoosh is a firmware
  feature for another day. The enclosure merely leaves the connector reachable.

## Print & colour

- Bambu H2D, 0.4 mm nozzle; PLA+ or PETG, 0.16–0.20 mm layers, 3–4 walls,
  15–20 % infill; translucent PETG diffuser (2–3 walls, low infill).
- Gunmetal gate, medium-grey tracks, dark glyph wash, red chevrons, frosted
  diffuser, dark-grey base; silver dry-brush on raised detail.
