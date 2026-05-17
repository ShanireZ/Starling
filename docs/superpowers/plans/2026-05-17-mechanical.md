# Mechanical Subsystem Plan — Starling Active Aero v1

> **Status:** Empty template. To be filled by `writing-plans`-dispatched subagent.
> **Master plan:** [`2026-05-17-active-aero-v1-master.md`](2026-05-17-active-aero-v1-master.md)
> **Source spec:** [`../specs/2026-05-17-active-front-aero-design.md`](../specs/2026-05-17-active-front-aero-design.md) §§ 3, 3.8, 3.9

**Goal:** Deliver CAD-ready (STEP/STL) wing + dual-SKU sub-frames + mechanical assembly drawings + BOM-Mech, suitable for direct submission to a CNC house and 3D printing service. v1 wings produced via SLA; v2 path via 3D-printed PETG molds + carbon-fiber hand layup is designed concurrently.

**Bound by these Interface Contracts (from master plan):**
- **IC-1** — Physical / electrical connectors and MCU pin map (only the J7/J8 servo connector pair and the AS5600 encoder magnet pocket geometry concern mechanical)
- **IC-6** — Power budget (servo selection must respect 30 W continuous per channel, 50 W peak; mechanical sizing must permit this servo class)

**Tech stack:**
- CAD: Fusion 360 (preferred) or FreeCAD (fallback for open-source mirror)
- Airfoil generator: XFoil-style NACA 4412 coordinate generation (Python: `naca4` library or hand-derived)
- 3D printing: SLA (Formlabs Tough 2000 or vendor equivalent) for v1 wings; FDM PETG for v2 molds
- CNC: 6061-T6 aluminum, anodized; vendor candidates: 嘉立创精密 / 三阪 / 闲鱼 small-batch shops
- Hardware: stainless steel SS304 torsion springs (custom), SS6201 deep-groove ball bearings, M6 stainless socket cap screws + Loctite 243

**Files this plan will create or modify:**
- `cad/wing/NACA4412_inverted.step` — wing 3D model (v1: solid for SLA print)
- `cad/wing/wing_v1_print.stl` — v1 print file
- `cad/wing/mold_upper.step` + `mold_lower.step` — v2 PETG mold halves
- `cad/subframe/gsx250r-2022.step` — GSX250R sub-frame CAD
- `cad/subframe/rc450-2026.step` — RC450 sub-frame CAD
- `cad/assembly/master.step` — full assembly with wing + servo + spring + sub-frame
- `cad/drawings/*.pdf` — engineering drawings for each part
- `cad/airfoil/naca4412_coords.csv` — wing coordinate table
- `cad/BOM-Mech.csv` — mechanical bill of materials with sourcing links
- `cad/README.md` — CAD organization + DFM notes for CNC house

**Scope (~25 tasks expected):**
1. Airfoil coordinate generation (NACA 4412 mathematical definition → CSV)
2. 2D wing profile sketch in Fusion 360 (loft-ready)
3. 3D wing body extrusion + structural carbon-rod channel
4. Wing pivot shaft + bearing pocket + servo coupling
5. Reset torsion spring sizing + spring mount pocket
6. Wing v1 SLA print prep (orientation, supports, draining)
7. v2 mold half design (upper / lower split + ejection draft)
8. GSX250R sub-frame design (走原车安装点)
9. RC450 sub-frame design
10. 4-bolt universal interface between sub-frame and wing module
11. Fairing cutout template (paper or CAD-derived)
12. Servo enclosure (IP67 box for servos)
13. Full assembly + interference check
14. FEA stress check on sub-frame (safety factor ≥ 3)
15. Engineering drawings for each part (mfg-ready)
16. DFM review pass per CNC vendor guidelines
17. STEP / STL export with proper tolerances
18. BOM-Mech with sourcing links + price targets
19. CNC vendor RFQ packet preparation
20. SLA print vendor RFQ packet preparation
21. Strain gauge mount pocket (for FMEA item #22 long-term monitoring)
22. Spring procurement (custom 不锈钢 304 torsion spring)
23. Bearing + shaft + hardware procurement
24. Assembly instructions document (步骤照片)
25. Hand-off package zip (everything an assembly agent or human needs)

---

**To the dispatched writing-plans subagent:** Generate ~25 bite-sized tasks following the writing-plans skill format. Each task must specify exact file paths, complete content for that step (no "TBD" placeholders), and committable units. The implementer for mechanical tasks will primarily produce CAD files and engineering documents — adapt the TDD pattern to "specify acceptance criteria + generate file + verify file opens cleanly + verify dimensions". Reference the master plan IC-1 / IC-6 for any contract-relevant details.
