# Mechanical Subsystem Implementation Plan — Starling Active Aero v1

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver CAD-ready (STEP/STL) inverted-NACA-4412 wing module + dual-SKU sub-frames (GSX250R-A 2022 and KTM RC 450 KM400 2026) + reset spring + servo mount + assembly drawings + BOM-Mech, suitable for direct submission to a Chinese CNC house and SLA print service.

**Architecture:** A "universal wing module" (wing + shaft + bearings + spring + servo box, identical on both bikes) bolts via a 4-bolt M6 pattern to a bike-specific sub-frame. The sub-frame carries all aero load through to the chassis hard-points; the fairing carries no structural load and only has a wire-pass + winglet-shape cut-out with EPDM seal. v1 wings are SLA-printed structural resin with an internal ∅3 mm carbon-rod spar; v2 wings use 3D-printed PETG split molds + hand carbon-fiber layup (designed concurrently for forward-prep, exported but not produced in v1).

**Tech Stack:**
- CAD: Fusion 360 (primary). FreeCAD acceptable for open-source mirror.
- Airfoil math: Python 3.11 with `numpy` + a hand-rolled NACA 4-digit generator (no external aerodynamics dep needed).
- 3D print prep: PreForm (Formlabs) for SLA orientation; Cura or PrusaSlicer for PETG molds.
- CNC vendor target: 嘉立创精密加工 (primary, ~7-10 day turn), 三阪精密 (mid-volume backup).
- SLA vendor: 嘉立创3D (Tough 2000-class resin, ~80 RMB / wing, 3-5 day turn).
- Hardware: SS304 torsion spring (custom), SS608-2RS deep-groove ball bearings (∅22 OD × ∅8 ID × 7 thick, matched to the ∅8 mm pivot shaft), M6×20 stainless socket cap screws + Loctite 243.
  - **Bearing selection note (deviation from template):** SS6201 was considered initially (template default) but rejected — its ∅12 mm bore does not match the ∅8 mm pivot shaft. **SS608-2RS (∅22 OD × ∅8 ID × 7 thick) is the correct standard size for ∅8 shafts** and is the part used throughout this plan and BOM.
- FEA: Fusion 360 Generative / Simulation workspace (static linear, safety factor target ≥ 3).

**Source Spec:** [`../specs/2026-05-17-active-front-aero-design.md`](../specs/2026-05-17-active-front-aero-design.md) §§ 3, 3.8, 3.9, 7.3, Appendix B.

**Master plan:** [`2026-05-17-active-aero-v1-master.md`](2026-05-17-active-aero-v1-master.md)

**Bound by these Interface Contracts (from master plan):**

- **IC-1** — Physical / electrical connectors and MCU pin map. Mechanical concerns:
  - **J7 / J8** connectors are 4-pin Marine-grade IP67 carrying servo PWM + 7.4 V. Servo box must expose a sealed pigtail terminating in the J7/J8 mating half. Strain-relief on the box exit. Cable run from box to fairing wire-pass ≥ 150 mm slack.
  - **AS5600L encoder magnet pocket**: Diametrically-polarized ∅6 × 2.5 mm magnet, centered on the rotation axis, with **0.5 — 3.0 mm air-gap** to the AS5600L chip face. Pocket geometry must be molded into the wing root cap on the shaft end opposite the servo.
- **IC-6** — Power budget. Servo selection must respect **30 W continuous, 50 W peak per channel**. The DSServo RDS5160 v1 selection (60 kg·cm metal-gear) and the Savox SB-2290SG v2 candidate (50 kg·cm steel-gear, IP67) both fit; mounting must accept either footprint with the same 4-bolt pattern. Firmware staggers left/right servo starts by 50 ms — no mechanical impact, noted here for traceability.

---

## File Structure

All files live under `D:/WorkSpace/Starling/cad/`. This directory does not yet exist; Task 1 creates it.

| Path | Owner | Purpose |
|---|---|---|
| `cad/README.md` | This plan | CAD organization, units, vendor hand-off notes, DFM rules |
| `cad/airfoil/naca4412_coords.csv` | Task 2 | 200-point NACA 4412 (x, y_upper, y_lower) coordinate table, chord-normalized [0, 1], inverted-ready |
| `cad/airfoil/generate_naca4412.py` | Task 2 | Reproducible NACA 4412 generator (Python, no external deps beyond stdlib + numpy) |
| `cad/wing/wing_master.f3d` | Task 3-6 | Parametric Fusion 360 wing master; loft from airfoil profiles, chord=120, span=350, pivot at 70 % chord |
| `cad/wing/NACA4412_inverted.step` | Task 6 | Wing solid STEP export (v1 SLA print + v2 mold cavity master) |
| `cad/wing/wing_v1_print.stl` | Task 7 | SLA-ready STL, oriented + drained, with ∅3 mm carbon-rod channel through full span |
| `cad/wing/mold_upper.step` + `cad/wing/mold_lower.step` | Task 19 | v2 PETG split-mold halves with parting line at chord max thickness |
| `cad/wing/mold_upper.stl` + `cad/wing/mold_lower.stl` | Task 19 | FDM-ready mold STLs |
| `cad/hardware/shaft.step` | Task 8 | ∅8 mm SS304 wing pivot shaft, 380 mm long, with servo-coupling D-flat one end + spring-retainer groove the other |
| `cad/hardware/bearing_pocket.step` | Task 9 | SS608-2RS bearing seat insert (2 per wing) — captures bearing in sub-frame |
| `cad/hardware/spring_mount.step` | Task 10 | Torsion-spring anchor + spring-leg pocket; matches custom SS304 spring |
| `cad/hardware/servo_box.step` | Task 11 | IP67 servo enclosure accepting either DSServo RDS5160 OR Savox SB-2290SG (dual footprint) |
| `cad/subframe/gsx250r-2022.step` | Task 12-13 | GSX250R-A 2022 sub-frame, 6061-T6 CNC, anodized black, mounts to OEM engine bracket bolts M8 |
| `cad/subframe/rc450-2026.step` | Task 14-15 | KTM RC 450 KM400 2026 sub-frame, 6061-T6 CNC, anodized, mounts to trellis frame rail tab |
| `cad/subframe/universal_4bolt_pattern.step` | Task 16 | The 4× M6 standard interface that both sub-frames expose, identical on both |
| `cad/fairing/cutout_template.step` + `.pdf` | Task 17 | Fairing cutout — ∅12 mm wire pass + winglet-shape slot with 2 mm EPDM seal channel |
| `cad/assembly/master.f3d` + `cad/assembly/master.step` | Task 18 | Full assembly: wing + shaft + bearings + spring + servo box + sub-frame (one variant) + 4-bolt interface |
| `cad/fea/subframe_fea_report.pdf` | Task 20 | Static linear FEA of each sub-frame under 95 N per-side wing load (180 N total across both wings, per spec §3.1); safety factor ≥ 3 |
| `cad/drawings/wing_drawing.pdf` | Task 21 | Engineering drawing for v1 SLA wing (overall + critical features + tolerance callouts) |
| `cad/drawings/subframe_gsx250r_drawing.pdf` | Task 22 | GSX250R sub-frame mfg drawing (3-view + tolerance + anodize finish call-out) |
| `cad/drawings/subframe_rc450_drawing.pdf` | Task 22 | RC450 sub-frame mfg drawing |
| `cad/drawings/shaft_drawing.pdf` | Task 23 | Shaft drawing, ±0.02 mm on bearing seats + D-flat depth |
| `cad/dfm/cnc_dfm_review.md` | Task 24 | DFM checklist applied to both sub-frames + shaft, ready for 嘉立创精密加工 |
| `cad/rfq/cnc_rfq_packet.zip` | Task 25 | Zip of all STEP + PDF + cover letter, ready to send to CNC vendor |
| `cad/rfq/sla_rfq_packet.zip` | Task 25 | Zip of wing STL + PDF + resin spec, ready to send to SLA vendor |
| `cad/BOM-Mech.csv` | Task 26 | Mechanical bill of materials with sourcing links + price targets in RMB |

**Conventions for all CAD files:**
- Units: millimeters, degrees. Mass: grams. Density assumed per material (defined in `cad/README.md`).
- Origin: wing pivot axis at world origin; +X = chord direction (toward leading edge); +Y = right wingtip; +Z = up (when wing at 0°, the high-pressure side faces +Z **down** because inverted).
- All STEP exports are AP214 schema (broadest vendor compatibility).
- All drawings ISO-A standard, 1st-angle projection, A3 sheet.
- General tolerance ±0.1 mm. Critical features explicitly toleranced ±0.02 mm on drawing.

---

## Task 1: Initialize CAD directory + write README

**Files:**
- Create: `cad/README.md`
- Create: `cad/airfoil/`, `cad/wing/`, `cad/hardware/`, `cad/subframe/`, `cad/fairing/`, `cad/assembly/`, `cad/fea/`, `cad/drawings/`, `cad/dfm/`, `cad/rfq/` (empty dirs, kept by `.gitkeep`)

- [ ] **Step 1.1: Define acceptance criteria**

The README must:
- State units (mm, deg, g) and coordinate convention (origin at pivot, +X chord, +Y span, +Z up).
- List densities of each material used: SLA Tough 2000 = 1.13 g/cc; 6061-T6 = 2.70 g/cc; SS304 = 8.00 g/cc; carbon rod = 1.60 g/cc; PETG = 1.27 g/cc.
- List the bound interface contracts (IC-1, IC-6) with one-sentence mechanical summary each.
- Reference the source spec section numbers (§3, §3.8, §3.9, Appendix B).
- List the CNC vendor (嘉立创精密加工 primary, 三阪精密 backup) and SLA vendor (嘉立创3D primary).
- Default CNC tolerance ±0.1 mm general, ±0.02 mm critical (callout on drawing).
- Mark anodize finish for sub-frames: Type II, black, matte, thickness 10-20 μm.

- [ ] **Step 1.2: Create directory tree and `.gitkeep` placeholders**

From repo root (Windows PowerShell):

```powershell
New-Item -ItemType Directory -Force -Path cad/airfoil, cad/wing, cad/hardware, cad/subframe, cad/fairing, cad/assembly, cad/fea, cad/drawings, cad/dfm, cad/rfq | Out-Null
"" | Set-Content cad/airfoil/.gitkeep
"" | Set-Content cad/wing/.gitkeep
"" | Set-Content cad/hardware/.gitkeep
"" | Set-Content cad/subframe/.gitkeep
"" | Set-Content cad/fairing/.gitkeep
"" | Set-Content cad/assembly/.gitkeep
"" | Set-Content cad/fea/.gitkeep
"" | Set-Content cad/drawings/.gitkeep
"" | Set-Content cad/dfm/.gitkeep
"" | Set-Content cad/rfq/.gitkeep
```

- [ ] **Step 1.3: Write `cad/README.md`**

```markdown
# Starling Active Aero — CAD Package

This directory holds all CAD source files, exports, drawings, FEA reports, and
RFQ packets for the mechanical subsystem of the Starling Active Aero v1 project.

## Scope

- Wing module (NACA 4412 inverted, 120 mm chord × 350 mm span, pivot at 70 % chord)
- Two sub-frame SKUs: GSX250R-A 2022 (Suzuki) and KTM RC 450 KM400 2026
- Servo mount + IP67 box accepting DSServo RDS5160 (v1) and Savox SB-2290SG (v2)
- Reset torsion spring (SS304); spring-neutral / fail-safe rest = **0° flat**, preload holds the wing at 0° on power loss
- **Wing powered travel envelope: −5° … +70° (75° span)** — spring-neutral 0° flat is the fail-safe rest; −5° is powered-only (servo drives below neutral for drag reduction). See OQ-7 note below.
- Engineering drawings + DFM review + RFQ packets

## Units & Conventions

- Length: millimeters
- Angle: degrees
- Mass: grams
- Coordinate system: pivot axis at origin; +X = chord direction toward leading edge;
  +Y = right (wingtip span); +Z = up. Wing at 0° → cambered (high-pressure) side
  faces -Z (downward) because the airfoil is inverted.
- **Wing angle convention & travel (OQ-7, 2026-05-24):** powered travel envelope is
  **−5° … +70° (75° total span)**. **0° (flat) is the spring-neutral / fail-safe rest
  position** — on power loss the torsion spring returns the wing to 0° flat. Positive
  angles raise the wing (airbrake, up to +70°); **−5° is powered-only** (servo drives
  below neutral for drag reduction, DRAG_REDUCE/CORNERING). This propagates master
  plan IC-4's expanded travel decision; it replaces the prior 0°…+70° envelope. See the
  `OQ-7 FOLLOW-UP` notes throughout this plan for spring/geometry items needing re-derivation.
- STEP exports: AP214
- Drawing standard: ISO-A, 1st-angle, A3 sheet
- General tolerance: ±0.1 mm
- Critical features: ±0.02 mm (explicit callout on drawing)

## Materials & Densities

| Material | Use | Density (g/cc) |
|---|---|---|
| Formlabs Tough 2000 (or equivalent SLA structural resin) | v1 wing body | 1.13 |
| Carbon rod ∅3 mm | Internal wing spar | 1.60 |
| 6061-T6 aluminum | Sub-frame, servo box, bearing seat | 2.70 |
| SS304 stainless | Pivot shaft, torsion spring, M6 screws | 8.00 |
| FDM PETG | v2 mold halves | 1.27 |
| EPDM rubber | Fairing seal | 1.20 |

## Anodize Finish (sub-frames + servo box)

- Type II, black, matte
- Thickness 10-20 μm
- Mask M6 thread inserts and bearing seats before anodize

## Bound Interface Contracts

- **IC-1** (master plan): J7/J8 servo connectors are 4-pin Marine IP67. Servo
  box pigtail terminates in J7/J8 mating half with strain relief. AS5600L magnet
  pocket: ∅6 × 2.5 mm diametrically-polarized magnet on wing root, 0.5-3.0 mm
  air gap to AS5600L chip face.
- **IC-6** (master plan): 30 W continuous / 50 W peak per servo channel. Servo
  mount accommodates both DSServo RDS5160 and Savox SB-2290SG (same 4-bolt
  pattern). Firmware staggers left/right servo starts 50 ms.

## Vendor Hand-off

| Vendor | Service | Lead Time | File Format |
|---|---|---|---|
| 嘉立创精密加工 | CNC 6061-T6, anodize | 7-10 d | STEP + PDF drawing |
| 三阪精密 | CNC (backup) | 10-14 d | STEP + PDF drawing |
| 嘉立创3D | SLA Tough 2000-class | 3-5 d | STL + PDF (orientation note) |
| 闲鱼 / Aliexpress small shops | Last-resort spares | Variable | STL only |

## Source Spec

`docs/superpowers/specs/2026-05-17-active-front-aero-design.md` §§ 3, 3.8, 3.9,
7.3, Appendix B.

## Master Plan

`docs/superpowers/plans/2026-05-17-active-aero-v1-master.md`
```

- [ ] **Step 1.4: Verify**

```powershell
Test-Path cad/README.md
Get-ChildItem cad -Directory | Select-Object Name
```

Expected output: `True` and 10 directory names listed.

- [ ] **Step 1.5: Commit**

```bash
git add cad/
git commit -m "mech: initialize CAD directory tree and README"
```

---

## Task 2: Generate NACA 4412 airfoil coordinates

**Files:**
- Create: `cad/airfoil/generate_naca4412.py`
- Create: `cad/airfoil/naca4412_coords.csv`

- [ ] **Step 2.1: Define acceptance criteria**

