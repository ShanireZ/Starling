# Starling Active Aero v1 — Master Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **This is a coordinating plan, not an implementation plan.** It defines interface contracts, milestone gates, and the dispatch of 6 subsystem plans. Each subsystem plan, once written and approved, is executed independently (often in parallel by different agents).

**Goal:** 在 4-6 个月内交付一台车（GSX250R-A 或 RC450 之一）上完整工作、通过赛道日 KPI 验证（刹车距离改善 ≥ 3%）的主动空气动力学翼片系统。

**Architecture:** 6 个独立子系统（机械 / 电子 / 固件 / App / 云 / 集成测试），每个有自己的实现计划。本 master 计划负责：(1) 写出 6 份接口契约；(2) 调度 6 个子计划的撰写与执行；(3) 在 6 个 milestone gate 上做集成同步。

**Tech Stack:** Fusion 360 / KiCad / ESP-IDF (C/C++) / Flutter (Dart) / Firebase / Python (analysis)

**Source Spec:** [`docs/superpowers/specs/2026-05-17-active-front-aero-design.md`](../specs/2026-05-17-active-front-aero-design.md)

---

## Plan Index — 6 个子系统 plan

每个 plan 写完后由用户审阅，然后由相应 AI agent 执行：

| # | 子系统 plan | 文件 (未来生成) | 预估任务数 | 关键交付物 |
|---|---|---|---|---|
| 1 | **机械** | `2026-05-17-mechanical.md` | ~25 | 翼片 STEP/STL + 副框架 STEP (两套 SKU) + 装配图 + BOM-Mech |
| 2 | **电子** | `2026-05-17-electronics.md` | ~30 | KiCad project + Gerber + BOM-Elec + 装配说明 |
| 3 | **固件** | `2026-05-17-firmware.md` | ~50 | ESP-IDF project + Python 分析器 + 单元测试 |
| 4 | **App** | `2026-05-17-app.md` | ~35 | Flutter project + 7 个页面 + BLE/WiFi 通信 + APK 构建 |
| 5 | **云** | `2026-05-17-cloud.md` | ~25 | Firebase config + Cloud Functions + Web 控制台 |
| 6 | **集成测试** | `2026-05-17-integration.md` | ~20 | 7 阶段测试 checklist + 实验报告模板 + 数据采集 |

---

## 接口契约 (Interface Contracts) — 所有子系统 plan 必须遵守

### IC-1: 物理 / 电气连接器

**Backplane PCB ↔ 外部模块连接器列表**（电子 plan 实现，所有其他 plan 依赖）：

| 连接器编号 | 功能 | 类型 | 引脚定义 |
|---|---|---|---|
| J1 | GPS 模块 (u-blox NEO-M9N) | 4-pin Marine IP67 | VCC 3.3V / GND / TX (ESP UART RX) / RX (ESP UART TX) |
| J2 | 已直焊 IMU BMI270 (无外部连接器) | — | — |
| J3 | 后轮 Hall 传感器 + 磁铁 | 3-pin Marine IP67 (屏蔽线) | VCC 5V / GND / OUT (digital pulse) |
| J4 | 刹车杆 Hall 传感器 + 磁铁 | 3-pin Marine IP67 (屏蔽线) | VCC 5V / GND / OUT (digital pulse) |
| J5 | 左翼片 **AS5600L** 角度编码器 | 5-pin Marine IP67 | VCC 3.3V / GND / SCL / SDA / ADDR (ADDR=GND → 0x40) |
| J6 | 右翼片 **AS5600L** 角度编码器 | 5-pin Marine IP67 | VCC 3.3V / GND / SCL / SDA / ADDR (ADDR=VCC → 0x41) |
| J7 | 左舵机 (DSServo RDS5160) | 4-pin Marine IP67 | VCC 7.4V (50W 功率限流) / GND / PWM / Current sense return |
| J8 | 右舵机 (同上) | 4-pin Marine IP67 | 同 J7 |
| J9 | USB-C PD 输入 | USB-C (盒外密封盖) | PD 协商至 9V/5A |
| J10 (内部) | SD 卡 SMD socket | 板载 | SPI |

**MCU 引脚分配**（固件 plan 必须严格按此走，电子 plan PCB 走线也按此）：

