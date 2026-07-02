// ============================================================================
// Starling 原型一号 · 机构参数化模型 v0.1(台架版)
// OpenSCAD 源文件 —— 唯一 CAD 真相;STL 由本文件导出,勿手编 STL。
//
// 用法:
//   GUI:打开本文件,改底部 PART 变量预览 / F6 渲染 / 导出 STL;
//   CLI:openscad -o stl/frame.stl -D "PART=\"frame\"" starling_v1.scad
//   装配预览:PART="assembly",OPEN_DEG=CLOSED_DEG(闭合)~90(全开)
//
// 打印件清单:frame ×1 · blade ×4 · crank ×4 · linkbar ×1
//            servo_bracket ×1 · stand ×1
// 外购件:Ø2 不锈钢轴(切 4 段×125)· 黄铜套内2外3(切 8 段×6)
//        M2 球头拉杆一组(舵机臂→拉杆下孔)· M2/M3 螺丝 · 扭簧 · EMAX ES3054
//
// ★ 到货必须卡尺复测再打印的参数:SV_*(舵机三项)、BUSH_OD、SHAFT_D
// ★ 机构行程:闭合 = CLOSED_DEG(10°,微倾使相邻叶鳞片式搭接不干涉),
//   全开 = 90°(水平);固件把 0-100% 开度映射到 10°-90°。
// ============================================================================

// ---------------- 全局参数(单位 mm) ----------------
FRAME_W  = 120;   // 框外宽(X)
FRAME_H  = 70;    // 框外高(Y)
FRAME_D  = 25;    // 框深/喉道(Z;前脸 z=0,喉道向 +Z)
LIP_T    = 3;     // 前脸包边板厚
OPEN_W   = 105;   // 内腔宽(叶片区)
OPEN_H   = 60;   // 内腔高(叶尖扫掠 ±28.9 → 留 1.1 间隙)
LIP_W    = 98;    // 前脸窗宽(包住叶端 3.5mm×2)
LIP_H    = 50;    // 前脸窗高(包住上下叶行程 3mm×2)
AXIS_Z   = 10;    // 叶轴线距前脸深度

N_BLADE  = 4;
PITCH    = 14;    // 叶片轴距(弦 15 → 闭合搭接 1mm)
BLADE_L  = 100;   // 叶长
CHORD    = 15;    // 叶弦
BLADE_T  = 2.0;   // 叶厚
CAMBER   = 1.5;   // 拱高(前凸)
CLOSED_DEG = 10;  // 闭合角(见文件头注释)

SHAFT_D  = 2.0;   // 钢轴径 ★复测
BUSH_OD  = 3.0;   // 黄铜套外径 ★复测
HOLE_COMP= 0.2;   // FDM 孔收缩补偿:所有孔径 = 目标实际尺寸 + 此值

CRANK_R  = 8;     // 曲柄半径(舵盘也取 8mm 孔 → 1:1)
CRANK_T  = 3;
CRANK_HUB= 7;     // 曲柄毂径
CRANK_GAP= 1.5;   // 曲柄内侧面与框外壁间隙

LINK_W   = 8;     // 拉杆截面宽
LINK_T   = 3;     // 拉杆厚
LINK_EXT = 20;    // 拉杆自最下曲柄销孔向下延伸至球头孔的距离

EAR      = 12;    // 安装耳边长
$fn = 48;

// ---- 舵机 EMAX ES3054(★全部到货复测) ----
SV_BODY_L = 28.6;    // 体长(留 0.2 装配余量)
SV_BODY_W = 13.2;    // 体宽
SV_HOLE_SPAN = 34.0; // 两安装孔中心距 ★最关键
SV_SCREW  = 2.4;     // 安装孔过孔径(配自带自攻钉)
SV_AXIS_OFF = 9.7;   // 输出轴中心距体上端的偏移 ★复测
SV_DROP  = 30;       // 舵机轴位于最下叶轴之下的距离(球头短杆可调,允差大)