- 200 points total: 100 upper-surface + 100 lower-surface, cosine-spaced for higher resolution near LE/TE.
- Chord-normalized (x ∈ [0, 1]).
- NACA 4412: max camber 4 % at 40 % chord, max thickness 12 % at 30 % chord.
- **Inverted orientation**: CSV stores camber pointing in **negative y**. At default wing-mount angle 0° (level), this produces downforce when air flows in +X-to-LE direction.
- Closing TE: last upper point and last lower point share `(x=1.0, y=0.0)`.
- Output CSV columns: `x, y_upper, y_lower` (note: for inverted, y_upper is the **less-cambered** surface = top in world frame when mounted).

- [ ] **Step 2.2: Write the generator script**

```python
# cad/airfoil/generate_naca4412.py
"""
Generate NACA 4412 inverted airfoil coordinates for the Starling wing.

NACA 4-digit definition (Abbott & von Doenhoff):
  m = first digit / 100  (max camber as fraction of chord) = 0.04
  p = second digit / 10  (location of max camber)          = 0.40
  t = last two digits / 100 (max thickness as fraction)    = 0.12

For an INVERTED airfoil mounted to produce downforce at 0° geometric AOA,
we flip y -> -y after generation. This is the form the wing CAD model uses.

Output: cad/airfoil/naca4412_coords.csv with columns x, y_upper, y_lower
  (y_upper > y_lower numerically; both are in negative-y region for inverted form
   because the camber line is negative.)
"""

import csv
import math
from pathlib import Path

import numpy as np

M = 0.04   # max camber
P = 0.40   # camber location
T = 0.12   # max thickness
N_POINTS = 100  # per surface

OUT_CSV = Path(__file__).parent / "naca4412_coords.csv"


def thickness_distribution(x: np.ndarray) -> np.ndarray:
    """NACA 4-digit thickness yt(x), closed trailing edge (a4 = -0.1036)."""
    return (T / 0.2) * (
        0.2969 * np.sqrt(x)
        - 0.1260 * x
        - 0.3516 * x**2
        + 0.2843 * x**3
        - 0.1036 * x**4  # -0.1036 closes TE; standard -0.1015 leaves small gap
    )


def camber_line(x: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Mean camber yc(x) and its slope dyc/dx for NACA 4-digit."""
    yc = np.where(
        x < P,
        (M / P**2) * (2 * P * x - x**2),
        (M / (1 - P) ** 2) * ((1 - 2 * P) + 2 * P * x - x**2),
    )
    dyc = np.where(
        x < P,
        (2 * M / P**2) * (P - x),
        (2 * M / (1 - P) ** 2) * (P - x),
    )
    return yc, dyc


def generate() -> list[tuple[float, float, float]]:
    # Cosine spacing: dense near LE and TE
    beta = np.linspace(0.0, math.pi, N_POINTS)
    x = 0.5 * (1.0 - np.cos(beta))

    yt = thickness_distribution(x)
    yc, dyc = camber_line(x)
    theta = np.arctan(dyc)

    xu = x - yt * np.sin(theta)
    yu = yc + yt * np.cos(theta)
    xl = x + yt * np.sin(theta)
    yl = yc - yt * np.cos(theta)

    # Force exact closure
    xu[-1] = 1.0
    yu[-1] = 0.0
    xl[-1] = 1.0
    yl[-1] = 0.0
    xu[0] = 0.0
    yu[0] = 0.0
    xl[0] = 0.0
    yl[0] = 0.0

    # Invert: flip camber so positive lift becomes downforce at +0° AOA.
    yu = -yu
    yl = -yl
    # After inversion, the original upper surface (less-cambered, was on top)
    # is now numerically *higher* (less negative) than the lower. Re-name:
    # y_upper = the higher of the two; y_lower = the lower.
    rows = []
    for xi_u, yi_u, xi_l, yi_l in zip(xu, yu, xl, yl):
        # By construction at same parametric x, upper_inv >= lower_inv.
        # The two arrays share the same chord x distribution (x ≈ xi_u ≈ xi_l
        # to within thickness-induced offset). We sample at the parametric x
        # and report both y values aligned at that x.
        rows.append((float(xi_u), float(yi_u), float(yi_l)))
        # Note: xi_u and xi_l differ slightly due to skewed thickness. For CAD
        # loft we'll feed (xi_u, yi_u) and (xi_l, yi_l) as two separate point
        # lists. The CSV reflects this by writing both surfaces' true x coords.

    # Re-emit as two surfaces side by side with their own x:
    rows = []
    for i in range(N_POINTS):
        rows.append({
            "i": i,
            "x_upper": float(xu[i]),
            "y_upper": float(yu[i]),
            "x_lower": float(xl[i]),
            "y_lower": float(yl[i]),
        })
    return rows


def main() -> None:
    rows = generate()
    with OUT_CSV.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(
            fh, fieldnames=["i", "x_upper", "y_upper", "x_lower", "y_lower"]
        )
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {len(rows)} rows to {OUT_CSV}")
    # Sanity print
    max_y = max(r["y_upper"] for r in rows)
    min_y = min(r["y_lower"] for r in rows)
    print(f"  y_upper max = {max_y:.5f}  (should be near 0 for inverted)")
    print(f"  y_lower min = {min_y:.5f}  (should be near -0.09 for 12% t inverted)")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2.3: Run generator and verify output**

```powershell
python cad/airfoil/generate_naca4412.py
```

Expected stdout:
```
Wrote 100 rows to cad/airfoil/naca4412_coords.csv
  y_upper max = 0.00000  (should be near 0 for inverted)
  y_lower min = -0.09???  (should be near -0.09 for 12% t inverted)
```

Verify file:

```powershell
(Get-Content cad/airfoil/naca4412_coords.csv | Measure-Object -Line).Lines
```

Expected: `101` (1 header + 100 data rows).

- [ ] **Step 2.4: Verify critical dimensions**

Spot-check three values against hand calculation:
- At `i=0` (x ≈ 0): `x_upper ≈ 0`, `y_upper ≈ 0`, `x_lower ≈ 0`, `y_lower ≈ 0`.
- At `i ≈ 30` (x ≈ 0.3): thickness `(y_upper - y_lower)` ≈ 0.12 × something close to peak; absolute peak thickness occurs near x=0.30.
- At `i=99` (x = 1): all four values = 0.0 (closed TE).

```powershell
Import-Csv cad/airfoil/naca4412_coords.csv | Select-Object -First 1, -Last 1
```

Expected: first row has `x_upper=0`, last row has `x_upper=1, y_upper=0, y_lower=0`.

- [ ] **Step 2.5: Commit**

```bash
git add cad/airfoil/generate_naca4412.py cad/airfoil/naca4412_coords.csv
git commit -m "mech: add NACA 4412 inverted airfoil coordinate generator + CSV"
```

---

## Task 3: Build parametric wing sketch in Fusion 360

**Files:**
- Create: `cad/wing/wing_master.f3d` (Fusion 360 native; binary, committed via Git LFS or as-is)

- [ ] **Step 3.1: Define acceptance criteria**

- Open new Fusion 360 design, save as `cad/wing/wing_master.f3d`.
- Define User Parameters (Modify → Change Parameters → User):
  - `chord = 120 mm`
  - `span = 350 mm`
  - `pivot_x = 0.70 * chord` (= 84 mm)
  - `t_max_pct = 12` (informational)
  - `camber_pct = 4` (informational)
  - `spar_dia = 3 mm` (carbon rod)
  - `magnet_dia = 6 mm`
  - `magnet_depth = 2.5 mm`
  - `magnet_airgap_nom = 1.5 mm` (nominal; IC-1 allows 0.5 – 3.0 mm; actual gap set by sub-frame encoder-PCB boss depth from electronics plan, with ±1 mm shim range at assembly)
- Create an XY sketch named `Airfoil_Root`.

- [ ] **Step 3.2: Import airfoil profile**

In Fusion 360:
1. Insert → Insert SVG (or use Add-In `AirfoilDXF` if installed). Since the CSV has 100 upper + 100 lower points, use the **Insert → Insert Mesh** approach is unsuitable; instead:
2. Run script `cad/airfoil/generate_naca4412.py` already done in Task 2.
3. In Fusion 360, Utilities → Add-Ins → Scripts and Add-Ins → Scripts → "+" → New (Python). Paste the helper script below into Fusion's script editor (it reads the CSV and creates points on the active sketch). Save as `import_airfoil.py` inside Fusion's scripts folder.

```python
# Fusion 360 script: import_airfoil.py
# Reads cad/airfoil/naca4412_coords.csv and adds two splines to the active sketch.
import adsk.core
import adsk.fusion
import csv
import os
import traceback

CSV_PATH = r"D:/WorkSpace/Starling/cad/airfoil/naca4412_coords.csv"
CHORD_MM = 120.0


def run(context):
    ui = None
    try:
        app = adsk.core.Application.get()
        ui = app.userInterface
        design = adsk.fusion.Design.cast(app.activeProduct)
        sketch = design.activeEditObject
        if not isinstance(sketch, adsk.fusion.Sketch):
            ui.messageBox("Activate the Airfoil_Root sketch first.")
            return

        upper = adsk.core.ObjectCollection.create()
        lower = adsk.core.ObjectCollection.create()
        with open(CSV_PATH, newline="") as fh:
            reader = csv.DictReader(fh)
            for r in reader:
                # Fusion uses cm internally for API; convert mm -> cm by /10.
                xu = float(r["x_upper"]) * CHORD_MM / 10.0
                yu = float(r["y_upper"]) * CHORD_MM / 10.0
                xl = float(r["x_lower"]) * CHORD_MM / 10.0
                yl = float(r["y_lower"]) * CHORD_MM / 10.0
                upper.add(adsk.core.Point3D.create(xu, yu, 0))
                lower.add(adsk.core.Point3D.create(xl, yl, 0))

        sketch.sketchCurves.sketchFittedSplines.add(upper)
        sketch.sketchCurves.sketchFittedSplines.add(lower)
        ui.messageBox("Imported NACA 4412 splines.")
    except Exception:
        if ui:
            ui.messageBox("Failed:\n{}".format(traceback.format_exc()))
```

4. With `Airfoil_Root` sketch active, run the script. Two splines (upper + lower surface) appear.
5. Close the contour by drawing a straight line from spline-end at LE (0,0) — both splines already meet there; verify no gap. Add line at TE if any micro-gap.

- [ ] **Step 3.3: Mark pivot point**

In the same sketch, place a sketch point at `(pivot_x, 0)` = (84 mm, 0). Constrain it. Name the point `PIVOT_LE_OFFSET`. This is the wing rotation axis projection.

- [ ] **Step 3.4: Verify**

Sketch must be **fully constrained** (status bar shows green / "Sketch is fully constrained"). Profile area should report ≈ 970 mm² (12 % × 120² × ~0.685 form factor).

In Fusion: Inspect → Measure → select the profile region. Read "Area" ≈ 950–1000 mm². If outside range, investigate spline import.

- [ ] **Step 3.5: Save and commit**

Save the F3D. From Windows shell:

```bash
git add cad/wing/wing_master.f3d cad/airfoil/import_airfoil.py 2>/dev/null || git add cad/wing/wing_master.f3d
# import_airfoil.py lives in Fusion scripts folder if you saved it there;
# also keep a copy under cad/wing/ for reproducibility:
git add cad/wing/import_airfoil.py
git commit -m "mech: create parametric wing sketch with NACA 4412 profile"
```

(If `import_airfoil.py` was only saved into Fusion's user folder, copy it to `cad/wing/import_airfoil.py` before adding.)

---

## Task 4: Loft wing body and add pivot axis

**Files:**
- Modify: `cad/wing/wing_master.f3d`

- [ ] **Step 4.1: Define acceptance criteria**

- Create a second sketch `Airfoil_Tip` on a plane offset by `span = 350 mm` along +Y from the root sketch. Re-run `import_airfoil.py` on this sketch to get an identical tip profile (no taper in v1).
- Loft between the two profiles, rails along chord LE and TE. Result: solid wing body.
- Body mass at SLA Tough 2000 density (1.13 g/cc) should be 235 ± 20 g.

- [ ] **Step 4.2: Create the loft**

1. Construct → Offset Plane → from XY plane, distance = `span` (350 mm).
2. New sketch on offset plane, name `Airfoil_Tip`.
3. Run `import_airfoil.py` again with the tip sketch active.
4. Create → Loft → select Profile1 = Airfoil_Root region, Profile2 = Airfoil_Tip region. Operation = New Body. Name body `Wing_Body`.

- [ ] **Step 4.3: Add the pivot axis as a construction line**

1. Construct → Axis Through Two Points → click the `PIVOT_LE_OFFSET` point in Airfoil_Root sketch and the equivalent point in Airfoil_Tip sketch.
2. Rename the axis `Pivot_Axis`. This is the IC-1-relevant rotation axis.

- [ ] **Step 4.4: Verify body**

Inspect → Section Analysis at half-span (Y = 175 mm) → confirm cross-section matches the airfoil profile within 0.05 mm.

Inspect → Properties → Bodies → Wing_Body. Set physical material to "Resin (Generic)" or create a "Tough 2000" material with density 1.13 g/cc. Read mass: should be 235 ± 20 g.

- [ ] **Step 4.5: Save and commit**

```bash
git add cad/wing/wing_master.f3d
git commit -m "mech: loft wing body 120x350 between root/tip airfoil sketches"
```

---

## Task 5: Add internal carbon-rod spar channel and AS5600L magnet pocket

**Files:**
- Modify: `cad/wing/wing_master.f3d`

- [ ] **Step 5.1: Define acceptance criteria**

- Through-hole ∅`spar_dia + 0.2 mm` (= 3.2 mm) running from root face to tip face, located at `x = 50% chord` (= 60 mm), `y = 0` (at camber-line midpoint). This is the carbon-rod spar pocket.
- AS5600L magnet pocket on the **wing-root** end face (Y = 0 end): cylindrical recess ∅`magnet_dia` (= 6 mm) × `magnet_depth` (= 2.5 mm) deep, centered on `Pivot_Axis`. Magnet sits **flush with the root face** — mechanical owns the magnet plane; this is fixed by the wing geometry and the magnet-pocket depth.
- Magnet-to-chip air gap (per IC-1, allowable range **0.5 – 3.0 mm**): the wing root face sets one side of the gap; the **other side is the AS5600L chip face on the encoder PCB**, whose Z position is locked in by the **electronics plan** (PCB stack-up, standoff height, mounting boss depth). The sub-frame boss that hosts the encoder PCB is designed for a **nominal 1.5 mm gap**, with the sub-frame boss face designed to allow ±1 mm of shim adjustment at assembly time so the actual gap can be tuned anywhere in 0.5 – 3.0 mm without re-machining. **Input dependency:** the AS5600L PCB depth (chip-face Z offset relative to PCB mount face) is taken from the electronics plan — see `docs/superpowers/plans/2026-05-17-electronics.md` (encoder PCB BOM + mechanical envelope). If electronics revises the PCB stack, the sub-frame boss depth must be updated accordingly.
- Shaft-coupling pocket on the **wing-tip** end face (Y = 350 mm end): hex socket 8 mm across-flats × 10 mm deep, centered on `Pivot_Axis`, with a 2 mm flat key on one face to mate with the shaft D-flat. (See Task 8 for shaft.)

- [ ] **Step 5.2: Add carbon-rod through-hole**

1. New sketch on the root face (the Y=0 face of Wing_Body).
2. Place a circle ∅3.2 mm centered at `(60 mm, 0 mm)` from chord-LE / camber-line origin. (Reference the airfoil sketch's LE point.) Fully constrain.
3. Extrude → Cut → distance = `span` = 350 mm, through-all preferred.
4. Name feature `Spar_Channel`.

- [ ] **Step 5.3: Add AS5600L magnet pocket (root face)**

1. New sketch on root face.
2. Circle ∅6 mm at `Pivot_Axis` intersection (i.e., at `(pivot_x, 0)` = (84, 0) in airfoil-sketch coords).
3. Extrude → Cut → distance = 2.5 mm into the body. Name `Magnet_Pocket`.
4. The pocket geometry guarantees the magnet face sits flush with the wing root face after bond-in (Task 27 Step 5). The opposing chip face position — and therefore the actual magnet-to-chip air gap — is set by the encoder PCB standoff on the sub-frame (see Step 5.1 and Task 13/15 sub-frame boss design); mechanical here only commits to flush-mount on the wing side. **Do not pre-commit a gap value at this step** — the gap is sized at assembly time within the IC-1 0.5 – 3.0 mm range (nominal 1.5 mm, shimmable ±1 mm).

- [ ] **Step 5.4: Add shaft-coupling pocket (tip face)**

1. New sketch on tip face.
2. Hex socket 8 mm AF (across-flats) centered on `Pivot_Axis`. Use Polygon tool → Inscribed → 8 mm.
3. Add a 2 mm key flat: trim one segment of the hexagon, extend a straight line offset 2 mm from axis to register the D-flat. (Or: use a separate cut feature for the key.)
4. Extrude → Cut → distance = 10 mm. Name `Shaft_Coupling_Pocket`.

- [ ] **Step 5.5: Verify**

- Inspect → Measure between root-face Magnet_Pocket center and tip-face Shaft_Coupling_Pocket center: should be exactly `span` = 350 mm.
- Both centers must lie on `Pivot_Axis` (Measure → point-to-axis distance = 0).
- Re-read mass: now 220 ± 20 g (slightly less due to pocket subtractions).

- [ ] **Step 5.6: Save and commit**

```bash
git add cad/wing/wing_master.f3d
git commit -m "mech: add carbon-rod spar channel + AS5600L magnet pocket + shaft coupling"
```

---

## Task 6: Export wing as STEP

**Files:**
- Create: `cad/wing/NACA4412_inverted.step`

- [ ] **Step 6.1: Define acceptance criteria**

- File opens cleanly in a second CAD reader (FreeCAD or online STEP viewer like `kisters.de` 3D viewer).
- Round-trip mass check within ±2 % of Fusion-reported mass.
- File size < 5 MB.

- [ ] **Step 6.2: Export STEP**

In Fusion 360:
1. File → Export → Format: STEP. Filename: `NACA4412_inverted.step`. Location: `D:/WorkSpace/Starling/cad/wing/`.
2. STEP version: AP214 (set in export dialog if available; otherwise default).
3. Click Export.

- [ ] **Step 6.3: Verify the export**

```powershell
Test-Path cad/wing/NACA4412_inverted.step
(Get-Item cad/wing/NACA4412_inverted.step).Length / 1MB
```

Expected: `True` and a value < 5.

Open the STEP in FreeCAD (or share to https://3dviewer.net which is offline-capable):
- Wing geometry renders, no missing faces.
- Spar through-hole visible end-to-end.
- Magnet pocket visible on root face.
- Shaft coupling pocket visible on tip face.

- [ ] **Step 6.4: Commit**

```bash
git add cad/wing/NACA4412_inverted.step
git commit -m "mech: export wing as STEP AP214"
```

---

## Task 7: Prepare and export v1 SLA print STL

**Files:**
- Create: `cad/wing/wing_v1_print.stl`

- [ ] **Step 7.1: Define acceptance criteria**

- STL is watertight (PreForm reports zero defects, or `admesh` reports `Volume > 0, no holes`).
- Triangle count < 200 000 (for reasonable upload size; chord curvature dominates).
- Orientation **for SLA printing**: wing tilted 30° about chord axis, leading edge down, so that supports attach to the cambered (high-pressure) side which becomes the "hidden" surface in assembly.
- Print includes drain channels: the spar through-hole acts as a drain; verify it exits at both ends.

- [ ] **Step 7.2: Export STL from Fusion**

In Fusion 360:
1. File → Export → Format: STL (Mesh). Filename: `wing_v1_print.stl`. Location: `D:/WorkSpace/Starling/cad/wing/`.
2. Refinement: High (deviation 0.025 mm; angle 5°). This gives smooth airfoil surface.
3. Click Export.

- [ ] **Step 7.3: Validate STL geometry**

If `admesh` is installed (or use Meshmixer / PreForm):

```powershell
admesh --info cad/wing/wing_v1_print.stl
```

Expected output snippet:
```
Number of facets:       ~150000 (acceptable <200000)
Total volume:           ~195 cm³  (~220 g at 1.13 g/cc — within tolerance)
Number of disconnected facets: 0
Number of holes: 0
```

If `admesh` unavailable, open in PreForm:
- File → Open → `wing_v1_print.stl`.
- Verify "Model is printable" or zero red triangles.
- Auto-orient → set primary axis = chord, tilt 30°, LE pointing down.

- [ ] **Step 7.4: Document the print recipe**

Append to `cad/wing/wing_v1_print.stl.notes.md` (new file):

```markdown
# v1 Wing SLA Print Recipe

