# Starling

[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg?style=flat-square)](LICENSE)
![Type: physical prototype](https://img.shields.io/badge/type-physical%20prototype-success.svg?style=flat-square)
![Platform: GSX250R](https://img.shields.io/badge/platform-GSX250R-blue.svg?style=flat-square)
![Prototype: v1 specified](https://img.shields.io/badge/prototype-v1%20specified-orange.svg?style=flat-square)

[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文(TW)](README.zh-TW.md) | [日本語](README.ja.md)

Starling v2 是面向 Suzuki GSX250R 車身側板的實驗性電子百葉進氣口：固定框朝車頭迎風，一個伺服馬達聯動多片葉片，開度隨車速變化。

## 目前狀態

原型一號已有可審查的設計包。韌體尚未完成上板編譯驗證，硬體尚未完成實車驗證。

- [立項文件](docs/charter.md)定義範圍、失效保護與安全邊界。
- [原型規格](docs/prototype-v1.md)包含 BOM、接線、臺架測試順序與控制邏輯。
- [參數化 CAD 原始碼](cad/starling_v1.scad)與[列印／裝配說明](cad/README.md)是機構依據；`cad/dist/` 包含列印交付物。
- [ESP32 DevKit（WROOM-32）韌體骨架](firmware/starling/starling.ino)定義皮托壓差測速、伺服馬達控制、被動記錄與 USB／藍牙設定，仍屬於未驗證的骨架。

## 3D 機構示範

[gsx250r-vreal.html](proto/gsx250r-vreal.html) 是目前的 3D 示範。在儲存庫根目錄執行：

```shell
python -m http.server 8000 --bind 127.0.0.1
```

開啟 `http://127.0.0.1:8000/proto/gsx250r-vreal.html`。滑桿模擬車速與葉片開度，也可拖入其他 `.glb`／`.gltf` 模型。氣流效果用於說明機構，不是 CFD 或效能證據。

## 設計邊界

動態造型是主要目標；任何氣流或散熱收益都是附帶且尚未驗證的。設計要求斷電後由彈簧關閉葉片，並設置機械與軟體限位。上路前應完成臺架、封閉場地測試及適用的當地法規檢查。USB／藍牙外部連線只設定或讀取資料，不即時控制開度。具體要求以立項文件與規格為準。

## 授權

原創程式碼、文件與素材依 [GNU 通用公共授權條款 v3.0](LICENSE) 散布。摩托車模型保留其 [CC-BY-4.0 署名與授權條款](res/sports_bike/license.txt)。