// ---------------- 派生量 ----------------
function hd(d) = d + HOLE_COMP;              // 孔径补偿
COL_W    = (FRAME_W-OPEN_W)/2;               // 侧柱厚 7.5
BLADE_Y  = [ for (i=[0:N_BLADE-1]) (i-(N_BLADE-1)/2)*PITCH ]; // -21,-7,7,21
Y_BOT    = BLADE_Y[0];
Y_TOP    = BLADE_Y[N_BLADE-1];
CRANK_X  = FRAME_W/2 + CRANK_GAP;            // 曲柄内侧面 x
SPINE_Z  = -BLADE_T - 0.3;                   // 叶背脊/轴心相对叶弦面的 z
SV_AXIS_Y = Y_BOT - SV_DROP;                 // 舵机输出轴 y(-51)
SV_BODY_C = SV_AXIS_Y + SV_AXIS_OFF - SV_BODY_L/2; // 舵机体中心 y

echo("== Starling v0.1 派生量 ==");
echo(COL_W=COL_W, BLADE_Y=BLADE_Y, CRANK_X=CRANK_X, SV_AXIS_Y=SV_AXIS_Y);

// ============================================================================
// 零件 1:固定框 frame
// 前脸 z=0;两侧实心柱(厚 COL_W)带轴孔;后侧通透;四角安装耳(后缘)
// ============================================================================
module frame() {
  difference() {
    union() {
      translate([-FRAME_W/2, -FRAME_H/2, 0]) cube([FRAME_W, FRAME_H, FRAME_D]);
      for (sx=[-1,1], sy=[-1,1])   // 安装耳(后缘平面;嵌入本体 0.2 保证融合)
        translate([sx>0 ? FRAME_W/2-0.2 : -FRAME_W/2-EAR,
                   sy>0 ? FRAME_H/2-0.2 : -FRAME_H/2-EAR,
                   FRAME_D-3])
          cube([EAR+0.2, EAR+0.2, 3]);
    }
    // 前脸窗(包边圈)
    translate([-LIP_W/2, -LIP_H/2, -0.5]) cube([LIP_W, LIP_H, LIP_T+0.5]);
    // 主腔(叶片区,后侧通透;向前重叠 0.2 避免与前脸窗切割面共面)
    translate([-OPEN_W/2, -OPEN_H/2, LIP_T-0.2]) cube([OPEN_W, OPEN_H, FRAME_D]);
    // 轴套孔:Ø3(黄铜套压入),两侧柱贯通
    for (y=BLADE_Y)
      translate([-FRAME_W/2-1, y, AXIS_Z]) rotate([0,90,0])
        cylinder(d=hd(BUSH_OD), h=FRAME_W+2);
    // 扭簧锚孔(右柱,顶叶轴上方 6mm,Ø2 贯通)
    translate([FRAME_W/2-COL_W-1, Y_TOP+6, AXIS_Z]) rotate([0,90,0])
      cylinder(d=hd(2), h=COL_W+2);
    // 舵机支架安装孔:右柱下部 2×M3 贯通
    for (z=[8,18])
      translate([FRAME_W/2-COL_W-1, -FRAME_H/2+11, z]) rotate([0,90,0])
        cylinder(d=hd(3.2), h=COL_W+2);
    // 安装耳 M3 孔(轴向 Z)
    for (sx=[-1,1], sy=[-1,1])
      translate([sx*(FRAME_W/2+EAR/2), sy*(FRAME_H/2+EAR/2), FRAME_D-4])
        cylinder(d=hd(3.2), h=5);
  }
}

