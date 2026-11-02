"""Renders session state onto the WS2812B ring.

The ring is divided into equal arcs, one per active session, ordered by when
each session was first seen so an arc does not jump around mid-run.

Neighbouring arcs are separated two ways, because one cue is not enough: a
dark LED sits between them (visible even in a still photo), and each arc's
animation is staggered around the cycle so two adjacent amber arcs pulse in
antiphase rather than breathing as one. Above 12 sessions the gaps are dropped
in favour of keeping every session visible - the ring is past readable by then
anyway.

  working    brighter comet sweeping the arc (on your turn)
  background slower comet (agents running - wants nothing from you)
  input      slow pulse   <- turn finished, awaiting your prompt
  attention  fast pulse   <- permission prompt / needs input now
  done       fades out over the linger window

Colours come from PALETTES, selected by THEME in config. Motion carries the
same information independently of hue: comets mean "leave it alone", pulses
mean "it wants you", and faster means more urgent within each pair.

With no sessions, a single very dim pixel creeps around the ring: a heartbeat
that distinguishes "idle" from "powered off" at a glance.
"""

import math
import time
from machine import Pin
from neopixel import NeoPixel

import sessions as S

# 64-entry half-sine lookup, 0..255. Integer lookups per frame instead of
# floating-point trig keeps the render loop cheap enough to share the CPU
# with the HTTP server.
_SINE = [int(127.5 * (1 - math.cos(2 * math.pi * i / 64))) for i in range(64)]

# Palettes, at full scale. Scaled down by BRIGHTNESS at write time.
#
# Whatever the theme, one rule holds: states that want you are WARM, states
# that do not are COOL. That split has to survive a glance from across the
# room, long before you have read the individual hue.
#
# DONE used to be green. Once BACKGROUND claimed green - the far more common
# and longer-lived state - a shared colour would have reintroduced exactly the
# ambiguity it was meant to remove, so DONE is a white fade in every theme.
PALETTES = {
    "classic": {
        "working": (0, 40, 255),        # blue
        "background": (0, 255, 60),     # green
        "input": (255, 140, 0),         # amber
        "attention": (255, 0, 0),       # red
        "done": (255, 255, 255),
    },
    # Cyan and hot pink carry the theme because working and input are the two
    # states you see most. Green and red stay as accents rather than being
    # forced into the scheme: background needs to sit apart from working, and
    # red is the one colour nobody has to learn.
    "neon": {
        "working": (0, 220, 255),       # cyan
        "background": (0, 255, 120),    # spring green
        "input": (255, 0, 130),         # hot pink
        "attention": (255, 20, 40),     # red
        "done": (255, 255, 255),
    },
    # Everything in the pink/cyan family, for when the ring is decor as much as
    # instrument. Less legible - attention leans on its fast pulse to stand out
    # from input rather than on hue.
    "vapor": {
        "working": (0, 220, 255),       # cyan
        "background": (120, 60, 255),   # violet
        "input": (255, 0, 160),         # hot pink
        "attention": (255, 40, 90),     # pink-red
        "done": (255, 255, 255),
    },
}


def _scale(colour, level):
    """Apply 0-255 `level` to an (r, g, b), staying in integer maths."""
    r, g, b = colour
    return (r * level // 255, g * level // 255, b * level // 255)


class Ring:
    def __init__(self, pin, count, brightness, theme="vapor"):
        self.n = count
        self.max = brightness
        self.np = NeoPixel(Pin(pin, Pin.OUT), count)
        self.pal = self._resolve(theme)
        self.clear()

    @staticmethod
    def _resolve(theme):
        """Accept a palette name or a literal dict, falling back to classic.

        A typo in config should dim the lights, not brick the device on boot -
        the ring is unattended and a KeyError here would take the whole HTTP
        server down with it.
        """
        if isinstance(theme, dict):
            merged = dict(PALETTES["classic"])
            merged.update(theme)
            return merged
        pal = PALETTES.get(theme)
        if pal is None:
            print("ring: unknown theme %r, using classic" % (theme,))
            pal = PALETTES["classic"]
        return pal

    def clear(self):
        self.np.fill((0, 0, 0))
        self.np.write()

    # -- per-state arc painters ---------------------------------------------

    def _paint_comet(self, lo, hi, colour, phase, offset, slow=4):
        """Dim base with a comet head sweeping lo->hi.

        `slow` divides the phase: a larger value moves the head more lazily.
        BACKGROUND uses a slower sweep than WORKING so that even at a glance,
        without reading the colour, "running without me" looks calmer than
        "working on my turn".
        """
        span = hi - lo
        base = _scale(colour, self.max // 5)
        for i in range(lo, hi):
            self.np[i] = base
        head = lo + (phase // slow + offset) % span
        self.np[head] = _scale(colour, self.max)
        # Short tail, so direction of travel reads clearly.
        self.np[lo + (head - lo - 1) % span] = _scale(colour, self.max // 2)

    def _paint_pulse(self, lo, hi, colour, phase, speed, offset):
        level = self.max * _SINE[(phase * speed // 4 + offset) % 64] // 255
        # Floor keeps the arc readable at the bottom of the pulse.
        level = max(level, self.max // 6)
        c = _scale(colour, level)
        for i in range(lo, hi):
            self.np[i] = c

    def _paint_done(self, lo, hi, fade):
        c = _scale(self.pal["done"], self.max * fade // 255)
        for i in range(lo, hi):
            self.np[i] = c

    def _paint_heartbeat(self, phase):
        level = max(self.max // 8, 1)
        self.np[(phase // 12) % self.n] = _scale(self.pal["working"], level)

    # -- frame --------------------------------------------------------------

    def render(self, registry, phase, linger_ms):
        self.np.fill((0, 0, 0))
        active = registry.active()

        if not active:
            self._paint_heartbeat(phase)
            self.np.write()
            return

        count = min(len(active), self.n)

        # One dark LED after each arc so two same-coloured neighbours cannot
        # read as a single segment. A lone session needs no separator, and if
        # there are so many sessions that gaps would starve the arcs, drop the
        # gaps rather than the sessions.
        gap = 1 if count > 1 else 0
        usable = self.n - gap * count
        if usable < count:
            gap = 0
            usable = self.n
        span = usable // count
        extras = usable % count  # spread the remainder over the first arcs

        now = time.ticks_ms()
        pos = 0

        for idx in range(count):
            s = active[idx]
            lo = pos
            hi = lo + span + (1 if idx < extras else 0)
            pos = hi + gap

            # Second, motion-based cue: stagger each arc's animation around the
            # cycle so neighbours are never in step. Two adjacent amber arcs
            # pulse in antiphase rather than breathing as one.
            phase_off = idx * 64 // count
            comet_off = idx * span // count

            # Render the effective state, which suppresses INPUT while the
            # session still has background work outstanding.
            st = S.display_state(s)

            if st == S.WORKING:
                self._paint_comet(lo, hi, self.pal["working"], phase, comet_off, 4)
            elif st == S.BACKGROUND:
                self._paint_comet(lo, hi, self.pal["background"], phase, comet_off, 10)
            elif st == S.INPUT:
                self._paint_pulse(lo, hi, self.pal["input"], phase, 1, phase_off)
            elif st == S.ATTENTION:
                self._paint_pulse(lo, hi, self.pal["attention"], phase, 3, phase_off)
            elif st == S.DONE:
                elapsed = time.ticks_diff(now, s.ended or now)
                fade = max(0, 255 - (elapsed * 255 // max(1, linger_ms)))
                self._paint_done(lo, hi, fade)

        self.np.write()
