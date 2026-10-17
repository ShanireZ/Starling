# Starling

[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg?style=flat-square)](LICENSE)
![Type: physical prototype](https://img.shields.io/badge/type-physical%20prototype-success.svg?style=flat-square)
![Platform: GSX250R](https://img.shields.io/badge/platform-GSX250R-blue.svg?style=flat-square)
![Prototype: v1 specified](https://img.shields.io/badge/prototype-v1%20specified-orange.svg?style=flat-square)

Starling v2 是面向 Suzuki GSX250R 車身側板的電子百葉進氣口（“鰓口”）原型：固定框承風、多片葉片由一個舵機聯動，開口朝車頭迎風，並隨車速張合。

## 當前狀態

原型一號已經形成可審查的設計包，但尚未完成上板或實車驗證：

- [立項文件](docs/charter.md)記錄 v2 的範圍、失效保護和安全邊界。
- [原型一號規格](docs/prototype-v1.md)包含 BOM、串接、臺架驗證順序和控制邏輯。
- [參數化 CAD](cad/starling_v1.scad)及其 [列印/裝配說明](cad/README.md)是機構的唯一 CAD 來源；`cad/dist/` 為列印交付包。
- [韌體骨架](firmware/starling/starling.ino)面向 ESP32 DevKit（WROOM-32），定義了皮託壓差測速、舵機控制、被動記錄和 USB/藍牙設定邊界；原始碼明確標註為尚未上板編譯驗證的骨架。

## 3D 機構演示

[gsx250r-vreal.html](proto/gsx250r-vreal.html) 是唯一現行 3D 演示。可通過本機靜態 HTTP 伺服器從儲存庫根目錄打開。頁面用滑桿模擬車速和百葉開度，並可拖入其他 `.glb`/`.gltf` 模型。頁面中的氣流效果是機制演示，**不是 CFD 或效能驗證**。

## 專案約束

- 設計鐵律和當前狀態見 [AGENTS.md](AGENTS.md)。
- 斷電時機構應由彈簧回到閉合位置；上路前須完成臺架、封閉場地和當地法規自查。

## License

本專案自有的程式碼、文件與素材採用 [GNU General Public License v3.0](LICENSE) 發佈。
