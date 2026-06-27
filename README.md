# Starling

车头两侧一对**电子百叶进气口("鳃口")**——固定框 + 多片联动百叶,随车速张合的动态造型件。速度越快,叶片开得越大、前缘下斜露缝(战斗机 / F1 多段开缝的样子)。

**这是一个看得见的视觉 / 动态件,不是性能件。** 不追求下压力,面向 100km/h 以内的日常骑行,主打张合动态本身的炫酷。

- 立项文档:[docs/charter.md](docs/charter.md)
- 项目约定与状态:[AGENTS.md](AGENTS.md)
- **3D 演示(真实车身 + 鳃口落位):[proto/gsx250r-vreal.html](proto/gsx250r-vreal.html)** — 默认加载真实运动摩托模型,鳃口落在前整流罩侧面;滑杆模拟车速 → 百叶开度;可拖入别的 `.glb/.gltf` 换车型。
- 3D 机构示意(轻量方块版,旧):[proto/wing-3d.html](proto/wing-3d.html)

> 网页为单文件 three.js;真实车体模型需经本地静态服务器加载(见 `res/`)。

### 第三方素材署名
- 车体模型 **"Sports Bike" by Futurealiti**(https://sketchfab.com/3d-models/sports-bike-a80259b859c842d5824c25c61e0fc421),授权 **CC-BY-4.0**。仅作占位 / 演示用的运动摩托车体,**非 Suzuki GSX250R 官方车型**;后续可替换。

> v2 重启。上一版因"为微小性能堆五学科复杂度"而流产;本版以 **收益封顶 + 第一周可观察 + 单人可调 + 禁战线蔓延** 为铁律。
