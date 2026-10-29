# Starling

[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg?style=flat-square)](LICENSE)
![Type: physical prototype](https://img.shields.io/badge/type-physical%20prototype-success.svg?style=flat-square)
![Platform: GSX250R](https://img.shields.io/badge/platform-GSX250R-blue.svg?style=flat-square)
![Prototype: v1 specified](https://img.shields.io/badge/prototype-v1%20specified-orange.svg?style=flat-square)

[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文(TW)](README.zh-TW.md) | [日本語](README.ja.md)

Starling v2 is an experimental electronic louvered intake for the side panels of the Suzuki GSX250R. A fixed frame faces the oncoming airflow; one servo links several blades whose opening follows vehicle speed.

## Status

Prototype 1 has a reviewable design package. Firmware has not been compiled and verified on a board, and the hardware has not been validated on a motorcycle.

- The [charter](docs/charter.md) defines scope, failure protection and safety boundaries.
- The [prototype specification](docs/prototype-v1.md) contains the BOM, wiring, bench-test sequence and control logic.
- The [parametric CAD source](cad/starling_v1.scad) and [printing/assembly guide](cad/README.md) own the mechanism; `cad/dist/` contains the printing deliverables.
- The [ESP32 DevKit (WROOM-32) firmware skeleton](firmware/starling/starling.ino) defines pitot differential-pressure speed sensing, servo control, passive recording and USB/Bluetooth configuration. It remains an unverified skeleton.

## 3D mechanism demo

[gsx250r-vreal.html](proto/gsx250r-vreal.html) is the current 3D demo. From the repository root, run:

```shell
python -m http.server 8000 --bind 127.0.0.1
```

Open `http://127.0.0.1:8000/proto/gsx250r-vreal.html`. Sliders simulate speed and blade opening; another `.glb`/`.gltf` model can be dropped in. The airflow effect illustrates the mechanism; it is not CFD or performance evidence.

## Design boundaries

Dynamic appearance is the main goal; any airflow or cooling benefit is secondary and unverified. The design requires a spring to close the blades on power loss, with mechanical and software limits. Complete bench tests, closed-course tests and the applicable local legal checks before road use. External USB/Bluetooth connections configure or read data rather than control the opening in real time. The charter and specification own these requirements.

## License

Original code, documents and assets use [GNU General Public License v3.0](LICENSE). The motorcycle model retains its [CC-BY-4.0 attribution and license](res/sports_bike/license.txt).
