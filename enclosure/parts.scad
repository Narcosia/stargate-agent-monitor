// Component models — used for difference() cuts and assembly views.
// Convention: front face z=0, +z rearward, -y is 6 o'clock (USB-C down).
include <config.scad>

module screen_puck() {                     // CONFIRMED envelope, -B drawing
    cylinder(d = SCREEN_D, h = SCREEN_T, $fn = FN);
    // USB-C stub at 6 o'clock, mid-depth
    translate([0, -SCREEN_D/2, SCREEN_T/2])
        cube([USB_W - 2, 6, USB_H - 2], center = true);
    // rear 8-pin header block (x from HEADER_ZONE)
    translate([(HEADER_ZONE[0][0]+HEADER_ZONE[0][1])/2, 0, SCREEN_T])
        cube([5, 22, 6], center = true);
    // MX1.25 connector block
    translate([(CONN_ZONE[0][0]+CONN_ZONE[0][1])/2, 0, SCREEN_T])
        cube([8, 20, 4], center = true);
}

module led_ring() {                        // CONFIRMED 72/60 x 3.5, 24 LEDs
    difference() {
        cylinder(d = LED_OD, h = LED_T, $fn = FN);
        translate([0, 0, -0.5]) cylinder(d = LED_ID, h = LED_T + 1, $fn = FN);
    }
    // flying leads, SIDEWAYS in-plane (radial), gate-local -x side (same
    // side as the header cavity — Task 6 amendment, 2026-08-13). Trimmed to
    // end at the slot's outer extent LEAD_SLOT_R1 (=45), not a fixed
    // LEAD_LEN — fixed 2026-08-13 (review Minor): the marker was
    // overshooting to x=-51, past the slot's actual x=-45 opening.
    translate([-(LED_OD/2 + LEAD_SLOT_R1)/2, 0, LED_T/2])
        cube([LEAD_SLOT_R1 - LED_OD/2, LEAD_SLOT_W - 2, 2], center = true);
}

// usb_socket() deleted (Task 6 Step 9, 2026-08-13): the blind panel-socket
// recess it modelled is gone, superseded by base_main.scad's direct
// rear-wall cable port (decision 16, DESIGN.md) — never called anywhere,
// confirmed by grep before deletion.

echo("PARTS_LOADED");