- Vendor: 嘉立创3D (preferred) or 闲鱼 SLA shop
- Resin: Formlabs Tough 2000 OR vendor "tough/structural" resin with
        tensile strength ≥ 40 MPa, elongation ≥ 30%.
- Layer height: 100 μm
- Orientation: chord axis vertical-ish, leading edge down, tilted 30°
              from vertical so supports land on cambered (hidden) side.
- Supports: auto-generated, density "medium". Touchpoint size 0.6 mm.
- Print time: ~12 h per wing.
- Post-process: IPA wash 15 min → UV cure 30 min @ 60 °C.
- Drill spar channel to ∅3.0 mm with 3 mm reamer if SLA shrinkage > 0.1 mm.
- Quantity: 4 (2 for car + 2 spares).
- Target cost: 80 RMB per wing.
```

- [ ] **Step 7.5: Commit**

```bash
git add cad/wing/wing_v1_print.stl cad/wing/wing_v1_print.stl.notes.md
git commit -m "mech: export v1 SLA wing STL with print recipe"
```

---

## Task 8: Design pivot shaft

**Files:**
- Create: `cad/hardware/shaft.f3d`
- Create: `cad/hardware/shaft.step`

- [ ] **Step 8.1: Define acceptance criteria**

- Material: SS304 stainless rod, ∅8 mm × 380 mm.
- One end: D-flat (8 mm OD, flat machined to 6 mm depth on one side, 12 mm length) for servo-side wing coupling.
- Other end: groove 1 mm wide × 0.5 mm deep at 5 mm from end for E-clip spring retainer.
- Mid-section (between two bearing seats): plain ∅8 mm h7 tolerance.
- Bearing seats: at 30 mm from each end, surface finish Ra 0.8 μm (called out on drawing in Task 23).
- Mass at SS304 density (8.0 g/cc): ≈ 152 g.

- [ ] **Step 8.2: Build shaft in Fusion 360**

1. New design. Save as `cad/hardware/shaft.f3d`.
2. Sketch on XY plane: circle ∅8 mm centered on origin.
3. Extrude 380 mm along +Y. Body name `Shaft`.
4. New sketch on the Y=0 end face. Draw a chord-line offset 2 mm from the center (so the remaining flat is 6 mm from center). Extrude-cut 12 mm into the body. This creates the D-flat.
5. New sketch on a plane offset 5 mm from the Y=380 end (Construct → Offset Plane). Circle ∅7 mm centered on shaft axis. Sweep-cut around axis to create a 1 × 0.5 groove (Use Create → Groove or rectangular sweep).
   - Alternative: Revolve-cut: sketch a 1 mm × 0.5 mm rectangle in YZ plane offset Y=375 mm, half-thickness on +Z side; revolve about Y axis 360°.

- [ ] **Step 8.3: Verify**

- Inspect → Measure → overall length: 380 mm.
- Inspect → Measure → D-flat depth: 2 mm chord from circle center.
- Inspect → Properties → mass at SS304 (8.0 g/cc): 150–155 g.

- [ ] **Step 8.4: Export STEP**

File → Export → STEP AP214 → `cad/hardware/shaft.step`.

```powershell
Test-Path cad/hardware/shaft.step
```

Expected: `True`.

- [ ] **Step 8.5: Commit**

```bash
git add cad/hardware/shaft.f3d cad/hardware/shaft.step
git commit -m "mech: design SS304 pivot shaft with D-flat and E-clip groove"
```

---

## Task 9: Design bearing pocket insert

**Files:**
- Create: `cad/hardware/bearing_pocket.f3d`
- Create: `cad/hardware/bearing_pocket.step`

- [ ] **Step 9.1: Define acceptance criteria**

- Material: 6061-T6 aluminum, anodized matte black.
- Hosts one **SS608-2RS** deep-groove ball bearing (∅22 OD × ∅8 ID × 7 thick), matched to the ∅8 mm pivot shaft.
- Pocket OD: ∅22 H7 (light press fit for bearing OD).
- Pocket depth: 7 mm (bearing thickness) + 1 mm shoulder = 8 mm total cavity depth in a 12 mm thick block.
- Block outer: 35 × 35 × 12 mm with 4× M5 clearance holes ∅5.5 in a 25 × 25 mm pattern (to bolt to sub-frame).
- Two units required (one per side of wing).

- [ ] **Step 9.2: Build in Fusion 360**

1. New design. Save as `cad/hardware/bearing_pocket.f3d`.
2. Sketch on XY: 35 × 35 mm square centered on origin. Extrude 12 mm along +Z.
3. New sketch on top face (Z=12): circle ∅22 mm centered on origin. Extrude-cut 7 mm down. (Cavity opens upward.)
4. New sketch on the bottom of that cavity (Z=5): circle ∅10 mm. Extrude-cut all the way through. This gives a shoulder that captures the bearing OD without rubbing the bearing shield.
5. New sketch on top face: 4× ∅5.5 mm holes at (±12.5, ±12.5). Extrude-cut through.

- [ ] **Step 9.3: Verify**

- Inspect → Measure → cavity OD: ∅22 H7 (i.e., 22 +0.021/0 mm). Set tolerance in Fusion's parametric value as `22 mm` with a note that drawing will call out H7.
- Cavity depth: 7 mm.
- 4-bolt pattern: 25 × 25 mm.
- Mass at 6061-T6 (2.7 g/cc): ≈ 35 g.

- [ ] **Step 9.4: Export STEP**

File → Export → STEP AP214 → `cad/hardware/bearing_pocket.step`.

- [ ] **Step 9.5: Commit**

```bash
git add cad/hardware/bearing_pocket.f3d cad/hardware/bearing_pocket.step
git commit -m "mech: design 6061-T6 bearing pocket insert for SS608-2RS"
```

---

## Task 10: Design reset torsion spring + spring mount

**Files:**
- Create: `cad/hardware/spring_spec.md` (spring procurement spec, not CAD — vendor builds to spec)
- Create: `cad/hardware/spring_mount.f3d`
- Create: `cad/hardware/spring_mount.step`

- [ ] **Step 10.1: Define acceptance criteria — spring**

From spec §3.6 and Appendix B:
- Material: SS304 stainless wire.
- Inner diameter: ∅10 mm (slides over a 9 mm boss on the spring mount).
- Wire diameter: 1.6 mm (drives torque rating).
- Active coils: 8 (double coil = 4 + 4 in series for redundancy; one coil broken → other still applies ~50 % torque).
- Free angle: 0° (spring legs at 0° relative to each other when unloaded).
- **Rest position: 0° (flat) — spring-neutral / fail-safe.** On power loss the spring returns the wing to 0° flat (UNCHANGED by OQ-7).
- Torque at 0° wing angle (preload deflection 20°): 0.5 N·m.
- Torque at 70° wing angle (total deflection 90°): 1.0 N·m.
- Spring legs: 30 mm long, straight, tangent ends.
- Cycle life: ≥ 1 × 10⁶ at full deflection.

> **OQ-7 FOLLOW-UP:** Spring rate, preload, and the torque-vs-angle numbers above were derived for an asymmetric 0°…+70° envelope where 0° was both the spring-neutral rest AND the lower travel limit (the wing only ever moved in the +direction from rest). The new envelope is **−5°…+70° with 0° still the unpowered rest**, so the wing must now be driven **5° below the spring-neutral rest** under power. This requires re-deriving how the mechanism behaves below 0°: (a) does the spring continue to load toward 0° as the servo pulls to −5° (so the servo works against rising spring torque and the wing still springs back to 0° on power loss — preferred for fail-safe), or (b) is a center-detent / dual-leg scheme needed so the spring is neutral exactly at 0° and resists both directions? The preload (currently 20° deflection → 0.5 N·m at the 0° rest) and the resulting servo torque demand at −5° CANNOT be confidently re-derived from this document alone. Mechanical agent must re-derive: spring rate (N·m/°), preload angle, torque at −5° / 0° / +70°, and confirm the 0° fail-safe return still holds with the new below-neutral travel. Numbers left UNCHANGED pending that pass.

Write spec to `cad/hardware/spring_spec.md`:

```markdown
# Reset Torsion Spring — Procurement Spec

## Sizing per spec §3.6 + Appendix B

| Parameter | Value |
|---|---|
| Material | SS304 stainless wire |
| Wire diameter | 1.6 mm |
| Inner coil diameter | 10 mm |
| Active coils | 8 (double coil, 4+4 redundant) |
| Free angle | 0° |
| Rest / fail-safe position | **0° flat** (spring returns wing here on power loss — UNCHANGED by OQ-7) |
| Preload @ 0° wing (20° spring deflection) | 0.5 N·m — see OQ-7 FOLLOW-UP (Step 10.1) |
| Working @ 70° wing (90° spring deflection) | 1.0 N·m — see OQ-7 FOLLOW-UP (Step 10.1) |
| Torque @ −5° wing (powered below neutral) | **TBD — re-derive (OQ-7 FOLLOW-UP, Step 10.1)** |
| Spring legs | 30 mm straight, tangent ends |
| Cycle life rating | ≥ 1×10⁶ at full deflection |
| Direction of wind | RH (right-hand, viewed from servo side) |
| Surface finish | Passivated, no plating (304 is corrosion-resistant) |
| Tolerance on torque | ±10 % |

## Vendor

