# Starling Active Aero

[English](README.md) | [中文](README.zh-CN.md)

Starling is an experimental active front aerodynamic system for motorcycles. It uses electronically controlled side-mounted front winglets to explore how adaptive aero can improve braking stability, front-wheel load, anti-wheelie behavior, and ride data collection on real motorcycles.

> Current status: design specification and v1 implementation planning. This repository is not yet a production-ready safety-certified product.

## Overview

Starling is a real-prototype active aero project, not just a CAD concept. The system mounts variable-angle winglets on both sides of a motorcycle front fairing and controls them with an ESP32-S3 based controller, sensor fusion, servo actuation, a mobile app, cloud data sync, and offline analysis tooling.

The v1 target is to deliver one working motorcycle prototype within 4-6 months and validate it with track-day data: active aero should improve 100-0 km/h braking distance by at least 3% without significant regression in acceleration, straight-line top speed, or cornering stability.

## Scope

The project covers six coordinated subsystems:

| Subsystem          | Deliverables                                                                                                   |
| ------------------ | -------------------------------------------------------------------------------------------------------------- |
| Mechanical         | NACA 4412 inverted wing CAD, shaft, torsion spring, servo enclosure, GSX250R / RC450 subframes, STEP/STL, BOM  |
| Electronics        | KiCad backplane PCB, ESP32-S3, ATtiny85 watchdog, servo rail, sensors, IP67 connectors, Gerber, BOM, CPL       |
| Firmware           | ESP-IDF control firmware, 100 Hz loop, 9-state FSM, lookup tables, BLE/WiFi, SD logging, OTA, ATtiny watchdog  |
| Mobile App         | Flutter Android app, BLE telemetry, WiFi log download, table editor, calibration, health checks, Firebase sync |
| Cloud              | Firebase Auth, Firestore, Storage, Cloud Functions, OTA release pipeline, minimal web console                  |
| Integration & Test | Bench, static, low-speed, mid-speed, baseline track, active aero track, endurance protocols                    |

## Design Highlights

- Dual target platforms: Suzuki GSX250R-A 2022 and KTM RC 450 / KM400.
- Wing geometry: 120 mm chord, 350 mm span per side, inverted NACA 4412 profile.
- Operating range: 0 to +70 degrees for v1, with -5 degrees planned for v2 drag reduction.
- Physical fail-safe: 70% chord pivot plus torsion spring so aerodynamic and mechanical forces return the winglets toward the flat position.
- Independent hardware watchdog: ATtiny85 monitors ESP32 heartbeat and cuts servo power on timeout.
- Non-invasive power: v1 runs from an external USB-PD power bank instead of tapping the motorcycle electrical system.
- Data-first validation: 128-byte binary frames logged at 100 Hz to SD card, then analyzed locally and in the cloud.

## Repository Layout

```text
Starling/
|-- docs/
|   `-- superpowers/
|       |-- specs/
|       |   `-- 2026-05-17-active-front-aero-design.md
|       `-- plans/
|           |-- 2026-05-17-active-aero-v1-master.md
|           |-- 2026-05-17-mechanical.md
|           |-- 2026-05-17-electronics.md
|           |-- 2026-05-17-firmware.md
|           |-- 2026-05-17-app.md
|           |-- 2026-05-17-cloud.md
|           `-- 2026-05-17-integration.md
|-- AGENTS.md
`-- CLAUDE.md
```

Planned implementation directories include `cad/`, `pcb/`, `firmware/`, `app/`, `cloud/`, `analyzer/`, `tests/`, and `scripts/`.

## Development Plan

The v1 plan is controlled by `docs/superpowers/plans/2026-05-17-active-aero-v1-master.md`. It defines shared interface contracts and milestone gates:

1. Gate A: interface freeze after all six subsystem plans are approved.
2. Gate B: long-lead hardware ordered.
3. Gate C: bench-level units functional.
4. Gate D: full integration ready.
5. Gate E: on-bike static and low-speed validation.
6. Gate F: mid-speed validation.
7. Gate G: track baseline established with aero disabled.
8. Gate H: active aero validation complete.

All subsystem work should trace back to the design spec and the master interface contracts. Silent protocol changes are not allowed; update the master plan first when pin maps, BLE schemas, binary frame layouts, lookup table formats, or Firebase schemas change.

## Safety Notice

Starling is experimental motorcycle hardware. It is intended for controlled engineering validation and closed-course testing, not ordinary road use. The current design explicitly does not pursue regulatory certification.

Do not install or ride with this system unless the relevant mechanical, electrical, firmware, app, cloud, and integration-test gates have passed. Any failure should bias toward the flat wing position, no active intervention, and full data logging for later analysis.

## Recommended Open Source Licensing

Because Starling is open hardware plus software plus documentation, a single software license is not the best fit. Recommended release structure:

| Project Part                                                                    | Recommended License                                             | Why                                                                                                       |
| ------------------------------------------------------------------------------- | --------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Hardware design files: CAD, PCB, schematics, Gerbers, mechanical drawings, BOM  | [CERN-OHL-S-2.0](https://cern-ohl.web.cern.ch/)                 | Hardware-specific, strongly reciprocal, encourages derivative safety and design improvements to stay open |
| Software: firmware, app, cloud functions, web console, Python analyzer, scripts | [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)       | Permissive, familiar for software, includes explicit patent language                                      |
| Documentation: specs, plans, manuals, test protocols, reports                   | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) | Attribution plus share-alike for derivative docs and procedures                                           |

If the priority is maximum commercial adoption rather than reciprocal hardware sharing, replace CERN-OHL-S-2.0 with CERN-OHL-W-2.0 or CERN-OHL-P-2.0. Avoid "non-commercial" Creative Commons variants if the goal is open-source hardware compatibility.

Before public release:

1. Add root license files such as `LICENSES/CERN-OHL-S-2.0.txt`, `LICENSES/Apache-2.0.txt`, and `LICENSES/CC-BY-SA-4.0.txt`.
2. Add `LICENSES.md` explaining which license applies to each directory.
3. Add SPDX headers or short notices where practical.
4. Keep the Starling name and logo as reserved trademarks unless you explicitly want to license branding too.
5. Remove secrets, local tokens, private paths, and any credentials from agent settings before publishing.

## Primary Documents

- Design specification: `docs/superpowers/specs/2026-05-17-active-front-aero-design.md`
- Master implementation plan: `docs/superpowers/plans/2026-05-17-active-aero-v1-master.md`
- Subsystem plans: `docs/superpowers/plans/2026-05-17-*.md`
