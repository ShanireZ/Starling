# Starling

[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg?style=flat-square)](LICENSE)
![Type: physical prototype](https://img.shields.io/badge/type-physical%20prototype-success.svg?style=flat-square)
![Platform: GSX250R](https://img.shields.io/badge/platform-GSX250R-blue.svg?style=flat-square)
![Prototype: v1 specified](https://img.shields.io/badge/prototype-v1%20specified-orange.svg?style=flat-square)

[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文(TW)](README.zh-TW.md) | [日本語](README.ja.md)

Starling v2 是面向 Suzuki GSX250R 车身侧板的实验性电子百叶进气口：固定框朝车头迎风，一个舵机联动多片叶片，开度随车速变化。

## 当前状态

原型一号已有可审查的设计包。固件尚未完成上板编译验证，硬件尚未完成实车验证。

- [立项文件](docs/charter.md)定义范围、失效保护和安全边界。
- [原型规格](docs/prototype-v1.md)包含 BOM、接线、台架测试顺序和控制逻辑。
- [参数化 CAD 源码](cad/starling_v1.scad)与[打印／装配说明](cad/README.md)是机构依据；`cad/dist/` 包含打印交付物。
- [ESP32 DevKit（WROOM-32）固件骨架](firmware/starling/starling.ino)定义皮托压差测速、舵机控制、被动记录和 USB／蓝牙配置，仍属于未验证的骨架。

## 3D 机构演示

[gsx250r-vreal.html](proto/gsx250r-vreal.html) 是当前 3D 演示。在仓库根目录运行：

```shell
python -m http.server 8000 --bind 127.0.0.1
```

打开 `http://127.0.0.1:8000/proto/gsx250r-vreal.html`。滑块模拟车速和叶片开度，也可拖入其他 `.glb`／`.gltf` 模型。气流效果用于说明机构，不是 CFD 或性能证据。

## 设计边界

动态造型是主要目标；任何气流或散热收益都是附带且尚未验证的。设计要求断电后由弹簧关闭叶片，并设置机械和软件限位。上路前应完成台架、封闭场地测试及适用的当地法规检查。USB／蓝牙外部连接只配置或读取数据，不实时控制开度。具体要求以立项文件和规格为准。

## 许可证

原创代码、文档和素材按 [GNU 通用公共许可证 v3.0](LICENSE) 分发。摩托车模型保留其 [CC-BY-4.0 署名和许可证](res/sports_bike/license.txt)。