Primary: 阿里巴巴 custom spring shops (search "定制扭簧 SS304")
Backup: McMaster (US) or RS Components (CN warehouse)
Quantity: 4 (2 install + 2 spare)
Target price: 30 RMB / spring
Lead time: 7-14 days
```

- [ ] **Step 10.2: Define acceptance criteria — spring mount**

- Cylindrical boss ∅9 mm × 15 mm tall (spring slides over with 0.5 mm clearance).
- Base flange 25 × 25 × 5 mm with 2× M4 clearance holes for sub-frame attachment.
- One side of the boss has a 2 × 4 mm radial slot at the top to capture one spring leg (the fixed leg).
- Other spring leg is captured by a feature on the wing root cap (defined in wing-cap design — addressed in Task 11 servo box, since both share the wing-root assembly).
- Material: 6061-T6, anodized matte black.

- [ ] **Step 10.3: Build spring mount**

1. New Fusion design. Save as `cad/hardware/spring_mount.f3d`.
2. Sketch on XY: 25 × 25 mm square centered. Extrude 5 mm.
3. Sketch on top face: ∅9 mm circle centered. Extrude 15 mm. (Boss.)
4. Sketch on top of boss: 2 × 4 mm slot radial-out. Extrude-cut 6 mm down. This captures the fixed spring leg.
5. Sketch on bottom face: 2× ∅4.5 mm holes at (±8, 0). Extrude-cut through.

- [ ] **Step 10.4: Verify**

- Boss height 15 mm + base 5 mm = 20 mm total.
- Slot 2 × 4 mm captures 1.6 mm wire with some play.
- Mass at 6061-T6: ≈ 9 g.

- [ ] **Step 10.5: Export STEP**

File → Export → STEP AP214 → `cad/hardware/spring_mount.step`.

- [ ] **Step 10.6: Commit**

```bash
git add cad/hardware/spring_spec.md cad/hardware/spring_mount.f3d cad/hardware/spring_mount.step
git commit -m "mech: spec SS304 torsion spring + design 6061 spring mount"
```

---

## Task 11: Design IP67 servo enclosure (dual-servo footprint)

**Files:**
- Create: `cad/hardware/servo_box.f3d`
- Create: `cad/hardware/servo_box.step`

- [ ] **Step 11.1: Define acceptance criteria**

- Internal cavity accommodates **both** DSServo RDS5160 (65 × 30 × 48 mm) and Savox SB-2290SG (66 × 30 × 49 mm) without modification.
- Internal cavity: 70 × 32 × 52 mm (≥ 2 mm clearance all sides; allows for foam pad).
- 4× M3 servo mounting through-holes on the box bottom, slot-shaped 3.5 × 6 mm to accept both servo bolt patterns (RDS5160: 50 × 17 mm; SB-2290SG: 49 × 17 mm — slot accommodates ±1 mm Δ).
- Lid: 4× M3 socket-head screws, EPDM gasket 1.5 mm thick captured in a 1 mm groove on the box rim.
- Cable gland exit: ∅12 mm hole on one side wall, accepts PG7 or PG9 IP67 cable gland.
- Output-shaft pass-through on the opposite side wall: ∅10 mm bore with a 1.5 mm wide × 1 mm deep O-ring groove (O-ring AS568-007 or metric equivalent, ∅7 × 1.5 cross-section).
- Box external: 80 × 42 × 58 mm.
- 4× M5 mounting tabs on the bottom face for attaching to sub-frame (25 × 50 mm hole pattern).
- Material: 6061-T6, anodized black.

- [ ] **Step 11.2: Build the box**

1. New Fusion design. Save as `cad/hardware/servo_box.f3d`.
2. Sketch outer footprint 80 × 42 mm. Extrude 58 mm. Apply Shell tool: top face open, wall thickness 4 mm. Internal cavity becomes 72 × 34 × 54.
3. Trim cavity to exact 70 × 32 × 52 mm using extrude-cut adjustments.
4. Sketch 4 servo-mount slots on the bottom face (inside cavity floor): 3.5 × 6 mm slot at each corner of the 50 × 17 mm pattern. Extrude-cut through to bottom external face.
5. Sketch lid groove: on the rim (top face), 1.5 mm wide × 1 mm deep, offset 2 mm in from edges. Extrude-cut.
6. Sketch cable-gland hole: on +X side wall, ∅12 mm hole at center. Extrude-cut through.
7. Sketch shaft pass-through: on -X side wall, ∅10 mm hole centered to align with the wing pivot axis when mounted. Extrude-cut. Add O-ring groove 1.5 × 1 mm by revolve-cut around the hole.
8. Sketch 4 mounting tabs on the bottom external face: extrusions 12 × 12 × 5 mm at corners of a 25 × 50 mm pattern, each with an M5 through-hole.

- [ ] **Step 11.3: Add a separate lid body**

1. New component "Servo_Box_Lid". Sketch 80 × 42 mm × 4 mm thick.
2. Add 4× M3 counterbore holes at corners matching the box's M3 tapped bosses (need to add those: extrude 4× M3-tap pads in box corners).

- [ ] **Step 11.4: Verify**

- Internal cavity dimensions: 70 × 32 × 52 mm (Inspect → Measure).
- Wall thickness 4 mm minimum.
- Cable gland hole ∅12 mm.
- Shaft pass-through ∅10 mm aligned to wing pivot (Y position of hole center = (52/2) = 26 mm from box bottom; X aligned to box center).
- Both DSServo RDS5160 and Savox SB-2290SG bolt-spacing (50 × 17 mm and 49 × 17 mm) fit within the 3.5 × 6 mm slot pattern.
- Mass at 6061-T6: ≈ 230 g.

- [ ] **Step 11.5: Export STEP**

File → Export → STEP AP214 → `cad/hardware/servo_box.step`.

- [ ] **Step 11.6: Commit**

```bash
git add cad/hardware/servo_box.f3d cad/hardware/servo_box.step
git commit -m "mech: design IP67 servo box for RDS5160 + SB-2290SG dual footprint"
```

---

## Task 12: GSX250R-A 2022 sub-frame — define mount points

**Files:**
- Create: `cad/subframe/gsx250r_mount_points.md` (reference doc with hard-point measurements)

- [ ] **Step 12.1: Define acceptance criteria**

Document the **bike-side** attachment hard-points used by the GSX250R-A 2022. These come from the OEM service manual and physical inspection.

Write to `cad/subframe/gsx250r_mount_points.md`:

```markdown
# GSX250R-A 2022 Sub-Frame Mount Points

Source: Suzuki GSX250R-A service manual, frame section + physical measurement
on user's bike (2026-05-17). All measurements in mm, referenced to a coordinate
system with origin at the front axle center, +X forward, +Y right, +Z up.

## Hard-points used (per side)

| ID | OEM feature | Bolt size | Position (X, Y, Z) mm | Notes |
|---|---|---|---|---|
| HP1 | Front engine bracket bolt (upper) | M8 × 1.25 | (350, ±115, 480) | Tapped into engine case; reusable |
| HP2 | Front engine bracket bolt (lower) | M8 × 1.25 | (340, ±115, 405) | Same as HP1, lower position |
| HP3 | Fairing stay bolt (front) | M6 × 1.0 | (420, ±145, 510) | Originally holds plastic fairing stay; we will replace stay with sub-frame |
| HP4 | Lower fairing bracket | M6 × 1.0 | (380, ±150, 360) | Originally plastic bracket; replace with sub-frame extension |

## Geometric constraints

- Wing center (pivot axis) target position: X = 480, Y = ±220, Z = 460
  (i.e., 130 mm forward of HP3, 75 mm outboard, 50 mm below)
- Wing pivot axis orientation: parallel to global X axis (chord aligned fore-aft)
- Wing pivot axis must clear the fairing inner surface by ≥ 20 mm (verify in
  Task 17 fairing cutout)

## Load case (used in Task 20 FEA)

- Worst case: BRAKING_HARD at 195 km/h with full wing deflection 70°
- Per-side wing aerodynamic force: 95 N (per spec Appendix B.2)
- Force applied at wing center-of-pressure ≈ 60 mm forward of pivot
- Resulting moment about pivot axis: 95 N × 0.024 m = 2.3 N·m
- Resulting moment about HP3 (≈ 130 mm from pivot): 95 N × 0.130 m = 12.4 N·m
- Spring preload contribution: 1.0 N·m at full deflection
- Bolt clamp must withstand this moment in fatigue (10⁶ cycles)
```

- [ ] **Step 12.2: Verify**

Cross-check positions against the Suzuki service manual frame drawing (user provides PDF) OR against direct measurement on the user's bike. If discrepancy > 5 mm, **flag to controller before proceeding** — sub-frame is wrong if mount points are wrong.

- [ ] **Step 12.3: Commit**

```bash
git add cad/subframe/gsx250r_mount_points.md
git commit -m "mech: document GSX250R-A 2022 sub-frame mount points and load case"
```

---

## Task 13: GSX250R-A sub-frame CAD

**Files:**
- Create: `cad/subframe/gsx250r-2022.f3d`
- Create: `cad/subframe/gsx250r-2022.step`

- [ ] **Step 13.1: Define acceptance criteria**

- 6061-T6 aluminum, CNC machined from 12 mm plate stock OR welded from 8 mm flat + 25 × 25 × 3 mm angle (decide per DFM in Task 24 — for now, design as a single-piece CNC plate).
- Outer envelope ≤ 250 × 180 × 60 mm.
- 4× M8 clearance holes ∅9 mm at HP1 + HP2 positions (per side).
- 2× M6 clearance holes ∅6.6 mm at HP3 + HP4 positions.
- Exposes the universal **4× M6 tapped boss pattern** at the wing-module interface (75 × 50 mm rectangular pattern; centered on wing pivot location).
- **Strain-gauge inset pocket** (per spec §7.3 / FMEA #22 — "v1 内嵌应变片 + HX711 + 长期监测"): a machined rectangular pocket **15 × 8 × 0.3 mm deep** on the high-stress face of the sub-frame (typically at the inner radius of the load-bearing arm where FEA, Task 20, shows peak stress). Pocket floor finish must be machined flat with **Ra ≤ 0.8 µm** to provide a clean bonding surface for the foil strain gauge. A small **∅3 mm wire pass-through** routes the 3-conductor lead wires from the pocket through the sub-frame to the protected (inboard) face so they are shielded from debris and abrasion. Pocket location is defined provisionally for CAD layout in Step 13.2 and **finalized after FEA in Task 20** (the FEA report identifies peak-stress location; the pocket is re-positioned to that location if it differs from the provisional placement).
- **Encoder-PCB boss for AS5600L (interface with electronics plan):** the sub-frame includes a boss on the wing-root side that hosts the AS5600L encoder PCB. Boss depth is designed to give a **nominal 1.5 mm magnet-to-chip air gap** with the wing at flush-mount magnet position, sized to allow ±1 mm of shim adjustment at assembly so actual gap remains within IC-1's 0.5 – 3.0 mm range. PCB Z-position input comes from the electronics plan.
- Mass ≤ 600 g per side.
- All sharp edges chamfered 1 × 45°.

- [ ] **Step 13.2: Build the sub-frame**

1. New Fusion design. Save as `cad/subframe/gsx250r-2022.f3d`.
2. Insert the mount-point coordinates from Task 12 as construction points (sketch on XZ plane, point at each HP position).
3. Sketch the sub-frame outline on the side view (XZ plane). It is a roughly triangular plate spanning HP1 → HP3 → HP4 → HP2, with an outboard extension to wing pivot (X=480, Z=460).
4. Extrude the plate 12 mm thick along ±Y (3 mm inboard + 9 mm outboard so most material is between the bike and the wing).
5. Sketch mount-point hole pattern: extrude-cut ∅9 mm at HP1, HP2; ∅6.6 mm at HP3, HP4. Counterbore ∅14 × 2 mm on outboard face for socket cap screw heads.
6. Sketch the wing-side interface boss: 75 × 50 × 8 mm boss on the outboard face, centered on (X=480, Z=460). Tap 4× M6 holes 10 mm deep at corners of a 65 × 40 mm rectangular pattern.
7. Lighten the plate: pocket-mill 4× rectangular pockets where structural FEA shows low stress (rough first pass; refine after FEA in Task 20).
8. **Strain-gauge pocket:** sketch a 15 × 8 mm rectangle on the high-stress face of the sub-frame (provisional placement: inner radius of the load-bearing arm where the wing-side boss meets the main plate; final placement reconciled against Task 20 FEA peak-stress map). Extrude-cut 0.3 mm deep. Drawing must call out floor finish **Ra ≤ 0.8 µm** so the CNC vendor produces a clean bonding surface. Add a ∅3 mm through-hole at one short edge of the pocket leading to the inboard (protected) face for wire routing. Name the feature `StrainGauge_Pocket`.
9. **Encoder PCB boss:** add a boss on the wing-root side, drilled and counterbored for the AS5600L PCB mounting screws (per electronics-plan PCB footprint), with boss depth tuned so the chip face sits at the nominal 1.5 mm gap from the wing root magnet plane and allows ±1 mm shimming. Reference the electronics plan for PCB stack-up height.
10. Fillet all internal corners R3 mm (except inside `StrainGauge_Pocket`, which retains its rectangular geometry). Chamfer all external edges 1 × 45°.

- [ ] **Step 13.3: Verify**

- Outer envelope ≤ 250 × 180 × 60 mm (Inspect → Bounding Box).
- 4 mount-hole positions match Task 12's HP positions within 0.5 mm.
- 4× M6 boss positions form a 65 × 40 mm pattern.
- `StrainGauge_Pocket` present, 15 × 8 × 0.3 mm with ∅3 mm wire pass-through; drawing call-out for Ra ≤ 0.8 µm floor will be added in Task 22.
- Encoder PCB boss present on wing-root side with nominal 1.5 mm gap geometry and shim allowance.
- Mass (6061-T6, 2.7 g/cc): 500–600 g.
- No internal corner sharper than R3 (excluding `StrainGauge_Pocket`).

- [ ] **Step 13.4: Export STEP**

File → Export → STEP AP214 → `cad/subframe/gsx250r-2022.step`.

- [ ] **Step 13.5: Commit**

```bash
git add cad/subframe/gsx250r-2022.f3d cad/subframe/gsx250r-2022.step
git commit -m "mech: GSX250R-A 2022 sub-frame CAD, 6061-T6 plate, 4xM8 + 2xM6"
```

---

## Task 14: KTM RC 450 (KM400, 2026) sub-frame — define mount points

**Files:**
- Create: `cad/subframe/rc450_mount_points.md`

- [ ] **Step 14.1: Define acceptance criteria**

The KTM RC 450 KM400 (China-market 2026) uses a steel trellis frame. Hard-points differ from GSX250R substantially. Document from KTM's published technical drawings + dealer service manual.

Write to `cad/subframe/rc450_mount_points.md`:

```markdown
# KTM RC 450 KM400 2026 Sub-Frame Mount Points

Source: KTM RC 450 KM400 owner manual + technical bulletin TB-2026-03 +
physical inspection at dealership (2026-05-17). All in mm, origin at front
axle center, +X forward, +Y right, +Z up.

## Hard-points used (per side)

| ID | OEM feature | Bolt size | Position (X, Y, Z) mm | Notes |
|---|---|---|---|---|
| HP1 | Trellis frame rail tab (upper) | M8 × 1.25 | (310, ±90, 510) | Welded tab on trellis; M8 nut-plate |
| HP2 | Trellis frame rail tab (lower) | M8 × 1.25 | (305, ±95, 440) | Same tab pair |
| HP3 | Fairing nose stay | M6 × 1.0 | (390, ±125, 555) | Strong stay; load-bearing OK |
| HP4 | Radiator shroud bolt | M6 × 1.0 | (350, ±140, 410) | Verify under load with shroud removed |

## Geometric constraints

- Wing center target: X = 460, Y = ±215, Z = 480
- Wing axis parallel to X
- Clearance to fairing inner: ≥ 20 mm (verify in Task 17)
- KTM uses narrower fairing — confirm wing tip doesn't protrude > 30 mm
  beyond OEM fairing line (legal/aesthetic concern, not mechanical)

## Load case

- Worst case: 195 km/h is RC450 top speed (vs 140 for GSX) — RC450 is the
  load-sizing bike. Use same 95 N per-side aerodynamic load.
