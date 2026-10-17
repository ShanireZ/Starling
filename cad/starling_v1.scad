// ============================================================================
// Starling 原型一號 · 機構參數化模型 v0.1(臺架版)
// OpenSCAD 原始檔 —— 唯一 CAD 真相;STL 由本檔案匯出,勿手編 STL。
//
// 用法:
//   GUI:打開本檔案,改底部 PART 變數預覽 / F6 繪製 / 匯出 STL;
//   CLI:openscad -o stl/frame.stl -D "PART=\"frame\"" starling_v1.scad
//   裝配預覽:PART="assembly",OPEN_DEG=CLOSED_DEG(閉合)~90(全開)
//
// 列印件清單:frame ×1 · blade ×4 · crank ×4 · linkbar ×1
//            servo_bracket ×1 · stand ×1
// 外購件:Ø2 不鏽鋼軸(切 4 段×125)· 黃銅套內2外3(切 8 段×6)
//        M2 球頭拉桿一組(舵機臂→拉桿下孔)· M2/M3 螺絲 · 扭簧 · EMAX ES3054
//
// ★ 到貨必須卡尺複測再列印的參數:SV_*(舵機三項)、BUSH_OD、SHAFT_D
// ★ 機構行程:閉合 = CLOSED_DEG(10°,微傾使相鄰葉鱗片式搭接不干涉),
//   全開 = 90°(水平);韌體把 0-100% 開度映射到 10°-90°。
// ============================================================================

// ---------------- 全域參數(單位 mm) ----------------
FRAME_W  = 120;   // 框外寬(X)
FRAME_H  = 70;    // 框外高(Y)
FRAME_D  = 25;    // 框深/喉道(Z;前臉 z=0,喉道向 +Z)
LIP_T    = 3;     // 前臉包邊板厚
OPEN_W   = 105;   // 內腔寬(葉片區)
OPEN_H   = 60;   // 內腔高(葉尖掃掠 ±28.9 → 留 1.1 間隙)
LIP_W    = 98;    // 前臉窗寬(包住葉端 3.5mm×2)
LIP_H    = 50;    // 前臉窗高(包住上下葉行程 3mm×2)
AXIS_Z   = 10;    // 葉軸線距前臉深度

N_BLADE  = 4;
PITCH    = 14;    // 葉片軸距(弦 15 → 閉合搭接 1mm)
BLADE_L  = 100;   // 葉長
CHORD    = 15;    // 葉弦
BLADE_T  = 2.0;   // 葉厚
CAMBER   = 1.5;   // 拱高(前凸)
CLOSED_DEG = 10;  // 閉合角(見檔案頭註解)

SHAFT_D  = 2.0;   // 鋼軸徑 ★複測
BUSH_OD  = 3.0;   // 黃銅套外徑 ★複測
HOLE_COMP= 0.2;   // FDM 孔收縮補償:所有孔徑 = 目標實際尺寸 + 此值

CRANK_R  = 8;     // 曲柄半徑(舵盤也取 8mm 孔 → 1:1)
CRANK_T  = 3;
CRANK_HUB= 7;     // 曲柄轂徑
CRANK_GAP= 1.5;   // 曲柄內側面與框外壁間隙

LINK_W   = 8;     // 拉桿截面寬
LINK_T   = 3;     // 拉桿厚
LINK_EXT = 20;    // 拉桿自最下曲柄銷孔向下延伸至球頭孔的距離

EAR      = 12;    // 安裝耳邊長
$fn = 48;

// ---- 舵機 EMAX ES3054(★全部到貨複測) ----
SV_BODY_L = 28.6;    // 體長(留 0.2 裝配餘量)
SV_BODY_W = 13.2;    // 體寬
SV_HOLE_SPAN = 34.0; // 兩安裝孔中心距 ★最關鍵
SV_SCREW  = 2.4;     // 安裝孔過孔徑(配自帶自攻釘)
SV_AXIS_OFF = 9.7;   // 輸出軸中心距體上端的偏移 ★複測
SV_DROP  = 30;       // 舵機軸位於最下葉軸之下的距離(球頭短杆可調,允差大)

// ---------------- 派生量 ----------------
function hd(d) = d + HOLE_COMP;              // 孔徑補償
COL_W    = (FRAME_W-OPEN_W)/2;               // 側柱厚 7.5
BLADE_Y  = [ for (i=[0:N_BLADE-1]) (i-(N_BLADE-1)/2)*PITCH ]; // -21,-7,7,21
Y_BOT    = BLADE_Y[0];
Y_TOP    = BLADE_Y[N_BLADE-1];
CRANK_X  = FRAME_W/2 + CRANK_GAP;            // 曲柄內側面 x
SPINE_Z  = -BLADE_T - 0.3;                   // 葉背脊/軸心相對葉弦面的 z
SV_AXIS_Y = Y_BOT - SV_DROP;                 // 舵機輸出軸 y(-51)
SV_BODY_C = SV_AXIS_Y + SV_AXIS_OFF - SV_BODY_L/2; // 舵機體中心 y

