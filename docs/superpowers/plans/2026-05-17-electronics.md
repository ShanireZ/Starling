# Electronics Subsystem Plan — Starling Active Aero v1

> **Status:** Empty template. To be filled by `writing-plans`-dispatched subagent.
> **Master plan:** [`2026-05-17-active-aero-v1-master.md`](2026-05-17-active-aero-v1-master.md)
> **Source spec:** [`../specs/2026-05-17-active-front-aero-design.md`](../specs/2026-05-17-active-front-aero-design.md) § 4

**Goal:** Deliver KiCad project + Gerber files + BOM-Elec + pick-place + DFM-clean board ready for JLCPCB SMT assembly. 100×120 mm 2-layer FR4, fully populated SMT (ESP32-WROOM-32E soldered directly, no DevKit-style headers), suitable for motorcycle vibration environment.

**Bound by these Interface Contracts (from master plan):**
- **IC-1** — Physical connectors (J1-J10 layout + pinout) and MCU pin map. *Every PCB net must match IC-1 exactly. Pin re-assignment requires master plan revision.*
- **IC-2** — BLE GATT (drives ESP32-S3 capability requirements — must use ESP32-S3 variant for BLE 5 + Wi-Fi STA combo)
- **IC-6** — Power budget (servo rail 8 A; MCU rail 3 A; PD trigger 9V/5A negotiation)

**Tech stack:**
- ECAD: KiCad 8.x (open source, free, well-supported by JLCPCB)
- Schematic capture: KiCad EEschema
- PCB layout: KiCad PcbNew (2-layer, mixed signal — keep digital and servo power isolated)
- DRC: KiCad built-in + JLCPCB's online DFM checker
- BOM tool: KiCad → InteractiveHtmlBom plugin → JLCPCB-compatible CSV
- Symbol/footprint libraries: KiCad official + JLCPCB Easy EDA library import
- Component sourcing: LCSC (primary, JLCPCB-aligned) + Mouser / Digi-key fallback

**Files this plan will create or modify:**
- `pcb/starling.kicad_pro` — KiCad project
- `pcb/starling.kicad_sch` — schematic
- `pcb/starling.kicad_pcb` — layout
- `pcb/lib/` — custom symbols / footprints for non-standard parts
- `pcb/gerber/` — gerber output (top + bottom + drill + outline + soldermask + silk)
- `pcb/BOM-Elec.csv` — JLCPCB-format BOM with LCSC part numbers + designators
- `pcb/CPL.csv` — pick-and-place (centroid) file for assembly
- `pcb/3d/starling.step` — 3D model for mechanical interference check
- `pcb/README.md` — PCB stack, version notes, change log

**Scope (~30 tasks expected):**
1. KiCad project setup + git ignore
2. Symbol libraries import / create (ESP32-WROOM-32E, ATtiny85, BMI270 module, AS5600 footprint, USB-PD trigger, etc.)
3. Footprint libraries — ensure JLCPCB-compatible
4. Schematic: Power input (USB-C PD + ESD + reverse polarity)
5. Schematic: 9→7.4V/8A buck (servo rail) with INA219 current monitor on each servo channel
6. Schematic: 9→5V/3A buck (MCU rail) with supercap buffer
7. Schematic: ESP32-WROOM-32E core (3.3V LDO, decoupling, RF matching, boot pins)
8. Schematic: ATtiny85 + dual MOSFET kill switch (per FMEA #9 fix)
9. Schematic: I2C bus with IMU BMI270 directly on board
10. Schematic: External connector blocks (J1 GPS, J3 wheel Hall, J4 brake Hall, J5/J6 encoders, J7/J8 servos)
11. Schematic: SD card socket (SPI)
12. Schematic: Brake/wheel signal opto-isolation (if needed; with PD-only operation may be optional)
13. Schematic: In-line fuses (5A main + 1A servo secondary)
14. Schematic: USB-C debug port (盒外密封盖) for OTA fallback
15. Schematic ERC + cleanup
16. PCB layout: board outline 100×120 mm + mounting holes per IC-1
17. PCB layout: power planes (separate analog, digital, servo)
18. PCB layout: ESP32 module + antenna keep-out per Espressif guidelines
19. PCB layout: Connectors on board edge per IC-1 J1-J10 placement
20. PCB layout: routing — high current servo (≥ 30 mil) and digital signals
21. PCB layout: differential pairs (USB) length matching
22. PCB layout: IMU placement (vibration-isolated, away from servo current paths)
23. DRC clean (zero errors / zero warnings)
24. JLCPCB DFM check (online tool, fix any issues)
25. Gerber export (4 layers + drill + outline)
26. BOM-Elec.csv generation with LCSC numbers
27. CPL.csv pick-place generation
28. 3D STEP export for assembly interference check (interfaces with mechanical plan)
29. Order-ready package (gerber.zip + BOM.csv + CPL.csv) committed to git
30. Documentation: PCB README + assembly notes + post-assembly QC checklist

---

**To the dispatched writing-plans subagent:** Generate ~30 bite-sized tasks. Adapt TDD pattern as: "define net / footprint specification → make ECAD change → verify ERC/DRC pass → verify net continuity in schematic". Use KiCad's built-in ERC/DRC as the verification step. For BOM tasks, verify by counting components against schematic. Reference master IC-1 for *every* net and pin assignment — no creative pin re-shuffling allowed.