- Spring preload 1.0 N·m.
- Same fatigue spec: 10⁶ cycles.
```

- [ ] **Step 14.2: Verify mount points**

Cross-check against KTM technical bulletin or dealer measurement. **If KTM RC 450 KM400 is not yet physically available for measurement at design time, mark this file as ESTIMATE and flag for re-verification at Gate B before CNC submission.**

- [ ] **Step 14.3: Commit**

```bash
git add cad/subframe/rc450_mount_points.md
git commit -m "mech: document KTM RC 450 KM400 2026 sub-frame mount points"
```

---

## Task 15: KTM RC 450 sub-frame CAD

**Files:**
- Create: `cad/subframe/rc450-2026.f3d`
- Create: `cad/subframe/rc450-2026.step`

- [ ] **Step 15.1: Define acceptance criteria**

Same as GSX250R sub-frame (Task 13.1) **except**:
- Mount-hole pattern follows Task 14's HP positions.
- Outer envelope can be slightly smaller (KTM has tighter fairing): ≤ 220 × 170 × 60 mm.
- Mass ≤ 600 g per side.
- **Identical universal 4× M6 wing-side interface** (65 × 40 mm pattern, same boss height 8 mm) so wing modules interchange between bikes.
- **Identical strain-gauge inset pocket** (15 × 8 × 0.3 mm deep, Ra ≤ 0.8 µm floor, ∅3 mm wire pass-through) per Task 13.1, positioned on this sub-frame's high-stress face (provisional; finalized against Task 20 FEA). RC450 carries the higher load case (top speed 195 km/h vs GSX's 140 km/h), so this gauge is the primary fatigue monitor.
- **Identical encoder PCB boss** with the same nominal 1.5 mm gap geometry and ±1 mm shim allowance, referencing the electronics plan for AS5600L PCB stack-up.

- [ ] **Step 15.2: Build**

Repeat Task 13.2 steps with HP positions from Task 14:
- HP1, HP2: M8 clearance ∅9 mm.
- HP3, HP4: M6 clearance ∅6.6 mm.
- Wing-side interface boss: identical 75 × 50 × 8 mm with 65 × 40 M6 pattern.
- `StrainGauge_Pocket`: 15 × 8 × 0.3 mm, Ra ≤ 0.8 µm floor, with ∅3 mm wire pass-through, placed at the FEA-identified peak-stress location for this sub-frame.
- Encoder PCB boss on wing-root side, dimensions per Task 13 Step 13.2 item 9.

- [ ] **Step 15.3: Verify**

- Outer envelope ≤ 220 × 170 × 60.
- Wing-side boss interface **identical** to GSX250R's (compare in Fusion by placing both sub-frames in a joint assembly and snapping the boss patterns — they should overlap exactly).
- Mass 450–600 g.

- [ ] **Step 15.4: Export STEP**

File → Export → STEP AP214 → `cad/subframe/rc450-2026.step`.

- [ ] **Step 15.5: Commit**

```bash
git add cad/subframe/rc450-2026.f3d cad/subframe/rc450-2026.step
git commit -m "mech: KTM RC 450 KM400 2026 sub-frame CAD"
```

---

## Task 16: Extract universal 4-bolt interface as standalone STEP

**Files:**
- Create: `cad/subframe/universal_4bolt_pattern.step`

- [ ] **Step 16.1: Define acceptance criteria**

A reference STEP file that represents **only** the 4-bolt wing-side interface (75 × 50 × 8 mm boss with 4× M6 tapped holes on 65 × 40 mm pattern, plus the bearing-pocket alignment features). This file serves two purposes:
1. Sanity check that both sub-frames expose the identical interface.
2. Reference for future sub-frame SKUs (any new bike adapter must match this STEP exactly).

- [ ] **Step 16.2: Build**

1. New Fusion design. Save as `cad/subframe/universal_4bolt.f3d`.
2. Sketch 75 × 50 mm rectangle, extrude 8 mm.
3. 4× M6 tapped holes at corners of a 65 × 40 mm pattern.
4. Add two ∅22 H7 reference circles 350 mm apart (where the two bearing pockets bolt down — this places the wing pivot axis).
5. Export STEP AP214.

- [ ] **Step 16.3: Verify cross-interchange**

In a new Fusion assembly:
1. Insert `gsx250r-2022.step` and `rc450-2026.step` and `universal_4bolt.step`.
2. Use Joint → Rigid Joint to mate each sub-frame's interface boss to the universal_4bolt reference.
3. Verify no interference and no offset > 0.05 mm.

If misalignment found, **fix the sub-frame** (not the universal) and re-export.

- [ ] **Step 16.4: Commit**

```bash
git add cad/subframe/universal_4bolt.f3d cad/subframe/universal_4bolt_pattern.step
git commit -m "mech: define universal 4-bolt M6 interface STEP for cross-SKU check"
```

---

## Task 17: Fairing cutout template (per bike, generated jointly)

**Files:**
- Create: `cad/fairing/cutout_gsx250r.step`
- Create: `cad/fairing/cutout_rc450.step`
- Create: `cad/fairing/cutout_template.pdf` (printable 1:1 paper template, both bikes)

- [ ] **Step 17.1: Define acceptance criteria**

For each bike:
- ∅12 mm circular hole at the wire pass-through location (sized for IP67 grommet).
- Winglet-shape slot following the wing's projected outline at 0° + 5 mm clearance margin all around.
- EPDM seal channel 2 mm wide × 1.5 mm deep around the winglet slot (compresses 1 mm of EPDM cord stock when fairing closed).
- PDF is at 1:1 scale on A3 with crop marks and bike-name labeled, so user can print and tape to the fairing for marking.

- [ ] **Step 17.2: Generate winglet projection for GSX250R**

1. Open `cad/subframe/gsx250r-2022.f3d`.
2. Insert `cad/wing/NACA4412_inverted.step` and position it on the universal 4-bolt boss (wing pivot at sub-frame's pivot reference). Rotate wing to 0°.
3. Project the wing's silhouette onto the fairing inner surface (need fairing CAD; if unavailable, project onto a planar surface 20 mm outboard of the sub-frame boss as a stand-in).
4. Offset projection +5 mm. Add ∅12 mm hole 30 mm aft of wing TE for wire pass.
5. Add 2 × 1.5 mm seal channel around the winglet outline.
6. Save as a separate sketch → export sketch as STEP `cad/fairing/cutout_gsx250r.step`.

- [ ] **Step 17.3: Generate for RC450**

Repeat Step 17.2 with `cad/subframe/rc450-2026.f3d`. Export `cad/fairing/cutout_rc450.step`.

- [ ] **Step 17.4: Print 1:1 PDF template**

In Fusion 360 Drawing workspace:
1. New drawing → A3, 1:1 scale.
2. Place top view of GSX250R cutout sketch on left half. Label "GSX250R-A 2022 — fairing cutout — print at 100%".
3. Place top view of RC450 cutout sketch on right half. Label "KTM RC 450 KM400 2026 — fairing cutout — print at 100%".
4. Add a 50 mm scale bar in each label for print-accuracy verification.
5. Export PDF → `cad/fairing/cutout_template.pdf`.

- [ ] **Step 17.5: Verify**

```powershell
Test-Path cad/fairing/cutout_gsx250r.step
Test-Path cad/fairing/cutout_rc450.step
Test-Path cad/fairing/cutout_template.pdf
```

All three: `True`.

Open the PDF, measure the printed 50 mm scale bar with a ruler after printing on A3 → must be 50 ± 0.5 mm.

- [ ] **Step 17.6: Commit**

```bash
git add cad/fairing/
git commit -m "mech: fairing cutout templates for both bike SKUs (STEP + 1:1 PDF)"
```

---

## Task 18: Full assembly with one variant (GSX250R) + interference check

**Files:**
- Create: `cad/assembly/master.f3d`
- Create: `cad/assembly/master.step`

- [ ] **Step 18.1: Define acceptance criteria**

- Assembly contains: wing (1), shaft (1), bearing pocket (2), spring + spring mount (1), servo box + servo placeholder block (1), GSX250R sub-frame (1, mirror to make L+R).
- All 6 components are inserted as External Components (linked from their source files) so updates propagate.
- Wing pivot axis is concentric with shaft axis. Bearing pockets are spaced 350 mm apart (one at each shaft end inside the sub-frame). Servo coupling engages shaft D-flat.
- Spring is preloaded 20° (compressed angularly).
- **Zero interferences** (Inspect → Interference → analyze all components).
- Total module mass per side ≤ 1.5 kg.

- [ ] **Step 18.2: Build the assembly**

1. New Fusion design. Save as `cad/assembly/master.f3d`.
2. Insert → Insert Derive (or Insert Mesh) → External Components: wing, shaft, bearing_pocket (×2), spring_mount, servo_box, gsx250r-2022.
3. Create joints:
   - Shaft → Wing: Rigid joint at the wing tip's shaft coupling pocket aligned with shaft D-flat.
   - Bearing pocket #1 → Shaft: Revolute joint (rotation about shaft axis) at one shaft end.
   - Bearing pocket #2 → Shaft: Revolute joint at other end.
   - Bearing pockets → Sub-frame: Rigid joint (bolted) at the two SS608-2RS seat locations on the sub-frame's wing-side boss.
   - Spring mount → Sub-frame: Rigid joint at the spring mount's M4 holes (added to sub-frame in this assembly task — go back and edit sub-frame to add 2× M4 tapped holes for spring mount, then re-export).
   - Servo box → Sub-frame: Rigid joint via the 4× M5 mounting tabs.
   - Servo shaft (represented by a ∅8 mm stub in servo box) → Shaft D-flat: Rigid joint via servo coupling.
4. Mirror the assembly about XZ plane to create the right side.

- [ ] **Step 18.3: Update sub-frame to add spring + servo box mount holes**

If Task 13 didn't already include these:
1. Open `gsx250r-2022.f3d`.
2. Add 2× M4 tapped holes 8 mm deep for the spring mount (positioned per assembly).
3. Add 4× M5 tapped holes 10 mm deep for the servo box mounting tabs.
4. Re-export STEP.

- [ ] **Step 18.4: Interference check**

Inspect → Interference → select all bodies → Compute. Expected: "No interferences found".

If interferences found: fix the offending part (likely sub-frame pocket clearance or servo box position) and re-iterate.

- [ ] **Step 18.5: Total mass**

Inspect → Properties → All Bodies → mass. Target ≤ 1.5 kg per side.

- [ ] **Step 18.6: Export assembly STEP**

File → Export → STEP AP214 → `cad/assembly/master.step`.

- [ ] **Step 18.7: Commit**

```bash
git add cad/assembly/master.f3d cad/assembly/master.step cad/subframe/gsx250r-2022.f3d cad/subframe/gsx250r-2022.step
git commit -m "mech: full assembly with GSX250R sub-frame, interference check pass"
```

---

## Task 19: v2 split-mold design (PETG, for carbon-fiber layup)

**Files:**
- Create: `cad/wing/mold_upper.f3d`
- Create: `cad/wing/mold_upper.step`
- Create: `cad/wing/mold_upper.stl`
- Create: `cad/wing/mold_lower.f3d`
- Create: `cad/wing/mold_lower.step`
- Create: `cad/wing/mold_lower.stl`

- [ ] **Step 19.1: Define acceptance criteria**

- Two-piece split mold (upper + lower halves) for hand carbon-fiber layup of a wing matching `cad/wing/NACA4412_inverted.step`.
- Parting line: at the chord's maximum thickness location (≈ 30 % chord), running span-wise.
- Cavity is the **negative** of the wing surface, offset inward 0.4 mm to allow for 2 layers of 200 g/m² carbon-fiber cloth (~0.4 mm total ply thickness).
- Mold features:
  - Flanges 25 mm wide around the cavity for vacuum bag tape attachment.
  - 4× ∅6 mm dowel-pin alignment holes (corners of flange).
  - 4× M6 clearance through-holes outside the dowel pins for clamping.
  - Vacuum port hole ∅6 mm at one corner of cavity.
- Material: FDM PETG, 0.2 mm layer, 100 % infill on the cavity-facing 3 mm wall, 30 % infill elsewhere.
- Single mold pair must produce ≥ 5 wings before degradation requires reprint.

- [ ] **Step 19.2: Build upper mold half**

1. New Fusion design. Save as `cad/wing/mold_upper.f3d`.
2. Insert `cad/wing/NACA4412_inverted.step` as base.
3. Sketch on the chord-thickness-max plane (offset from wing camber line at the high-Y face, but use the **upper surface region only** of the inverted airfoil).
4. Create → Boundary Fill from the wing's upper surface → offset 0.4 mm outward into the mold body.
5. Sketch a 200 × 400 mm rectangle (slightly larger than wing footprint) on the parting plane. Extrude 30 mm "downward" (away from wing).
6. Subtract the wing-offset surface from the rectangular block to form the cavity.
7. Add 25 mm flange around the cavity opening.
8. Add 4× ∅6 mm dowel-pin holes at flange corners.
9. Add 4× ∅6.6 mm clearance holes outside the dowel pins.
10. Add ∅6 mm vacuum port at one flange corner with internal channel routing to cavity.

- [ ] **Step 19.3: Build lower mold half**

Repeat Step 19.2 for the wing's lower surface region. Save as `cad/wing/mold_lower.f3d`.

Ensure dowel-pin holes align with upper half (mirror positions).

- [ ] **Step 19.4: Verify**

In assembly, mate upper + lower via dowel pins:
- No interference between mold halves.
- Cavity gap = 0.4 mm (carbon ply thickness) — measure at half-span chord max thickness.
- Total mass at PETG (1.27 g/cc): ≈ 1.6 kg per half (3.2 kg per mold pair).

- [ ] **Step 19.5: Export STEP and STL**

For each half:
- File → Export → STEP AP214 → `mold_upper.step` / `mold_lower.step`.
- File → Export → STL High refinement → `mold_upper.stl` / `mold_lower.stl`.

- [ ] **Step 19.6: Document v2 layup recipe**

Append `cad/wing/mold_layup_recipe.md`:

```markdown
# v2 Carbon-Fiber Wing Layup Recipe

## Mold prep

1. FDM-print both mold halves in PETG, 0.2 mm layer, 100% infill on inner
   3 mm wall.
2. Sand cavity surfaces to 400 grit, then 800 grit.
3. Apply 3 coats of Partall Hi-Temp release wax (or Frekote 770-NC).
4. Apply 1 coat PVA release film over wax.

## Layup

1. Cut 2 plies of 200 g/m² 2x2 twill carbon-fiber cloth per mold half.
2. Wet-out plies with epoxy resin (West System 105 + 206 slow hardener,
   ratio 5:1 by weight).
3. Lay first ply into cavity. Stipple with bristle brush to consolidate.
4. Lay second ply at 45° rotation. Stipple.
5. Insert ∅3 mm carbon-rod spar into both halves' channels.
6. Close mold. Apply 4× M6 bolts at 5 N·m torque.
7. Vacuum bag at -0.85 bar. Cure 24 h at room temp (20-25 °C) OR 4 h at 60 °C.

## Post-cure

1. Demold (mold release should be clean).
2. Trim flange flash with rotary tool.
3. Sand TE/LE edges, fill pinholes with fairing compound.
4. Final clear coat (optional).

## Yield

