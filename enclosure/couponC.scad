include <config.scad>
$fn = FN;
// Coupon C — the fit coupon that should have existed before the engineering
// print (Task 6, 2026-08-13). A stand-alone Ø80x7 disc carrying the REAL
// annular pocket (LED_POCKET_OD/ID/T) plus the lead through-slot, so the
// full-circle constraint that bound the ring on the failed print gets
// tested here first. Print-bed rules from coupon A: body bottom exactly
// z=0, mouse ears welded 2 mm into the footprint (tangent contact risks a
// disconnected shell — an edelkrone lesson).
//
// Print gate (Task 6 Step 7): ring drops in, rotates freely, diffuser drops
// in on top, leads pass the slot — BEFORE gate_rear reprints.
DISC_D = 80;
DISC_T = 7;
DISC_R = DISC_D / 2;
// through the rim; standalone ring test, so the angular position is
// arbitrary here (the real gate_rear cut lands on the -x/header side)
SLOT_R1 = DISC_R + 1;

module ear(px, py) { translate([px, py, 0]) cylinder(d = BRIM_D, h = BRIM_T); }

difference() {
    cylinder(d = DISC_D, h = DISC_T);
    // annular pocket, opens through the top face (print face-up), depth
    // LED_POCKET_T measured down from the top — same one-step cut as
    // gate_rear, mirrored in z since this coupon opens from its top instead
    // of a front face
    translate([0, 0, DISC_T - LED_POCKET_T]) difference() {
        cylinder(d = LED_POCKET_OD, h = LED_POCKET_T + 0.5);
        translate([0, 0, -0.5])
            cylinder(d = LED_POCKET_ID, h = LED_POCKET_T + 1.5);
    }
    // lead through-slot, full disc height, same -x radial-run shape as the
    // gate_rear cut: pocket wall (2 mm into the island) out through the rim
    translate([-SLOT_R1, -LEAD_SLOT_W/2, -0.5])
        cube([SLOT_R1 - LED_POCKET_ID/2 + 2, LEAD_SLOT_W, DISC_T + 1]);
}
// mouse ears, clear of the slot's angular footprint (~165-195 deg)
for (a = [45, 135, 225, 315])
    ear((DISC_R + BRIM_D/2 - 2) * cos(a), (DISC_R + BRIM_D/2 - 2) * sin(a));

echo("COUPON_C_DONE");
