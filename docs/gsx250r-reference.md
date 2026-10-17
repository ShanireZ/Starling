---
type: reference
title: GSX250R 建模參考資料
---

# GSX250R 建模參考資料

> 為 §8「完全仿真整車」收集的真實尺寸 / 比例底本。建模一律以此為準(單位:mm,three.js 場景按 m)。
> 收集日期:2026-06-26 · 來源見文末。

## 1. 整車尺寸(官方 / 規格站一致)

| 項 | 值 | 備註 |
|---|---|---|
| 總長 Overall length | **2085 mm** | 前輪最前 → 車尾最後 |
| 總寬 Overall width | **740 mm** | 多為後視鏡 / 把手寬 |
| 總高 Overall height | **1110 mm** | 地面 → 風擋 / 鏡頂 |
| 軸距 Wheelbase | **1430 mm** | 前後輪中心距(核心比例錨) |
| 座高 Seat height | **790 mm** | |
| 最小離地 Ground clearance | **≈165 mm** | 規格站未統一,取常見值,待官方手冊校 |
| 整備品質 Curb weight | **181 kg** | |
| 發動機 | 248cc 並列雙缸水冷 | 僅作體塊參考 |

## 2. 車輪 / 輪胎(前後都要,後輪此前缺)

| | 輪胎規格 | 胎寬 | 胎壁 | **外半徑** | 外徑 |
|---|---|---|---|---|---|
| 前 Front | **110/80-17** | 110 mm | 110×0.80=88 mm | **≈304 mm** | 608 mm |
| 後 Rear | **140/70-17** | 140 mm | 140×0.70=98 mm | **≈314 mm** | 628 mm |

- 17" 輪輞直徑 = 17×25.4 = **431.8 mm**(半徑 215.9 mm);外半徑 = 215.9 + 胎壁。
- 輪型:**十輻鑄鋁**(10-spoke cast aluminium),IRC 輪胎。
- 部分年份(2023)後胎為 **140/55-17**(胎壁 77 → 外半徑 ≈293 mm)。本專案主用 **140/70-17**。

## 3. 整流罩 / 散熱氣流(給「鰓口」落位的真實依據)

- 全包整流罩(full fairing),GSX-R 家族造型語言:豎排雙頭燈 + 尖鼻錐 + 燻黑風擋。
- 官方描述:整流罩**導冷風進水箱、把熱風帶離騎手**——即真車側整流罩本就有進 / 出風功能區。
- → Starling「電子百葉鰓口」的真實落位 = **上側整流罩 / 頭燈側下方的側頰面**(視覺顯眼,又貼近真車散熱區邏輯);非車頭正臉。

## 4. 建模座標 / 比例(three.js 場景,單位 m,1 unit = 1 m)

座標系:**+Z = 車頭朝前**,+Y = 上,+X = 右。以兩輪中心連線中點為原點附近佈局。

| 部位 | 位置(z, y) | 尺寸 | 來源 |
|---|---|---|---|
| 前輪中心 | z=+0.715, y=0.304 | 外半徑 0.304,胎寬 0.110 | 軸距/2;前胎 |
| 後輪中心 | z=-0.715, y=0.314 | 外半徑 0.314,胎寬 0.140 | 軸距/2;後胎 |
| 車頭最前 | z≈+1.019 | — | 前輪中心 + 前胎半徑(總長檢核) |
| 車尾最後 | z≈-1.066 | — | 總長 2.085 − 前段 |
| 座面 | y≈0.790 | — | 座高 |
| 油箱頂 | y≈0.88–0.92 | — | 估(座高之上一拳) |
| 風擋頂 / 總高 | y≈1.110(車頭處) | — | 總高 |
| 轉向頭 / 三角臺 | z≈+0.66, y≈0.95 | — | 估,前叉上端 |
| 前叉傾角 | ≈25–26°(rake) | — | 同級運動車常見值 |

> 檢核:總長 = 前胎最前(1.019) − 車尾(−1.066) = **2.085 m ✓**;軸距 = 0.715−(−0.715) = **1.430 m ✓**。

## 5. 待補 / 存疑

- 離地間隙、前叉精確 rake/trail、把寬、尾段精確長度 —— 規格站缺,需**官方使用者手冊 PDF** 或**三視圖藍圖**精校(見來源)。
- 三視圖藍圖:3DModels.org / the-blueprints.com 有 GSX250R 藍圖,可作側影對齊底圖(注意授權,僅作比例參考)。

## 來源

- [Suzuki GSX250R — Wikipedia](https://en.wikipedia.org/wiki/Suzuki_GSX250R)
- [Global Suzuki — GSX250R 產品頁](https://www.globalsuzuki.com/motorcycle/smgs/products/2024gsx250r/)
- [Torquepedia — GSX250R 規格](https://www.torquepedia.com/suzuki/gsx250r/2024)
- [UltimateSpecs — GSX250R 技術規格](https://www.ultimatespecs.com/motorcycles-specs/suzuki/suzuki-gsx250r-2019)
- [Webike Japan — GSX250R 規格](https://japan.webike.net/SUZUKI/GSX250R/13840/m-spec/)
- 藍圖:[3DModels.org — GSX250R 2023 Blueprint](https://3dmodels.org/blueprints/suzuki-gsx250r-2023-blueprint/) · [the-blueprints.com — Suzuki](https://www.the-blueprints.com/blueprints/motorcycles/suzuki/)
