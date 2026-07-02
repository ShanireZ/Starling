// ============================================================================
// Starling 原型一号 · 机构参数化模型 v0.1(台架版)
// OpenSCAD 源文件 —— 唯一 CAD 真相;STL 由本文件导出,勿手编 STL。
//
// 用法:
//   GUI:开本文件,改底部 PART 变量预览/导出;
//   CLI:openscad -o stl/frame.stl -D "PART=\"frame\"" starling_v1.scad
//   装配预览:PART="assembly",OPEN_DEG=0(闭合)~90(全开)
//
// 打印件清单:frame ×1 · blade ×4 · crank ×4 · linkbar ×1
//            servo_bracket ×1 · stand ×1
// 外购件:Ø2 不锈钢轴(切 4 段 ×125mm)· 黄铜套 内2外3(切 8 段 ×6mm)
//         M2 球头拉杆 ×1 组(舵机→拉杆)· M2/M3 螺丝 · 扭簧 · EMAX ES3054
//
// ★ 元件到货后必须卡尺复测再打印的参数:SV_*(舵机)、BUSH_OD、SHAFT_D
// ============================================================================

// ---------------- 全局参数(单位 mm) ----------------
FRAME_W  = 120;   // 框外宽(X)
FRAME_H  = 70;    // 框外高(Y)
FRAME_D  = 25;    // 框深/喉道(Z;前脸 z=0,喉道向 +Z)
LIP_T    = 3;     // 前脸包边板厚
OPEN_W   = 105;   // 内腔宽(叶片区)
OPEN_H   = 56;    // 内腔高
LIP_W    = 98;    // 前脸窗宽(包住叶端 1mm×2)
LIP_H    = 50;    // 前脸窗高(包住上下叶缘 3mm×2)
AXIS_Z   = 10;    // 叶轴距前脸深度

N_BLADE  = 4;
PITCH    = 14;    // 叶片轴距(弦 15 → 闭合搭接 1mm)
BLADE_L  = 100;   // 叶长
CHORD    = 15;    // 叶弦
BLADE_T  = 2.0;   // 叶厚
CAMBER   = 1.5;   // 拱高(前凸)

SHAFT_D  = 2.0;   // 钢轴径 ★复测
BUSH_OD  = 3.0;   // 黄铜套外径 ★复测
HOLE_COMP= 0.2;   // FDM 孔收缩补偿(孔径统一 +0.2;压入过紧可扩此值重打)

CRANK_R  = 8;     // 曲柄半径(舵盘取同半径孔 → 1:1)
CRANK_T  = 3;
CRANK_HUB= 7;     // 曲柄毂径
CRANK_GAP= 1.5;   // 曲柄内侧面与框外壁间隙

LINK_W   = 8;     // 拉杆截面宽(Z 向)
LINK_T   = 3;     // 拉杆厚(X 向)
LINK_EXT = 20;    // 拉杆下延至舵机球头孔的距离

M2_TAP   = 1.8;   // M2 自攻底孔(曲柄销)
M2_FREE  = 2.4;   // M2 过孔(拉杆销孔,留转动间隙)
M3_FREE  = 3.4;   // M3 过孔

// ---- 舵机 EMAX ES3054(★全部到货复测) ----
SV_BODY_L = 28.6; // 体长(含少量余量)
SV_BODY_W = 13.2; // 体宽
SV_HOLE_SPAN = 34.0; // 两安装孔中心距 ★最关键
SV_SCREW  = 2.4;  // 安装孔过孔(配 M2 自攻)
SV_AXIS_OFF = 9.7;  // 输出轴距体端中心偏移(轴不在体中心)★复测
SV_DROP  = 30;    // 舵机轴在最下叶轴之下的距离(球头短杆可调,允差大)

EAR      = 12;    // 安装耳边长
$fn = 48;