// ============================================================================
// 零件 2:叶片 blade
// 局部系:挤出沿 X;截面 (Y,Z):弦沿 Y(闭合姿态)、前凸 +Z;
// 钢轴槽心在 (y=0, z=SPINE_Z);装配时该点对齐框轴孔,旋转绕 X。
// ============================================================================
module blade_profile() {   // 2D:(弦向, 拱向)
  R  = (CHORD*CHORD/4 + CAMBER*CAMBER)/(2*CAMBER);
  A  = asin((CHORD/2)/R);
  zc = CAMBER - R;
  pts_out = [ for (t=[-A:A/16:A])  [R*sin(t), zc + R*cos(t)] ];
  pts_in  = [ for (t=[A:-A/16:-A]) [R*sin(t), zc + R*cos(t) - BLADE_T] ];
  polygon(concat(pts_out, pts_in));
}
module blade() {
  difference() {
    union() {
      // 弧板:2D(x=弦,y=拱) → 旋转使 弦→Y、拱→+Z、挤出→X
      translate([-BLADE_L/2,0,0]) rotate([0,90,0]) rotate([0,0,90])
        linear_extrude(BLADE_L) blade_profile();
      // 背脊(容轴)
      translate([-BLADE_L/2, 0, SPINE_Z]) rotate([0,90,0]) cylinder(d=5, h=BLADE_L);
    }
    // 轴道 Ø2.1 + 朝后 1.8 开口槽(钢轴卡入 + CA 胶)
    translate([-BLADE_L/2-1, 0, SPINE_Z]) rotate([0,90,0])
      cylinder(d=hd(SHAFT_D+0.1), h=BLADE_L+2);
    translate([-BLADE_L/2-1, -0.9, SPINE_Z-5]) cube([BLADE_L+2, 1.8, 5]);
  }
}

// ============================================================================
// 零件 3:曲柄 crank(毂过盈+CA 压钢轴端;销孔 M2 自攻)
// 局部系:毂心=原点,臂沿 +Y,厚沿 +Z
// ============================================================================
module crank() {
  difference() {
    union() {
      cylinder(d=CRANK_HUB, h=CRANK_T);
      translate([-2.5, 0, 0]) cube([5, CRANK_R, CRANK_T]);
      translate([0, CRANK_R, 0]) cylinder(d=6, h=CRANK_T);
    }
    translate([0,0,-1]) cylinder(d=hd(SHAFT_D-0.05), h=CRANK_T+2); // 轴孔(过盈)
    translate([0, CRANK_R, -1]) cylinder(d=hd(1.7), h=CRANK_T+2);  // M2 自攻底孔
  }
}

// ============================================================================
// 零件 4:拉杆 linkbar(平放建模:长沿 Y,厚沿 Z)
// 孔位:y=0..(N-1)*PITCH 曲柄销 ×4;y=-LINK_EXT 球头/舵机侧孔
// ============================================================================
module linkbar() {
  L_TOP = (N_BLADE-1)*PITCH;
  difference() {
    hull() {
      translate([0, -LINK_EXT, 0]) cylinder(d=LINK_W, h=LINK_T);
      translate([0,  L_TOP,    0]) cylinder(d=LINK_W, h=LINK_T);
    }
    for (i=[0:N_BLADE-1])
      translate([0, i*PITCH, -1]) cylinder(d=hd(2.4), h=LINK_T+2); // M2 过孔
    translate([0, -LINK_EXT, -1]) cylinder(d=hd(2.4), h=LINK_T+2);
  }
}