```c
// ESP32-S3 引脚 — 跨 plan 唯一真相源
#define GPIO_SERVO_L_PWM        4
#define GPIO_SERVO_R_PWM        5
#define GPIO_HALL_WHEEL         6
#define GPIO_HALL_BRAKE         7
#define GPIO_I2C_SDA            8
#define GPIO_I2C_SCL            9
#define GPIO_SD_MOSI            10
#define GPIO_SD_MISO            11
#define GPIO_SD_CLK             12
#define GPIO_SD_CS              13
#define GPIO_UART_GPS_TX        14
#define GPIO_UART_GPS_RX        15
#define GPIO_HEARTBEAT_OUT      16    // 心跳输出给 ATtiny85
#define GPIO_ATTINY_RESET       17    // 复位 ATtiny85
#define GPIO_SUPPLY_VOLTAGE_ADC 18    // 主供电监测
#define GPIO_FAULT_STATUS_OUT   19    // FAULT 状态指示 LED
#define GPIO_USER_BUTTON        0     // 启动校准触发

// I2C 地址（多设备共用 1 个 I2C 总线）
// NOTE: 使用 AS5600L (NOT 标准 AS5600 — 后者地址固定 0x36 无法双芯片同总线)
#define I2C_ADDR_IMU_BMI270     0x68
#define I2C_ADDR_AS5600L_LEFT   0x40   // ADDR pin = GND
#define I2C_ADDR_AS5600L_RIGHT  0x41   // ADDR pin = VCC

// ATtiny85 ↔ 主 MCU
// HEARTBEAT_OUT 应每 50ms 翻转一次（10Hz 心跳）
// ATtiny85 200ms 没收到翻转 → 切舵机电源
```

### IC-2: BLE GATT 服务定义

**固件 plan + App plan 必须严格一致**：

```
Service UUID: a8c2d3e4-f5a6-4b7c-8d9e-1f2a3b4c5d6e

Characteristic UUIDs:
├─ telemetry_live   (e1000001-..., notify @10Hz)    binary 50B
├─ command          (e1000002-..., write)           JSON
├─ status           (e1000003-..., read)            JSON
├─ table_data       (e1000004-..., read/write)      CSV (gzip-compressed)
├─ session_list     (e1000005-..., read)            JSON
└─ debug            (e1000006-..., notify)          UTF-8 ASCII (调试日志)

Telemetry frame (50 bytes binary, little-endian):
  uint64_t time_us           (8B)
  uint16_t speed_kmh_cx100   (2B)
  uint16_t altitude_m        (2B)
  int16_t  roll_cdeg         (2B)
  int16_t  pitch_cdeg        (2B)
  int16_t  long_accel_cms2   (2B)
  uint8_t  state_current     (1B, enum)
  uint8_t  fault_flag        (1B)
  int16_t  target_l_cdeg     (2B)
  int16_t  target_r_cdeg     (2B)
  int16_t  measured_l_cdeg   (2B)
  int16_t  measured_r_cdeg   (2B)
  uint8_t  brake_active      (1B)
  uint8_t  health_bits       (1B)
  uint16_t supply_mv         (2B)
  uint16_t servo_l_ma        (2B)
  uint16_t servo_r_ma        (2B)
  uint8_t  table_version     (1B)
  uint8_t  pad[11]           (11B)
  uint16_t crc16             (2B)

Command JSON schema (写 command characteristic):
  {"op": "start_recording" | "stop_recording" | "mark_event" |
         "switch_state_force" | "calibrate_zero" | "reboot",
   "args": {...}  // 操作相关参数
  }

Status JSON schema (读 status characteristic, ASCII):
  {"firmware_version": "0.1.0",
   "uptime_sec": 1234,
   "free_heap": 56789,
   "sd_card_present": true,
   "sd_card_free_mb": 12345,
   "last_fault": null | {"time": "...", "code": "..."},
   "bike_profile": "gsx250r" | "rc450",
   "calibration_done": true}
```

### IC-3: Binary 日志帧 schema

**固件 plan + Python 分析器 + App plan + 云 plan 必须一致**：

128 字节/帧 binary 格式（详见 spec §6.2 完整 C struct）。

```
关键不变量:
1. 帧长固定 128 字节，packed，little-endian
2. CRC16 (CCITT, init 0xFFFF) 在帧最后 2 字节
3. SD 卡上以 frame 为单位顺序写
4. 文件头 4KB header，单独的 file-header schema (固件 plan 定义)
```

**版本字段**：`starlog_frame_t` 第 99 字节是 `lookup_table_version` —— 改变 schema 时必须 bump 这个字段，Python 分析器靠它选 parser。

### IC-4: 查找表 CSV 格式

**固件 plan + App plan 必须一致**：

