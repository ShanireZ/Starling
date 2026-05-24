# Starling — Active Front Aero for Motorcycles

**设计规格 (Design Specification)**

| | |
|---|---|
| 项目代号 | **Starling** |
| 文档日期 | 2026-05-17 |
| 文档版本 | 1.0 (initial design) |
| 状态 | 设计阶段，待进入实现计划 |
| 设计者 | Shanire (产品决策 + 组装) + AI Agent 编排团队 |

---

## 1. 项目概览

### 1.1 目标

为摩托车设计一套 **电子自动控制的车头两侧可变翼片系统**（active front aero），实现：

- **高速巡航**：翼片贴平 + 微小负迎角 → 最小阻力，零下压力扰动
- **正常骑行**：翼片默认 0° → 利用 NACA 4412 倒装翼型自然产生下压力，提升前轮抓地与抗 wheelie
- **刹车 / 减速**：翼片由 0°（贴平）立起至最大 +70° → 产生大面积气动阻力作为辅助减速器（刹车只用正角度；负角度 −5° 用于减阻/过弯。整机行程见 §3.1：−5°…+70°）
- **过弯**：轻微反向偏置 → 避免下压力扰动前轮转向手感
- **抗 wheelie**：检测前轮抬起趋势时 → 额外下压力压制前轮

### 1.2 项目定位

- **形态**：真车原型（不仅是仿真 / CAD）
- **市场定位**：aftermarket 改装级，**不走法规认证**
- **使用场景**：赛道日 + 山路骑制作（场景 2 + 4，"性能 + 工程数据验证"）
- **载体平台**：**双适配** —— Suzuki GSX250R-A 2022 + KTM RC 450 (KM400, 2026 中国上市)
- **HMI**：全自动、骑手无感；仅通过手机 App 查看 / 调参
- **第一轮原型预算**：20,000+ RMB（成品级 / 可量产原型）

### 1.3 工作模式

- **决策者 + 装配者**：项目所有人（Shanire），不亲自做 CAD / PCB / 嵌入式
- **实现团队**：AI Agent 编排，覆盖机械、电气、固件、App、云、数据分析
- 所有交付物**必须可由下游 agent 直接执行**（无歧义 STEP / Gerber / 编译可构建工程）

### 1.4 关键车辆规格

| 参数 | GSX250R-A 2022 | KTM RC 450 (2026) |
|---|---|---|
| 引擎 | 248cc 双缸 SOHC | 449cc 双缸 270° crank |
| 功率 | 25 hp | 56 hp |
| 极速 | ~140 km/h | **195 km/h** |
| 整备质量 | 178 kg | 168 kg |
| 电子套件 | 基础 ABS | Bosch 全套（弯道 ABS / TCS / 巡航 / 快排，含可读 CAN） |
| 整流罩 | 全包覆 sport-tourer | 全包覆 supersport |

设计载荷以 **RC 450 顶速 195 km/h** 为锚点（动压 1800 Pa）。

---

## 2. 系统级架构

### 2.1 6 模块结构

```
                                         手机 App
                                      （WiFi STA / BLE）
                                            ▲
                                            │ JSON telemetry @ 10Hz
                                            │
┌──────────────┐    ┌──────────────────────┴──────────────────┐    ┌──────────────┐
│  传感模块     │    │            主控板 / MCU                  │    │  驱动模块     │
│              │    │                                          │    │              │
│ • GPS u-blox │──→│  ┌────────────────────────────────────┐  │    │ • 左舵机      │
│ • IMU BMI270 │    │  │ Layer 4: 通信 (WiFi/BLE/UART)      │  │    │ • 右舵机      │
│ • 轮速 Hall  │I2C │  ├────────────────────────────────────┤  │←──→│ • 角度编码器  │
│ • 刹车杆 Hall│ /  │  │ Layer 3: 数据采集 (SD/缓冲)         │  │PWM │   ×2        │
│ • 翼片角度   │GPIO│  ├────────────────────────────────────┤  │    │ • 防水接插件 │
│ • 电源监控   │ /  │  │ Layer 2: 控制 (FSM + 查表 + 内层PID) │  │    │              │
│              │UART│  ├────────────────────────────────────┤  │    └──────────────┘
└──────────────┘    │  │ Layer 1: 传感融合 (Mahony + 滑窗)  │  │
                     │  ├────────────────────────────────────┤  │    ┌──────────────┐
                     │  │ Layer 0: HAL (硬件抽象)            │  │    │ 机械结构     │
                     │  └────────────────────────────────────┘  │    │              │
                     │           ▲                              │    │ • 翼片 ×2    │
                     │           │ Heartbeat                    │    │ • 转轴 ×2    │
                     │  ┌────────┴──────┐                       │    │ • 复位扭簧   │
                     │  │ ATtiny85       │ 失效时切舵机 MOSFET   │    │ • 副框架     │
                     │  │ 独立 watchdog  │ → 弹簧+气动 复位     │    │   (双 SKU)   │
                     │  └───────────────┘                       │    └──────────────┘
                     └──────────────────────────────────────────┘
                                            ▲
                                            │ USB-C PD (9V → 7.4V/5V 经板载 DC/DC)
                                            │
                                     外置 USB-PD 充电宝
                                  (Anker 737 / 24000mAh 140W)
```

| # | 模块 | 物理位置 | 输入 | 输出 |
|---|---|---|---|---|
| 1 | 传感模块 | 整流罩内 + 后轮 + 车架 | 5V 电源 | GPS / IMU / 轮速脉冲 / 刹车 / 翼片角度 |
| 2 | 主控板 | 油箱下 / 副驾位防水盒 | 传感数据 + 9V | 舵机 PWM ×2，SD/WiFi/BLE 数据流 |
| 3 | 驱动模块 | 整流罩内（左右各一） | 主控 PWM + 7.4V | 翼片旋转 + 角度反馈 |
| 4 | 机械结构 | 整流罩侧面 | 驱动扭矩 | 翼片角度（气动力作用于车架） |
| 5 | 手机 App | 用户 Android（iOS in v2） | BLE/WiFi | 实时可视 + 日志离线分析 |
| 6 | 独立健康监控 | 主控板内 | 心跳 + 总线电流 | 故障切断舵机供电 |

### 2.2 5 层防御纵深

```
Layer 5: 气动复位 (转轴 70% 弦长 → 气动力天然推回贴平)        ←—— 物理层
Layer 4: 机械复位 (扭簧 1.0 N·m → 断电立即拉回 0°)            ←—— 物理层
Layer 3: 独立 watchdog (ATtiny85 → 切舵机电源)                ←—— 硬件层
Layer 2: 主 MCU FAULT 状态 (软命令 0° + 禁用 PID)              ←—— 软件层
Layer 1: FSM 状态机 (优先级仲裁 + 7 项 health check)           ←—— 软件层
```

**关键不变量**：任何单一失效都被 **至少 3 层** 捕获。Layer 5（气动复位）不依赖任何电子系统。

