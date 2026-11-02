# Batch check + export. Run from enclosure/.
$env:OPENSCADPATH = "$PSScriptRoot/libs"
$OS = "C:\Program Files\OpenSCAD\openscad.com"
# All finished STL/3MF exports land in print/ (2026-08-18), keeping enclosure/
# root down to sources. renders/ (PNGs) is unaffected.
if (-not (Test-Path print)) { New-Item -ItemType Directory print | Out-Null }

function Invoke-ScadCheck($scad, $marker) {
    $echo = [System.IO.Path]::ChangeExtension($scad, ".echo")
    Remove-Item $echo -ErrorAction SilentlyContinue
    & $OS -o $echo $scad | Out-Null
    if (-not (Test-Path $echo)) { throw "$scad produced no echo - did OpenSCAD run?" }
    $text = Get-Content $echo -Raw
    if ($text -match "ERROR")   { throw "$scad FAILED:`n$text" }
    if ($text -match "WARNING") { throw "$scad raised a WARNING:`n$text" }
    if ($text -notmatch [regex]::Escape($marker)) {
        throw "$scad missing completion marker '$marker' - render incomplete"
    }
}

function Invoke-ScadExport($outFile, [string[]]$scadArgs) {
    Remove-Item $outFile -ErrorAction SilentlyContinue
    # OpenSCAD 2021.01 CLI exports ASCII STL by default; force binary so
    # count_shells.py's binary parse is always valid (2026-08-12 crash fix)
    if ($outFile -like "*.stl") { $scadArgs = @("--export-format", "binstl") + $scadArgs }
    # Windows PowerShell 5.1 passes embedded double-quotes (e.g. -D 'PART="diff"')
    # to native processes unescaped, so OpenSCAD's argv parser sees them stripped
    # (PART=diff, no quotes) and treats "diff" as an unknown identifier. PowerShell
    # 7 already escapes this correctly on its own. Only pre-escape under 5.1
    # (2026-08-12 fix, found while restoring the couponB pipeline).
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        $scadArgs = $scadArgs | ForEach-Object { $_ -replace '"', '\"' }
    }
    $output = & $OS @scadArgs 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "$outFile FAILED: exit $LASTEXITCODE`n$output" }
    if ($output -match "Simple:\s*no") { throw "$outFile FAILED: non-manifold mesh`n$output" }
    if (-not (Test-Path $outFile) -or (Get-Item $outFile).Length -eq 0) {
        throw "$outFile missing or empty after export"
    }
    Write-Host "OK  $outFile"
}

function Invoke-InterferenceCheck() {
    # Round 15 (Narcosia review): the OpenSCAD/CGAL Nef-polyhedron half that
    # used to run here first is DELETED — it permanently errors on this
    # decorated mesh ("CGAL error ... e_below", every run, not a fluke —
    # Round 14 FIX C) for zero information (~53s + a WARNING every pipeline
    # run). tools/interference_check.py (trimesh + manifold3d, a real
    # polygon mesh boolean that doesn't share CGAL's Nef fragility here) IS
    # the gate now, full stop — interference_check.scad remains in the repo
    # as a documented manual/exploratory tool only (see its own header),
    # no longer invoked by this pipeline.
    $pyOut = & python tools/interference_check.py . 2>&1 | Out-String
    if ($pyOut -notmatch "interference_mm3=([\d.]+)") {
        throw "tools/interference_check.py produced no interference_mm3 reading:`n$pyOut"
    }
    $vol = [double]$Matches[1]
    if ($vol -gt 0.01) {
        throw "manifold interference check: ${vol} mm^3 of interference between base_main and the assembled gate:`n$pyOut"
    }
    Write-Host "OK  interference_check.py interference_mm3=$vol"
}

