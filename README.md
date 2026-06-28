# Starling

**车身侧板(车把下整流罩)**上一对**电子百叶进气口("鳃口")**——固定框 + 多片联动百叶,**开口朝车头迎风**,随车速张合的动态造型件。速度越快,叶片开得越大、张开露缝(战斗机 / F1 多段开缝的样子),像**张鳃呼吸**纳入迎面气流。

**这是一个看得见的视觉 / 动态件,不是性能件。** 不追求下压力 / 散热 / 性能,面向 100km/h 以内的日常骑行,主打张合动态本身的炫酷。

- 立项文档:[docs/charter.md](docs/charter.md)
- 项目约定与状态:[AGENTS.md](AGENTS.md)
- **3D 演示(真实车身 + 鳃口落位):[proto/gsx250r-vreal.html](proto/gsx250r-vreal.html)** — 默认加载真实运动摩托模型,鳃口落在**车身侧板、开口朝车头迎风**;滑杆模拟车速 → 百叶开度;「🌫 风洞气流」演示迎风口纳气;可拖入别的 `.glb/.gltf` 换车型。**(唯一 3D 真相;旧轻量方块版 `wing-3d.html` 已于 2026-06-28 退役。)**

> 网页为单文件 three.js;真实车体模型需经本地静态服务器加载(见 `res/`)。

### 第三方素材署名
- 车体模型 **"Sports Bike" by Futurealiti**(https://sketchfab.com/3d-models/sports-bike-a80259b859c842d5824c25c61e0fc421),授权 **CC-BY-4.0**。仅作占位 / 演示用的运动摩托车体,**非 Suzuki GSX250R 官方车型**;后续可替换。

> v2 重启。上一版因"为微小性能堆五学科复杂度"而流产;本版以 **收益封顶 + 第一周可观察 + 单人可调 + 禁战线蔓延** 为铁律。

## 许可 / License

- 本项目自有的代码、文档与素材采用 **GNU GPL-3.0**(见 [LICENSE](LICENSE))。Copyright © 2026 ShanireZ。
- **例外**:`res/sports_bike/` 为第三方模型 **"Sports Bike" by Futurealiti**,授权 **CC-BY-4.0**,其许可与署名以 [`res/sports_bike/license.txt`](res/sports_bike/license.txt) 为准,**不受本仓库 GPL 协议覆盖**。