---

## 3. 机械设计

### 3.1 翼片气动尺寸

```
单边翼片：弦长 120mm × 翼展 350mm = 420 cm²
翼型：    NACA 4412 倒装（4% camber 朝下，产生下压力）
转轴：    70% 弦长（即 leading edge 后 84mm）
工作角度：-5°（减阻）↔ +70°（最大立起）；弹簧中性 / 失效复位位 = 0°（贴平）
```

> **AMENDMENT (OQ-7, 2026-05-24):** 工作角度范围由原 "0°↔+70°，-5° 为 v2 扩展" **修订为 v1 即包含 -5°…+70°**（总行程 75°）。原意保留供追溯：-5° 仍是"取消 camber、趋近零阻力"的减阻位。变更原因：IC-4 查找表在 v1 已对 DRAG_REDUCE/CORNERING 下发 -3°/-5°，物理行程必须能到达。**关键不变量：弹簧中性 / 失效复位 / FAULT 目标位仍为 0°（贴平）**——断电时扭簧仍把翼片拉回 0° 平贴；-5° 是**仅上电可达**（舵机主动驱动到中性以下）。IC-4 表本身不变。详见 master plan IC-4 与机械 plan OQ-7 传播。

**性能曲线（双侧总和）**：

| 速度 | 默认 0°（下压力 / 阻力） | 最大 +70°（阻力） | 备注 |
|---|---|---|---|
| 60 km/h | 3 N / 1 N | 13 N | 城市低速气动可忽略 |
| 100 km/h | 16 N / 3 N | 48 N | 高速公路巡航 |
| 140 km/h (GSX 顶速) | 31 N / 6 N | 95 N | 实际刹车场景 |
| 195 km/h (RC450 顶速) | **60 N / 12 N** | **180 N** | 赛道直线尾速 |

195 km/h 全立起时 **180 N 总气动阻力 ≈ 7.3% 额外减速**（RC450 + 75kg 骑手）。

> **注**：上述系数基于 NACA 4412 二维理论 + 简化端板修正。**实际装机后需要风洞或路试 ±20% 验证**；最终运行表是在阶段 5/6 实测数据基础上修订的。

### 3.2 翼型选择

**NACA 4412 倒装**：4% camber 朝下（生成下压力），12% 厚度（结构强度）。倒装的设计意图：

- 默认贴平（几何 0°）即产生 60-120 N 下压力（速度相关）
- 不需要倾斜驱动即可获得"基础下压力"
- 通过驱动到 -5° 可"取消"camber 效果，趋近零阻力（v1 DRAG_REDUCE 状态用，仅上电可达；见 §3.1 OQ-7 修订）
- 驱动到 +70° 进入大角度失速区，最大阻力

### 3.3 转轴位置 — 70% 弦长

设计意图：把压力中心（~50% 弦长处）放在转轴**前方**，气动力天然把翼片往贴平方向推。这是 **Layer 5 气动复位** 的物理实现。

工程取舍：
- 25% 弦长（aero center，MotoGP 固定翼用）→ 静稳定，但需要驱动持续工作维持任何角度
- 70% 弦长（我们的选择）→ 自带"weathercock"复位，断电时气动力主动协助弹簧
- 100% 弦长（trailing edge）→ 气动力臂太大，驱动扭矩需求过高

### 3.4 驱动扭矩校核

```
70° 立起时 @ 195 km/h：
  气动力法向 ≈ 95 N（单侧）
  气动力对转轴力臂 ≈ 24 mm（70% - 50% 弦长 = 20% × 120mm）
  气动反扭 ≈ 2.3 N·m
  + 扭簧反力 ≈ 1.0 N·m
  ─────────────
  舵机峰值扭矩需求 ≈ 3.3 N·m = 33.6 kg·cm
```

### 3.5 舵机选型分阶段

| 版本 | 舵机型号 | 扭矩 | 单价 RMB | 理由 |
|---|---|---|---|---|
| v1 | **DSServo RDS5160** | 60 kg·cm 金属齿 | 400 | 验证阶段，1.78x 余量足；坏掉损失低 |
| v2 | **Savox SB-2290SG** | 50 kg·cm 钢齿无刷防水 | 2500 | 产品级，IP67，长期耐久 |

### 3.6 复位扭簧

- 不锈钢 SS304 双线圈
- 0°: 0.5 N·m 初载（保持贴平不被微小气流震动）
- 70°: 1.0 N·m（断电时把翼片拉回）
- 预期寿命 > 10⁶ 次循环

### 3.7 安装架构 — 通用模块 + 双 SKU 副框架

```
通用模块（一套硬件）              车型专属（两套 SKU）
┌───────────────────┐              ┌────────────────────┐
│ 翼片本体 ×2        │              │ GSX250R 副框架     │
│ 转轴 + 轴承 ×2     │              │ • 6061-T6 CNC      │
│ 扭簧 ×2            │  ── 4 螺栓 ──│ • 走车架原厂安装点  │
│ 防水舵机盒 ×2      │     标准位    │ • 整流罩切口模板   │
│ 角度编码器 ×2      │              ├────────────────────┤
│ 4 螺栓接口         │              │ KTM RC450 副框架   │
└───────────────────┘              │ • 同 4 螺栓接口    │
                                    │ • Trellis 车架适配 │
                                    └────────────────────┘
```

**关键决策**：副框架通过 4 个 M6 螺栓接到车型专属副框架，**全部承力路径走车架原厂硬点**，整流罩不承力。整流罩仅开 ∅12mm 走线孔 + 翼片伸出造型切口（EPDM 密封防水）。

### 3.8 翼片本体材料与制造路径

采用 **三阶段渐进路径**，每阶段都建立在前一阶段验证基础上：

```
v1：3D 打印 直接成翼            v2：3D 打印模具 → 碳纤湿布 layup        v3：CNC 模具 → 预浸料 autoclave
┌──────────────────┐           ┌──────────────────────────────┐         ┌──────────────────────────┐
│ SLA 结构树脂      │   验证   │ 1. PETG / SLA 打印 上下半模    │  量产化  │ CNC 钢模 / 铝模           │
│ (Formlabs        │   →      │ 2. 模具表面打磨 + 离型剂涂层    │  →      │ + 碳纤预浸料 prepreg       │
│  Tough 2000)     │           │ 3. 碳纤布 + 环氧树脂湿布 layup │         │ + autoclave 加压固化       │
│ + ∅3mm 碳棒纵梁  │           │ 4. 真空袋 + 室温 24h 固化     │         │ + 自动化脱模               │
│                  │           │ 5. 脱模 + 修边 + 表面处理     │         │                            │
│ ~300 RMB / 翼   │           │ ~800 RMB / 翼 (含模具一次)    │         │ ~2000 RMB / 翼 (摊销后)   │
└──────────────────┘           └──────────────────────────────┘         └──────────────────────────┘

  迭代成本最低，               介于二者之间，碳纤翼               量产单价最低，
  适合验证翼型 / 装配 / 控制     是真正的产品形态，              但模具开发 ~30K，
  低速测试 ≤ 80 km/h           可走全速测试 / 长期耐久              仅当确定 50+ 套订单时合算
```

