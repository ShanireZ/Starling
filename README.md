# Starling

[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg?style=flat-square)](LICENSE)
![Type: physical prototype](https://img.shields.io/badge/type-physical%20prototype-success.svg?style=flat-square)
![Platform: GSX250R](https://img.shields.io/badge/platform-GSX250R-blue.svg?style=flat-square)
![Prototype: v1 specified](https://img.shields.io/badge/prototype-v1%20specified-orange.svg?style=flat-square)

Starling v2 是面向 Suzuki GSX250R 车身侧板的电子百叶进气口（“鳃口”）原型：固定框承风、多片叶片由一个舵机联动，开口朝车头迎风，并随车速张合。

它首先是可见的动态造型件。迎风纳气和散热只是不堆复杂度的温和附带收益；不以性能提升、主动空气动力学或重型冷却系统为目标。

## 当前状态

原型一号已经形成可审查的设计包，但尚未完成上板或实车验证：

- [立项文档](docs/charter.md)记录 v2 的范围、失效保护和安全边界。
- [原型一号规格](docs/prototype-v1.md)包含 BOM、接线、台架验证顺序和控制逻辑。
- [参数化 CAD](cad/starling_v1.scad)及其 [打印/装配说明](cad/README.md)是机构的唯一 CAD 来源；`cad/dist/` 为打印交付包。
- [固件骨架](firmware/starling/starling.ino)面向 ESP32 DevKit（WROOM-32），定义了皮托压差测速、舵机控制、被动记录和 USB/蓝牙配置边界；源码明确标注为尚未上板编译验证的骨架。

## 3D 机构演示

[gsx250r-vreal.html](proto/gsx250r-vreal.html) 是唯一现行 3D 演示。请通过本地静态 HTTP 服务器从仓库根目录打开它；页面用滑杆模拟车速和百叶开度，并可拖入其他 `.glb`/`.gltf` 模型。页面中的气流效果是机制演示，**不是 CFD 或性能验证**。

默认加载的车体是第三方运动摩托模型，便于示意鳃口在侧板的落位；它不是 Suzuki GSX250R 官方模型。

## 项目约束

- 设计铁律和当前状态见 [AGENTS.md](AGENTS.md)。
- 断电时机构应由弹簧回到闭合位置；上路前须完成台架、封闭场地和当地法规自查。
- 不加入 App 实时控制、云遥测、OTA 或将被动数据记录接入控制闭环。

## 第三方素材

`res/sports_bike/` 中的 **“Sports Bike” by Futurealiti** 采用 [CC-BY-4.0](res/sports_bike/license.txt)，仅用于演示占位，且不受仓库 GPL 许可覆盖。

## License

本项目自有的代码、文档与素材采用 [GNU General Public License v3.0](LICENSE) 发布。