```csv
# Starling lookup table v1
# state, speed_kmh, angle_deg
PARKED,0,0
LOW_SPEED,*,0           # * = wildcard, 所有速度
CRUISE,*,0
DRAG_REDUCE,150,-3
DRAG_REDUCE,170,-4
DRAG_REDUCE,195,-5
BRAKING_LIGHT,30,25
BRAKING_LIGHT,50,40
BRAKING_LIGHT,80,55
BRAKING_LIGHT,120,60
BRAKING_LIGHT,160,62
BRAKING_HARD,30,30
BRAKING_HARD,50,50
BRAKING_HARD,80,65
BRAKING_HARD,120,70
BRAKING_HARD,160,70
TRAIL_BRAKE,*,(0.5 * BRAKING_LIGHT(speed))   # 表达式插入式
CORNERING,*,-3
WHEELIE_GUARD,*,30
FAULT,*,0

# Metadata
# bike_profile: gsx250r | rc450 | universal
# table_version: 1
# created: 2026-05-17T00:00:00Z
# author: shanire
# crc16: 0xABCD  (over all rows excluding this line)
```

插值规则（固件 + App 必须一致）：
- 状态行按速度找 piecewise linear interpolation
- 速度 < 最小行的速度时，返回最小行的角度
- 速度 > 最大行的速度时，返回最大行的角度
- `*` 通配符忽略速度

### IC-5: Firebase 数据模型

**云 plan + App plan + Python 分析器必须一致**：

```
Firestore collections:
  users/{user_id}
    email, created_at, bikes: [bike_id]
  
  bikes/{bike_id}
    user_id, profile: "gsx250r" | "rc450", vin?: string,
    created_at, last_session_id

  sessions/{session_id}
    user_id, bike_id, start_time, duration_sec,
    distance_km, max_speed_kmh, fault_count,
    state_dwell_percent: {CRUISE: 75, BRAKING_LIGHT: 12, ...},
    storage_uri: "gs://bucket/sessions/<session_id>.starlog",
    firmware_version, table_version,
    analyzed_at?: timestamp,
    summary?: {braking_events: [...], peak_decel: ...}

  firmware_releases/{version}
    version: "0.1.0",
    storage_uri: "gs://bucket/firmware/0.1.0.bin",
    rollout_percentage: 100,
    released_at,
    changelog

Cloud Storage paths:
  /sessions/<session_id>.starlog (gzip-compressed binary log)
  /firmware/<version>.bin
  /lookup_tables/<bike_profile>/<version>.csv

Cloud Functions:
  - on_session_upload(): 解析 starlog → 提取关键指标 → 写 Firestore
  - on_firmware_publish(): 校验签名 → 通知所有用户
  - get_signed_url(): 生成 session 文件下载临时链接
```

Auth 角色：
- `auth.uid == doc.user_id` 才能读自己的 session
- 公开 firmware_releases (匿名可读)
- 写 sessions 只允许通过 Cloud Function (不允许 client 直接写)

### IC-6: 电源预算

**电子 plan + 机械 plan 协同**：

```
源:    USB-C PD 9V @ 5A max (45W 协商)
       
9V → 7.4V buck (8A max)  → Servo rail
                            │
                            ├─ 左 Servo  (~25W 峰值, ~3W idle)
                            └─ 右 Servo  (~25W 峰值, ~3W idle)
                              
9V → 5V buck (3A max)    → MCU + 传感 rail
                            │
                            ├─ ESP32-S3      (~1W active, ~0.3W sleep)
                            ├─ ATtiny85      (~0.05W)
                            ├─ GPS NEO-M9N   (~0.5W active)
                            ├─ IMU BMI270    (~0.01W)
                            ├─ AS5600L ×2    (~0.05W)
                            ├─ Hall ×2       (~0.02W)
                            ├─ SD 卡        (~0.2W write, ~0.05W idle)
                            └─ 法拉电容 buffer

总功耗预算:
  Servo 同时全功率:  50W
  其他持续:          ~2W
  ─────────────────────────
  峰值:              52W (< 45W PD 上限!! 必须分时驱动 servo)
  平均 (cruise):     ~5W
  平均 (制作期):     ~20W

约束传递:
  - 固件 plan: 必须实现 "左右 servo 错开 50ms 启动" 避免同时峰值
  - 电子 plan: PCB 走线考虑 servo rail 8A，需要 ≥ 1.5mm² 等效 (PCB 走线 ≥ 30mil)
  - 机械 plan: servo 选型不能超过单只 30W 持续
```

---

## Milestone Gates

下列 gate 必须按序通过。每个 gate 是 "不通过则禁止进下一阶段" 的硬约束。

### Gate A — 接口冻结 [D+0 — 写完所有 plan 时]