// ---------------- 派生量 ----------------
COL_W   = (FRAME_W-OPEN_W)/2;            // 侧柱厚 7.5
BLADE_Y = [ for (i=[0:N_BLADE-1]) (i-(N_BLADE-1)/2)*PITCH ]; // 叶轴 y:-21,-7,7,21
Y_BOT   = BLADE_Y[0];                    // 最下叶轴
CRANK_X = FRAME_W/2 + CRANK_GAP;         // 曲柄内侧面 x
SV_AXIS_Y = Y_BOT - SV_DROP;             // 舵机轴 y
ROD_CH  = SHAFT_D + 0.1 + HOLE_COMP;     // 叶背轴槽径

// ============================================================================
// 零件 1:固定框 frame
// ============================================================================
module frame() {
  difference() {
    union() {
      // 主体
      translate([-FRAME_W/2, -FRAME_H/2, 0]) cube([FRAME_W, FRAME_H, FRAME_D]);
      // 4 安装耳(后缘平面,M3)
      for (sx=[-1,1], sy=[-1,1])
        translate([sx*(FRAME_W/2+EAR/2)-EAR/2, sy*(FRAME_H/2)-(sy>0?0:EAR), FRAME_D-3])
          cube([EAR, EAR, 3]);
    }
    // 前脸窗(包边)
    translate([-LIP_W/2, -LIP_H/2, -0.5]) cube([LIP_W, LIP_H, LIP_T+0.5]);
    // 主腔(叶片区,后侧通透)
    translate([-OPEN_W/2, -OPEN_H/2, LIP_T]) cube([OPEN_W, OPEN_H, FRAME_D]);
    // 轴套孔:两侧柱,Ø(BUSH_OD+COMP) 贯通
    for (y=BLADE_Y)
      translate([-FRAME_W/2-1, y, AXIS_Z]) rotate([0,90,0])
        cylinder(d=BUSH_OD+HOLE_COMP, h=FRAME_W+2);
    // 扭簧锚孔(右柱顶部,Ø2 贯通 X)
    translate([FRAME_W/2-COL_W-1, BLADE_Y[N_BLADE-1]+6, AXIS_Z]) rotate([0,90,0])
      cylinder(d=2+HOLE_COMP, h=COL_W+2);
    // 舵机支架安装孔:右柱下部 2×M3 贯通 X
    for (z=[8,18])
      translate([FRAME_W/2-COL_W-1, -FRAME_H/2+11, z]) rotate([0,90,0])
        cylinder(d=M3_FREE, h=COL_W+2);
    // 安装耳 M3 孔
    for (sx=[-1,1], sy=[-1,1])
      translate([sx*(FRAME_W/2+EAR/2), sy*(FRAME_H/2+EAR/2)-sy*EAR/2*0 + (sy>0?EAR/2:-EAR/2), FRAME_D-4])
        cylinder(d=M3_FREE, h=5);
  }
}

// ============================================================================
// 零件 2:叶片 blade(挤出等厚弧板 + 背脊轴槽)
// 局部系:挤出沿 X;截面在 (Y,Z),弦沿 Y(=闭合姿态),前凸 +Z;轴心=原点
// ============================================================================
module blade_profile() {
  R = (CHORD*CHORD/4 + CAMBER*CAMBER)/(2*CAMBER); // 弧半径
  A = asin((CHORD/2)/R);                          // 半张角
  zc = CAMBER - R;                                // 弧心 z
  pts_out = [ for (t=[-A:A/16:A]) [R*sin(t), zc + R*cos(t)] ];
  pts_in  = [ for (t=[A:-A/16:-A]) [R*sin(t), zc + R*cos(t) - BLADE_T] ];
  polygon(concat(pts_out, pts_in));
}
module blade() {
  spine_z = -BLADE_T - 0.3;   // 背脊圆柱心(凹面后方)
  difference() {
    union() {
      translate([-BLADE_L/2,0,0]) rotate([0,90,0]) rotate([0,0,-90])
        linear_extrude(BLADE_L) blade_profile();
      // 背脊(容轴槽)
      translate([-BLADE_L/2, 0, spine_z]) rotate([0,90,0])
        cylinder(d=5, h=BLADE_L);
    }
    // 轴槽(Ø2.1 通道 + 1.8 开口朝后,钢轴卡入+胶)
    translate([-BLADE_L/2-1, 0, spine_z]) rotate([0,90,0])
      cylinder(d=ROD_CH, h=BLADE_L+2);
    translate([-BLADE_L/2-1, -0.9, spine_z-5]) cube([BLADE_L+2, 1.8, 5]);
  }
}
// 注:轴心在背脊(y=0,z=spine_z);装配时该点对齐框轴孔。