echo("== Starling v0.1 派生量 ==");
echo(COL_W=COL_W, BLADE_Y=BLADE_Y, CRANK_X=CRANK_X, SV_AXIS_Y=SV_AXIS_Y);

// ============================================================================
// 零件 1:固定框 frame
// 前臉 z=0;兩側實心柱(厚 COL_W)帶軸孔;後側通透;四角安裝耳(後緣)
// ============================================================================
module frame() {
  difference() {
    union() {
      translate([-FRAME_W/2, -FRAME_H/2, 0]) cube([FRAME_W, FRAME_H, FRAME_D]);
      for (sx=[-1,1], sy=[-1,1])   // 安裝耳(後緣平面;嵌入本體 0.2 保證融合)
        translate([sx>0 ? FRAME_W/2-0.2 : -FRAME_W/2-EAR,
                   sy>0 ? FRAME_H/2-0.2 : -FRAME_H/2-EAR,
                   FRAME_D-3])
          cube([EAR+0.2, EAR+0.2, 3]);
    }
    // 前臉窗(包邊圈)
    translate([-LIP_W/2, -LIP_H/2, -0.5]) cube([LIP_W, LIP_H, LIP_T+0.5]);
    // 主腔(葉片區,後側通透;向前重疊 0.2 避免與前臉窗切割面共面)
    translate([-OPEN_W/2, -OPEN_H/2, LIP_T-0.2]) cube([OPEN_W, OPEN_H, FRAME_D]);
    // 軸套孔:Ø3(黃銅套壓入),兩側柱貫通
    for (y=BLADE_Y)
      translate([-FRAME_W/2-1, y, AXIS_Z]) rotate([0,90,0])
        cylinder(d=hd(BUSH_OD), h=FRAME_W+2);
    // 扭簧錨孔(右柱,頂葉軸上方 6mm,Ø2 貫通)
    translate([FRAME_W/2-COL_W-1, Y_TOP+6, AXIS_Z]) rotate([0,90,0])
      cylinder(d=hd(2), h=COL_W+2);
    // 舵機支架安裝孔:右柱下部 2×M3 貫通
    for (z=[8,18])
      translate([FRAME_W/2-COL_W-1, -FRAME_H/2+11, z]) rotate([0,90,0])
        cylinder(d=hd(3.2), h=COL_W+2);
    // 安裝耳 M3 孔(軸向 Z)
    for (sx=[-1,1], sy=[-1,1])
      translate([sx*(FRAME_W/2+EAR/2), sy*(FRAME_H/2+EAR/2), FRAME_D-4])
        cylinder(d=hd(3.2), h=5);
  }
}

// ============================================================================
// 零件 2:葉片 blade
// 局部系:擠出沿 X;截面 (Y,Z):弦沿 Y(閉合姿態)、前凸 +Z;
// 鋼軸槽心在 (y=0, z=SPINE_Z);裝配時該點對齊框軸孔,旋轉繞 X。
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
      // 弧板:2D(x=弦,y=拱) → 旋轉使 弦→Y、拱→+Z、擠出→X
      translate([-BLADE_L/2,0,0]) rotate([0,90,0]) rotate([0,0,90])
        linear_extrude(BLADE_L) blade_profile();
      // 背脊(容軸)
      translate([-BLADE_L/2, 0, SPINE_Z]) rotate([0,90,0]) cylinder(d=5, h=BLADE_L);
    }
    // 軸道 Ø2.1 + 朝後 1.8 開口槽(鋼軸卡入 + CA 膠)
    translate([-BLADE_L/2-1, 0, SPINE_Z]) rotate([0,90,0])
      cylinder(d=hd(SHAFT_D+0.1), h=BLADE_L+2);
    translate([-BLADE_L/2-1, -0.9, SPINE_Z-5]) cube([BLADE_L+2, 1.8, 5]);
  }
}

// ============================================================================
// 零件 3:曲柄 crank(轂過盈+CA 壓鋼軸端;銷孔 M2 自攻)
// 局部系:轂心=原點,臂沿 +Y,厚沿 +Z
// ============================================================================
module crank() {
  difference() {
    union() {
      cylinder(d=CRANK_HUB, h=CRANK_T);
      translate([-2.5, 0, 0]) cube([5, CRANK_R, CRANK_T]);
      translate([0, CRANK_R, 0]) cylinder(d=6, h=CRANK_T);
    }
    translate([0,0,-1]) cylinder(d=hd(SHAFT_D-0.05), h=CRANK_T+2); // 軸孔(過盈)
    translate([0, CRANK_R, -1]) cylinder(d=hd(1.7), h=CRANK_T+2);  // M2 自攻底孔
  }
}