**通过判据**:
- [ ] 6 份子系统 plan 全部写完并经用户审阅
- [ ] IC-1 至 IC-6 全部签字（用户在 master plan 上确认）
- [ ] 任何 IC 变更需要 master plan 修订 + 所有受影响子 plan 同步更新

### Gate B — 长周期件下单 [D+7]

**通过判据**:
- [ ] 机械 plan task "CAD 翼片 + 副框架完成" → STEP / STL 文件可送 CNC / 3D 打印厂
- [ ] 电子 plan task "PCB 设计完成" → Gerber 文件可送 JLCPCB
- [ ] BOM-Mech 和 BOM-Elec 全部下单（含 Anker 737 充电宝、舵机、传感器模块、备件）
- [ ] 预计 2-3 周到货

### Gate C — 台架单元可工作 [D+30]

**通过判据**:
- [ ] PCB 收到、SMT 装配完成、上电通过、电压轨稳定
- [ ] 固件 plan Phase 1 单元测试全部通过 (10/10)
- [ ] 3D 打印翼片 + 舵机 + 扭簧机构台架装配，全行程 0-70° 可控
- [ ] App plan 至少 "Dashboard" 页面跑通（连模拟 ESP32 显示遥测）
- [ ] 云 plan Firebase project 创建，session 文件可上传

### Gate D — 集成就绪 [D+60]

**通过判据**:
- [ ] 完整硬件已装配在车架旁（不上车）
- [ ] 固件 + App 通过真 BLE 通信
- [ ] App 可读 SD 卡日志
- [ ] App 可上传 session 到 Firebase
- [ ] OTA 流程通过测试（推一个 dummy 固件版本，回滚验证）

### Gate E — 上车静态 + 低速 [D+75]

**通过判据**:
- [ ] 集成测试 plan Phase 2（车上静态）通过：28 项启动自检全绿 + 静置 1 小时无 fault
- [ ] 集成测试 plan Phase 3（停车场低速）通过：状态转换正确 + 30 分钟无 fault

### Gate F — 中速空旷路 [D+90]

**通过判据**:
- [ ] 集成测试 plan Phase 4（70-100 km/h）通过：9 状态全部触发 + 60 分钟无 fault + 舵机 < 60°C

### Gate G — 赛道基线 [D+105]

**通过判据**:
- [ ] 集成测试 plan Phase 5（aero 禁用基线）完成：完整测试项目数据归档

### Gate H — Active aero 验证 [D+135]

**通过判据**:
- [ ] 集成测试 plan Phase 6 通过：刹车距离改善 ≥ 3% **且**其他指标不退步
- [ ] v1 项目结题报告写完

---

## 任务清单 (Master 层级)

### Task 1: 准备 6 个子系统 plan 模板与依赖图

**Files:**
- Create: `docs/superpowers/plans/2026-05-17-mechanical.md` (空模板)
- Create: `docs/superpowers/plans/2026-05-17-electronics.md` (空模板)
- Create: `docs/superpowers/plans/2026-05-17-firmware.md` (空模板)
- Create: `docs/superpowers/plans/2026-05-17-app.md` (空模板)
- Create: `docs/superpowers/plans/2026-05-17-cloud.md` (空模板)
- Create: `docs/superpowers/plans/2026-05-17-integration.md` (空模板)

- [ ] **Step 1.1: 为每个子系统创建空 plan 模板**

每个模板包含：
- 引用本 master plan 的接口契约（"This plan is bound by IC-1 to IC-6 in master plan"）
- Scope 章节（覆盖 spec 的哪些章节）
- Tech stack
- Files to create/modify
- 占位 "Tasks (to be filled by writing-plans for this subsystem)"

- [ ] **Step 1.2: 用 Mermaid 画子系统依赖图**

```
graph TD
    M[机械] --> I[集成]
    E[电子] --> F[固件]
    E --> I
    F --> I
    A[App] --> I
    C[云] --> A
    F -.-> C  
    A --> F
    
    style M fill:#fef
    style E fill:#efe
    style F fill:#ffe
    style A fill:#eef
    style C fill:#fee
    style I fill:#eee
```

- [ ] **Step 1.3: Commit**

```bash
git add docs/superpowers/plans/
git commit -m "Add 6 empty subsystem plan templates with IC bindings"
```

### Task 2: 撰写机械子系统 plan

**Approach:** 调用 writing-plans skill 在一个新 subagent 上，输入：
- spec §3 (机械设计) + §3.8 (材料) + §3.9 (制造里程碑)
- 本 master 的 IC-1 (物理接口) + IC-6 (电源预算约束)