// ============================================================================
// 零件 5:舵机支架 servo_bracket
// 局部系=装配系:贴壁面 x=0(装配时平移 FRAME_W/2),板厚 +X,宽沿 Z(0..26)
// 上段贴框右柱(2×M3 竖槽);下段开舵机窗(体竖装,轴朝 +X,轴心 y=SV_AXIS_Y)
// ============================================================================
module servo_bracket() {
  PT = 3; W = 26;
  TOP_Y  = -FRAME_H/2 + 30;              // 上段顶
  BOT_Y  = SV_BODY_C - SV_HOLE_SPAN/2 - 6; // 下段底(孔外留 6)
  difference() {
    translate([0, BOT_Y, 0]) cube([PT, TOP_Y-BOT_Y, W]);
    // 2×M3 竖长槽(对框柱孔 y=-24, z=8/18;允 ±3 调)
    for (z=[8,18]) hull() for (dy=[-3,3])
      translate([-1, -FRAME_H/2+11+dy, z]) rotate([0,90,0]) cylinder(d=hd(3.2), h=PT+2);
    // 舵机体窗口(轴心 y=SV_AXIS_Y → 体窗按 SV_AXIS_OFF 反推)
    translate([-1, SV_BODY_C - SV_BODY_L/2, W/2 - SV_BODY_W/2])
      cube([PT+2, SV_BODY_L, SV_BODY_W]);
    // 舵机安装孔 ×2(跨距中心 = 体中心)
    for (sy=[-1,1])
      translate([-1, SV_BODY_C + sy*SV_HOLE_SPAN/2, W/2]) rotate([0,90,0])
        cylinder(d=hd(SV_SCREW), h=PT+2);
  }
}

// ============================================================================
// 零件 6:台架座 stand(平放打印:基板在 XY,立柱 +Z)
// 装配姿态:rotate([-90,0,0]) 后立柱朝上、柱顶孔沿世界 Z,与框下两耳自攻对接
// ============================================================================
POST_H = 45; POST = 10;
module stand() {
  BASE_L = 170; BASE_W = 60; BASE_T = 4;
  difference() {
    union() {
      translate([-BASE_L/2, -BASE_W/2, 0]) cube([BASE_L, BASE_W, BASE_T]);
      for (sx=[-1,1])
        translate([sx*(FRAME_W/2+EAR/2)-POST/2, -POST/2, 0])
          cube([POST, POST, POST_H]);
    }
    for (sx=[-1,1])   // 柱顶 M3 自攻孔(沿局部 Y 贯通柱)
      translate([sx*(FRAME_W/2+EAR/2), POST/2+1, POST_H-6]) rotate([90,0,0])
        cylinder(d=hd(2.8), h=POST+2);
  }
}

// ============================================================================
// 装配预览 assembly(仅预览用;OPEN_DEG=叶片自竖直转过的角度)
// 平行四边形:曲柄臂闭合时朝 +Z(后),开启绕 X 转 OPEN_DEG(上缘后仰)
// ============================================================================
OPEN_DEG = 45;
module assembly() {
  a = OPEN_DEG;
  color("dimgray") frame();
  for (y=BLADE_Y) translate([0, y, AXIS_Z]) rotate([a,0,0])
    translate([0,0,-SPINE_Z]) color("lightsteelblue") blade();
  // 曲柄:局部(厚Z,臂Y)→(厚X,臂Z):循环置换 X→Y→Z→X
  for (y=BLADE_Y) translate([CRANK_X, y, AXIS_Z]) rotate([a,0,0])
    rotate(120, [1,1,1]) color("orange") crank();
  // 拉杆:0 号孔跟随最下曲柄销(销圆弧平移,平行四边形)
  translate([CRANK_X+CRANK_T+0.4,
             Y_BOT - CRANK_R*sin(a),
             AXIS_Z + CRANK_R*cos(a)])
    rotate([0,90,0]) color("gold") linkbar();
  color("skyblue") translate([FRAME_W/2, 0, 0]) servo_bracket();
  color("saddlebrown") translate([0, -(POST_H+FRAME_H/2), FRAME_D+POST/2])
    rotate([-90,0,0]) stand();
}

// ---------------- 导出选择 ----------------
PART = "assembly";
if      (PART=="frame")         frame();
else if (PART=="blade")         blade();
else if (PART=="crank")         crank();
else if (PART=="linkbar")       linkbar();
else if (PART=="servo_bracket") servo_bracket();
else if (PART=="stand")         stand();
else assembly();
