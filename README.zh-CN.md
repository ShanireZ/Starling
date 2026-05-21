# Starling Active Aero

[English](README.md) | [中文](README.zh-CN.md)

Starling is an experimental active front aerodynamic system for motorcycles. It uses electronically controlled side-mounted front winglets to explore how adaptive aero can improve braking stability, front-wheel load, anti-wheelie behavior, and ride data collection on real motorcycles.

Starling 是一套面向摩托车真实原型的主动前翼系统。它通过电子控制的车头两侧可变翼片，探索自适应空气动力学对刹车稳定性、前轮载荷、抗 wheelie 能力和路试数据闭环的实际价值。

## 项目概览

Starling 不是单纯的 CAD 概念，而是一个真实可上车验证的主动空气动力学项目。系统计划在摩托车车头整流罩两侧安装可变角度翼片，并通过 ESP32-S3 主控、传感器融合、舵机驱动、手机 App、云端数据同步和离线分析工具完成闭环控制。

v1 目标是在 4-6 个月内完成一台可工作的摩托车原型，并通过赛道日数据验证：主动气动启用后，100-0 km/h 刹车距离改善不少于 3%，同时加速、直线尾速和过弯稳定性不出现显著退步。

## 项目范围

项目由六个协同子系统组成：

| 子系统   | 交付物                                                                                           |
| -------- | ------------------------------------------------------------------------------------------------ |
| 机械     | NACA 4412 倒装翼片 CAD、转轴、复位扭簧、舵机盒、GSX250R / RC450 副框架、STEP/STL、BOM            |
| 电子     | KiCad 主控背板 PCB、ESP32-S3、ATtiny85 看门狗、舵机电源轨、传感器、IP67 接插件、Gerber、BOM、CPL |
| 固件     | ESP-IDF 控制固件、100 Hz 控制循环、9 状态 FSM、查找表、BLE/WiFi、SD 日志、OTA、ATtiny 看门狗     |
| 手机 App | Flutter Android App、BLE 遥测、WiFi 日志下载、表编辑器、校准、健康检查、Firebase 同步            |
| 云端     | Firebase Auth、Firestore、Storage、Cloud Functions、OTA 发布管线、轻量 Web 控制台                |
| 集成测试 | 台架、静态、低速、中速、赛道基线、主动气动赛道验证、长期耐久测试流程                             |

## 设计亮点

- 双目标平台：Suzuki GSX250R-A 2022 与 KTM RC 450 / KM400。
- 翼片几何：单侧弦长 120 mm、翼展 350 mm，倒装 NACA 4412 翼型。
- 工作范围：v1 为 0 到 +70 度，v2 计划扩展到 -5 度减阻状态。
- 物理失效保护：70% 弦长转轴加复位扭簧，使气动力和机械力都倾向于把翼片推回贴平。
- 独立硬件看门狗：ATtiny85 监听 ESP32 心跳，超时后切断舵机供电。
- 非侵入供电：v1 使用外置 USB-PD 充电宝，不接入摩托车原车电气系统。
- 数据优先验证：以 100 Hz 频率写入 128 字节二进制日志帧，再进行本地和云端分析。

## 开发计划

v1 由 `docs/superpowers/plans/2026-05-17-active-aero-v1-master.md` 统一控制。该计划定义共享接口契约和里程碑门禁：

1. Gate A：六个子系统计划全部确认后冻结接口。
2. Gate B：长周期硬件下单。
3. Gate C：台架级单元可工作。
4. Gate D：完整集成就绪。
5. Gate E：上车静态与低速验证通过。
6. Gate F：中速验证通过。
7. Gate G：完成 aero 禁用的赛道基线。
8. Gate H：完成主动气动验证。

所有子系统工作都必须追溯到设计规格和 master plan 的接口契约。GPIO、BLE schema、二进制日志帧、查找表格式或 Firebase schema 不能静默变更，需要先修订 master plan。

## 安全说明

Starling 是实验性摩托车硬件，目标是受控工程验证和封闭场地测试，不是公共道路使用产品。当前设计明确不走法规认证。

除非机械、电子、固件、App、云端和集成测试门禁均已通过，否则不要安装或骑行测试。任何故障都应偏向翼片贴平、停止主动干预，并完整记录数据供后续分析。

## 开源协议

Starling 同时包含开源硬件、软件和文档，因此采用分层授权。目录级授权映射见 [LICENSES.md](LICENSES.md)。

| 项目部分                                                 | 推荐协议                                     | 原因                                                     |
| -------------------------------------------------------- | -------------------------------------------- | -------------------------------------------------------- |
| 硬件设计文件：CAD、PCB、原理图、Gerber、机械图纸、BOM    | [CERN-OHL-S-2.0](LICENSE-CERN-OHL-S-2.0.txt) | 面向硬件设计，强互惠，鼓励安全相关改型和设计改进保持开放 |
| 软件：固件、App、云函数、Web 控制台、Python 分析器、脚本 | [Apache-2.0](LICENSE-Apache-2.0.txt)         | 宽松、软件生态熟悉，并包含明确专利授权条款               |
| 文档：规格、计划、手册、测试流程、报告                   | [CC BY-SA 4.0](LICENSE-CC-BY-SA-4.0.txt)     | 保留署名要求，并要求衍生文档以相同方式共享               |

## 主要文档

- 设计规格：`docs/superpowers/specs/2026-05-17-active-front-aero-design.md`
- Master 实施计划：`docs/superpowers/plans/2026-05-17-active-aero-v1-master.md`
- 子系统计划：`docs/superpowers/plans/2026-05-17-*.md`