**关键决策**：v2 不用 CNC 铝芯方案 —— 改为 **3D 打印模具 + 手工 layup**。原因：

- 3D 打印模具开发周期 1-2 天（CNC 铝芯需要 1-2 周）
- 模具可改型迭代（CNC 改一次成本几乎等于重做）
- 翼面表面质量取决于 layup 工艺而非模芯（CNC 铝芯仍要表面涂层）
- 一套 3D 打印模具可做 5-10 件翼后再换（碳纤布脱模磨损模具）

**v1 阶段也保留 "3D 打印替换件" 库存** —— 翼片若在装配或低速测试中损坏，~6 小时即可重新打印。

### 3.9 制造路径节点交付（给 AI agent 编排）

| 节点 | 输入 | 输出 |
|---|---|---|
| 3.9.1 翼片 CAD | NACA 4412 翼型坐标 + 弦长 120mm + 翼展 350mm + 转轴位置 | 翼片 STEP / STL（v1 直接打印用）+ 上下半模 STEP / STL（v2 打模具用） |
| 3.9.2 v1 3D 打印 | 翼片 STL + 树脂选型 | SLA 翼片 ×4（每车 2 片 + 备份 2 片） |
| 3.9.3 v2 模具打印 | 半模 STL + PETG 选型 | 一套 PETG 上下半模（可打 5-10 翼） |
| 3.9.4 v2 碳纤翼制造 | 半模 + 碳纤布选型 + 树脂 | 碳纤翼 ×4 + 装配测试报告 |
| 3.9.5 v3 量产模具 | 半模 STEP + 钢 / 铝选型 + 表面处理规格 | CNC 钢/铝模具（仅当 v3 确定时执行） |

---

## 4. 电子与驱动

### 4.1 主控板架构 — 全 SMT 定制 PCB

```
Backplane PCB（定制 2 层，JLCPCB SMT 全装配）
外形 100 × 120 mm，装入 IP67 防水盒
┌─────────────────────────────────────────────────────────────────────┐
│                                                                      │
│   [ESP32-WROOM-32E]  [ATtiny85]                                     │
│   主 MCU（直焊）       独立 watchdog（直焊）          [DC/DC]        │
│   ▪ FSM + FF + PID    ▪ <50 行代码                 ▪ 9V→7.4V/8A     │
│   ▪ 数据采集           ▪ 监听主MCU心跳                (servo rail)   │
│   ▪ WiFi/BLE          ▪ 看门狗超时 → 双 MOSFET     ▪ 9V→5V/3A       │
│      telemetry          切断 servo 电源              (MCU rail)     │
│                                                     ▪ 法拉电容       │
│   连接器（全 IP67）:                                  buffer 1F×4    │
│   ▶ J1: GPS (UART, 4-pin)                                            │
│   ▶ J2: IMU 已直焊                                                   │
│   ▶ J3: 轮速 Hall (digital, 3-pin 屏蔽线)                            │
│   ▶ J4: 刹车杆 Hall (digital, 3-pin 屏蔽线)                          │
│   ▶ J5/J6: 角度编码器 ×2 (I2C, 5-pin 屏蔽线)                          │
│   ▶ J7/J8: 舵机 ×2 (PWM + 7.4V, 4-pin)                               │
│   ▶ J9: SD 卡 (板载 SMD socket)                                      │
│   ▶ J10: USB-C 输入 (PD 协议，盒外密封盖)                              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.2 BOM (v1 第一台原型)

| # | 模块 | 型号 | 数量 | 单价 RMB | 小计 |
|---|---|---|---|---|---|
| 1 | ESP32-WROOM-32E 模组 | 直焊上 PCB | 1 | 30 | 30 |
| 2 | ATtiny85 SOIC | 直焊上 PCB | 1 | 5 | 5 |
| 3 | u-blox NEO-M9N + 天线 | GPS | 1 | 250 | 250 |
| 4 | Bosch BMI270 | IMU 直焊 | 1 | 50 | 50 |
| 5 | AS5600 编码器 + 磁铁 | 翼片角度 | 2 | 30 | 60 |
| 6 | A3144 + 磁铁 (套件 ×2) | 后轮 Hall + 刹车杆 Hall | 2 | 10 | 20 |
| 7 | SMD MicroSD socket + 32GB 工业卡 | 数据采集 | 1 | 35 | 35 |
| 8 | **DSServo RDS5160** | 60 kg·cm 金属齿 | 2 | 400 | 800 |
| 9 | USB-PD trigger 9V | 9V 输出贴片模块 | 1 | 20 | 20 |
| 10 | DC/DC 9→7.4V/8A | 工业级 sealed | 1 | 60 | 60 |
| 11 | DC/DC 9→5V/3A | TPS5430 SMT | 1 | 30 | 30 |
| 12 | 法拉电容 buffer | 5.5V 1F ×4 | 4 | 5 | 20 |
| 13 | **定制 PCB + SMT 全装配** | JLCPCB 5 片打样 | 5 | 100 | 500 |
| 14 | IP67 防水盒 | ABS + 4× PG 防水接头 | 1 | 200 | 200 |
| 15 | 防水接插件 | Marine-grade IP67 | 1 套 | 200 | 200 |
| 16 | **Anker 737 充电宝** | 24000mAh / 140W USB-PD | 1 | 600 | 600 |
| 17 | USB-C to XT60 cable | PD 协议线 | 1 | 80 | 80 |
| 18 | 屏蔽线 + 紧固 + 杂项 | 走线套件 | 1 套 | 150 | 150 |
| **电子小计** | | | | | **3110** |

### 4.3 零摩托车电气改装

v1 完全使用外置 USB-PD 充电宝供电：

```
摩托车电气系统  ←× 完全不接 ×→  Starling 系统
                                   ↑
                              USB-C PD
                                   ↑
                            外置 Anker 737
                          (放坐桶 / 油箱包)
```

- **正面效益**：拆装可逆性 100%，赛道日失败可立即拆下
- **续航估算**：平均 20W 功耗下，24000 mAh @ 9V 约 5 小时（一个完整赛道日）
- **v2 选项**：可选连接摩托车 12V 电瓶（用户自选）

### 4.4 磁感刹车杆传感器

不 tap 摩托车刹车灯线，改用非接触磁感方案：

```
正常握把姿态：                  捏刹车后：
  ┌─握把─┐                       ┌─握把─┐
  │ 磁铁 │ ← A3144 (HIGH)        │      │
  └──┬──┘                        └──┬──┘
     │                              │ 磁铁随手柄旋开
   主缸                            主缸
     │                              │ ← A3144 (LOW)
                                    │   ✓ 检测到刹车意图
