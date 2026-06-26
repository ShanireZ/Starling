# GSX250R 建模参考资料

> 为 §8「完全仿真整车」收集的真实尺寸 / 比例底本。建模一律以此为准(单位:mm,three.js 场景按 m)。
> 收集日期:2026-06-26 · 来源见文末。

## 1. 整车尺寸(官方 / 规格站一致)

| 项 | 值 | 备注 |
|---|---|---|
| 总长 Overall length | **2085 mm** | 前轮最前 → 车尾最后 |
| 总宽 Overall width | **740 mm** | 多为后视镜 / 把手宽 |
| 总高 Overall height | **1110 mm** | 地面 → 风挡 / 镜顶 |
| 轴距 Wheelbase | **1430 mm** | 前后轮中心距(核心比例锚) |
| 座高 Seat height | **790 mm** | |
| 最小离地 Ground clearance | **≈165 mm** | 规格站未统一,取常见值,待官方手册校 |
| 整备质量 Curb weight | **181 kg** | |
| 发动机 | 248cc 并列双缸水冷 | 仅作体块参考 |

## 2. 车轮 / 轮胎(前后都要,后轮此前缺)

| | 轮胎规格 | 胎宽 | 胎壁 | **外半径** | 外径 |
|---|---|---|---|---|---|
| 前 Front | **110/80-17** | 110 mm | 110×0.80=88 mm | **≈304 mm** | 608 mm |
| 后 Rear | **140/70-17** | 140 mm | 140×0.70=98 mm | **≈314 mm** | 628 mm |

- 17" 轮辋直径 = 17×25.4 = **431.8 mm**(半径 215.9 mm);外半径 = 215.9 + 胎壁。
- 轮型:**十辐铸铝**(10-spoke cast aluminium),IRC 轮胎。
- 部分年份(2023)后胎为 **140/55-17**(胎壁 77 → 外半径 ≈293 mm)。本项目主用 **140/70-17**。

## 3. 整流罩 / 散热气流(给「鳃口」落位的真实依据)

- 全包整流罩(full fairing),GSX-R 家族造型语言:竖排双头灯 + 尖鼻锥 + 熏黑风挡。
- 官方描述:整流罩**导冷风进水箱、把热风带离骑手**——即真车侧整流罩本就有进 / 出风功能区。
- → Starling「电子百叶鳃口」的真实落位 = **上侧整流罩 / 头灯侧下方的侧颊面**(视觉显眼,又贴近真车散热区逻辑);非车头正脸。

## 4. 建模坐标 / 比例(three.js 场景,单位 m,1 unit = 1 m)

坐标系:**+Z = 车头朝前**,+Y = 上,+X = 右。以两轮中心连线中点为原点附近布局。

| 部位 | 位置(z, y) | 尺寸 | 来源 |
|---|---|---|---|
| 前轮中心 | z=+0.715, y=0.304 | 外半径 0.304,胎宽 0.110 | 轴距/2;前胎 |
| 后轮中心 | z=-0.715, y=0.314 | 外半径 0.314,胎宽 0.140 | 轴距/2;后胎 |
| 车头最前 | z≈+1.019 | — | 前轮中心 + 前胎半径(总长校验) |
| 车尾最后 | z≈-1.066 | — | 总长 2.085 − 前段 |
| 座面 | y≈0.790 | — | 座高 |
| 油箱顶 | y≈0.88–0.92 | — | 估(座高之上一拳) |
| 风挡顶 / 总高 | y≈1.110(车头处) | — | 总高 |
| 转向头 / 三角台 | z≈+0.66, y≈0.95 | — | 估,前叉上端 |
| 前叉倾角 | ≈25–26°(rake) | — | 同级运动车常见值 |

> 校验:总长 = 前胎最前(1.019) − 车尾(−1.066) = **2.085 m ✓**;轴距 = 0.715−(−0.715) = **1.430 m ✓**。

## 5. 待补 / 存疑

- 离地间隙、前叉精确 rake/trail、把宽、尾段精确长度 —— 规格站缺,需**官方用户手册 PDF** 或**三视图蓝图**精校(见来源)。
- 三视图蓝图:3DModels.org / the-blueprints.com 有 GSX250R 蓝图,可作侧影对齐底图(注意授权,仅作比例参考)。

## 来源

- [Suzuki GSX250R — Wikipedia](https://en.wikipedia.org/wiki/Suzuki_GSX250R)
- [Global Suzuki — GSX250R 产品页](https://www.globalsuzuki.com/motorcycle/smgs/products/2024gsx250r/)
- [Torquepedia — GSX250R 规格](https://www.torquepedia.com/suzuki/gsx250r/2024)
- [UltimateSpecs — GSX250R 技术规格](https://www.ultimatespecs.com/motorcycles-specs/suzuki/suzuki-gsx250r-2019)
- [Webike Japan — GSX250R 规格](https://japan.webike.net/SUZUKI/GSX250R/13840/m-spec/)
- 蓝图:[3DModels.org — GSX250R 2023 Blueprint](https://3dmodels.org/blueprints/suzuki-gsx250r-2023-blueprint/) · [the-blueprints.com — Suzuki](https://www.the-blueprints.com/blueprints/motorcycles/suzuki/)
