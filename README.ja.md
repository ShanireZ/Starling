# Starling

[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg?style=flat-square)](LICENSE)
![Type: physical prototype](https://img.shields.io/badge/type-physical%20prototype-success.svg?style=flat-square)
![Platform: GSX250R](https://img.shields.io/badge/platform-GSX250R-blue.svg?style=flat-square)
![Prototype: v1 specified](https://img.shields.io/badge/prototype-v1%20specified-orange.svg?style=flat-square)

[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文(TW)](README.zh-TW.md) | [日本語](README.ja.md)

Starling v2 は Suzuki GSX250R の車体側面に取り付ける実験的な電子ルーバー式吸気口です。固定フレームが前方からの気流を受け、一つのサーボで複数の羽根を連動させ、車速に応じて開度を変えます。

## 現在の状態

試作一号の設計資料はレビュー可能な状態です。ファームウェアの実機コンパイル・動作確認と、車両に装着したハードウェアの検証は完了していません。

- [プロジェクト方針](docs/charter.md)が範囲、故障時の保護、安全上の境界を定義します。
- [試作仕様](docs/prototype-v1.md)に BOM、配線、ベンチ試験の順序、制御ロジックを記載しています。
- [パラメトリック CAD ソース](cad/starling_v1.scad)と[印刷・組立ガイド](cad/README.md)が機構の正本です。`cad/dist/` に印刷用成果物があります。
- [ESP32 DevKit（WROOM-32）用ファームウェアの骨組み](firmware/starling/starling.ino)は、ピトー管の差圧による速度計測、サーボ制御、受動記録、USB／Bluetooth 設定を定義しています。まだ未検証の骨組みです。

## 3D 機構デモ

[gsx250r-vreal.html](proto/gsx250r-vreal.html) が現行の 3D デモです。リポジトリのルートで次を実行します。

```shell
python -m http.server 8000 --bind 127.0.0.1
```

`http://127.0.0.1:8000/proto/gsx250r-vreal.html` を開きます。スライダーで車速と羽根の開度を模擬し、別の `.glb`／`.gltf` モデルもドロップできます。気流の表現は機構の説明用で、CFD や性能の検証結果ではありません。

## 設計上の境界

主な目的は動きのある外観です。気流や冷却への効果は副次的で、未検証です。停電時にばねで羽根を閉じること、機械とソフトウェアの両方で動作範囲を制限することを要求します。公道で使用する前にベンチ試験、閉鎖コースでの試験、適用される地域の法令確認を行ってください。外部の USB／Bluetooth 接続は設定とデータ取得用で、開度のリアルタイム制御には使いません。要件の正本はプロジェクト方針と仕様です。

## ライセンス

独自のコード、文書、素材は [GNU General Public License v3.0](LICENSE) に基づいて配布します。オートバイモデルの [CC-BY-4.0 の帰属表示とライセンス](res/sports_bike/license.txt)を維持してください。