```

- 完全非接触，拆下即恢复
- 反应时间 < 1 ms
- 物料 ~20 RMB

---

## 5. 传感与控制逻辑

### 5.1 两层控制架构

```
┌────────────────────────────────────────────────────────────────┐
│  外层（决策层）                                                  │
│  FSM 状态机 → 各状态查找表 → 目标翼角 θ_target                   │
│  • 优先级仲裁（9 状态）                                          │
│  • 速度阈值、刹车检测、IMU 减速 → 状态切换                       │
│  • 状态内根据速度查 CSV 表得 θ_target                           │
│  • v1：纯前馈                                                   │
│  • v2：BRAKING_HARD 状态内 PID（目标减速度 → ±Δθ 修正，限幅 ±10°）│
└────────────────────────┬───────────────────────────────────────┘
                         │ θ_target (°)
                         ▼
┌────────────────────────────────────────────────────────────────┐
│  内层（执行层）                                                  │
│  PID 位置闭环：θ_target − θ_measured (AS5600) → PWM 给舵机     │
│  • 100Hz 控制循环                                               │
│  • 内置在所有版本里，永远开启                                    │
│  • 编码器 vs 舵机命令偏差 > 5° 持续 100ms → 触发 FAULT           │
└────────────────────────────────────────────────────────────────┘
```

### 5.2 9 状态优先级仲裁

每 10ms 循环，从高到低评估条件，**第一个命中的状态生效**。

```
优先级           状态名              典型场景            目标角度策略
═══════════════════════════════════════════════════════════════════════
  9   FAULT             硬故障              health check 任一爆 → 命令 0° + ATtiny85 切电
  8   WHEELIE_GUARD     抗 wheelie 警戒     IMU pitch > 8° OR 油门>80% 加速 > 0.6g  → +30° 增前轮下压力
  7   BRAKING_HARD      重刹 / 紧急         减速 > 0.5g OR brake_lever + 减速 > 0.4g → 70° 满 airbrake
  6   BRAKING_LIGHT     轻刹 / 减速接近     0.2g < 减速 ≤ 0.5g OR brake_lever       → 表(v) 中等立起
  5   TRAIL_BRAKE       弯中带刹            BRAKING_LIGHT/HARD AND |lean| > 15°    → BRAKING 角度 × 0.5（衰减）
  4   CORNERING         弯道（无刹）        |lean| > 15° 持续 200ms                → -3°（轻微减阻避免扰动）
  3   DRAG_REDUCE       高速巡航 / 直线尾速 v > 150 km/h AND |accel| < 0.1g AND |lean| < 5° 持续 5s → -5°（最大减阻）
  2   CRUISE            正常巡航            v ∈ [60, 150] km/h，无以上特殊条件     → 0°（默认下压力）
  1   LOW_SPEED         低速 / 城市         5 < v < 60 km/h                       → 0°（不动）
  0   PARKED            停车                v < 5 km/h 持续 1s                    → 0°（不动）
```

仲裁伪代码：

```c
state_t evaluate_state() {
    if (fault_flag) return FAULT;
    if (wheelie_detected()) return WHEELIE_GUARD;
    if (brake_intent && decel > 0.5) return BRAKING_HARD;
    if (brake_intent || decel > 0.2) {
        if (abs(lean) > 15) return TRAIL_BRAKE;
        return BRAKING_LIGHT;
    }
    if (abs(lean) > 15) return CORNERING;
    if (speed > 150 && abs(accel) < 0.1 && abs(lean) < 5 && timer_high_speed > 5s) return DRAG_REDUCE;
    if (speed >= 60) return CRUISE;
    if (speed > 5) return LOW_SPEED;
    return PARKED;
}
```

### 5.3 查找表（v1 初始值）

**CRUISE**：恒 0° 几何角，下压力靠 NACA 4412 + 速度 q 自动产生。

```csv
speed_kmh,angle_deg
60,0
100,0
150,0
```

**BRAKING_LIGHT**：

```csv
speed_kmh,angle_deg
30,25
50,40
80,55
120,60
160,62
```

**BRAKING_HARD**：

```csv
speed_kmh,angle_deg
30,30
50,50
80,65
120,70
160,70
```

**DRAG_REDUCE**：

```csv
speed_kmh,angle_deg
150,-3
170,-4
195,-5
```

**TRAIL_BRAKE**：取 BRAKING_LIGHT 或 BRAKING_HARD 查表值的 0.5 倍。

**CORNERING**：恒 -3°。

**WHEELIE_GUARD**：恒 +30°。

**LOW_SPEED / PARKED / FAULT**：恒 0°。

### 5.4 传感器融合策略

| 量 | 主源 | 次源 | 融合策略 |
|---|---|---|---|
| 速度 | GPS（10Hz） | 后轮 Hall（kHz） | GPS 健康时为主；GPS 丢失 > 0.5s 切 Hall；后轮抬起（Hall=0 但 GPS>0）→ 用 GPS |
| 刹车意图 | 磁感刹车杆 Hall（1ms） | IMU 长向减速 > 0.3g（100ms 滤波） | OR 关系增加灵敏度 |
| 倾角 | IMU 角速度积分 | 加速度向量重力分解 | Mahony 互补滤波（50Hz 更新，需要发动机振动 30Hz 低通预处理） |
| 翼片角度 | AS5600 编码器 | 舵机内部 PWM 反推 | 编码器为唯一可信源，舵机反推仅供 fault 检测 |

### 5.5 健康检查清单

每 10ms 检测，任一硬故障 → FAULT：

```
1. servo_command vs encoder_angle 偏差 > 5° AND 持续 > 100ms       → HARD FAULT
2. supply_voltage < 4.5V（电池低 / DCDC 故障）                     → HARD FAULT
3. IMU I2C 读失败连续 3 次                                          → HARD FAULT
4. GPS NO_FIX 持续 > 5s                                            → SOFT 降级（不进 FAULT，禁用倾角逻辑）
5. wheel_speed 与 GPS_speed 偏差 > 30% 持续 > 1s                    → SOFT 降级
6. cpu_loop_jitter > 2x normal                                     → HARD FAULT
7. ATtiny85 心跳超时（主 MCU 卡死）                                  → ATtiny85 切电（独立于主 MCU）
```

### 5.6 转场平滑

- 角度斜率限制：最大变化率 **300°/秒**
- 状态切换迟滞：进 CRUISE 用 60 km/h，退 CRUISE 用 55 km/h；进 BRAKING 阈值低，退 BRAKING 阈值高

### 5.7 100Hz 控制循环伪代码

```c
void control_loop_10ms() {  // timer 中断触发
    sensor_fusion();
    health_check();
    if (fault_flag) {
        commanded_angle = 0;
        goto SERVO_DRIVE;
    }
    current_state = evaluate_state();  // 优先级仲裁
    target_angle = lookup_table[current_state](current_speed);
    // v2: target_angle += pid_correction(target_decel, measured_decel);
    target_angle = rate_limit(target_angle, last_angle, MAX_SLEW);
SERVO_DRIVE:
    servo_drive(target_angle);
    encoder_check(target_angle);
    last_angle = target_angle;
    log_buffer_push(sensors, state, target_angle, fault_flag);
}
```

---

## 6. 数据采集、遥测与云

### 6.1 三层数据架构

```
┌──────────────────────────────────────────────────────────────────┐
│  Layer 3: 云后端 (Firebase / Supabase)                            │
│  • 会话自动上传（WiFi STA 在线 + 充电时）                          │
│  • Firestore 元数据 + Cloud Storage 大文件                        │
│  • Cloud Functions 分析处理                                       │
│  • OTA 固件分发                                                    │
└────────────────────────────▲─────────────────────────────────────┘
                              │ 压缩 + 断点续传上传