function Invoke-SeatingCheck() {
    # Round 18 FIX B (reviewer DO-NOT-PRINT blocker): tools/seating_check.py
    # — manifold boolean of rear_cover/gate_front, each placed exactly per
    # assembly.scad's relative nesting, against gate_rear. This is the gate
    # that would have caught the Round-17 lip-flare blocker (37.2 mm^3
    # collision, cover sitting 0.86mm proud, found only by a reviewer's own
    # by-hand boolean) automatically, every run, instead of relying on
    # someone remembering to check by hand. Distinct from
    # Invoke-InterferenceCheck above: that one is base_main vs. the whole
    # assembled gate stack; this one is WITHIN the gate stack itself
    # (cover-to-rear and front-to-rear seating).
    $pyOut = & python tools/seating_check.py . 2>&1 | Out-String
    if ($pyOut -notmatch "seating_cover_mm3=([\d.]+)" -or $pyOut -notmatch "seating_front_mm3=([\d.]+)") {
        throw "tools/seating_check.py produced no seating_*_mm3 reading:`n$pyOut"
    }
    if ($pyOut -match "seating_cover_mm3=([\d.]+)") { $volCover = [double]$Matches[1] }
    if ($pyOut -match "seating_front_mm3=([\d.]+)") { $volFront = [double]$Matches[1] }
    if ($volCover -gt 0.01 -or $volFront -gt 0.01) {
        throw "seating check: rear_cover=${volCover} mm^3 / gate_front=${volFront} mm^3 collision with gate_rear (either > 0.01 fails):`n$pyOut"
    }
    Write-Host "OK  seating_check.py seating_cover_mm3=$volCover seating_front_mm3=$volFront"
}

function Invoke-ShellCheck($stl, [int]$expected, [double]$expectedZ = 0) {
    # $expectedZ defaults to 0 (the bed) for every existing caller, which
    # prints its part flat on the build plate. gate_front_glyphs.stl is the
    # one exception (2026-08-17, AMS colour export): it's the AMS "ink"
    # solid, exported in gate_front's own coordinate frame so it registers
    # with the engraving rather than sitting on a bed of its own - its
    # shells legitimately float at z = FRONT_T - GLYPH_DEPTH. The check's
    # job either way is the same: every shell's own floor must sit at the
    # SAME z (a disconnected/misregistered island is a real defect).
    $out = & python tools/count_shells.py $stl 2>&1 | Out-String
    if ($out -notmatch "shells=(\d+)") { throw "$stl shell count failed:`n$out" }
    $n = [int]$Matches[1]
    if ($n -ne $expected) { throw "$stl has $n shells, expected $expected" }
    if ($out -notmatch "zmin=(-?[\d.]+)") { throw "$stl zmin missing:`n$out" }
    $z = [double]$Matches[1]
    if ([math]::Abs($z - $expectedZ) -gt 0.05) { throw "$stl floats: zmin=$z (expected $expectedZ)" }
    if ($out -notmatch "worst_shell_zmin=(-?[\d.]+)") { throw "$stl worst_shell_zmin missing:`n$out" }
    $wz = [double]$Matches[1]
    if ([math]::Abs($wz - $expectedZ) -gt 0.05) { throw "$stl has a floating body: worst shell zmin=$wz (expected $expectedZ)" }
    Write-Host "OK  $stl shells=$n zmin=$z worst_shell_zmin=$wz"
}

function Invoke-OverhangCheck($stl) {
    # Round 13 semantic gate (base_main prints flat, bed at z=0, per
    # Invoke-ShellCheck's own zmin gate): downward-facing (>30deg from
    # vertical) triangles above the bed, outside the internal-ceiling
    # bbox allowlist, are grouped by mesh-adjacency+coplanarity and flagged
    # unless the GROUP's own projected reach (shorter side of its footprint)
    # is <=2.5mm (a thin groove lintel, not a real cantilever). Throws on
    # N > 0, naming the worst group's bbox and reach.
    $out = & python tools/overhang_check.py $stl 2>&1 | Out-String
    if ($out -notmatch "overhang_faces=(\d+)") { throw "$stl overhang check failed:`n$out" }
    $n = [int]$Matches[1]
    if ($n -gt 0) {
        $bbox  = if ($out -match "worst_group_bbox=(\[[^\]]*\])") { $Matches[1] } else { "unknown" }
        $reach = if ($out -match "worst_group_reach=([\d.]+)") { $Matches[1] } else { "unknown" }
        throw "$stl has $n overhang triangle(s) - worst group bbox=$bbox reach=${reach}mm`n$out"
    }
    Write-Host "OK  $stl overhang_faces=0"
}