- [ ] **Step 2.1: dispatch subagent**

```
subagent_type: general-purpose
prompt: |
  You will write a writing-plans-format implementation plan for the
  MECHANICAL subsystem of the Starling Active Aero project.
  
  Read these files first:
  - docs/superpowers/specs/2026-05-17-active-front-aero-design.md (§§ 3, 3.8, 3.9)
  - docs/superpowers/plans/2026-05-17-active-aero-v1-master.md (Interface Contracts IC-1, IC-6)
  - docs/superpowers/plans/2026-05-17-mechanical.md (the empty template)
  
  Then invoke the superpowers:writing-plans skill and write the
  detailed plan into docs/superpowers/plans/2026-05-17-mechanical.md.
  
  The plan must cover:
  - Fusion 360 翼片 CAD with NACA 4412 inverted (4% camber)
  - 副框架 CAD for both GSX250R-A 2022 and KTM RC 450 (KM400) - two SKUs
  - Carbon-rod-reinforced SLA wing prototype for v1
  - 3D-printed PETG mold design (v2-ready, low-priority but designed now)
  - Servo mount bracket + shaft + bearings
  - Reset torsion spring sizing and mount
  - Engineering drawings + STEP/STL exports
  - DFM review for CNC house (Aliexpress accepted vendor list)
  - BOM-Mech with sourcing links
  
  Output ~25 tasks. Each task must follow bite-sized format from
  writing-plans skill.
```

- [ ] **Step 2.2: User reviews `2026-05-17-mechanical.md`**

- [ ] **Step 2.3: Commit if approved**

### Task 3: 撰写电子子系统 plan

**Approach:** Same pattern as Task 2.

- [ ] **Step 3.1: dispatch subagent**

```
subagent_type: general-purpose
prompt: |
  Write the ELECTRONICS subsystem plan for Starling Active Aero.
  
  Reference:
  - spec §4 (电子与驱动)
  - master IC-1 (Backplane PCB connectors + MCU pin map) + IC-6 (Power budget)
  - master IC-2 (BLE GATT) for ESP32 capability requirements
  - empty template at docs/superpowers/plans/2026-05-17-electronics.md
  
  Plan must cover:
  - KiCad project setup
  - Schematic per IC-1's MCU pin map (no ambiguity allowed)
  - PCB layout 100×120mm, 2-layer, full SMT, JLCPCB-compatible
  - Component selection per spec BOM (ESP32-S3-WROOM-1U external-antenna module, ATtiny85,
    BMI270 module land pattern, AS5600L footprint, USB-PD trigger,
    DC/DC modules, SD socket, supercaps, fuses)
  - Dual MOSFET series for safety (item #9 in FMEA)
  - In-line fuses (5A main + 1A servo secondary)
  - Marine-grade IP67 connector callouts on PCB edge
  - Gerber export + JLCPCB-format BOM + CPL pick-place
  - DFM check + design rule check
  - BOM-Elec with LCSC/JLCPCB part numbers
  - Component sourcing strategy + lead-time matrix
  
  Output ~30 tasks.
```

- [ ] **Step 3.2: User reviews**

- [ ] **Step 3.3: Commit if approved**

### Task 4: 撰写固件子系统 plan

- [ ] **Step 4.1: dispatch subagent**

```
subagent_type: general-purpose
prompt: |
  Write the FIRMWARE subsystem plan for Starling Active Aero.
  
  Reference:
  - spec §§ 5 (传感与控制), 6 (数据采集)
  - master IC-1 (MCU pin map), IC-2 (BLE GATT), IC-3 (binary frame),
    IC-4 (lookup table CSV), IC-5 (Firebase schema)
  - empty template at docs/superpowers/plans/2026-05-17-firmware.md
  
  Plan must cover ESP-IDF C/C++ project + Python analyzer:
  - HAL layer (sensor abstractions, all per IC-1 pinout)
  - GPS UART driver (u-blox NEO-M9N, NMEA + UBX protocol)
  - IMU BMI270 driver (I2C, with Mahony filter for roll/pitch)
  - AS5600L ×2 driver (I2C, two addresses 0x40 / 0x41)
  - Hall input handlers (interrupt + debounce)
  - Servo PWM control (50Hz, 1000-2000μs pulse, with position closed-loop verify)
  - ATtiny85 heartbeat output (10Hz)
  - Sensor fusion layer (50Hz Mahony + 100Hz speed estimation)
  - FSM with 9-state priority arbitration (per spec §5.2)
  - Lookup table parser + piecewise linear interpolation
  - Health check 7 items (per spec §5.5)
  - 100Hz control loop (timer-driven, jitter < 200μs)
  - Data logging (128B binary frames, RAM ring buffer → SD)
  - BLE GATT server (per IC-2 UUIDs and characteristics)
  - WiFi STA mode for file download
  - OTA via ESP-IDF dual-bank
  - ATtiny85 firmware (<50 lines C, monitoring heartbeat)
  - Unit tests (state machine, table interpolation, CRC)
  - Python analyzer package: starlog_analyzer with .load(), .plot_overview(),
    .detect_braking_events(), .compare_braking()
  
  Output ~50 tasks across firmware + analyzer.
```