┌────────────────────────────┴─────────────────────────────────────┐
│  Layer 2: Flutter 原生 App（Android first, iOS v2）              │
│  • BLE 10Hz 实时遥测                                              │
│  • WiFi STA 拉日志大文件                                          │
│  • 在线分析 / 表编辑 / 仿真预览                                    │
│  • Crashlytics + Push 通知                                        │
└────────────────────────────▲─────────────────────────────────────┘
                              │ BLE GATT @ 10Hz / WiFi STA 文件
┌────────────────────────────┴─────────────────────────────────────┐
│  Layer 1: ESP32-S3 主控板                                         │
│  • 100Hz 控制循环 + 100Hz 写 RAM 环形缓冲                          │
│  • 1Hz flush 环形缓冲 → SD 卡（binary 128B 帧）                    │
│  • 文件按 10 分钟自动 rotate                                       │
└──────────────────────────────────────────────────────────────────┘
```

### 6.2 二进制数据帧 schema（128 B / 帧，100Hz）

> **AMENDMENT (OQ-3, 2026-05-24):** 本 struct 已按 master plan IC-3 契约**修正**。修正前的版本字段排列存在缺陷：字段实际求和仅为 **124 字节**（`lookup_table_version` 落在 offset 96、CRC16 落在 offset 122），与 IC-3 声明的「`lookup_table_version` 是 **uint8 @ byte 99**、帧长 **128 B**、CRC16 @ **offset 126**」不符。经人工裁决：**IC-3 为权威**。下面的 struct 已重排 padding 使字段精确求和为 128 字节，并将版本字段改为 **uint8 @ byte 99**、CRC16 固定在 **offset 126**。固件 plan（Task 20）与 Python 分析器（Task 44）已按此布局实现，二者用 `_Static_assert(offsetof(...lookup_table_version)==99)` / `TABLE_VERSION_OFFSET=99` 锁定。

```c
typedef struct __attribute__((packed)) {
    // 时间 (12B)
    uint64_t time_us;                 // off 0
    uint32_t gps_time_unix;           // off 8
    // GPS (20B)
    int32_t  gps_lat_e7, gps_lon_e7;  // off 12, 16
    int16_t  gps_alt_dm;              // off 20
    uint16_t gps_speed_kmh_cx100;     // off 22
    uint8_t  gps_fix_type, gps_hdop, gps_sats;  // off 24, 25, 26
    uint8_t  pad1[5];                 // off 27..31
    // IMU 原始 (24B)
    int16_t  ax, ay, az, gx, gy, gz;  // off 32..43
    uint8_t  pad2[12];                // off 44..55
    // 姿态融合 (8B)
    int16_t  roll_cdeg, pitch_cdeg, yaw_cdeg;   // off 56, 58, 60
    int16_t  linear_accel_long_cms2;  // off 62
    // 控制相关 (24B)
    uint16_t wheel_speed_kmh_cx100;   // off 64
    uint8_t  brake_lever_active, state_current; // off 66, 67
    int16_t  target_angle_l_cdeg, target_angle_r_cdeg;     // off 68, 70
    int16_t  measured_angle_l_cdeg, measured_angle_r_cdeg; // off 72, 74
    uint16_t servo_current_l_ma, servo_current_r_ma;       // off 76, 78
    uint8_t  pad3[8];                 // off 80..87
    // 健康 (8B)
    uint8_t  fault_flag, health_bits; // off 88, 89
    uint16_t supply_voltage_mv, supercap_voltage_mv;       // off 90, 92
    uint16_t cpu_loop_us;             // off 94
    // 杂项 (30B) — OQ-3 修正：版本字段是 uint8 @ byte 99（IC-3 权威）
    uint8_t  pad_misc[3];             // off 96..98  (对齐 version 到 byte 99)
    uint8_t  lookup_table_version;    // off 99  (IC-3 不变量：byte 99，uint8)
    uint8_t  pad4[26];                // off 100..125
    // CRC (2B)
    uint16_t crc16;                   // off 126
} starlog_frame_t;  // 总长 128 字节（字段精确求和 = 128，CRC16 @ offset 126）
```

100Hz × 128B = **12.5 KB/秒 = 45 MB/小时**。32GB SD 容量 ≈ **700 小时**。

### 6.3 文件管理

- 单文件最多 10 分钟（~7.5MB）或 100MB
- 命名：`starlog_YYYYMMDD_HHMMSS.starlog`
- 头部 4KB header：版本、传感器配置、表 hash、骑手备注

### 6.4 Flutter App 架构

| 项 | 选择 |
|---|---|
| 框架 | Flutter (Dart) |
| 阶段 | v1 Android-only beta；v2 iOS |
| 通信 | BLE GATT (实时) + WiFi STA (文件) |
| 图表 | fl_chart |
| 状态管理 | Riverpod |
| BLE 库 | flutter_blue_plus |

**核心页面**：Dashboard / Recording / Sessions / Table Editor / Calibration / Health / Settings

**杀手特性**：表编辑器内置 sandbox 仿真 —— 改完表后用历史 session 回放看新表效果，再决定是否写回 ESP32。

### 6.5 BLE GATT 服务定义

```
Service: Starling Active Aero (UUID 自定义)
├─ Char: telemetry_live    (notify @10Hz, 50B 二进制)
├─ Char: command            (write, JSON)
├─ Char: status             (read, 系统信息)
├─ Char: table_data         (read/write, 9 个查找表 CSV)
└─ Char: session_list       (read, SD 文件列表)