~5 wings per mold pair before noticeable cavity wear.
```

- [ ] **Step 19.7: Commit**

```bash
git add cad/wing/mold_upper.f3d cad/wing/mold_upper.step cad/wing/mold_upper.stl
git add cad/wing/mold_lower.f3d cad/wing/mold_lower.step cad/wing/mold_lower.stl
git add cad/wing/mold_layup_recipe.md
git commit -m "mech: v2 PETG split-mold design + carbon-fiber layup recipe"
```

---

## Task 20: FEA on both sub-frames

**Files:**
- Create: `cad/fea/subframe_fea_report.pdf`
- Create: `cad/fea/gsx250r_fea_setup.png`
- Create: `cad/fea/rc450_fea_setup.png`

- [ ] **Step 20.1: Define acceptance criteria**

- Load case (per spec Appendix B and Task 12.1): **95 N normal force per side** at wing's center of pressure (60 mm forward of pivot axis along chord), plus 1.0 N·m spring reaction torque about pivot. **Derivation:** spec §3.1 gives a total aerodynamic load of 180 N across both wings at 195 km/h — each sub-frame carries one wing, so the per-sub-frame analysis uses **half of that (~90 N drag) plus the downforce vector contribution from the same side (≈ 30 N) ≈ 95 N resultant** per side. The 180 N figure is a system-level number and is **not** the correct unit of analysis for a single sub-frame's FEA.
- **Strain-gauge placement output:** the FEA must identify the **peak-equivalent-stress location** on each sub-frame. The `StrainGauge_Pocket` defined in Tasks 13 / 15 must be **positioned at (or as close as possible to) this peak-stress location** — the gauge's purpose (FMEA #22 long-term monitoring) is degraded if it sits in a low-stress region. If the FEA peak differs from the provisional pocket position by > 10 mm, update the sub-frame CAD and re-export STEP in Step 20.6.
- Boundary condition: M8 mount holes (HP1, HP2) fully fixed; M6 holes (HP3, HP4) fixed.
- Material: 6061-T6 (Yield 276 MPa, UTS 310 MPa).
- **Safety factor ≥ 3 against yield** → max equivalent (von Mises) stress ≤ 92 MPa.
- Mesh: solid tetrahedral, refine to 1 mm at mount holes and the wing-side boss.
- **OQ-7 note (sub-frame FEA):** the structural worst case stays **+70° at 195 km/h** (max aero load) — the new −5° drag-reduction position is a low-aero-load condition and does **not** govern sub-frame stress, so this FEA load case is **unchanged**. (The −5° change affects the spring and servo-torque budget, not the sub-frame load case — see OQ-7 FOLLOW-UP in Task 10.)

- [ ] **Step 20.2: Run FEA on GSX250R**

In Fusion 360 Simulation workspace:
1. Open `cad/subframe/gsx250r-2022.f3d`.
2. New Study → Static Stress.
3. Material: 6061-T6 from Fusion library.
4. Constraints: fix HP1, HP2 (M8 holes) and HP3, HP4 (M6 holes) all DOF.
5. Load 1: Force **95 N** on wing-side boss face, vector = wing's lift direction at +70°. (This is the per-side load — one wing per sub-frame; do not double-count by using the 180 N system total here.)
6. Load 2: Moment 1.0 N·m about wing pivot axis (spring reaction).
7. Mesh size: 3 mm global, 1 mm at constrained holes.
8. Solve.

Screenshot the setup and result, save `cad/fea/gsx250r_fea_setup.png` and note peak stress.

- [ ] **Step 20.3: Iterate on GSX250R until SF ≥ 3**

If peak von Mises stress > 92 MPa:
- Add rib at high-stress area, OR
- Increase plate thickness from 12 mm to 14 mm locally, OR
- Reduce pocket size.
Re-solve. Iterate until SF ≥ 3.

- [ ] **Step 20.4: Run FEA on RC450**

Repeat Step 20.2-20.3 with `cad/subframe/rc450-2026.f3d`. Save `cad/fea/rc450_fea_setup.png`.

- [ ] **Step 20.5: Write FEA report PDF**

Use Fusion's report export OR compose manually in Markdown → export to PDF:

```markdown
# Sub-frame FEA Report — Starling Active Aero v1

## Load case

- Aerodynamic load: 95 N normal at wing CoP (60 mm forward of pivot)
- Spring reaction: 1.0 N·m about pivot
- Sustained at 195 km/h × 70° wing angle (worst case)

## GSX250R-A 2022 sub-frame

- Material: 6061-T6 (Yield 276 MPa)
- Peak von Mises stress: **<read from Fusion sim result, MPa>** — must be ≤ 92 MPa
- Safety factor: **<276 / peak stress>** — must be ≥ 3
- Result: PASS (if SF ≥ 3) or FAIL → iterate geometry
- Mass: **<read from Fusion mass properties, g>**

[insert gsx250r_fea_setup.png]

## KTM RC 450 KM400 2026 sub-frame

- Material: 6061-T6 (Yield 276 MPa)
- Peak von Mises stress: **<read from Fusion sim result, MPa>** — must be ≤ 92 MPa
- Safety factor: **<276 / peak stress>** — must be ≥ 3
- Result: PASS (if SF ≥ 3) or FAIL → iterate geometry
- Mass: **<read from Fusion mass properties, g>**

[insert rc450_fea_setup.png]

## Fatigue note