// ============================================================================
// 零件 3:曲柄 crank(毂压入钢轴端+CA 胶;销孔 M2 自攻)
// 局部系:毂心=原点,臂沿 +Y,厚 CRANK_T 沿 Z(装配时 Z→X)
// ============================================================================
module crank() {
  difference() {
    union() {
      cylinder(d=CRANK_HUB, h=CRANK_T);
      translate([-2.5, 0, 0]) cube([5, CRANK_R, CRANK_T]);
      translate([0, CRANK_R, 0]) cylinder(d=6, h=CRANK_T);
    }
    translate([0,0,-1]) cylinder(d=SHAFT_D-0.05+HOLE_COMP, h=CRANK_T+2); // 轴孔(过盈+胶)
    translate([0, CRANK_R, -1]) cylinder(d=M2_TAP, h=CRANK_T+2);         // 销孔 M2 自攻
  }
}

// ============================================================================
// 零件 4:拉杆 linkbar(串 4 曲柄销 + 下延球头孔)
// 局部系:平放,长沿 Y,孔位 y=0,PITCH,2P,3P,下延 -LINK_EXT 处球头孔
// ============================================================================
module linkbar() {
  L_TOP = (N_BLADE-1)*PITCH;   // 42
  difference() {
    hull() {
      translate([0, -LINK_EXT, 0]) cylinder(d=LINK_W, h=LINK_T);
      translate([0, L_TOP, 0])     cylinder(d=LINK_W, h=LINK_T);
    }
    for (i=[0:N_BLADE-1])
      translate([0, i*PITCH, -1]) cylinder(d=M2_FREE, h=LINK_T+2);  // 曲柄销孔
    translate([0, -LINK_EXT, -1]) cylinder(d=M2_FREE, h=LINK_T+2); // 球头/舵机侧孔
  }
}

// ============================================================================
// 零件 5:舵机支架 servo_bracket(L 形:贴框右柱外壁,下垂托舵机)
// 局部系:与装配系同向;贴壁面 x=0(装配时移到 FRAME_W/2)
// ============================================================================
module servo_bracket() {
  PT = 3;         // 板厚
  TOP_H = 30;     // 上段贴壁板高(覆盖框柱下部)
  W = 26;         // 板宽(Z 向)
  DROP = -Y_BOT + (-SV_AXIS_Y) ;  // 由框底延伸的落差参考
  BODY_TOP = SV_AXIS_Y + SV_HOLE_SPAN/2 + 4;
  BODY_BOT = SV_AXIS_Y - SV_HOLE_SPAN/2 - 4;
  difference() {
    union() {
      // 上段:贴框右柱外壁(x=0..PT),y 从框底向上 TOP_H
      translate([0, -FRAME_H/2, 0]) cube([PT, TOP_H, W]);
      // 下段:舵机安装板(同一平面延伸向下)
      translate([0, BODY_BOT, 0]) cube([PT, -FRAME_H/2 - BODY_BOT + 0.1, W]);
    }
    // 上段:2×M3 竖长槽(对框柱孔,允 ±3 调)
    for (z=[8,18]) hull() for (dy=[-3,3])
      translate([-1, -FRAME_H/2+11+dy, z]) rotate([0,90,0]) cylinder(d=M3_FREE, h=PT+2);
    // 舵机体窗口(体长沿 Y 竖装,轴朝 +X 指向曲柄平面)
    translate([-1, SV_AXIS_Y - SV_AXIS_OFF - SV_BODY_L/2 + SV_BODY_L/2*0, W/2 - SV_BODY_W/2])
      translate([0, -(SV_BODY_L/2) + SV_AXIS_OFF, 0])
        cube([PT+2, SV_BODY_L, SV_BODY_W]);
    // 舵机安装孔 ×2(跨距 SV_HOLE_SPAN,过孔;体窗口中心对 SV 轴偏移)
    for (sy=[-1,1])
      translate([-1, SV_AXIS_Y - SV_AXIS_OFF + SV_BODY_L/2*0 + sy*SV_HOLE_SPAN/2 - (SV_BODY_L/2 - SV_AXIS_OFF), W/2])
        rotate([0,90,0]) cylinder(d=SV_SCREW, h=PT+2);
  }
}
// 注:窗口/孔位以 SV_AXIS_OFF 把「舵机输出轴」对齐 SV_AXIS_Y;到货复测后修正。