File download: ESP32 WiFi STA + 本地 IP HTTP API
```

### 6.6 云后端

| 项 | **默认：Firebase** | 备选：Supabase 自托管 |
|---|---|---|
| Auth | Firebase Auth | Supabase Auth |
| 元数据 | Firestore (NoSQL) | PostgreSQL |
| 文件 | Cloud Storage | Supabase Storage (S3) |
| 后台计算 | Cloud Functions | Edge Functions |
| 国内访问 | 差，需绕路 | 自托管阿里云/腾讯云 |

云端功能矩阵：

| 功能 | v1 | v2 |
|---|---|---|
| 会话自动上传 | ✓ | — |
| Web 分析控制台 | ✓ 基础 | 高级（多 session / 赛道分段对比） |
| 固件 OTA | ✓ | 灰度发布 |
| 多车 profile | ✓ | 多用户 / 多车队 |
| 赛道分段分析 | — | ✓（GPS 地理围栏 + 圈速） |
| 查找表市场 | — | ✓（社区分享赛道优化表） |

### 6.7 离线分析 Python 工具

随固件一起交付 `starlog_analyzer` Python 包：

```python
session = sa.load('starlog_20260520_143015.starlog')
session.plot_overview()
brakes = session.detect_braking_events(min_decel=0.3)
sa.compare_braking(session_aero, session_baseline)
```

### 6.8 OTA 固件流程

- ESP32 WiFi 在线检查 Cloud Storage `firmware/latest/`
- 比对版本 → 下载 → 写 OTA partition → 重启切换
- 失败自动 rollback（ESP-IDF dual-bank 标配）
- 连续失败 3 次禁用 OTA 直到 App 手动触发

---

## 7. FMEA 与安全分析

### 7.1 5 层防御纵深（见 2.2 节）

### 7.2 关键 FMEA 摘要（完整 30 项见附录 A）

**RPN 排序前 10 危险项**：

| RPN | 项 | 失效模式 | 缓解 |
|---|---|---|---|
| 45 | 用户操作 | 没拧紧 / 走错线 / 不校准 | App 启动自检 28 项强制通过 |
| 40 | 翼片刮地 | 极端压弯擦地 | 设计离地 > 200mm + lean 直方图报警 |
| 36 | 软件 | 查找表填错 | App 表编辑强制仿真预览 + CRC + 版本回滚 |
| 32 | 角度编码器 | 磁铁松动零漂 | 启动自检 + 运行中编码器对比 |
| 30 | 走线 | 磨破短路 | 全程波纹管 + 主保险丝 5A + 二级 1A |
| 25 | ATtiny85 MOSFET | 失效 closed | 双 MOSFET 串联（一个坏不影响） |
| 24 | 接插件 | 振动松动 | IP67 螺纹锁紧 + 双重 zip-tie 应力释放 |
| 20 | 翼片 | 异物撞击 | SLA 优先碎裂（脆性失效） |
| 20 | 副框架 | 长期疲劳 | v1 加应变片月度回顾 |
| 20 | 走线 | 短路（见上） | 同上 |

### 7.3 残余风险 ≥ 中等的强化清单（必须 v1 实现）

| 项 | 强化措施 |
|---|---|
| MOSFET 失效 closed | 强制双 MOSFET 串联，BOM 加一颗 |
| 角度编码器零漂 | 启动自检 + 运行中编码器自检 + IP67 封装 |
| 接插件松动 | 每次骑前 App 启动自检引导手动晃测 |
| 走线短路 | 主保险丝 5A + 二级 1A in-line（servo rail）|
| 螺栓松动 | 扭力扳手装配标定 + App 强制 "已检查螺栓" 勾选 |
| 副框架疲劳 | v1 内嵌应变片 (HX711 + 应变规) + 长期监测 |
| 查找表错填 | 强制三步：编辑 → 仿真 → 写入 → 确认 |
| 用户操作 | 启动自检 28 项不通过则限速 30km/h |
| 翼片刮地 | 倾角直方图 +实时 lean 报警 (>45°) |

### 7.4 安全文化原则

1. **可观测性优先于干预性**：能不动手就别动手，但所有状态都被记录、能事后追溯
2. **失败保守优于失败激进**：任何模糊判断都朝"不动" / "贴平"方向倾斜
3. **物理优于软件**：扭簧 + 气动复位永远独立于代码运行
4. **用户必须知情**：fault 发生立即手机响铃 + 震动 + push 通知
5. **可重复性强制**：每次启动自检必须通过，无"我跳过这次"按钮

---

## 8. 测试与验证计划

### 8.1 7 阶段流程

| 阶段 | 范围 | 通过判据（强制） |
|---|---|---|
| 1. 台架单元 | 不上车 | 10/10 单元测试通过 + 故障注入正确响应 |
| 2. 静态集成 | 车上不动 | 28 项启动自检全绿 + 静置 1 小时无 fault |
| 3. 低速骑行 | 停车场 < 30 km/h | 状态转换正确 + 30 分钟无 fault + 振动数据可接受 |
| 4. 中速空旷路 | 70-100 km/h | 9 状态全部触发 + 60 分钟无 fault + 舵机 < 60°C |
| 5. 赛道基线 | aero 完全禁用 | 完整测试项目数据归档 |
| 6. 赛道日 aero 启用 | aero 工作 | 刹车距离改善 ≥ 3% **且**其他指标不退步 |
| 7. 长期耐久 | v1 后期 | 5000 km 无重大失效 |

**任意阶段未通过 → 禁止进下一阶段**。

### 8.2 设备清单

| 设备 | 用途 |
|---|---|
| 数字万用表 | 电压电流测量 |
| 示波器 (≥ 100MHz, 2 通道) | PWM / I2C 时序 |
| 直流可调电源 | 模拟供电 |
| 小型风扇组合 | 静态气动模拟 |
| 红外测温枪 | 过热检测 |
| 应变片 + HX711 | 副框架监测 |
| 240fps 手机摄像 | 翼片动作捕捉 |

### 8.3 测试 KPI

| 指标 | 期望改善 | 警戒线 |
|---|---|---|
| 100-0 刹车距离 | -5% ~ -10% | 缩短 / 不退步 |
| 0-100 加速时间 | ±0.2s | 不显著退步 |
| 直线尾速 | ±2 km/h | 不显著退步 |
| 过弯稳定性 | -10% IMU 高频噪声 | 不变差 |
| 续航 | -3% ~ -5% | 不显著退步 |

### 8.4 安全护具（强制）

- 全套皮衣（One-piece 或两件套）
- 全盔 ECE 22.06 / DOT 认证
- 护手套 + 护膝 + 护肘
- 赛道护脊
- 测试当天至少有一个伴骑 / 观察员（不能单人测试）

---

## 9. 迭代路线图

### 9.1 v1 / v2 / v3 总览

| 版本 | 主要交付 | 时长 | 增量成本 | 决策门 |
|---|---|---|---|---|
| **v1** | 1 台车原型 + Android App + Firebase + 9 状态前馈 + 数据采集 | **4-6 月** | ~12-15K RMB | 阶段 6 KPI 达成（刹车距离改善 ≥ 3%） |
| **v2** | 双车适配 + 外层 PID + iOS App + Savox 升级 + **3D 打印模具 + 碳纤湿布 layup 翼片** + 应变监测 | **3-4 月** | +6-8K RMB | 5000 km 耐久达成 |
| **v3** | 通用化 + 可选 12V tap + Web 控制台 + 社区表市场 | **6-12 月** | +10-15K RMB | 5-10 台外部装机意愿 |

### 9.2 v1 6 月里程碑

```
Month 1: 设计冻结 + 长周期件采购
Month 2: 台架组装与单元测试（阶段 1）
Month 3: 上车 + 阶段 2-3
Month 4: 阶段 4-5
Month 5: 阶段 6 + 数据分析
Month 6: 收尾 + Buffer
```

### 9.3 AI Agent 编排团队

| Agent | 工具栈 | 交付物 |
|---|---|---|
| 机械 | Fusion 360 / FreeCAD | STEP / STL + CNC BOM |
| 电气 | KiCad | Gerber + BOM + JLCPCB 装配 |
| 固件 | ESP-IDF C/C++ | 完整工程 + 烧录手册 |
| App | Flutter / Dart | 项目 + APK |
| 云 | Firebase + Cloud Functions | 配置 + 部署脚本 |
| 分析 | Python (matplotlib + jupyter) | starlog_analyzer 包 |
| 编排 | Claude Code 主控 | 跨 agent 状态同步 |

### 9.4 决策门

```
v1 完成检验门:
  □ 阶段 6 完成，刹车距离改善 ≥ 3%
  □ 0 重大失效在过去 1000 km
  □ 数据采集全链路稳定
  □ App 可日常使用
  → 全部 √ 进入 v2

