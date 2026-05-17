# Integration & Test Subsystem Plan — Starling Active Aero v1

> **Status:** Empty template. To be filled by `writing-plans`-dispatched subagent.
> **Master plan:** [`2026-05-17-active-aero-v1-master.md`](2026-05-17-active-aero-v1-master.md)
> **Source spec:** [`../specs/2026-05-17-active-front-aero-design.md`](../specs/2026-05-17-active-front-aero-design.md) §§ 7, 8

**Goal:** Deliver actionable test protocols + checklists + report templates for the 7 test phases. Each phase has explicit pass/fail criteria, equipment list, safety checklist, data acquisition procedure, and report template. This plan is the "integration glue" between mechanical / electronics / firmware / app / cloud and the physical world (a real motorcycle).

**Bound by all Interface Contracts** — integration plan is the consumer of every other plan's deliverables and verifies they fit together as specified.

**Tech stack:**
- Test equipment (procured separately): 数字万用表, 示波器 ≥ 100MHz / 2-channel (鼎阳 SDS1102 推荐), 直流可调电源, 小型风扇组 / 风洞 (DIY 3-5K RMB), 红外测温枪, 应变片 + HX711 模块, 240 fps 手机摄像
- Test track candidates: 珠海国际赛车场 / 上海国际赛车场 / 北京金港赛道
- Documentation: Markdown checklists + CSV data sheets + photographs
- Data analysis: starlog_analyzer Python package (from firmware plan)
- Test report repo: `docs/test-reports/YYYY-MM-DD-phaseN.md`

**Files this plan will create or modify:**
- `tests/phase1_bench_checklist.md` — 10-item台架单元测试
- `tests/phase2_static_checklist.md` — 8-item 车上静态测试
- `tests/phase3_lowspeed_checklist.md` — 5-item 低速骑行
- `tests/phase4_midspeed_checklist.md` — 6-item 中速空旷路
- `tests/phase5_baseline_protocol.md` — 赛道日基线协议
- `tests/phase6_active_protocol.md` — 赛道日 active aero 协议
- `tests/phase7_endurance_protocol.md` — 长期耐久协议
- `tests/safety_gear_checklist.md` — 每次测试前强制检查
- `tests/fault_injection_protocol.md` — 故障注入测试
- `tests/test_report_template.md` — 实验报告模板
- `tests/equipment_setup.md` — 设备清单 + 校准
- `scripts/test_phase1.py` — 自动化 Phase 1 unit harness (启动自检脚本)
- `scripts/kpi_compare.py` — Phase 5 vs Phase 6 KPI 对比生成 markdown 报告

**Scope (~20 tasks expected):**

### Phase Checklists
1. Phase 1 (台架) — 10-item pass/fail checklist with expected outputs per item
2. Phase 2 (车上静态) — 8-item checklist + 28-item startup self-test inventory
3. Phase 3 (低速骑行) — 5-item checklist + stop-on-fail criteria
4. Phase 4 (中速空旷路) — 6-item checklist + temperature/timing thresholds
5. Phase 5 (赛道基线) — full protocol with 5 test items × repetitions
6. Phase 6 (active aero 启用) — protocol mirroring Phase 5 for direct comparison
7. Phase 7 (耐久) — 5000 km / 50000 cycle / strain monthly review

### Safety + Equipment
8. Safety gear checklist (强制 before each test)
9. Equipment procurement list + budget + calibration procedure
10. Test track booking process + cost estimates

### Fault Injection
11. Fault injection test protocol (deliberately disconnect/jam → verify FMEA matches reality)
12. Health-bit verification matrix (each of 7 health checks tested individually)

### Reports + Analysis
13. Test report markdown template (data + photos + video links + decisions)
14. KPI extraction script using starlog_analyzer
15. Phase 5 vs 6 comparison script (auto-generates comparison report)
16. Strain gauge monitoring protocol (HX711 setup + monthly review)

### Process Discipline
17. Pre-test brief template (review FMEA + spec + plan changes before each on-bike test)
18. Post-test debrief template (issues + photos + data file links)
19. Gate transition acceptance form (sign-off before next phase)
20. Run book: "What to do if [X] fails" for each failure mode

---

**To the dispatched writing-plans subagent:** Generate ~20 bite-sized tasks. These tasks are mostly **documentation** + small Python scripts — adapt TDD as: "define acceptance test → generate document/script → verify checklist items map to spec §8 / §7 / §5 references → commit". For Python automation scripts, real pytest TDD. Cross-reference every checklist item to either FMEA mitigation (§7) or test KPI (§8) — every line must trace back to spec.