// ============================================================================
// 零件 4:拉桿 linkbar(平放建模:長沿 Y,厚沿 Z)
// 孔位:y=0..(N-1)*PITCH 曲柄銷 ×4;y=-LINK_EXT 球頭/舵機側孔
// ============================================================================
module linkbar() {
  L_TOP = (N_BLADE-1)*PITCH;
  difference() {
    hull() {
      translate([0, -LINK_EXT, 0]) cylinder(d=LINK_W, h=LINK_T);
      translate([0,  L_TOP,    0]) cylinder(d=LINK_W, h=LINK_T);
    }
    for (i=[0:N_BLADE-1])
      translate([0, i*PITCH, -1]) cylinder(d=hd(2.4), h=LINK_T+2); // M2 過孔
    translate([0, -LINK_EXT, -1]) cylinder(d=hd(2.4), h=LINK_T+2);
  }
}

// ============================================================================
// 零件 5:舵機支架 servo_bracket
// 局部系=裝配系:貼壁面 x=0(裝配時平移 FRAME_W/2),板厚 +X,寬沿 Z(0..26)
// 上段貼框右柱(2×M3 豎槽);下段開舵機窗(體豎裝,軸朝 +X,軸心 y=SV_AXIS_Y)
// ============================================================================
module servo_bracket() {
  PT = 3; W = 26;
  TOP_Y  = -FRAME_H/2 + 30;              // 上段頂
  BOT_Y  = SV_BODY_C - SV_HOLE_SPAN/2 - 6; // 下段底(孔外留 6)
  difference() {
    translate([0, BOT_Y, 0]) cube([PT, TOP_Y-BOT_Y, W]);
    // 2×M3 豎長槽(對框柱孔 y=-24, z=8/18;允 ±3 調)
    for (z=[8,18]) hull() for (dy=[-3,3])
      translate([-1, -FRAME_H/2+11+dy, z]) rotate([0,90,0]) cylinder(d=hd(3.2), h=PT+2);
    // 舵機體視窗(軸心 y=SV_AXIS_Y → 體窗按 SV_AXIS_OFF 反推)
    translate([-1, SV_BODY_C - SV_BODY_L/2, W/2 - SV_BODY_W/2])
      cube([PT+2, SV_BODY_L, SV_BODY_W]);
    // 舵機安裝孔 ×2(跨距中心 = 體中心)
    for (sy=[-1,1])
      translate([-1, SV_BODY_C + sy*SV_HOLE_SPAN/2, W/2]) rotate([0,90,0])
        cylinder(d=hd(SV_SCREW), h=PT+2);
  }
}

// ============================================================================
// 零件 6:臺架座 stand(平放列印:基板在 XY,立柱 +Z)
// 裝配姿態:rotate([-90,0,0]) 後立柱朝上、柱頂孔沿世界 Z,與框下兩耳自攻對接
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
    for (sx=[-1,1])   // 柱頂 M3 自攻孔(沿局部 Y 貫通柱)
      translate([sx*(FRAME_W/2+EAR/2), POST/2+1, POST_H-6]) rotate([90,0,0])
        cylinder(d=hd(2.8), h=POST+2);
  }
}

// ============================================================================
// 裝配預覽 assembly(僅預覽用;OPEN_DEG=葉片自豎直轉過的角度)
// 平行四邊形:曲柄臂閉合時朝 +Z(後),開啟繞 X 轉 OPEN_DEG(上緣後仰)
// ============================================================================
OPEN_DEG = 45;
module assembly() {
  a = OPEN_DEG;
  color("dimgray") frame();
  for (y=BLADE_Y) translate([0, y, AXIS_Z]) rotate([a,0,0])
    translate([0,0,-SPINE_Z]) color("lightsteelblue") blade();
  // 曲柄:局部(厚Z,臂Y)→(厚X,臂Z):循環置換 X→Y→Z→X
  for (y=BLADE_Y) translate([CRANK_X, y, AXIS_Z]) rotate([a,0,0])
    rotate(120, [1,1,1]) color("orange") crank();
  // 拉桿:0 號孔跟隨最下曲柄銷(銷圓弧平移,平行四邊形)
  translate([CRANK_X+CRANK_T+0.4,
             Y_BOT - CRANK_R*sin(a),
             AXIS_Z + CRANK_R*cos(a)])
    rotate([0,90,0]) color("gold") linkbar();
  color("skyblue") translate([FRAME_W/2, 0, 0]) servo_bracket();
  color("saddlebrown") translate([0, -(POST_H+FRAME_H/2), FRAME_D+POST/2])
    rotate([-90,0,0]) stand();
}

// ---------------- 匯出選擇 ----------------
PART = "assembly";
if      (PART=="frame")         frame();
else if (PART=="blade")         blade();
else if (PART=="crank")         crank();
else if (PART=="linkbar")       linkbar();
else if (PART=="servo_bracket") servo_bracket();
else if (PART=="stand")         stand();
else assembly();