function Invoke-Ams3mf() {
    # 2026-08-17: builds the multi-colour AMS export from the just-exported
    # gate_front_face.stl / gate_front_glyphs.stl (+ gate_front.stl for the
    # volume cross-check). tools/make_3mf.py itself throws (exit 1) on
    # non-zero overlap or a volume mismatch; this wrapper enforces the
    # output actually exists and surfaces the overlap/volume numbers in the
    # pipeline log the same way Invoke-InterferenceCheck does.
    $pyOut = & python tools/make_3mf.py . 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "tools/make_3mf.py FAILED:`n$pyOut" }
    if ($pyOut -notmatch "overlap_mm3=([\d.]+)") {
        throw "tools/make_3mf.py produced no overlap_mm3 reading:`n$pyOut"
    }
    if (-not (Test-Path "print/gate_front_ams.3mf") -or (Get-Item "print/gate_front_ams.3mf").Length -eq 0) {
        throw "print/gate_front_ams.3mf missing or empty after make_3mf.py:`n$pyOut"
    }
    Write-Host "OK  print/gate_front_ams.3mf overlap_mm3=$($Matches[1])"
}

Invoke-ScadCheck "config.scad" "CONFIG_LOADED"
Invoke-ScadCheck "tests.scad"  "TESTS_COMPLETE"
Invoke-ScadCheck "decor.scad" "DECOR_LOADED"
# --- exports appended by later tasks below this line ---
Invoke-ScadCheck "parts.scad" "PARTS_LOADED"
Invoke-ScadCheck "gate_rear.scad" "GATE_REAR_DONE"
Invoke-ScadExport "print/gate_rear.stl" @("-o","print/gate_rear.stl","gate_rear.scad")
Invoke-ShellCheck "print/gate_rear.stl" 1
Invoke-ScadCheck "gate_front.scad" "GATE_FRONT_DONE"
Invoke-ScadExport "print/gate_front.stl" @("-o","print/gate_front.stl","gate_front.scad")
Invoke-ShellCheck "print/gate_front.stl" 1
# Multi-colour AMS export (2026-08-17): gate_front.scad's PART variable
# splits the SAME geometry into a face body and 39 glyph "ink" solids (see
# gate_front.scad's glyph_ink() comment). PART="face" is byte-for-byte the
# same branch as the default "all" above, just re-exported under its own
# name so tools/make_3mf.py has two separate STLs to colour.
$faceParam = 'PART="face"'
Invoke-ScadExport "print/gate_front_face.stl" @("-o","print/gate_front_face.stl","-D",$faceParam,"gate_front.scad")
Invoke-ShellCheck "print/gate_front_face.stl" 1
$glyphsParam = 'PART="glyphs"'
Invoke-ScadExport "print/gate_front_glyphs.stl" @("-o","print/gate_front_glyphs.stl","-D",$glyphsParam,"gate_front.scad")
# 49 shells measured 2026-08-17 (count_shells.py, plausible range 39-150):
# 39 glyph cells, each cell's 2-3 strokes sometimes touch (merging into one
# printed island) and sometimes don't (staying separate) - 49 disconnected
# ink islands is the as-designed result of glyph2d()'s deterministic stroke
# picks, not a defect. expectedZ=5.3 == FRONT_T-GLYPH_DEPTH: the ink sits in
# gate_front's own frame (registering with the engraving), not on a bed.
Invoke-ShellCheck "print/gate_front_glyphs.stl" 49 5.3
Invoke-Ams3mf
Invoke-ScadCheck "diffuser.scad" "DIFFUSER_DONE"
Invoke-ScadExport "print/diffuser.stl" @("-o","print/diffuser.stl","diffuser.scad")
Invoke-ShellCheck "print/diffuser.stl" 1
Invoke-ScadCheck "chevron.scad" "CHEVRON_DONE"
Invoke-ScadExport "print/chevron.stl" @("-o","print/chevron.stl","chevron.scad")
Invoke-ShellCheck "print/chevron.stl" 1
Invoke-ScadCheck "rear_cover.scad" "REAR_COVER_DONE"
Invoke-ScadExport "print/rear_cover.stl" @("-o","print/rear_cover.stl","rear_cover.scad")
Invoke-ShellCheck "print/rear_cover.stl" 1
# Round 18 FIX B: gate_rear/gate_front/rear_cover are all exported by this
# point — real seating gate now, not a by-hand reviewer boolean.
Invoke-SeatingCheck
Invoke-ScadCheck "base_main.scad" "BASE_MAIN_DONE"
Invoke-ScadExport "print/base_main.stl" @("-o","print/base_main.stl","base_main.scad")
Invoke-ShellCheck "print/base_main.stl" 1
Invoke-OverhangCheck "print/base_main.stl"
Invoke-InterferenceCheck
Invoke-ScadCheck "base_bottom.scad" "BASE_BOTTOM_DONE"
Invoke-ScadExport "print/base_bottom.stl" @("-o","print/base_bottom.stl","base_bottom.scad")
Invoke-ShellCheck "print/base_bottom.stl" 1
Invoke-ScadCheck "couponA.scad" "COUPON_A_DONE"
Invoke-ScadExport "print/couponA.stl" @("-o","print/couponA.stl","couponA.scad")
Invoke-ShellCheck "print/couponA.stl" 4
Invoke-ScadCheck "couponB.scad" "COUPON_B_DONE"
Invoke-ScadExport "print/couponB.stl" @("-o","print/couponB.stl","couponB.scad")
Invoke-ShellCheck "print/couponB.stl" 1
$diffParam = 'PART="diff"'
Invoke-ScadExport "print/couponB_diff.stl" @("-o","print/couponB_diff.stl","-D",$diffParam,"couponB.scad")
Invoke-ShellCheck "print/couponB_diff.stl" 1
Invoke-ScadCheck "couponC.scad" "COUPON_C_DONE"
Invoke-ScadExport "print/couponC.stl" @("-o","print/couponC.stl","couponC.scad")
Invoke-ShellCheck "print/couponC.stl" 1
# Round 18 (reviewer): couponD — the cover-lip / rear-groove MATING fit
# coupon (two 60-deg sectors on one plate: gate_rear's grooved back-face
# region + rear_cover's rim with the real shoulder/lip; see couponD.scad).
# Two bodies by design -> shells=2; both bottoms on the bed (zmin 0).
# couponD.scad `use`s gate_rear.scad/rear_cover.scad's own reg_groove()/
# reg_shoulder_cut()/reg_lip() (not re-typed copies), so a lip/groove
# change upstream flows into the coupon automatically.
Invoke-ScadCheck "couponD.scad" "COUPON_D_DONE"
Invoke-ScadExport "print/couponD.stl" @("-o","print/couponD.stl","couponD.scad")
Invoke-ShellCheck "print/couponD.stl" 2
Invoke-ScadExport "renders/couponD.png" @("-o","renders/couponD.png","--imgsize=1100,850","--camera=0,26,0,35,0,0,290","--colorscheme=Cornfield","couponD.scad")
Invoke-ScadExport "renders/assembly.png" @("-o","renders/assembly.png","--imgsize=1100,850","--camera=0,30,60,70,0,25,420","assembly.scad")
# Task 6 Step 12 decoration-pass renders (decoration plan step 12c)
Invoke-ScadExport "renders/step12_front.png" @("-o","renders/step12_front.png","--imgsize=1100,850","--camera=0,0,60,75,0,0,420","assembly.scad")
Invoke-ScadExport "renders/step12_threequarter.png" @("-o","renders/step12_threequarter.png","--imgsize=1100,850","--camera=0,0,60,60,0,35,450","assembly.scad")
Invoke-ScadExport "renders/step12_rim_closeup.png" @("-o","renders/step12_rim_closeup.png","--imgsize=1100,850","--camera=35,0,93,60,0,35,110","assembly.scad")
# Dock-relief-boldening pass (2026-08-17): front-left flank + ramp closeup
Invoke-ScadExport "renders/step12_dock_closeup.png" @("-o","renders/step12_dock_closeup.png","--imgsize=1100,850","--camera=-40,-30,35,60,0,30,180","assembly.scad")
# Round 11 pedestal treatment (2026-08-17): low three-quarter of the front-
# right corner, showing front face + side face + top plate together
Invoke-ScadExport "renders/step12_pedestal.png" @("-o","renders/step12_pedestal.png","--imgsize=1100,850","--camera=25,-45,20,55,0,40,200","assembly.scad")
# Round 12 (overhang-removal + top-plate brickwork, 2026-08-17): steep
# top-down of the plateau, checking whether the top-plate courses/joints
# read as continuous stone floor around the lugs.
Invoke-ScadExport "renders/step12_topdown.png" @("-o","renders/step12_topdown.png","--imgsize=1100,850","--camera=0,5,30,25,0,0,260","assembly.scad")
# Round 14 FIX B: base_main ONLY, reviewer's own verified camera — replaces
# Round 13's step12_plateau_ortho.png/step12_flank_under.png (the reviewer
# called the ortho one "useless" for judging the reworked 3-region
# brickwork's readability).
Invoke-ScadExport "renders/step12_plateau.png" @("--render","-o","renders/step12_plateau.png","--projection=o","--camera=0,0,25,35,0,15,190","--imgsize=1400,1000","--colorscheme=Cornfield","base_main.scad")
# Round 19 (decision 22, pedestal squared to a 4-sided planar taper): low
# 3/4 of the front-right corner, matching Narcosia's own screenshot angle —
# checking the running-bond courses wrap continuously across the corner
# edge instead of stopping mid-brick against a chamfer facet.
Invoke-ScadExport "renders/step12_corner.png" @("-o","renders/step12_corner.png","--imgsize=1100,850","--camera=45,-40,15,60,0,45,150","assembly.scad")
# Round 20 (task B, re-camera'd): flank top close-up — single folded groove
# system (2 perpendicular-depth course lines + short running-bond joints),
# checking it reads as stacked stone, not a crossed grille/ladder.
Invoke-ScadExport "renders/step12_flanktop.png" @("-o","renders/step12_flanktop.png","--imgsize=1100,850","--camera=35,7,36,55,0,20,90","assembly.scad")
# Round 20 FIX A: +X end wall, base_main only (no gate/chevrons in the way)
# — must show ONE continuous flat plane with courses wrapping unbroken, no
# crease/facet shading (Round 19's per-y "ruled twist" model, now deleted,
# would have shown a visible dihedral kink here). Round 22 FIX 2 (reviewer):
# Round 21's perspective camera (rx=58,rz=90,dist=240) still cropped band 0
# and the z=10 course line out of frame — the report's own "full z 2..22
# coursing (all 3 bands)" claim didn't match what the image actually showed.
# Replaced with a plain ORTHOGRAPHIC elevation (--projection=o) — no
# perspective foreshortening/framing guesswork. rz=90 is still the azimuth
# that faces the end wall's X-facing surface (off step12_front.png's own
# rz=0 convention); rx=90 for a true (untilted) elevation. GOTCHA (found
# empirically): --projection=o renders BLANK in preview mode on this
# geometry, at any rx/rz/dist — needs --render (full CGAL evaluation), same
# as step12_plateau.png's own precedent below. translate/dist tuned so the
# WHOLE pedestal silhouette (base to the rear's own z=30 apex) clears the
# frame with margin — all 3 bands + both z=10/20 course lines fully visible,
# nothing clipped (band 2 reads as a tapering wedge, not a defect: the wall's
# own real top edge legitimately varies 22->30 front-to-rear, and this is a
# TRUE elevation, so every Y-depth's envelope is visible at once).
Invoke-ScadExport "renders/step12_endwall.png" @("--render","-o","renders/step12_endwall.png","--imgsize=1100,850","--projection=o","--camera=0,0,17,90,0,90,160","--colorscheme=Cornfield","base_main.scad")
# Multi-colour AMS export sanity render (2026-08-17): colours the split
# STLs the same grey/black as make_3mf.py's defaults, straight-on close-up
# of the front face, so the glyph ink split + registration can be eyeballed
# without opening a slicer. See gate_front_ams_preview.scad.
Invoke-ScadExport "renders/gate_front_ams.png" @("-o","renders/gate_front_ams.png","--imgsize=1200,1200","--camera=0,0,3,0,0,0,200","--colorscheme=Cornfield","gate_front_ams_preview.scad")
# Round 16 (gate-stack registration + continuous rim brickwork) renders.
# stack_view.scad is assembly.scad's gate-stack block minus the base_main
# import, so the rim drum is visible edge-on without the pedestal in the way.
Invoke-ScadExport "renders/stack_edge.png" @("-o","renders/stack_edge.png","--imgsize=1300,950","--camera=0,0,93,78,0,30,240","stack_view.scad")
# Round 17 FIX (reviewer): cover_lip.png switched from an oblique exterior
# shot to a true radial SECTION (reviewer's own method — intersect the
# exported STL with a thin box at one angle) so the lip's 45-deg chamfer
# profile is actually visible, not just implied. cover_lip_section.scad
# depends on rear_cover.stl already being exported (the export line above
# this block), consistent with gate_front_ams.png's own STL-dependency
# pattern earlier in this file.
# Round 18 FIX E asked for --render (CGAL) here instead of the fast preview,
# reasoning that CGAL would show the section more accurately. Tried it:
# --render throws "CGAL error ... e_below" (assertion violation in
# SNC_FM_decorator.h) on this decorated mesh and silently produces an EMPTY,
# blank PNG — the EXACT same CGAL Nef-polyhedron fragility this project
# already documented and worked around in Round 14 FIX C / Round 15
# (interference_check.scad's own CGAL intersection() permanently errors on
# this decorated geometry too, which is why tools/interference_check.py
# exists at all). Verified the preview-mode command (no --render) still
# produces a valid, non-blank section on the Round-18 geometry — kept as-is.
# The authoritative verification of the lip/shoulder profile is the ray-
# probe data in task-stack-report.md, not this image (noted honestly there
# already in Round 17 — preview-mode booleans of an already-tessellated
# imported mesh can show minor visual gaps even when the underlying
# geometry, independently probed, is correct).
Invoke-ScadExport "renders/cover_lip.png" @("-o","renders/cover_lip.png","--imgsize=1100,1100","--projection=o","--camera=53.5,0,3.5,90,0,0,26","--colorscheme=Cornfield","cover_lip_section.scad")
Invoke-ScadExport "renders/rear_back.png" @("-o","renders/rear_back.png","--imgsize=1100,1100","--camera=0,0,14,45,0,0,300","--colorscheme=Cornfield","gate_rear.scad")
Write-Host "ALL CHECKS PASSED"