// ============================================================================
// 零件 6:台架座 stand(基板 + 双立柱,挂框下两耳)
// ============================================================================
module stand() {
  BASE_L = 170; BASE_W = 60; BASE_T = 4;
  POST_H = 45; POST = 10;
  difference() {
    union() {
      translate([-BASE_L/2, -BASE_W/2, 0]) cube([BASE_L, BASE_W, BASE_T]);
      for (sx=[-1,1])
        translate([sx*(FRAME_W/2+EAR/2)-POST/2, -POST/2, 0]) cube([POST, POST, POST_H]);
    }
    for (sx=[-1,1])
      translate([sx*(FRAME_W/2+EAR/2), POST/2+1, POST_H-6]) rotate([90,0,0])
        cylinder(d=2.8, h=POST+2);   // M3 自攻
  }
}

// ============================================================================
// 装配预览 assembly(OPEN_DEG=0 闭合 / 90 全开)
// ============================================================================
OPEN_DEG = 45;
module assembly() {
  color("dimgray") frame();
  // 叶片(绕各自轴转 -OPEN_DEG:上缘后仰、下缘前压 → 开缝)
  for (y=BLADE_Y) translate([0, y, AXIS_Z]) rotate([-OPEN_DEG,0,0])
    translate([0,0, BLADE_T+0.3])  // 把背脊轴心移到原点
      color("lightsteelblue") blade();
  // 曲柄(右侧,臂初始朝 +Z 前方;随叶同转)
  for (y=BLADE_Y) translate([CRANK_X, y, AXIS_Z]) rotate([-OPEN_DEG,0,0]) rotate([90,0,90])
    rotate([0,0,-90]) color("orange") crank();
  // 拉杆(平行四边形:随曲柄销平移)
  translate([CRANK_X+CRANK_T+0.5, BLADE_Y[0], AXIS_Z]) rotate([0,90,0]) rotate([0,0,-90])
    translate([ -CRANK_R*sin(OPEN_DEG), CRANK_R*cos(OPEN_DEG), 0]*0 ) // 示意:CLI 渲染用
      color("gold") translate([CRANK_R*cos(90-OPEN_DEG)*0, 0, 0]) linkbar_at(OPEN_DEG);
  color("skyblue") translate([FRAME_W/2, 0, 0]) servo_bracket();
  color("saddlebrown") translate([0, -FRAME_H/2-45+0.1, 12]) rotate([0,0,0]) stand_pose();
}
module linkbar_at(a) {
  // 拉杆姿态:销心圆弧平移(平行四边形)
  translate([CRANK_R*sin(-a)*0 + 0, 0, 0]) linkbar();
}
module stand_pose() { rotate([90,0,0]) translate([0,0,-4]) stand(); }

// ---------------- 导出选择 ----------------
PART = "assembly";
if (PART=="frame")          frame();
else if (PART=="blade")     blade();
else if (PART=="crank")     crank();
else if (PART=="linkbar")   linkbar();
else if (PART=="servo_bracket") servo_bracket();
else if (PART=="stand")     stand();
else assembly();