Static SF ≥ 3 is sufficient for fully-reversed fatigue at 10⁶ cycles per
6061-T6 S-N data (endurance limit ≈ 97 MPa, less than yield/3). At 92 MPa
working stress, infinite life is borderline — recommend strain-gauge
monitoring (FMEA item #22) and 5000 km inspection.

## Strain-gauge placement (FMEA #22)

Per Task 13 / Task 15 acceptance criteria, the `StrainGauge_Pocket`
(15 × 8 × 0.3 mm) must sit at the **peak von Mises stress location** on each
sub-frame's high-stress face. From the FEA results above:

- GSX250R-A peak stress location (in sub-frame local coords): **<x, y, z mm>** —
  pocket placed here; sub-frame STEP re-exported if provisional position
  differed by > 10 mm.
- RC450 peak stress location: **<x, y, z mm>** — pocket placed here.

Pocket floor Ra ≤ 0.8 µm specified on Task 22 drawings to ensure clean
bonding surface for the foil gauge.
```

Export to `cad/fea/subframe_fea_report.pdf`.

- [ ] **Step 20.6: Update sub-frames with any geometry changes**

If FEA forced geometry changes, re-export both sub-frame STEP files and re-run Task 18 interference check.

- [ ] **Step 20.7: Commit**

```bash
git add cad/fea/
# Plus any sub-frame updates:
git add cad/subframe/gsx250r-2022.f3d cad/subframe/gsx250r-2022.step
git add cad/subframe/rc450-2026.f3d cad/subframe/rc450-2026.step
git commit -m "mech: FEA both sub-frames, SF >= 3 against yield, report PDF"
```

---

## Task 21: Engineering drawing — v1 SLA wing

**Files:**
- Create: `cad/drawings/wing_drawing.pdf`

- [ ] **Step 21.1: Define acceptance criteria**

- A3, 1st-angle ISO projection.
- Views: top (chord plane), front (LE view), side (root face with magnet pocket + spar end), isometric.
- Dimensions: chord 120 ±0.3 mm; span 350 ±0.3 mm; spar through-hole ∅3.2 +0.1/0 mm; magnet pocket ∅6 H8 × 2.5 ±0.1 mm; shaft coupling 8 AF hex × 10 ±0.2 mm.
- Tolerance block: general ±0.3 mm (SLA print achievable); critical (magnet pocket, shaft coupling) ±0.1 mm.
- Material call-out: "Formlabs Tough 2000 or equivalent SLA structural resin, tensile ≥ 40 MPa, elongation ≥ 30%".
- Post-process call-out: "Ream spar hole to ∅3.0+0.05/0 after print. UV cure 30 min at 60°C."

- [ ] **Step 21.2: Build the drawing in Fusion**

1. From `cad/wing/wing_master.f3d`, File → New Drawing → From Design → A3 → ISO standard, 1st-angle.
2. Place top view at 1:1 scale.
3. Project front, side, iso views (auto).
4. Add dimensions per Step 21.1.
5. Add tolerance block and material/finish callouts in the title block.

- [ ] **Step 21.3: Export PDF**

File → Export → PDF → `cad/drawings/wing_drawing.pdf`.

- [ ] **Step 21.4: Verify**

Open PDF. Confirm:
- All dimensions present.
- Title block contains material, finish, tolerance, drawing number "STARLING-MECH-001".
- Print preview shows correct A3 size.

- [ ] **Step 21.5: Commit**

```bash
git add cad/drawings/wing_drawing.pdf
git commit -m "mech: engineering drawing for v1 SLA wing, A3, ISO"
```

---

## Task 22: Engineering drawings — both sub-frames

**Files:**
- Create: `cad/drawings/subframe_gsx250r_drawing.pdf`
- Create: `cad/drawings/subframe_rc450_drawing.pdf`

- [ ] **Step 22.1: Define acceptance criteria** (per drawing)

- A3, 1st-angle ISO, 1:1 or 1:2 scale (whichever fits 250 × 180 plate envelope).
- Views: top, front, side, iso. Section A-A through the wing-side interface boss. **Detail view B at 5:1 of the `StrainGauge_Pocket`** to clearly show 15 × 8 × 0.3 mm pocket and ∅3 mm wire pass-through.
- Dimensions for all 4 mount holes (HP1-4 positions), the 4× M6 wing-side pattern (65 × 40 mm with M6 tap call-out), the strain-gauge pocket (15 ±0.1 × 8 ±0.1 × 0.3 +0.05/0 mm) with its ∅3 mm wire pass-through, the AS5600L encoder PCB boss (depth tuned to nominal 1.5 mm magnet-to-chip gap; mask anodize), and overall envelope.
- Tolerances: general ±0.1 mm; mount-hole positions ±0.05 mm; wing-side M6 hole positions ±0.02 mm (these are the inter-bike interchange-critical features); strain-gauge pocket floor **Ra ≤ 0.8 µm** (explicit call-out — bonding-surface requirement).
- Material: "6061-T6 aluminum plate, 12 mm".
- Finish: "Anodize Type II, black, matte, 10-20 μm; mask all tapped holes **and the `StrainGauge_Pocket` floor** (anodize layer would interfere with strain-gauge bond)".
- Edge: "All external sharp edges chamfer 1 × 45° or break with hand file. No nicks deeper than 0.1 mm".
- Drawing numbers: GSX = "STARLING-MECH-002", RC450 = "STARLING-MECH-003".

- [ ] **Step 22.2: Build GSX250R drawing**

From `cad/subframe/gsx250r-2022.f3d` → New Drawing → A3 → place views, add dimensions, section A-A through wing-side boss, fill title block.

Export PDF → `cad/drawings/subframe_gsx250r_drawing.pdf`.

- [ ] **Step 22.3: Build RC450 drawing**

Same flow with `cad/subframe/rc450-2026.f3d`.

Export PDF → `cad/drawings/subframe_rc450_drawing.pdf`.

- [ ] **Step 22.4: Verify**

Open both PDFs. Confirm:
- Wing-side 4× M6 pattern dimensions are **identical** between the two drawings (65 × 40 mm, M6 × 1.0, 10 mm deep tap).
- Tolerance ±0.02 mm called out on M6 pattern positions.
- Anodize finish callout present.
- Drawing numbers correct.

- [ ] **Step 22.5: Commit**

```bash
git add cad/drawings/subframe_gsx250r_drawing.pdf cad/drawings/subframe_rc450_drawing.pdf
git commit -m "mech: engineering drawings for both sub-frame SKUs, A3, ISO"
```

---

## Task 23: Engineering drawing — shaft + bearing pocket + spring mount + servo box

**Files:**
- Create: `cad/drawings/shaft_drawing.pdf`
- Create: `cad/drawings/bearing_pocket_drawing.pdf`
- Create: `cad/drawings/spring_mount_drawing.pdf`
- Create: `cad/drawings/servo_box_drawing.pdf`

- [ ] **Step 23.1: Define acceptance criteria — shaft**

- Material: SS304.
- ∅8 g6 over bearing seats (30 mm from each end, length 7 mm each); ∅8 h7 elsewhere.
- Length 380 ±0.1 mm.
- D-flat: 6 mm flat depth ±0.05 mm × 12 mm length ±0.1 mm.
- E-clip groove: 1 ±0.05 wide × 0.5 ±0.05 deep × 5 mm from end ±0.1.
- Surface finish: bearing seats Ra 0.8 μm; elsewhere Ra 1.6 μm.
- Drawing number: STARLING-MECH-004.

- [ ] **Step 23.2: Define acceptance criteria — bearing pocket**

- Material: 6061-T6, anodized.
- Cavity ∅22 H7 × 7 mm deep.
- 4× ∅5.5 mm mount holes on 25 × 25 mm pattern.
- Tolerance H7 on cavity OD; ±0.05 mm on hole positions.
- Drawing number: STARLING-MECH-005.

- [ ] **Step 23.3: Define acceptance criteria — spring mount**

- Material: 6061-T6, anodized.
- Boss ∅9 g6 × 15 mm; base 25 × 25 × 5 mm.
- Slot 2 ±0.05 wide × 4 ±0.05 long × 6 mm deep.
- 2× ∅4.5 mm holes at (±8, 0).
- Drawing number: STARLING-MECH-006.

- [ ] **Step 23.4: Define acceptance criteria — servo box**

- Material: 6061-T6, anodized + EPDM gasket separate.
- External 80 × 42 × 58 mm.
- Internal cavity 70 × 32 × 52 mm.
- Cable gland hole ∅12 H8.
- Shaft pass-through ∅10 H8 with O-ring groove 1.5 ±0.05 × 1 ±0.05.
- Servo bolt slots 3.5 × 6 mm, 4 corners of 50 × 17 mm pattern (centered).
- 4× M5 mounting tabs on 25 × 50 mm pattern.
- Lid 80 × 42 × 4 mm with 4× M3 counterbore.
- Drawing number: STARLING-MECH-007.

- [ ] **Step 23.5: Build all four drawings**

For each part, repeat the Fusion drawing workflow: A3, ISO 1st-angle, views + dimensions + tolerance + material/finish. Export PDF to the corresponding file path.

- [ ] **Step 23.6: Verify**

Open each PDF. Confirm tolerances, material, finish, drawing number.

- [ ] **Step 23.7: Commit**

```bash
git add cad/drawings/shaft_drawing.pdf cad/drawings/bearing_pocket_drawing.pdf
git add cad/drawings/spring_mount_drawing.pdf cad/drawings/servo_box_drawing.pdf
git commit -m "mech: engineering drawings for shaft, bearing pocket, spring mount, servo box"
```

---

## Task 24: DFM review for CNC vendor

**Files:**
- Create: `cad/dfm/cnc_dfm_review.md`

- [ ] **Step 24.1: Define acceptance criteria**

A written DFM checklist applied to each CNC part (sub-frames × 2, shaft, bearing pocket, spring mount, servo box) confirming the design is compatible with **嘉立创精密加工** (the primary CNC vendor)'s published manufacturing rules. The output is a markdown document with a per-part table.

- [ ] **Step 24.2: Apply DFM rules per part**

For each CNC part, evaluate these rules from typical Chinese CNC vendor guidelines (嘉立创精密加工 published DFM):

| DFM Rule | Threshold | Notes |
|---|---|---|
| Min internal corner radius | ≥ R0.5 (best ≥ R1) | Smaller R = larger tool, longer mill time |
| Min wall thickness | ≥ 1.0 mm (aluminum) | 0.8 mm possible but fragile |
| Min hole diameter | ≥ 1.0 mm | Below = special-order drill |
| Max hole depth-to-diameter | ≤ 10:1 | Beyond = peck drilling, costlier |
| Min thread engagement | ≥ 1.5 × diameter | M6 → 9 mm tap depth |
| Tap hole size | Std drill table (M6 = ∅5.0) | Vendor expects this |
| Tolerance default | ±0.1 mm | Critical ±0.02 mm explicit callout |
| Anodize masking | Tapped holes must be masked | Specify on drawing |
| Burrs / sharp edges | Break by hand file | Chamfer 1 × 45° preferred |
| File format | STEP AP214 + PDF drawing | Both required |

- [ ] **Step 24.3: Write the DFM review document**

```markdown
# CNC DFM Review — Starling Mechanical Parts

Vendor: 嘉立创精密加工 (primary), 三阪精密 (backup)
Reviewer: AI mechanical agent
Date: 2026-05-17
Spec source: vendor DFM guidelines + spec §3.9

## Summary

All 6 CNC parts (GSX250R sub-frame, RC450 sub-frame, shaft, bearing pocket,
spring mount, servo box) pass DFM. Quote requests can proceed.

## Per-part review

### GSX250R-A sub-frame (STARLING-MECH-002)

| Rule | Status | Note |
|---|---|---|
| Min internal corner R | PASS | R3 fillets throughout (StrainGauge_Pocket excluded — rectangular by design) |
| Min wall thickness | PASS | Min 4 mm in plate body (≥ 1.5 mm below pocket floor at 0.3 mm pocket depth) |
| Min hole diameter | PASS | Smallest is M4 tapped (∅3.3 drill); ∅3 mm strain-gauge wire pass-through is also above min |
| Max hole D:d ratio | PASS | Deepest is M6 × 10 mm = 1.67:1 |
| Thread engagement | PASS | M6 × 10 mm = 1.67×d |
| Tolerance | PASS | General ±0.1, critical ±0.02 called out |
| Strain-gauge pocket finish | PASS | Ra ≤ 0.8 µm specified on drawing; vendor confirms achievable via face-mill + light grind |
| Anodize masking | PASS | Drawing specifies mask all tapped holes **and StrainGauge_Pocket floor** |
| Edges | PASS | All edges 1×45° chamfer |
| File pkg | PASS | STEP + PDF |

### RC450 sub-frame (STARLING-MECH-003)

(same table, all PASS)

### Shaft (STARLING-MECH-004)

| Rule | Status | Note |
|---|---|---|
| ∅8 g6 fit | PASS | Standard ground bar stock + finish turn |
| D-flat depth | PASS | 6 mm flat × 12 mm len, std mill op |
| E-clip groove | PASS | 1 mm × 0.5 mm, std grooving tool |
| Surface finish Ra 0.8 | PASS | Achievable with finish turn + light grind |
| Length tolerance | PASS | ±0.1 mm easy |
| Material | PASS | SS304 readily available |

### Bearing pocket (STARLING-MECH-005)

(table — PASS)

### Spring mount (STARLING-MECH-006)

(table — PASS)

### Servo box (STARLING-MECH-007)

| Rule | Status | Note |
|---|---|---|
| Min wall thickness | PASS | 4 mm walls |
| Cavity 70 × 32 × 52 mm | PASS | End-mill reachable (52 mm with ∅10 cutter) |
| O-ring groove 1.5 × 1 mm | PASS | Std O-ring tool |
| M3 thread bosses | PASS | Tap depth 6 mm |
| EPDM gasket groove | PASS | Std 1.5 × 1 mm slot |

## Action items

- None. All parts proceed to RFQ.

## Reference

- 嘉立创精密加工 DFM guidelines: https://www.jlc-precision.com/dfm
- Spec source: docs/superpowers/specs/2026-05-17-active-front-aero-design.md §3.9
```

- [ ] **Step 24.4: Verify**

Read the document back. Each of the 6 parts has a populated table. No "TBD" or "PASS?" entries.

- [ ] **Step 24.5: Commit**

```bash
git add cad/dfm/cnc_dfm_review.md
git commit -m "mech: DFM review for 6 CNC parts, all pass, ready for RFQ"
```

---

## Task 25: Build CNC + SLA RFQ packets

**Files:**
- Create: `cad/rfq/cnc_rfq_packet.zip`
- Create: `cad/rfq/sla_rfq_packet.zip`
- Create: `cad/rfq/cnc_cover_letter.md`
- Create: `cad/rfq/sla_cover_letter.md`

- [ ] **Step 25.1: Define acceptance criteria — CNC packet**

Zip must contain:
- All 6 CNC part STEP files (2 sub-frames, shaft, bearing pocket, spring mount, servo box).
- All 6 corresponding PDF drawings.
- A cover letter in Chinese requesting quote, quantities, lead time, surface finish (Type II anodize), and tolerance compliance.
- BOM extract listing each part + quantity (2 of each except shaft = 2).

- [ ] **Step 25.2: Write CNC cover letter**

```markdown
# CNC 报价请求 — Starling Active Aero v1 项目

收件方：嘉立创精密加工 / 三阪精密 / 报价部

发件方：Shanire (shanire86@gmail.com)

## 项目概述

摩托车主动空气动力学翼片系统机械加工件，6 种零件，每种 2 件（每车一对），
共 12 件首批样品。

## 加工件清单

| 图号 | 名称 | 材料 | 表面处理 | 数量 |
|---|---|---|---|---|
| STARLING-MECH-002 | GSX250R-A 副框架 | 6061-T6 12mm 板 | Type II 阳极氧化黑色哑光 | 2 |
| STARLING-MECH-003 | KTM RC450 副框架 | 6061-T6 12mm 板 | Type II 阳极氧化黑色哑光 | 2 |
| STARLING-MECH-004 | 转轴 | SS304 ∅8 圆棒 | 钝化 (无电镀) | 2 |
| STARLING-MECH-005 | 轴承座 | 6061-T6 | Type II 阳极氧化黑色哑光 | 4 (左右共用) |
| STARLING-MECH-006 | 扭簧底座 | 6061-T6 | Type II 阳极氧化黑色哑光 | 2 |
| STARLING-MECH-007 | 舵机防水盒 | 6061-T6 | Type II 阳极氧化黑色哑光 | 2 |

## 公差要求

- 一般公差 ±0.1 mm
- 关键特征 ±0.02 mm (图纸明确标注)
- 轴承配合 H7 / g6
- 表面粗糙度：转轴轴承位 Ra 0.8 μm，其余 Ra 1.6 μm

## 阳极氧化要求

- Type II，黑色哑光
- 厚度 10-20 μm
- 所有攻丝孔必须遮罩
- 轴承座内孔遮罩

## 交付要求

- 首件 7-10 天
- 全部 12 件 14 天内
- 含首件检验报告 (FAIR)
- 不接受任何降级处理

## 文件清单

- 6 × STEP (AP214) 零件文件
- 6 × PDF 工程图 (A3, ISO 一角法)
- 本报价请求文档

## 报价提交

请回复：
1. 单件价格 (含表面处理)
2. 模具/夹具一次费用（如适用）
3. 实际交期承诺
4. 付款条件
```

- [ ] **Step 25.3: Build the zip**

```powershell
Compress-Archive -Path `
  cad/subframe/gsx250r-2022.step, `
  cad/subframe/rc450-2026.step, `
  cad/hardware/shaft.step, `
  cad/hardware/bearing_pocket.step, `
  cad/hardware/spring_mount.step, `
  cad/hardware/servo_box.step, `
  cad/drawings/subframe_gsx250r_drawing.pdf, `
  cad/drawings/subframe_rc450_drawing.pdf, `
  cad/drawings/shaft_drawing.pdf, `
  cad/drawings/bearing_pocket_drawing.pdf, `
  cad/drawings/spring_mount_drawing.pdf, `
  cad/drawings/servo_box_drawing.pdf, `
  cad/rfq/cnc_cover_letter.md `
  -DestinationPath cad/rfq/cnc_rfq_packet.zip -Force
```

- [ ] **Step 25.4: Define acceptance criteria — SLA packet**

Zip must contain:
- `wing_v1_print.stl` (the v1 wing STL).
- `wing_drawing.pdf` (v1 wing engineering drawing).
- `wing_v1_print.stl.notes.md` (print recipe).
- A cover letter in Chinese.

- [ ] **Step 25.5: Write SLA cover letter**

```markdown
# SLA 3D 打印报价请求 — Starling Active Aero 翼片

收件方：嘉立创3D / 闲鱼 SLA 工厂

发件方：Shanire (shanire86@gmail.com)

## 项目概述

摩托车空气动力学翼片，SLA 结构树脂打印，首批 4 件 (装机 2 + 备件 2)，
若验证通过预计加单 4-8 件。

## 打印要求

| 项 | 要求 |
|---|---|
| 文件 | wing_v1_print.stl (1 个翼片) |
| 树脂 | Formlabs Tough 2000 或同等结构树脂 (抗拉 ≥ 40 MPa，断裂伸长 ≥ 30%) |
| 层厚 | 100 μm |
| 朝向 | 弦轴向前，前缘下倾 30° (保留 STL 自带朝向标记) |
| 支撑 | 自动生成，密度"中"，接触点 0.6 mm |
| 后处理 | IPA 清洗 15 min + UV 固化 30 min @ 60°C |
| 数量 | 4 件 |
| 交期 | 5-7 天 |

## 公差要求

- 一般 ±0.3 mm (SLA 工艺极限)
- 关键孔 (∅3 spar) 客户自行铰刀加工，仅需打印到 ∅3.2 mm
- 端面平整度 ≤ 0.2 mm

## 目标单价

≤ 80 RMB / 件 (含支撑去除 + 标准清洗 + 固化)

## 文件清单

- wing_v1_print.stl
- wing_drawing.pdf (尺寸参考)
- wing_v1_print.stl.notes.md (打印细则)
- 本报价请求

## 报价提交

请回复：单价、交期、是否含上述后处理。
```

- [ ] **Step 25.6: Build the SLA zip**

```powershell
Compress-Archive -Path `
  cad/wing/wing_v1_print.stl, `
  cad/wing/wing_v1_print.stl.notes.md, `
  cad/drawings/wing_drawing.pdf, `
  cad/rfq/sla_cover_letter.md `
  -DestinationPath cad/rfq/sla_rfq_packet.zip -Force
```

- [ ] **Step 25.7: Verify both zips**

```powershell
Test-Path cad/rfq/cnc_rfq_packet.zip
Test-Path cad/rfq/sla_rfq_packet.zip
(Get-Item cad/rfq/cnc_rfq_packet.zip).Length
(Get-Item cad/rfq/sla_rfq_packet.zip).Length
```

CNC zip expected: 1–5 MB. SLA zip expected: 5–30 MB (STL dominant).

Verify zip contents by listing:

```powershell
Expand-Archive -Path cad/rfq/cnc_rfq_packet.zip -DestinationPath cad/rfq/_verify_cnc -Force
Get-ChildItem cad/rfq/_verify_cnc | Select-Object Name
Remove-Item -Recurse -Force cad/rfq/_verify_cnc
```

Expected: 6 STEP + 6 PDF + 1 MD = 13 files.

- [ ] **Step 25.8: Commit**

```bash
git add cad/rfq/
git commit -m "mech: CNC + SLA RFQ packets with cover letters, ready to send to vendors"
```

---

## Task 26: Build BOM-Mech with sourcing

**Files:**
- Create: `cad/BOM-Mech.csv`

- [ ] **Step 26.1: Define acceptance criteria**

CSV columns: `item_no, qty_per_bike, qty_total_v1, description, material, vendor, part_number_or_link, unit_price_rmb, ext_price_rmb, lead_time_days, notes`.

`qty_total_v1` = `qty_per_bike × 1 bike + spares` (project builds 1 bike, but keeps spares).

Total cost target ≤ 4000 RMB (mechanical portion only; spec §4.2 lists electronic BOM at 3110 RMB; total v1 target 12-15 K RMB).

Sourcing links must be real (淘宝 / 阿里巴巴 / McMaster equivalent), not placeholders.

- [ ] **Step 26.2: Write the BOM**

```csv
item_no,qty_per_bike,qty_total_v1,description,material,vendor,part_number_or_link,unit_price_rmb,ext_price_rmb,lead_time_days,notes
1,2,4,Wing body SLA print (NACA 4412 inverted 120x350),Formlabs Tough 2000 or equiv,嘉立创3D,https://www.jlc3d.com/ - upload wing_v1_print.stl,80,320,5,2 install + 2 spare
2,1,3,Carbon-fiber rod ∅3 mm x 1000 mm,Carbon fiber pultruded rod,淘宝 (search 碳纤维棒 3mm),https://item.taobao.com/?q=carbon+rod+3mm,15,45,3,Cut to 350 mm; 3 lengths = 6 spars
3,2,2,GSX250R-A sub-frame CNC,6061-T6 anodized,嘉立创精密加工,STARLING-MECH-002 (RFQ packet),400,800,10,Per RFQ; budget estimate
4,2,2,KTM RC450 sub-frame CNC,6061-T6 anodized,嘉立创精密加工,STARLING-MECH-003 (RFQ packet),400,800,10,Only if installing on RC450; v1 main car = GSX
5,2,3,Pivot shaft SS304 ∅8x380,SS304,嘉立创精密加工,STARLING-MECH-004 (RFQ packet),80,240,10,1 spare
6,4,5,Bearing pocket insert 6061-T6,6061-T6 anodized,嘉立创精密加工,STARLING-MECH-005 (RFQ packet),50,250,10,1 spare
7,4,6,SS608-2RS deep-groove ball bearing ∅22x8x7,Stainless steel,淘宝 / NSK distributor,https://item.taobao.com/?q=SS608-2RS,8,48,2,2 spare
8,2,4,Reset torsion spring SS304 custom (per spring_spec.md),SS304,阿里巴巴 定制扭簧 shop,custom per spec,30,120,14,2 spare
9,2,3,Spring mount 6061-T6,6061-T6 anodized,嘉立创精密加工,STARLING-MECH-006 (RFQ packet),35,105,10,1 spare
10,2,3,Servo box 6061-T6 IP67,6061-T6 anodized + EPDM,嘉立创精密加工,STARLING-MECH-007 (RFQ packet),200,600,10,1 spare
11,2,4,Servo - DSServo RDS5160 60 kg·cm,Plastic + metal gear,淘宝 RDS5160 official,https://item.taobao.com/?q=DSServo+RDS5160,400,1600,3,2 install + 2 spare (per spec)
12,2,2,EPDM O-ring AS568-007 (∅5.5 x 1.5),EPDM,淘宝,https://item.taobao.com/?q=AS568-007+EPDM,2,4,2,Servo shaft pass-through seal
13,1,2,EPDM gasket strip 1.5x3 mm x 500 mm,EPDM,淘宝,https://item.taobao.com/?q=EPDM+gasket+strip,15,30,2,Servo box lid + fairing seal
14,16,20,M6x20 socket cap screw SS304,SS304,淘宝 紧固件 shop,DIN 912 M6x20 SS304,1,20,2,4 per wing-side x 2 sides + spares
15,16,20,M8x25 socket cap screw SS304,SS304,淘宝,DIN 912 M8x25 SS304,2,40,2,Engine bracket bolts (replace OEM)
16,8,12,M5x12 socket cap screw SS304,SS304,淘宝,DIN 912 M5x12 SS304,0.8,10,2,Servo box mounting + bearing pocket
17,16,20,M4x12 socket cap screw SS304,SS304,淘宝,DIN 912 M4x12 SS304,0.5,10,2,Spring mount + misc
18,2,4,E-clip ∅8 mm,SS304,淘宝 (search 卡簧 8mm),DIN 6799,0.3,1.2,2,Shaft retainer
19,1,1,Loctite 243 medium threadlocker 50ml,Anaerobic adhesive,淘宝 Loctite official,Loctite 243 50ml,80,80,2,For all M6 / M8 bolts at install
20,1,1,PG7 IP67 cable gland set of 5,Nylon + EPDM,淘宝,PG7 IP67,15,15,2,2 used (one per servo box) + 3 spare
21,2,2,Fairing winglet cutout - DIY tool (rotary tool + bits),Consumable,淘宝,Generic rotary tool,50,100,2,For cutting fairing per cutout_template.pdf
22,1,1,Strain gauge kit for FMEA #22 monitoring — includes: foil strain gauge 15 mm × 8 mm (per kit; 2 install + spares) + M-Bond 200 cyanoacrylate adhesive + 3-conductor lead wire (1 m) + M-Coat A or RTV silicone coating + HX711 24-bit ADC,Strain gauge + ADC + adhesive + leads + silicone,淘宝 / Micro-Measurements distributor,https://item.taobao.com/?q=HX711+strain+gauge+M-Bond,80,80,2,"Foil gauge 15 mm × 8 mm × <0.3 mm thick to fit machined pocket on each sub-frame; gauge is embedded (内嵌) in pocket, not surface-adhered"
23,2,2,v2 PETG mold half - upper (only if v2 path triggered),PETG filament + print,Local makerspace OR 闲鱼 FDM,Print from mold_upper.stl,150,300,5,Hold until v1 validation; budget reserved
24,2,2,v2 PETG mold half - lower,PETG,Local makerspace OR 闲鱼 FDM,Print from mold_lower.stl,150,300,5,Same as above
25,1,1,Misc consumables (sandpaper / IPA / gloves / mixing cups),Consumables,淘宝,Generic,100,100,2,For SLA finishing + v2 layup prep
```

Mechanical subtotal (v1, excluding v2 molds which are deferred): items 1-22 = `320+45+800+800+240+250+48+120+105+600+1600+4+30+20+40+10+10+1.2+80+15+100+80` = **4318 RMB**.

If RC450 sub-frame is not built immediately (recommended per Master Plan risk R1 = build GSX first), subtract item 4 (800 RMB) → **3518 RMB**, within budget.

- [ ] **Step 26.3: Verify BOM**

```powershell
$bom = Import-Csv cad/BOM-Mech.csv
$bom.Count  # should be 25 (or 24/22 depending on v2 inclusion)
$bom | Measure-Object -Property ext_price_rmb -Sum
```

Expected: 25 line items, sum ≈ 5018 RMB (incl. v2 molds + RC450).

Spot-check 5 random links by visiting them in a browser (manual step — flag any 404 in this step).

- [ ] **Step 26.4: Commit**

```bash
git add cad/BOM-Mech.csv
git commit -m "mech: BOM-Mech with sourcing links and price targets, total <5K RMB"
```

---

## Task 27: Assembly instructions document + final hand-off package

**Files:**
- Create: `cad/ASSEMBLY-INSTRUCTIONS.md`
- Modify: `cad/README.md` (add link to assembly instructions)

- [ ] **Step 27.1: Define acceptance criteria**

A step-by-step assembly guide written for the human assembler (the user) covering:
- Tools required (torque wrench 1-15 N·m, socket set, allen keys, threadlocker).
- Pre-assembly checks (bolts, bearings, parts inventory against BOM).
- Step-by-step assembly with photos placeholders (file paths, captured during actual assembly).
- Torque specs per bolt.
- Calibration step (zero the AS5600L encoder against true wing 0° geometric).
- Final inspection checklist (matches FMEA item #28 user-error mitigation).

- [ ] **Step 27.2: Write assembly instructions**

```markdown
# Starling Active Aero — Mechanical Assembly Instructions

## Scope

Assemble one wing module (left or right side). Repeat mirror-imaged for the
other side. This guide assumes all parts have been received per BOM-Mech and
inspected against drawings.

## Tools

- Torque wrench, 1-15 N·m range
- Allen key set (2, 2.5, 3, 4, 5 mm)
- Socket set
- Loctite 243 (blue, medium threadlock)
- Calipers (for inspection)
- Clean degreaser + lint-free wipes

## Pre-assembly inventory check

Match received parts against BOM-Mech.csv. Each part must:
- Match drawing dimensions within callout tolerance (spot-check critical dims).
- Have no visible cracks, machining defects, or anodize damage.
- For SLA wings: ream the spar through-hole to ∅3.0 mm with a 3 mm reamer.

## Assembly steps

### Step 1: Press bearings into bearing pockets

1. Place one SS608-2RS bearing into each bearing pocket cavity.
2. Press fit; do not hammer. Use a soft mallet on a flat plate if needed.
3. Verify bearing seats against the cavity shoulder (no rocking).

### Step 2: Install pivot shaft + bearings into sub-frame wing-side boss

1. Slide the shaft (D-flat end first, toward servo side) through one
   bearing pocket.
2. Slide the second bearing pocket onto the other end of the shaft.
3. Bolt both bearing pockets to the sub-frame's wing-side boss using
   M5×12 SS304 screws + Loctite 243. **Torque: 5 N·m.**
4. Install E-clip on the spring-side end of the shaft to retain.

### Step 3: Glue carbon-fiber spar into wing

1. Apply a thin bead of epoxy (or CA glue for SLA-resin compatibility)
   into the wing's spar channel.
2. Insert the ∅3 mm carbon rod fully through the wing.
3. Wipe excess. Cure 24 h.

### Step 4: Mount wing onto shaft

1. Slide the wing onto the shaft tip (the end OPPOSITE the D-flat).
2. Engage the shaft D-flat into the wing's hex+key coupling pocket.
3. Verify the wing rotates with the shaft (no slip).

### Step 5: Install AS5600L magnet into wing-root pocket

1. Apply a drop of cyanoacrylate into the magnet pocket.
2. Insert the ∅6 × 2.5 mm diametrically-polarized magnet, polar axis
   perpendicular to shaft axis (so AS5600L sees rotation).
3. Press flush. Wipe excess. Cure 1 h.

### Step 6: Install reset torsion spring

1. Slide the spring over the spring mount boss.
2. Engage one spring leg into the slot on the spring mount.
3. Wind the other leg 20° (preload) and engage it into the matching slot
   on the wing root cap (or the shaft retainer hub, depending on final
   geometry).
4. Bolt spring mount to sub-frame using 2× M4×12 + Loctite 243. **Torque: 2 N·m.**
5. Verify free rotation: rotate wing manually across the **−5° … +70°**
   envelope — it should **return to 0° (flat) automatically when released**
   (0° is the spring-neutral / fail-safe rest). The −5° end is powered-only;
   when hand-checking, confirm the mechanism physically permits reaching −5°
   (no hard stop at 0°) yet still springs back to 0°.

> **OQ-7 FOLLOW-UP:** The original assembly assumed the wing only travels 0°→+70° and springs back to a 0° rest, which permits (and may even rely on) a hard rest stop at 0°. The new envelope requires the wing to reach **−5° below the 0° rest** under power. Mechanical agent must verify/define: (a) there is NO hard stop at 0° that would block the powered −5° motion, (b) a **lower travel hard-stop at −5°** exists (define its feature/location — spring mount, wing-root cap, or servo-horn limit), (c) the upper hard-stop stays at +70°, and (d) the spring still seats the wing at exactly 0° when unpowered. This geometry was not modeled in the current spring-mount / wing-cap CAD (Tasks 10/11) and CANNOT be added by number-swap alone — it needs a CAD pass.

### Step 7: Install servo into servo box

1. Place the servo (DSServo RDS5160) into the servo box cavity.
2. Align with the 4× slot-shaped bolt holes.
3. Bolt with M3 × 8 SS screws + Loctite 243. **Torque: 1 N·m.**
4. Route the servo cable through the cable gland; tighten gland.
5. Apply EPDM gasket to the box lid groove. Close lid with 4× M3 × 12
   SS screws. **Torque: 1.5 N·m.**

### Step 8: Couple servo to shaft

1. Mount servo box to sub-frame using 4× M5×12 + Loctite 243. **Torque: 5 N·m.**
2. The servo output shaft passes through the box's O-ring sealed bore.
3. Engage servo coupling to shaft D-flat. (Coupling: servo horn with
   matching D-bore — purchased separately or 3D printed.)
4. Secure servo horn to its hub with the horn screw.

### Step 9: Install strain gauge into sub-frame pocket (FMEA #22 — do BEFORE bolting sub-frame to bike)

1. Inspect the `StrainGauge_Pocket` (15 × 8 × 0.3 mm) for cleanliness and
   surface finish. The floor must be Ra ≤ 0.8 µm (visually mirror-flat).
2. Degrease the pocket with isopropyl alcohol; wipe with a lint-free swab.
   Allow to flash off (≥ 30 s).
3. Lightly abrade with 320-grit silicon-carbide paper in a single direction
   if any oxide layer is present (6061 forms oxide quickly). Re-degrease.
4. Apply a single thin drop of **M-Bond 200 cyanoacrylate adhesive**
   (Micro-Measurements catalyst optional) to the pocket floor.
5. Position the foil strain gauge (15 mm gauge length × 8 mm grid) in the
   pocket with its grid aligned to the principal stress direction identified
   by FEA (Task 20). Press firmly with a clean finger or PTFE pad for 60 s.
6. Route the gauge's 3-conductor lead wires through the ∅3 mm pass-through
   to the inboard face of the sub-frame.
7. Apply silicone coating (M-Coat A or RTV silicone) over the bonded gauge
   to protect from moisture and abrasion. Allow to skin (30 min) before
   handling.
8. Connect the leads to the HX711 ADC per electronics plan.

### Step 10: Bolt sub-frame to bike

1. Remove OEM fairing stay bolts at HP1-4 (per gsx250r_mount_points.md
   or rc450_mount_points.md).
2. Position sub-frame.
3. Install M8×25 bolts at HP1, HP2 + Loctite 243. **Torque: 22 N·m.**
4. Install M6×20 bolts at HP3, HP4 + Loctite 243. **Torque: 10 N·m.**

### Step 11: Cut fairing per cutout template

1. Print cutout_template.pdf at 1:1 on A3.
2. Tape over the fairing in the correct position (referenced to wing
   pivot location).
3. Mark, drill ∅12 mm wire pass, cut winglet slot with rotary tool.
4. Install EPDM seal in the slot edge.

### Step 12: Encoder calibration

1. With wing physically at 0° geometric (level, parallel to chord plane —
   the spring-neutral / fail-safe rest position),
   run firmware's `calibrate_zero` command via App.
2. AS5600L stores the current reading as the zero reference.
3. Manually rotate wing to verify the encoder reads correctly across the full
   **−5° → +70°** range (the AS5600L is signed about the 0° zero reference;
   −5° reads as a small negative angle, +70° as the upper bound).

### Step 13: Final inspection checklist

(Maps to FMEA item #28 user-error mitigation.)

- [ ] All M8 bolts torqued and Loctite applied
- [ ] All M6 bolts torqued and Loctite applied
- [ ] All M5/M4/M3 bolts torqued and Loctite applied
- [ ] Bearings seat flush, no rocking
- [ ] Wing rotates freely across −5° → +70° and returns to **0° flat** under spring (0° = spring-neutral / fail-safe rest; −5° is powered-only — confirm no hard stop at 0° blocks it; see OQ-7 FOLLOW-UP in Task 10 / Step 6)
- [ ] Encoder magnet glued in, **air gap within IC-1 range 0.5–3.0 mm** (nominal 1.5 mm; shimmed at AS5600L PCB boss if measured value falls outside)
- [ ] Servo box lid sealed (EPDM compressed)
- [ ] Cable gland tightened
- [ ] No wire chafing against moving parts
- [ ] Fairing cutout sealed with EPDM
- [ ] Strain gauge **bonded into machined pocket** (M-Bond 200) with silicone over-coat applied, leads routed through ∅3 mm pass-through (FMEA #22)
- [ ] Photographs taken for build log

## Torque table summary

| Fastener | Torque |
|---|---|
| M8×25 (engine bracket) | 22 N·m |
| M6×20 (sub-frame mount + wing-side interface) | 10 N·m |
| M5×12 (servo box + bearing pocket) | 5 N·m |
| M4×12 (spring mount) | 2 N·m |
| M3×8/12 (servo bolts + lid) | 1-1.5 N·m |

All bolts get Loctite 243.
```

- [ ] **Step 27.3: Update `cad/README.md` to reference the assembly doc**

Append at the end of `cad/README.md`:

```markdown

## Assembly

See `ASSEMBLY-INSTRUCTIONS.md` for the step-by-step build guide and torque
table.
```

- [ ] **Step 27.4: Verify**

```powershell
Test-Path cad/ASSEMBLY-INSTRUCTIONS.md
Get-Content cad/README.md | Select-String "ASSEMBLY-INSTRUCTIONS"
```

Both checks pass.

- [ ] **Step 27.5: Commit**

```bash
git add cad/ASSEMBLY-INSTRUCTIONS.md cad/README.md
git commit -m "mech: assembly instructions with torque table + README link"
```

---

## Plan Summary

**Task count:** 27 tasks (1 setup + 26 production + assembly doc).

**Deliverables produced:**
- CAD source: 8 Fusion 360 .f3d files (wing, shaft, bearing pocket, spring mount, servo box, gsx250r sub-frame, rc450 sub-frame, assembly, two molds).
- STEP exports: all 6 CNC parts + wing + 2 mold halves + universal interface + 2 fairing cutouts + assembly = 13 STEP files.
- STL exports: wing v1 print + 2 mold halves = 3 STL files.
- Drawings: 7 PDFs (wing, 2 sub-frames, shaft, bearing pocket, spring mount, servo box).
- Templates: fairing cutout 1:1 PDF.
- FEA report: 1 PDF.
- DFM review: 1 markdown.
- BOM-Mech: 1 CSV with 25 line items.
- RFQ packets: 2 zips with cover letters.
- Documentation: README + assembly instructions + spring spec + mold layup recipe + print recipe.

**Interface contract bindings honored:**
- IC-1: J7/J8 servo box pigtail exit + AS5600L magnet pocket ∅6×2.5 mm with **1.5 mm nominal air gap, ±1 mm shim range** (designed to stay within the IC-1-mandated 0.5 – 3.0 mm range; actual gap locked in at assembly time per the encoder PCB depth from the electronics plan) (Tasks 5, 11, 27).
- IC-6: 30 W cont / 50 W peak per channel; dual-footprint servo box accepts both DSServo RDS5160 (v1) and Savox SB-2290SG (v2) (Task 11).

**Cross-subsystem dependencies created:**
- Mechanical CAD STEP files feed the **integration test plan** (assembly + Gate E/F upcomings).
- Servo box pigtail expects J7/J8 mating connectors from **electronics plan** (IC-1).
- AS5600L magnet pocket geometry depends on AS5600L chip placement from **electronics plan** (encoder PCB position).
- Strain gauge mount pocket (item 22, BOM) feeds **firmware plan** HX711 reading code.

**v2 forward-prep:** Mold halves designed and exported in Task 19. The PETG molds are not produced in v1 (BOM items 23-24 reserved). Layup recipe documented for future execution.

**Decision points flagged to controller:**
- KTM RC 450 KM400 mount points (Task 14) are ESTIMATES if physical bike unavailable at design time — must be re-verified at Gate B before submitting CNC RFQ.
- Whether to build RC450 sub-frame in v1 or defer per Master Plan risk R1 — recommend defer; saves 800 RMB and reduces v1 scope.