v2 完成检验门:
  □ 双车实装可靠 6 个月
  □ PID 闭环上车验证稳定
  □ 5000 km 累计无重大失效
  □ 应变片无疲劳累积
  → 全部 √ 进入 v3

v3 完成检验门:
  □ 5 台不同车装机意愿
  □ 商业化路径成立或决定个人化封顶
  □ 安全文档可对外发布
  → 全部 √ 进入 v3 实施
```

---

## 10. 决策与权衡记录

本节记录设计阶段的关键决策与替代方案，供未来评审 / 重审参考。

| # | 议题 | 选择 | 替代方案 | 决策理由 |
|---|---|---|---|---|
| 1 | 控制器范式 | FSM 外层（v1 前馈，v2 PID）+ 内层位置 PID | 纯 PID / 纯查表 | "查表托底" 哲学：PID 不可信时降级到表，永远有 safe baseline |
| 2 | 翼型 | NACA 4412 倒装 | 对称 NACA 0015 | "默认有下压力"是用户明确需求；倒装是低工程开销升级 |
| 3 | 转轴位置 | 70% 弦长 | 25% (aero center) | 70% = 气动天然推回贴平 = Layer 5 复位 |
| 4 | 舵机分阶段 | v1 DSServo / v2 Savox | 一步到位 Savox | v1 减投入风险，验证后升级 |
| 5 | PCB 路线 | 全 SMT 直焊 | 模块叠插 / 飞线 | 摩托车振动下杜邦端子不可靠 |
| 6 | 供电 | 外置 USB-PD 充电宝 | 摩托车 12V tap | 零电气改装 = 100% 可逆 |
| 7 | 刹车检测 | 磁感刹车杆传感器 | 刹车灯线 tap | 非接触 + 1ms 延迟 + 零侵入 |
| 8 | 状态机 | 9 状态优先级仲裁 | 5 状态简单 FSM | 用户要求覆盖摩托车真实工况 |
| 9 | 数据格式 | Binary packed 128B 帧 | CSV | SD 写入抖动控制 + 解析速度 |
| 10 | App 框架 | Flutter (Android first) | WebApp / React Native / Native Kotlin | 跨平台 + 后期 iOS 0 代码改动 |
| 11 | 后端 | Firebase（默认）/ Supabase（备选） | 无后端 / 自建 | 用户要求云后端 + Flutter SDK 成熟 |
| 12 | 安装 | 副框架走车架 + 整流罩不承力 | 直接固定整流罩 | 整流罩 ABS 不可靠 + 拆下不影响美观 |

---

## 附录 A — 完整 FMEA 表（30 项）

| # | 部件 | 失效模式 | 失效后果 | S | P | D | RPN | 现有缓解 | 残余风险 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 舵机机械 | 齿轮卡死 / 烧 | 翼片卡在错位置 | 5 | 2 | 4 | 20 | 编码器 vs 命令差 > 5° → FAULT → 切电 → 弹簧+气动复位 | 低 |
| 2 | 舵机电子 | 电机绕组短路 | 过流 / 失控 | 5 | 1 | 4 | 10 | INA219 电流监测 + 5A 保险丝 + 切电 | 低 |
| 3 | 翼片本体 | 异物 / 鸟击 | 翼片或转轴损坏 | 4 | 1 | 1 | 20 | SLA 优先碎裂 + 编码器读跳变检测 | 中（赛道用受控） |
| 4 | 翼片转轴 | 轴承磨损 | 旷量 / 卡顿 | 3 | 2 | 3 | 18 | SS6201 50000h 额定 + 编码器抖动早期诊断 | 低 |
| 5 | 复位扭簧 | 弹簧断裂 | 断电不返回 | 5 | 1 | 5 | 5 | 双线圈冗余 + Layer 5 气动复位 | 极低 |
| 6 | 主 MCU | 代码死循环 | 控制循环停止 | 5 | 2 | 5 | 10 | ATtiny85 心跳超时 (200ms) → 切电 | 低 |
| 7 | 主 MCU | 内存损坏 | 不可预测行为 | 5 | 1 | 4 | 10 | 看门狗 + 内存保护 + CRC 关键变量 | 低 |
| 8 | ATtiny85 | 自身死亡 | 失去最后电子保险 | 4 | 1 | 5 | 4 | 上电自检 + Layer 4/5 独立 | 低 |
| 9 | ATtiny85 MOSFET | 失效 closed | 无法切电 | 5 | 1 | 1 | 25 | 双 MOSFET 串联 + 主 MCU 软命令 0° | 中 |
| 10 | DC/DC servo | 输出短路 | 舵机损坏 | 4 | 1 | 3 | 12 | 工业级 sealed + TVS + 保险丝 | 低 |
| 11 | DC/DC MCU | 输出失效 | 系统 brownout | 4 | 2 | 4 | 16 | 法拉电容 buffer (500ms) + 低压检测 → FAULT | 低 |
| 12 | 充电宝 | 突然没电 / 脱落 | 系统断电 | 3 | 2 | 5 | 6 | 法拉电容 buffer + UI 早期警告 | 低 |
| 13 | 充电宝过热 | 高温保护切断 | 同上 | 3 | 2 | 3 | 12 | 通风安装 + 温度告警 + 选认证型号 | 低 |
| 14 | GPS | 信号丢失 | 速度估算不准 | 2 | 3 | 4 | 12 | 软降级：切轮速 + IMU | 低 |
| 15 | IMU BMI270 | I2C 失败 | 失去倾角 | 3 | 1 | 3 | 15 | 软降级：禁用倾角依赖状态，回 5 状态模式 | 低 |
| 16 | 轮速 Hall 磁铁 | 磁铁脱落 | 失去轮速 | 2 | 2 | 4 | 8 | 双重粘接 + Hall vs GPS 一致性检查 | 低 |
| 17 | 刹车杆 Hall 磁铁 | 磁铁脱落 | 刹车检测延迟（IMU 仍可） | 3 | 2 | 4 | 12 | 双重粘接 + IMU 减速备份 + 一致性检查 | 低 |
| 18 | 角度编码器 | 磁铁松动零漂 | 看错角度 | 4 | 2 | 2 | 32 | 启动自检 + 运行中 servo 命令 vs 编码器 → FAULT | 中 |
| 19 | 接插件 | 振动松动 | 信号丢失 | 4 | 2 | 3 | 24 | IP67 螺纹锁紧 + 双重 zip-tie + 启动连续性检查 | 中 |
| 20 | 走线 | 磨破短路 | 火灾 / 系统死 | 5 | 2 | 3 | 30 | 全程波纹管 + 远离热源 + 主保险丝 5A + DC/DC 过流 | 中 |
| 21 | 副框架螺栓 | 松动 | 翼片震动 / 脱落 | 5 | 1 | 3 | 15 | Loctite 243 + 强制目检清单 | 中 |
| 22 | 副框架疲劳 | 长期裂纹 | 翼片脱落 | 5 | 1 | 2 | 20 | 应力分析安全系数 ≥ 3 + 5000 km 维护 | 中 |
| 23 | 整流罩 | 开孔处开裂 | 美观 / 进水 | 2 | 3 | 5 | 6 | EPDM 密封 + 环氧补强 + 不承力 | 低 |
| 24 | 软件 | 查找表填错 | 错速度做错事 | 4 | 3 | 3 | 36 | App 写表 sandbox 仿真预览 + CRC + 版本回滚 | 中 |
| 25 | 软件 | FSM 死锁 | 卡某状态 | 4 | 2 | 4 | 16 | 切换日志 + 主循环看门狗 + CI 状态机测试 | 低 |
| 26 | BT/WiFi 干扰 | App 失连 | 仅 telemetry 影响 | 1 | 4 | 1 | 20 | 控制循环 100% 本地 + 自动重连 | 极低 |
| 27 | OTA 升级 | 升级中砖 | 系统不可用 | 3 | 2 | 5 | 6 | dual-bank + 自动 rollback + 3 次禁用 OTA | 低 |
| 28 | 用户操作 | 不校准 / 没拧紧 | 任意上述失效 | 5 | 3 | 3 | 45 | App 启动自检 28 项强制通过 → 限速 30km/h | 中 |
| 29 | 极端天气 | 暴雨 / -10°C / 50°C | 各种 | 4 | 2 | 4 | 16 | IP67 + 工业温度元件 (-40~85°C) + 法拉电容降额 | 低 |
| 30 | 不预期路况 | 翼片刮地 | 损坏 | 4 | 2 | 1 | 40 | 设计离地 > 200mm + lean 直方图早警 | 中 |

---

## 附录 B — 关键计算

### B.1 气动力计算

```
F_drag = ½ · ρ · v² · Cd · A
F_lift = ½ · ρ · v² · Cl · A

