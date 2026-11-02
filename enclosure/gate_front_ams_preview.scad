// Throwaway preview for the multi-colour AMS export (2026-08-17): colours the
// two split STLs the same way tools/make_3mf.py colours the 3MF (grey face,
// black glyph ink) so the split + registration can be eyeballed without
// opening a slicer. Not part of the frozen geometry pipeline - a visual
// sanity check only. Regenerate gate_front_face.stl / gate_front_glyphs.stl
// (render.ps1) before rendering this.
FACE_GREY    = [110, 110, 110] / 255;   // #6E6E6E, matches make_3mf.py's default
GLYPHS_BLACK = [0, 0, 0];               // #000000, matches make_3mf.py's default

color(FACE_GREY) import("print/gate_front_face.stl");
color(GLYPHS_BLACK) import("print/gate_front_glyphs.stl");
echo("GATE_FRONT_AMS_PREVIEW_DONE");