- [ ] **Step 4.2: User reviews**

- [ ] **Step 4.3: Commit if approved**

### Task 5: 撰写 App 子系统 plan

- [ ] **Step 5.1: dispatch subagent**

```
subagent_type: general-purpose
prompt: |
  Write the APP subsystem plan for Starling Active Aero.
  
  Reference:
  - spec §6.4 (Flutter App architecture) + §6.5 (BLE GATT)
  - master IC-2 (BLE GATT), IC-3 (binary frame for log download),
    IC-4 (table CSV format), IC-5 (Firebase schema)
  - empty template at docs/superpowers/plans/2026-05-17-app.md
  
  Plan must cover Flutter Android (iOS to come in v2):
  - Project init + Riverpod state management
  - BLE client (flutter_blue_plus) with auto-reconnect
  - WiFi STA HTTP client for log file download
  - 7 pages: Dashboard, Recording, Sessions, Table Editor, Calibration,
    Health, Settings
  - fl_chart real-time chart performance (10Hz updates without jank)
  - Firebase Auth (Google sign-in) + Firestore + Storage clients
  - Crashlytics integration
  - Push notifications (FCM) for fault alerts
  - Native storage (sqflite) for offline session metadata
  - Background WiFi sync when charging + on home network
  - Calibration wizard with step-by-step UI
  - Lookup table editor with sandbox simulation
  - APK build pipeline (debug + release signed)
  
  Output ~35 tasks.
```

- [ ] **Step 5.2: User reviews**

- [ ] **Step 5.3: Commit if approved**

### Task 6: 撰写云子系统 plan

- [ ] **Step 6.1: dispatch subagent**

```
subagent_type: general-purpose
prompt: |
  Write the CLOUD subsystem plan for Starling Active Aero.
  
  Reference:
  - spec §6.6 (Firebase 后端) + §6.8 (OTA)
  - master IC-5 (Firestore + Storage schema), IC-2 (data formats)
  - empty template at docs/superpowers/plans/2026-05-17-cloud.md
  
  Plan must cover Firebase project:
  - Firebase project creation + 计费配置
  - Firestore schema + 安全规则 (per IC-5)
  - Cloud Storage buckets + IAM (sessions, firmware, lookup_tables)
  - Auth (Google sign-in + email)
  - Cloud Functions (Node.js or Python):
    * on_session_upload — 解析 starlog.gz → 提取指标 → 写 Firestore
    * on_firmware_publish — 验证 + 通知
    * get_signed_url — 生成临时下载链接
  - Web Console (Next.js or basic React):
    * 用户登录
    * Session 列表 + 详细视图
    * 多 session 时序图对比
    * Firmware OTA 发布界面
  - CI/CD via GitHub Actions
  - Monitoring + alerting
  - Cost monitoring + free tier 注意事项
  
  Output ~25 tasks.
```

- [ ] **Step 6.2: User reviews**

- [ ] **Step 6.3: Commit if approved**

### Task 7: 撰写集成测试子系统 plan

- [ ] **Step 7.1: dispatch subagent**

```
subagent_type: general-purpose
prompt: |
  Write the INTEGRATION & TEST subsystem plan for Starling Active Aero.
  
  Reference:
  - spec §8 (测试与验证计划) + §7 (FMEA)
  - All master IC contracts
  - empty template at docs/superpowers/plans/2026-05-17-integration.md
  
  Plan must cover:
  - Test equipment procurement (示波器, 多用表, 直流电源, 风扇组,
    应变片, IR 测温, 240fps 相机)
  - Phase 1 (台架) test checklist with pass/fail per item (10 项)
  - Phase 2 (车上静态) test checklist (8 项)
  - Phase 3 (低速骑行) test checklist (5 项)
  - Phase 4 (中速空旷路) test checklist (6 项)
  - Phase 5 (赛道基线 - aero 关闭) test protocol with 数据采集
  - Phase 6 (赛道 active aero 启用) comparative protocol
  - Phase 7 (耐久 - v1 后期持续)
  - 实验报告模板 (CSV + Markdown)
  - 安全护具检查清单 (强制 before each test)
  - 故障注入测试方案 (deliberately disconnect sensor → verify FAULT
    behavior matches FMEA expectations)
  - 数据回放 + KPI 提取脚本
  - Pass/fail gate enforcement (no skipping)
  
  Output ~20 tasks.
```