参数：
  ρ (空气密度, 海平面 20°C) = 1.225 kg/m³
  v (速度, m/s) = km/h / 3.6
  A (单边翼面积) = 0.042 m² (120 × 350 mm)

NACA 4412 倒装系数估算 (无湍流校正):
  Cl @ 0° AOA = -0.4 (下压力)
  Cd @ 0° AOA = 0.012
  Cl @ ±5° AOA ≈ ±0.0 (减阻状态目标)
  Cl @ 60° AOA ≈ ±0.5 (失速后)
  Cd @ 60° AOA ≈ 1.0
  Cd @ 70° AOA ≈ 1.2

@ 195 km/h (54.2 m/s), q = ½·ρ·v² = 1800 Pa:
  F_drag @ 70° = 1800 · 1.2 · 0.042 · 2 = 181 N
  F_lift @ 0°  = 1800 · 0.4 · 0.042 · 2 = 60 N
```

### B.2 驱动扭矩计算

```
70° 立起时压力中心 (PC) 距 LE 约 50% chord = 60 mm
转轴位置 = 70% chord = 84 mm
PC 到转轴力臂 = 24 mm

气动法向力 (单侧) ≈ F_normal = ½·ρ·v²·Cn·A
  Cn @ 70° AOA ≈ 1.2–1.4（粗略，受 3D 效应影响 ±20%）
  F_normal @ 195km/h ≈ 1800 · 1.2 · 0.042 ≈ 90–106 N

气动反扭 (单侧) ≈ 95 N · 0.024 m ≈ 2.3 N·m（与 §3.4 一致）
扭簧反力 @ 70° ≈ 1.0 N·m
总舵机扭矩需求 ≈ 3.3 N·m = 33.6 kg·cm

DSServo RDS5160 额定 60 kg·cm → 余量 1.78x ✓
（Savox SB-2290SG @ 50 kg·cm 余量 1.49x，v2 升级用）
```

---

## 附录 C — 缩写表

| 缩写 | 全称 | 解释 |
|---|---|---|
| AOA | Angle of Attack | 迎角 |
| BLE | Bluetooth Low Energy | 蓝牙低功耗 |
| Cd | Drag Coefficient | 阻力系数 |
| Cl | Lift Coefficient | 升力系数 |
| CAD | Computer-Aided Design | 计算机辅助设计 |
| CAN | Controller Area Network | 控制器局域网（车载总线） |
| CRC | Cyclic Redundancy Check | 循环冗余校验 |
| ECU | Electronic Control Unit | 电子控制单元 |
| FF | Feedforward | 前馈 |
| FMEA | Failure Mode and Effects Analysis | 失效模式与效应分析 |
| FSM | Finite State Machine | 有限状态机 |
| GATT | Generic Attribute Profile | BLE 通用属性配置 |
| HAL | Hardware Abstraction Layer | 硬件抽象层 |
| HMI | Human-Machine Interface | 人机界面 |
| IMU | Inertial Measurement Unit | 惯性测量单元 |
| KPI | Key Performance Indicator | 关键绩效指标 |
| LE | Leading Edge | 前缘 |
| MCU | Microcontroller Unit | 微控制器 |
| OTA | Over-the-Air | 空中升级 |
| PCB | Printed Circuit Board | 印制电路板 |
| PID | Proportional-Integral-Derivative | 比例-积分-微分（控制器） |
| PWM | Pulse Width Modulation | 脉宽调制 |
| RPN | Risk Priority Number | 风险优先数（FMEA）|
| SKU | Stock Keeping Unit | 库存单位（产品型号） |
| SMT | Surface Mount Technology | 表面贴装 |
| TE | Trailing Edge | 后缘 |
| TVS | Transient Voltage Suppressor | 瞬态电压抑制器 |

---

**END OF DESIGN SPECIFICATION**
