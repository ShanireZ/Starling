# AGENTS.md — Starling

> 本文件遵循工作区集体准则 [`../AGENTS.md`](../AGENTS.md)。先读该文件，再读本文件、[立项文档](docs/charter.md)和与改动相邻的规格或源码。

## 项目是什么

Starling v2 是 GSX250R 车身侧板上的电子百叶进气口（“鳃口”）原型：固定框、多片联动百叶、一个舵机自由度，开口朝车头迎风。它以动态造型为主，迎风纳气和散热只是温和的附带收益。

早期折叠翼与“侧向羽化/下压力”叙事已经废弃。当前形态、位置和气动表述以 [docs/charter.md](docs/charter.md) 为准；不要恢复已退役的 `proto/wing-3d.html` 或旧方案。

## 当前实现边界

- 原型一号已有规格、BOM、接线图、参数化 CAD、STL/打印交付包和 ESP32 固件骨架。固件尚未上板编译验证，硬件也未完成实车验证；不得把设计稿写成已验证产品。
- `proto/gsx250r-vreal.html` 是唯一现行 3D 演示。其气流可视化是机制演示，**不是 CFD 或性能证据**。
- 计划的控制链是皮托压差测速 → 阈值/斜坡/滞回/限位 → 舵机；数据采集仅被动记录，不能反向控制开度。

## 设计铁律

1. **收益封顶**：不为微小性能收益引入显著复杂度；不做主动空气动力学、重型涵道或冷却系统。
2. **第一周可观察**：优先交付能看到的最小纵切片，再谈扩展。
3. **单人可造可调**：避免需专家或多人长期维护的结构。
4. **不扩大战线**：无 App 实时控制、云遥测、OTA 或多学科性能反馈链；外部端仅可配置或读取数据。
5. **安全优先**：维持断电弹簧回闭合、机械硬限位和软件软限位；上路前先完成台架、封闭场地和当地法规自查。

## 工作方式

- 文档、注释和提交信息使用中文；历史状态日志保留为历史，不反向改写旧决策。
- 修改机构时先查 `docs/prototype-v1.md`、`cad/starling_v1.scad` 与 `cad/README.md`；`starling_v1.scad` 是唯一 CAD 真相，STL 应从它导出。
- 修改网页演示时使用本地静态 HTTP 服务器检查 `proto/gsx250r-vreal.html`；不要声称视觉演示已完成道路、气动或性能验证。
- 自有代码、文档和素材采用 [GPL-3.0](LICENSE)。`res/sports_bike/` 为 CC-BY-4.0 第三方素材，必须保留其 [署名与许可](res/sports_bike/license.txt)。

## 提交约定

- 默认不提交，除非用户明确要求或任务明确包含建仓、charter 或状态更新。
- 提交信息简洁、中文。

## Agent skills

### Issue tracker

Issues and specs are tracked in this repository's GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the five canonical triage labels. See `docs/agents/triage-labels.md`.

### Domain docs

This target uses a single-context domain-doc layout. See `docs/agents/domain.md`.

### Related engineering skills

See `docs/agents/skill-workflows.md` for recommendations on when to use the installed engineering skills and how their workflows compose.

### Documentation system

Maintain durable documentation as an OKF knowledge bundle. See `docs/agents/documentation.md` and `docs/agents/index.md`.