- [ ] **Step 7.2: User reviews**

- [ ] **Step 7.3: Commit if approved**

### Task 8: Gate A 检查 — 6 个子系统 plan 全部就位

- [ ] **Step 8.1: 确认所有 6 份 plan 都已 commit 到 git**

```bash
ls docs/superpowers/plans/
```

Expected output:
```
2026-05-17-active-aero-v1-master.md
2026-05-17-app.md
2026-05-17-cloud.md
2026-05-17-electronics.md
2026-05-17-firmware.md
2026-05-17-integration.md
2026-05-17-mechanical.md
```

- [ ] **Step 8.2: 用户在每一份 plan 上确认 "接受作为 v1 实施准绳"**

逐份审阅，记录决策。

- [ ] **Step 8.3: 冻结接口契约 (IC-1 至 IC-6)**

在 master plan 头部加注 `**Interface contracts frozen at commit <SHA>**`，之后任何 IC 修改必须经 master plan 修订。

- [ ] **Step 8.4: Gate A 通过 commit**

```bash
git commit --allow-empty -m "Gate A passed: all subsystem plans approved, ICs frozen"
git tag gate-A
```

### Task 9: Gate A → B 转换 — 长周期件下单

**Files:**
- 主要执行体在各子系统 plan 内（机械 + 电子）

- [ ] **Step 9.1: 机械 plan 内：CAD 完成（前 5-10 个 task）**

由机械 agent 执行其 plan 的早期 task。

- [ ] **Step 9.2: 电子 plan 内：PCB 设计完成（前 5-15 个 task）**

由电子 agent 执行。

- [ ] **Step 9.3: 用户审阅 STEP/STL/Gerber，确认无误**

- [ ] **Step 9.4: 下单**

- CNC 加工厂送图（淘宝 / 闲鱼 / 嘉立创精密加工）
- JLCPCB 提交 Gerber + BOM + CPL
- 长周期 BOM 件采购（充电宝 / 舵机 / GPS / IMU 模块）

- [ ] **Step 9.5: Gate B 通过 commit**

```bash
git commit --allow-empty -m "Gate B passed: long-lead-time hardware ordered"
git tag gate-B
```

### Task 10: Gate B → C 转换 — 台架单元可工作

**Files:**
- 由固件 + 电子 + 机械 + App + 云 各 plan 的中期 task 完成

- [ ] **Step 10.1: 等待硬件到货（~2-3 周）**

- [ ] **Step 10.2: PCB SMT 装配 + 上电测试**

电子 plan 执行。

- [ ] **Step 10.3: 固件下载 + 单元测试**

固件 plan 执行 Phase 1 单元测试。

- [ ] **Step 10.4: 机械台架装配**

机械 plan 执行。

- [ ] **Step 10.5: App MVP 跑通**

App plan 执行。

- [ ] **Step 10.6: Firebase project 创建 + Storage 上传测试**

云 plan 执行。

- [ ] **Step 10.7: Gate C 通过 commit + tag**

```bash
git commit --allow-empty -m "Gate C passed: bench-level units functional"
git tag gate-C
```

### Task 11: Gate C → D 转换 — 集成就绪

- [ ] **Step 11.1: 硬件全部到位**

- [ ] **Step 11.2: 固件 + App 真 BLE 集成测试**

- [ ] **Step 11.3: App 读取真 SD 卡日志**

- [ ] **Step 11.4: Firebase session 上传 + Cloud Function 触发验证**

- [ ] **Step 11.5: OTA 流程通过测试**

- [ ] **Step 11.6: Gate D 通过 commit + tag**

```bash
git commit --allow-empty -m "Gate D passed: integration ready"
git tag gate-D
```

### Task 12: Gate D → E 转换 — 上车静态 + 低速

集成测试 plan 执行 Phase 2 + Phase 3。

- [ ] **Step 12.1: Phase 2 静态集成 - 全 28 项启动自检通过**

- [ ] **Step 12.2: Phase 3 停车场低速 30 分钟无 fault**

- [ ] **Step 12.3: Gate E 通过 commit + tag**

