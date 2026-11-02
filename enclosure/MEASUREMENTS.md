# Measurements worksheet

Caliper-measured dimensions of the actual hardware. Everything starts
**PROVISIONAL** (datasheet, brief, or eyeball) and is promoted to **CONFIRMED**
only when measured on the physical part or proven on a printed coupon.
`config.scad` cites this file; nothing downstream hardcodes a dimension.

Source of the confirmed numbers: caliper work on the real parts, 2026-08-12,
and the original design brief.

Tolerances proven on an earlier build's coupons for the same printer/material
(Bambu H2D / 0.4 mm / PETG) carry over as starting values but get their own
coupon here before the shell prints: `FIT = 0.25`, `CLEAR = 0.15`.

## Round ESP32 touchscreen — Waveshare ESP32-S3-Touch-AMOLED-1.75-B (SKU 31262)

Identified 2026-08-12. Official dimension drawing (DWG + PDF): [Waveshare wiki](https://www.waveshare.com/wiki/ESP32-S3-Touch-AMOLED-1.75)
(not redistributed here); source listing:
<https://www.aliexpress.com/item/1005009067973350.html>. Board features that
matter here: side USB-C, rear 8-pin 2.54 mm female header, MX1.25 speaker +
battery connectors, side power/boot buttons, PMU. The screen image rotates in
software, so the puck can be **clocked freely** — port positions are ours to
choose.

| Dimension | Value | Status | Notes |
|---|---|---|---|
| Case diameter | Ø51.00 mm | CONFIRMED | official drawing = Narcosia's calipers |
| Case thickness | 11.70 body / 12.10 incl. glass | CONFIRMED | Narcosia measured 12.5 incl. protrusions — pocket depth keeps margin |
| Touch active area | Ø43.76 mm | CONFIRMED | official drawing |
| Pocket diameter | 51.4–51.6 mm | PROVISIONAL | brief starting value — coupon before trusting |
| Pocket depth | 13–13.5 mm | PROVISIONAL | brief starting value |
| Front opening (retaining bezel) | 49.5–50 mm | PROVISIONAL | bezel bears on case, never on glass; must stay ≥ Ø43.76 + margin |
| USB-C port | side-mounted, centred on one flat | CONFIRMED | plan: clock it to 6 o'clock so the extension drops straight into the base |
| Rear 8-pin header | 2.54 mm pitch, offset ~14.7–18.7 mm from centre | CONFIRMED | exact coords from DWG during CAD; cavity 8–10 mm behind |
| Speaker + battery connectors (MX1.25) | opposite side of rear, ~20.5 mm from centre | CONFIRMED | leave clearance even if unused |
| Case screw positions | ±13.75 mm | CONFIRMED | case's own assembly screws — not mounting points |
| Side buttons (power/boot) | viewer's 11 & 1 o'clock, ~1.5 mm proud | CONFIRMED 2026-08-13 | Narcosia, physical unit — overrides the earlier "adjacent to USB-C" drawing impression. The Ø51.5 screen-pocket wall presses them; relieved by two BTN_RELIEF wall cuts in gate_rear.scad at gate-local 60/120 deg (Task 6 Step 8). The old bottom button-slot is DELETED (Task 6 Step 9) — its rim break was the stray "see-in" hole visible on the printed rear cover photo; the USB tunnel is now the gate's only rim opening |

## LED status ring

| Dimension | Value | Status | Notes |
|---|---|---|---|
| Outside diameter | 72 mm | CONFIRMED | |
| Inside opening | 60 mm | CONFIRMED | |
| Ring width | 7 mm | CONFIRMED | |
| Cable section below PCB | ~15 mm SIDEWAYS in-plane (radial) — through-slot at viewer's 3 o'clock (gate-local -x, same side as the 8-pin header) | CONFIRMED 2026-08-13 | Task 6 rework: the "15 mm below" measurement was actually radial, not a droop below the PCB — the leads exit sideways, in the ring's own plane. Moved off 6 o'clock and onto the header side (shortest loop) 2026-08-13 per Narcosia; leads loop free across the gate's open rear face into the adjacent header cavity (no rear channel). NOTE: leads-at-3-o'clock shifts the firmware's LED index origin by 6 LEDs (firmware constant, out of scope here) |
| PCB thickness incl. LED package | 3.5 mm | CONFIRMED 2026-08-12 | pocket depth = 3.5 + 0.3 ≈ **3.8 mm**; diffuser sits directly above |
| LED count | 24 | CONFIRMED 2026-08-12 | matches firmware; front face gets one window per LED |

## Derived layout (from the brief — all PROVISIONAL until the engineering print)

| Dimension | Value | Notes |
|---|---|---|
| Radial gap, screen edge → LED inner edge | ~4.5 mm | hosts the inner bezel |
| LED PCB pocket | OD 74.0 / ID 58.0 / depth 4.3 mm | CONFIRMED (coupon C, 2026-08-18): ring drops in + rotates freely, diffuser sits on top, leads pass the slot (Task 6 rework 2026-08-13: was 72.6/59.5/3.8, but the engineering print showed the ring bound on a full circle and the diffuser's 0.4 mm "press-fit" was actually a bug, not a feature — one-step pocket now swallows ring + diffuser with a full mm/side wall) |
| Diffuser | OD ~73 / ID 59–60 / t 0.8–1.2 mm | translucent PETG, frost with 400–600 grit |
| Gate overall | ~110 mm OD × ~20 mm deep | leaves ~19 mm radial for glyphs + chevrons |
| Clearance below visible ring (GATE_GAP) | 8 mm | PROVISIONAL, updated 2026-08-13 (Task 6 Step 11, Narcosia visual gate — was 3–6, the brief's range, which was a pre-visual guess): photos of the printed engineering assembly showed the pedestal crowding the front of the ring (bottom windows level with the buttress tops); raised to 12 until the float read clearly in a render. GATE_CZ (gate centre height) = platform_top_at_ring_y + GATE_GAP + GATE_OD/2 — re-derived for Task 6 Step 11b (Narcosia ruling, cradle lugs/rear pillars): the ring's outer rim runs the whole gate stack's depth, so the binding case is the tallest platform point under it, the flat un-sloped BASE_H plateau (confirmed by re-checking the sloped-platform hull numerically — see task-6-report.md Round 6); GATE_CZ stayed 30+12+55 = 97 through Step 11b, now on a verified rather than assumed footing. **Task 6 Step 11c (Narcosia ruling, after the step11b renders): dialled back 12→8 — wants the ring closer.** GATE_CZ re-derives to 30+8+55 = **93**, everything downstream (lug/pillar/flank placement) follows automatically since none of it is a literal |
| Platform slope (PLATFORM_DROP) | 8 mm | PROVISIONAL, new 2026-08-13 (Task 6 Step 11): the pedestal's top face now falls 8 mm from rear (BASE_H=30) to front, opening up the view instead of presenting a flat crowding shelf; internal cavity ceiling dropped to z<=18 to keep >=3mm of material under the sloped top's lowest point (22) |
| Cradle lugs (CRADLE_LUG) | 14 × 8 × 6 mm (w × d × h, saddle nub, before the concave cut); true hull-envelope outer edge ±36.5 (anchor half-width 9, not the nub's 7 — corrected 2026-08-16, Task 6 Step 11d review, was mis-stated ±34.5 in an old base_main.scad comment) | PROVISIONAL, new 2026-08-13 (Task 6 Step 11b, Narcosia ruling): replaces the deleted buttress heads. Two lugs rise from the platform's flat rear plateau (y-band centred on gate_rear's own REAR_T/2=7) and cradle the ring's outer edge at LUG_ANG=30° off bottom (viewer's 5 & 7 o'clock) — contact point x=±27.5, z≈GATE_CZ-47.6 (≈45.4 at Step 11c's GATE_CZ=93; was ≈49.4 at Step 11's 97); concave-cut with a Ø(GATE_OD+0.5) cylinder coaxial with the gate so the Ø110 rim beds in with 0.25mm running clearance. Asserted well clear of the window annulus (55·cos30°=47.6 > WINDOW_R1+6=41.75) and the USB tunnel/drop-slot mouth. Saddle-floor thickness after the cut is **~2.71mm, restored and machine-checked 2026-08-16 (Task 6 Step 11d, review Critical fix)**: Round 7's flank relief was a strict superset of this saddle cut and, applied against the whole base instead of the flank solids only, silently gutted this floor to **0.70mm** (probe-verified, task-6-report.md Round 7 review) — invisible to every existing gate (manifold/shells/interference all stayed green; none gate on thickness). Fixed by scoping the flank relief inside `flank()`'s own `difference()`, and now permanently machine-checked in tests.scad (`saddle_floor >= LUG_FLOOR_MIN=2.0`) using formulas hoisted into config.scad (`lug_x()`, `LUG_CONTACT_Z`, `LUG_SADDLE_R`, `LUG_NUB_BOTTOM_Z`) so geometry and the test can never drift apart again |
| Rear pillars (REAR_PILLAR) | 12 × 10 mm (w × front-to-back thickness), r=45 target | PROVISIONAL, new 2026-08-13 (Task 6 Step 11b, Narcosia ruling): the gate's primary retention now that the tab/socket pair is deleted. Two pillars rise from the platform behind the gate (gate-local 245°/295°, ±25° off the USB tunnel's 270°), flush + FIT against rear_cover's back (base y=20.25), top at base z≈GATE_CZ-30 (=63 at Step 11c's GATE_CZ=93; was 67 at Step 11b's 97); each carries a straight M2 clearance bore (driven in shear from behind, no side-driving) through a new Ø2.4 pass-through in rear_cover into a new M2_INSERT hole in gate_rear's back face. Interference-gate-verified empty (pillars share no world-y range with the gate stack at all, by construction); Task 6 Step 11c added a round-6-review-follow-on assert that both pillars clear the rear-wall USB port in x by >=3mm |
| Buttress flanks (FLANK) | [15, 20, 34, 14] = [top_z_below_lowest_window, foot_w, foot_d, top_w] mm | PROVISIONAL, new 2026-08-13 (Task 6 Step 11c, Narcosia ruling, middle-ground base after the step11b renders); foot_w CUT 30->20 (Round 13 FIX 1, reviewer Critical — the old 30-wide foot's outboard edge oversailed the end wall's real tapered face by up to 5mm, an unsupported cantilever). Pure cosmetic/stability mass — the cradle lugs remain the ring's only seat, the rear pillars remain the only retention. Two flanks, each a hull() of a wide foot slab on the sloped platform (foot centre x=±(BASE_W/2-24.5)=±43, y-band matching the cradle lugs; outboard edge 43+10=53, inside END_X1=55.5 with a 2.5mm margin) and a narrow top pad leaning inboard toward the ring (top centre x = ±(rim-half-width-at-that-z + top_w/2 + 4) ≈ ±32.2, all DERIVED from GATE_CZ/WINDOW_R1/GATE_OD, no literals). Top pad caps at z=(GATE_CZ-WINDOW_R1)-FLANK[0] ≈ 42.25 at Step 11c's GATE_CZ=93 — 15mm below the lowest window, asserted <= 10mm-from-window floor. A dedicated coaxial Ø(GATE_OD+4) relief cut (bigger than the lugs' own Ø(GATE_OD+0.5) saddle cut) removes any flank material that could ever reach the ring regardless of the hull's exact shape — interference-gate-verified empty |
| Pedestal hull inset (HULL_INSET) | 12 mm, both axes | PROVISIONAL, new 2026-08-18 (decision 22): squares the pedestal's corners to a true four-sided planar taper — replaces the old 3-box hull (bottom slab + separate rear/front top strips sharing one x-width but DIFFERENT y-ranges, which left the END walls effectively vertical and cut the running-bond courses off mid-brick at each corner — Narcosia's screenshot). `hull()` of the SAME 135×75 footprint slab against ONE sloped top deck (rear edge at BASE_H=30, front edge at BASE_H-PLATFORM_DROP=22), inset HULL_INSET on every side: x-inset numerically unchanged (135→111); y-inset changes an asymmetric ~10/side (old strips' own YS/YC math) → a uniform 12/side, deck span 55→51mm. Front/rear faces stay exactly planar. **Round 19's first pass modelled the END walls as a smooth per-y "ruled twist" — reviewer mesh-probing found the real hull() output triangulates into two flat facets meeting at a real 11.4° diagonal crease instead, burying grooves under a 0.07-0.63mm skin over half their length. Round 20 fixed this at the source** with a second new value, `HULL_TOP_XHALF_FRONT` (below) — see that row for the corrected geometry. Corner continuity (courses reaching ≥2mm past each true corner) verified via `mesh.contains()` probes on the exported STL (review rounds 19-20) |
| Pedestal deck FRONT half-width (HULL_TOP_XHALF_FRONT) | 58.93 mm (was 55.5, same as the rear) | PROVISIONAL, new 2026-08-18 (Round 20 FIX A): widens the deck's FRONT strip only (rear stays HULL_TOP_XHALF=55.5) so the end wall's 4 corners — the footprint's own two corners (z=2) plus the deck's front (z=22) and rear (z=30) corners — are exactly coplanar (machine-checked in tests.scad via the scalar triple product, tolerance 1.0). `HULL_TOP_XHALF_FRONT = HULL_BOT_XHALF - (HULL_BOT_XHALF-HULL_TOP_XHALF)*(HULL_FRONT_Z1-HULL_BOT_ZS)/(HULL_REAR_Z1-HULL_BOT_ZS)`. The end wall is now a fixed-angle plane (`END_PHI=atan(12/28)≈23.2°`, x independent of y) — `end_phi_local()`/`end_course_line()` (Round 19's per-y model) deleted; `end_cut()` reverted to one constant rotation. 3.4mm/side wider than the rear deck edge — the deck's own footprint becomes a slight (117.9×51 vs 111×51) trapezoid rather than a rectangle, visually nil |
| Base | ~135 w × ~75 d × ~30 h mm | stability against touchscreen presses |
| Header cavity clearance | 8–10 mm horiz / 5–8 mm vert | connector must plug in un-crushed |
| USB-C side opening | 22 × 10 mm | PROVISIONAL, updated 2026-08-20 (was 16 × 10, was 11–12 × 6–7): on the ASSEMBLED build the puck's port sits slightly off-vertical and the plug bound in the 16-wide tunnel — widened +3 mm/side (decision 24) so the screen's clocking can be trimmed internally; dead-straight radial tunnel at 6 o'clock — the gate's only rim opening |
| Button wall reliefs | width 10 / radial depth 2.2 mm | PROVISIONAL, new 2026-08-13 (Task 6 Step 8): two cuts in the screen-pocket wall at gate-local 60/120 deg, clearing the buttons found at 11 & 1 o'clock; asserted to leave >=1mm of island before the LED pocket |
| Rear cover dish | Ø110 × 6 mm deep, 1.8 mm wall/floor | PROVISIONAL, new part 2026-08-13 (Task 6 Step 8): encloses gate_rear's back (lead loop + header/connector cavities); 4× M2 countersunk at r=40; plain closed dish, no rim notches (Task 6 Step 9 — tabs sit entirely inside gate_rear's own thickness, in front of the cover). Held by 4 screws + 2 pillar screws — the Task 6 Step 10 locating lip (was its own row here) is REVERTED (Task 6 Step 11c, Narcosia ruling): gate_rear prints face-down (back on top), so the proud lip was a support-requiring overhang |
| Rear-cover screw guide bosses ×6 | Ø6 × 3.9 (Ø9 base collar), bore Ø2.4, tip 0.3 clear of gate_rear | PROVISIONAL, new 2026-08-21 (decision 26): tubes on the floor's inside face at the four cover-screw positions AND the two pillar pass-throughs (r 45 @ 245/295°) — screw guidance across the 4.2 mm cavity + clamp column under the CSK heads; 0.3 tip clearance keeps seating rim/lip-defined (couponD) |
| Base rear-wall cable port | 16 × 14 × 12 mm (w × depth-into-wall × h) | PROVISIONAL, new 2026-08-13 (Task 6 Step 9, decision 16): direct through-hole in the pedestal's rear wall into the cavity, replacing the deleted blind USB panel-socket recess placeholder (USB_SOCKET_FLANGE/HOLES/CUT — never had confirmed dims, part never bought); cable crosses the cavity and rises through the existing platform drop slot |
| Rim brick grooves (`RIM_GROOVES`/`SEG_N`/`SEG_GROOVE`) | 36 axial grooves, 10° pitch, [0.9, 0.8] mm (w × d), full REAR_T height + 1 circumferential groove at REAR_T/2 | PROVISIONAL, new 2026-08-17 (Task 6 Step 12a, decision 19): cut into gate_rear's own clean Ø110 rim, reusing gate_front's own SEG_N/SEG_GROOVE constants so the pitch matches exactly; phase-matches automatically (no offset needed — gate_front's 36 grooves already populate every 10° position, and the assembly's rotate([180,0,180]) just relabels which k lands where within that same set, re-derived from the actual transform not assumed). Skips 260/270/280° (USB tunnel mouth) |
| Flank stepped courses (`DOCK_STEP`) | 3 bands, 1.2 mm deep, cut into each flank's outer skin only (x beyond lug_x+9) | PROVISIONAL, new 2026-08-17 (Task 6 Step 12b, decision 19): evenly spaced z from the foot's own top (BASE_H, the flank/platform-slab junction) to the top pad's own top (FLANK_TOP_Z, ~0.1mm below the cradle-lug nub's own bottom — the flank/lug junction) so the end bands land ON those two existing joins rather than floating mid-face. Scoped inside `flank()`'s own `difference()` (never the whole-base union) — the same discipline Step 11d's flank-relief-cut bug established |
| Ramp treads (`DOCK_RAMP_STEPS`/`DOCK_TREAD`) | 3 grooves, [0.8, 0.7] mm (w × d), spanning x ±13 mm | PROVISIONAL, new 2026-08-17 (Task 6 Step 12b, decision 19): stops 2mm clear of the USB drop slot (x ±11). Re-spaced inward from the ramp's full y-range after a numeric check found the naive even spread put treads #1/#3 within 0.3mm of `ramp_panel()`'s own border grooves (verified via echo, not assumed) — close enough to physically fuse into one line; now spread across the panel frame's own span, inset 2mm further, so all 3 stay clear of every panel line except the deliberate perpendicular crossing at the mid divider |
| Panel-line grids (`DOCK_PANEL`/`DOCK_INSET`) | 0.6 × 0.8 mm (w × d) grooves, 6 mm inset from each face's edge; 2×1 grid on front/back, 1×1 outline on each end, 1 outline per flank face | PROVISIONAL, new 2026-08-17 (Task 6 Step 12b, decision 19): front/back grooves follow the pedestal's own tapered surfaces (`ramp_cut()`/`rear_cut()`, rotated-frame cuts derived from the same hull-vertex numbers the USB-slot and cable-port comments already proved); end panels sit at y inside the rear strip's own [2, 27.5] range where the X-taper formula is exact |
| Rear block grid (`DOCK_BLOCK`) | 12 mm pitch, same 0.6 × 0.8 mm groove, explicitly clipped around the cable-port keepout (x ±10, z 6–22) | PROVISIONAL, new 2026-08-17 (Task 6 Step 12b, decision 19): rear face only; unlike the panel-line borders (which rely on the port cut's own boolean no-op where they cross it) this one actively splits each affected line into the surviving segments either side of the keepout |
| Flank-top coursing (`DOCK_FLANK_TOP`) | `[1.5, 1.5, 6]` = [width, depth, pitch] mm | PROVISIONAL, new 2026-08-18 (Round 19, decision 22, task B): continues each flank's own side coursing UP AND OVER its cap — the small flat pad top (z=FLANK_TOP_Z) and the sloping OUTBOARD taper down to the foot (proven exactly planar: foot and pad share the identical Y-range, so hull()-ing two same-Y rectangles at different Z is a pure 2D extrusion along Y). Shallower than the 2.0mm side grooves (the pad is only 2mm thick over the hull) — 1.5mm depth machine-checked in tests.scad to leave ≥1.5mm of material over the flank's own internal void (the Ø(GATE_OD+4) relief cut) at the worst (closest-to-axis) groove point, the flat pad-top groove nearest its 2mm inboard/relief-zone skip margin — measured 1.9mm actual, passes with margin. One central lengthwise joint runs the full cap, foot to pad |
| Gate-stack registration groove/lip (`REG_R`/`REG_W`/`REG_D`) — Round 18 shoulder design | groove r 51.6–53.2 (`REG_R`=52.4, `REG_W`=1.6), 1.6mm deep, gate_rear's back face. rear_cover: internal 45° shoulder carved into the wall's hollow cut (r 52.0→53.2 over z 4.8→6.0, entirely below the rim edge) topped by a PLAIN vertical lip, r 52.0–53.0 (`REG_LIP_CLR`=[0.2,0.4] outer/inner clearance off the groove), 1.3mm proud — nothing tapered, nothing above the rim edge outside r=53.0 | CONFIRMED (coupon D, 2026-08-18), decision 20 (2026-08-17) superseded twice more by decision 21 (Round 17: `REG_R` 53.0→52.4 to clear the axial rim-groove tick floor, chamfer-formula bug fixed, asymmetric clearance; Round 18: entire lip redesigned to support from BELOW after the Round-17 shape flared material ABOVE the rim edge into gate_rear's solid "post" — 37.2mm³ seating collision, now 0.000mm³, verified by `tools/seating_check.py`, a real pipeline gate). Outer wall remaining on gate_rear's rim beyond the groove to the axial-tick floor = 1.0mm (asserted ≥1.0, the binding constraint). Both parts skip the same arc over the USB tunnel — `REG_SKIP_LO`/`REG_SKIP_HI` ≈ 257.95°/282.05°, derived from the tunnel's real angular footprint (~10.05°) + 2° margin; the cover's own LIP skip is 1.5°/side wider still (`REG_LIP_SKIP_LO/HI` ≈ 256.45°/283.55°) so its flat end-caps don't bind against the groove's end walls. **Fit coupon: `couponD.scad`** (Round 18) — printed and mated 2026-08-18: groove/tick post printed clean, cover lip drops in without force, seats flush no rock, lifts out — `REG_LIP_CLR` promoted from PROVISIONAL |
| Gate-stack registration pin (`REG_PIN_*`) | Ø2.0 × 3mm blind hole, r=52, gate_rear front face @ 95° / gate_front rear face @ 85° (derived: 180−95) | PROVISIONAL, new 2026-08-17 (decision 20): filament-pin lock breaking the front-plate screw set's 4-fold rotational symmetry; off the SEG_N 10° groove grid on purpose |
| Chevron pin radii (`CHEV_PIN_R`) — Round 18 FIX D | `[52.0, 53.0]` (was `[52.0, 53.4]`) | PROVISIONAL, decision 21 (2026-08-17/18): the outer pin at 53.4 reached r=54.4 (Ø2), past the axial rim-groove tick floor (54.2) at all 9 chevron angles (all on the 10° tick grid) — a ~1.2mm slot opening into the tick, hidden under the chevron pad but a real defect. At 53.0 it reaches 54.0, clear; both existing asserts re-verified (pad-edge 54.4<54.9, screw-clearance 4.62>3.75) |
| Rim brickwork extended to gate_front + rear_cover | gate_front: 36 grooves, full `FRONT_T`=6mm rim height, no skip. rear_cover: 36 grooves, full `REAR_COVER_T`=6mm wall height + 1 circumferential groove at mid-depth, same 260/270/280° skip as gate_rear | PROVISIONAL, new 2026-08-17 (decision 20): all three parts now call decor.scad's shared `rim_grooves(h, skip)` — one formula, can't drift out of phase. rear_cover wall remaining beyond the groove = 1.0mm (asserted ≥0.9) |

## Reference lamp model (not redistributed)

Measured from the meshes, 2026-08-12 — the donor model is **220 mm diameter,
exactly 2× our target**:

| Part | Bounding box | Notes |
|---|---|---|
| Gate A / Gate B | 220.7 × 220.2 × 20 mm | front/back gate faces, 23k tris each |
| Diffusor 1 / 2 | 181.7 / 180.7 mm OD | lamp-style full-disc diffusers |
| Verdunklung A / B | 185.9 mm × 1 mm | blackout discs |
| Halter A / B | 226 × 40 × 25 mm | holders |
| Gehäuse | 222 × 96 × 36 mm | base/housing |
| Stift 1–3 | 7 × 7 × 12 mm | assembly pins |
| Activators (16 pcs) | ~10–14 mm × 6 mm | chevron detail parts |

At 50% scale the gate face's detailed annulus lands roughly on our 73–110 mm
decoration zone — candidate donor for glyph/chevron detailing. In the end no donor geometry
was used: glyphs and chevrons are generated in `decor.scad` / `chevron.scad`,
and the inner structure (screen pocket, LED track, cavities, base) is
parametric throughout.

## Decoration zones (v2)

All PROVISIONAL — pending the v2 print gate.

| Zone | Radii | Relief | Notes |
|---|---|---|---|
| Bezel ring | 25.4–29.4 mm | +1.0 mm | raised ring around screen pocket |
| Track ring | 36.3–37.9 mm | +0.8 mm | divider between windows and glyphs |
| Glyph band | 38.5–45.5 mm | flat (engraved) | 39 cells, Ø 0.7 mm deep, layered relief from base face |
| Outer ring | 46.2–54.9 mm | +1.5 mm | mechanical ring, raised above plate |
| Chevron pins | 52.0–53.4 mm (radial) | Ø2.0 mm | two filament pins per chevron, mounted on outer ring |
| Chevron pad corner | — | ≈55.17 mm radius | pad corner overhangs the Ø110 mm rim by ~0.17 mm — intentional, matches concept art |