```bash
git commit --allow-empty -m "Gate E passed: on-bike static + low speed validated"
git tag gate-E
```

### Task 13: Gate E → F 转换 — 中速空旷路

集成测试 plan 执行 Phase 4。

- [ ] **Step 13.1: Phase 4 70-100 km/h, 60 分钟无 fault**

- [ ] **Step 13.2: 9 状态触发数据全部回放分析**

- [ ] **Step 13.3: Gate F 通过 commit + tag**

```bash
git commit --allow-empty -m "Gate F passed: mid-speed validated"
git tag gate-F
```

### Task 14: Gate F → G 转换 — 赛道基线

集成测试 plan 执行 Phase 5。

- [ ] **Step 14.1: 赛道日 #1 - aero 完全禁用**

按 spec §8.5 的实验协议完成。

- [ ] **Step 14.2: 基线数据归档**

CSV + 视频 + 实验报告进 Firebase。

- [ ] **Step 14.3: Gate G 通过 commit + tag**

```bash
git commit --allow-empty -m "Gate G passed: baseline established"
git tag gate-G
```

### Task 15: Gate G → H 转换 — Active Aero 验证

集成测试 plan 执行 Phase 6。

- [ ] **Step 15.1: 赛道日 #2 - aero 工作**

- [ ] **Step 15.2: KPI 对比分析**

| 指标 | 期望 | 警戒线 |
|---|---|---|
| 100-0 刹车距离 | -5~-10% | 不退步 |
| 0-100 加速 | ±0.2s | 不退步 |
| 直线尾速 | ±2 km/h | 不退步 |
| 过弯稳定性 | -10% IMU 噪声 | 不变差 |
| 续航 | -3~-5% | 不显著退步 |

- [ ] **Step 15.3: 通过判据 = 刹车改善 ≥ 3% AND 其他不退步**

- [ ] **Step 15.4: 结题报告**

写 `docs/v1-completion-report-YYYYMMDD.md`，包含：
- 全部测试数据
- KPI 实际值
- 与设计预期的偏差分析
- v2 触发条件评估
- 经验教训 + bug 历史

- [ ] **Step 15.5: Gate H 通过 commit + tag**

```bash
git commit --allow-empty -m "Gate H passed: v1 active aero validated, project milestone complete"
git tag gate-H
git tag v1.0
```

---

## 跨子系统依赖矩阵

| 子系统 | 依赖于 | 阻塞 |
|---|---|---|
| 机械 | 仅 spec | 电子（外壳尺寸）、集成（车上装配） |
| 电子 | 仅 spec + IC-1, IC-6 | 固件（实物硬件）、集成 |
| 固件 | 仅 spec + IC-1, 2, 3, 4 | App、集成、云 |
| App | 仅 spec + IC-2, 3, 4, 5 | 集成、用户体验 |
| 云 | 仅 spec + IC-5 | App（云 client）、固件（OTA） |
| 集成 | 全部 | 项目完成 |

**关键并行机会**：
- 机械 / 电子 / 固件 / App / 云 5 个 plan 的 **设计与早期任务** 可在 Gate A 后**完全并行**（不同 agent 独立工作）
- 它们汇合于 Gate C（台架单元）和 Gate D（集成就绪）

---

## Self-Review 检查

执行完每一份子系统 plan 后，回到 master plan 跑一次自审：

1. **接口契约是否被遵守？** 每个 plan 都应明确引用并实现 IC 中的相关项
2. **Gate 通过判据是否对应任务？** Gate C-H 每个判据应能在某个 task 输出中找到
3. **是否有 silent dependency？** 比如 App 突然依赖了某个 cloud 字段，但云 plan 还没定义

---

## 风险与未决项 (待决策)

| # | 风险 / 未决项 | 待决策项 | 推荐 |
|---|---|---|---|
| R1 | 第一台装机选哪台？ | GSX250R vs RC450 | 推荐 GSX250R：转速低、刹车距离测量基线好建、改装件好买 |
| R2 | Firebase 国内访问慢 | 是否切 Supabase 自托管 | v1 先 Firebase，若 OTA 实际太慢再切 |
| R3 | 没有风洞访问 | Aero 系数靠路试经验 ±20% 校正 | 接受 v1 工程精度 |
| R4 | CNC 厂选择 | 嘉立创精密 / 立创 EDA-Pro / 三阪精密 / 闲鱼 | 三家比价，留预算空间 |
| R5 | 充电宝最终选型 | Anker 737 vs 小米 vs 京东京造 | Anker 737 经过验证，国内能买 |

---

**END OF MASTER PLAN**
