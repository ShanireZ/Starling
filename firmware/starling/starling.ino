// ============================================================================
// Starling 原型一号 · 固件骨架(2026-07-02)
// 目标板:ESP32 DevKit(WROOM-32) · Arduino 框架
//
// 链路:皮托管 → MS4525DO(I2C) → 阈值-斜坡曲线(滞回+限斜率+硬限位) → 舵机(百叶)
// 旁路:MPU6050 / BMP280 / DS3231 / GPS → microSD 10Hz CSV(纯被动记录,不进控制闭环)
// 配置:USB 串口 + 蓝牙 SPP 共用同一命令台(仅配置+取数,守 charter §3)
//
// ★ 状态:骨架代码——结构与控制律完整,尚未上板编译验证;
//   BMP280 补偿公式与 GPS NMEA 解析留 TODO(建议接 Adafruit_BMP280 / TinyGPSPlus 库)。
// ★ 边界(charter §3,勿改):无 OTA;蓝牙/串口不做任何实时开度控制;
//   test 命令仅在 IAS < 5 km/h(台架静止)时接受。
// ============================================================================

#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include <Preferences.h>
#include <BluetoothSerial.h>

// ---------------------------- 引脚与地址 ----------------------------
constexpr int PIN_I2C_SDA = 21;
constexpr int PIN_I2C_SCL = 22;
constexpr int PIN_SD_CS   = 5;    // VSPI:SCK=18 MISO=19 MOSI=23
constexpr int PIN_SERVO   = 13;   // LEDC 50Hz
constexpr int PIN_GPS_RX  = 16;   // UART2 ← GPS TX
constexpr int PIN_GPS_TX  = 17;   // UART2 → GPS RX

constexpr uint8_t ADDR_MS4525  = 0x28;
constexpr uint8_t ADDR_MPU6050 = 0x69; // AD0 → 3V3(避开 DS3231 的 0x68)
constexpr uint8_t ADDR_BMP280  = 0x76;
constexpr uint8_t ADDR_DS3231  = 0x68;

// ---------------------------- 可配置参数(NVS 持久化) ----------------------------
struct Params {
  float vOn        = 20.0f;  // km/h,开始张开阈值
  float vFull      = 60.0f;  // km/h,全开速度
  float hyst       = 3.0f;   // km/h,关闭滞回
  float openMaxDeg = 90.0f;  // 全开角硬上限(0=竖直闭合,90=水平全开)
  float slewDegS   = 120.0f; // 开度限斜率 °/s
  int   servoUs0   = 1000;   // 0° 脉宽(装配后标定)
  int   servoUs90  = 2000;   // 90° 脉宽
  int   logHz      = 10;     // 日志频率
};
Params P;
Preferences prefs;

void paramsLoad() {
  prefs.begin("starling", true);
  P.vOn        = prefs.getFloat("vOn",   P.vOn);
  P.vFull      = prefs.getFloat("vFull", P.vFull);
  P.hyst       = prefs.getFloat("hyst",  P.hyst);
  P.openMaxDeg = prefs.getFloat("omax",  P.openMaxDeg);
  P.slewDegS   = prefs.getFloat("slew",  P.slewDegS);
  P.servoUs0   = prefs.getInt("us0",     P.servoUs0);
  P.servoUs90  = prefs.getInt("us90",    P.servoUs90);
  P.logHz      = prefs.getInt("logHz",   P.logHz);
  prefs.end();
}
void paramsSave() {
  prefs.begin("starling", false);
  prefs.putFloat("vOn", P.vOn);   prefs.putFloat("vFull", P.vFull);
  prefs.putFloat("hyst", P.hyst); prefs.putFloat("omax", P.openMaxDeg);
  prefs.putFloat("slew", P.slewDegS);
  prefs.putInt("us0", P.servoUs0); prefs.putInt("us90", P.servoUs90);
  prefs.putInt("logHz", P.logHz);
  prefs.end();
}

// ---------------------------- 状态机 ----------------------------
enum class State { BOOT, ZERO_CAL, RUN, FAULT };
State state = State::BOOT;

float qZeroPa   = 0.0f;   // 静止零偏(上电校准)
float iasKmh    = 0.0f;   // 滤波后指示空速
float qPa       = 0.0f;   // 当前压差(去零偏)
float openDeg   = 0.0f;   // 当前输出开度
int   sensFails = 0;      // 传感连续失败计数(≥25 → FAULT)
bool  logging   = true;
bool  testMode  = false;  // test 命令台架模式
float testDeg   = 0.0f;

BluetoothSerial SerialBT;
File logFile;

// ---------------------------- MS4525DO 读取 ----------------------------
// ±1 psi 差压变体(常见空速计模块):14 位,10%~90% 满码映射 -1..+1 psi
bool ms4525Read(float &pa, float &tC) {
  Wire.requestFrom(ADDR_MS4525, (uint8_t)4);
  if (Wire.available() < 4) return false;
  uint8_t b0 = Wire.read(), b1 = Wire.read(), b2 = Wire.read(), b3 = Wire.read();
  uint8_t status = b0 >> 6;                 // 0=正常 2=陈旧 3=故障
  if (status == 3) return false;
  int16_t praw = ((b0 & 0x3F) << 8) | b1;
  const float PSI_TO_PA = 6894.76f;
  pa = ((praw - 0.1f * 16383.0f) * 2.0f / (0.8f * 16383.0f) - 1.0f) * PSI_TO_PA;
  int16_t traw = ((int16_t)b2 << 3) | (b3 >> 5);
  tC = traw * 200.0f / 2047.0f - 50.0f;
  return true;
}

// ---------------------------- 舵机(LEDC 50Hz) ----------------------------
constexpr int SERVO_CH = 0;
void servoInit() {
  ledcSetup(SERVO_CH, 50 /*Hz*/, 16 /*bit*/);
  ledcAttachPin(PIN_SERVO, SERVO_CH);
}
void servoWriteDeg(float deg) {
  deg = constrain(deg, 0.0f, P.openMaxDeg);           // 软限位(机构另有硬限位)
  float us = P.servoUs0 + (P.servoUs90 - P.servoUs0) * deg / 90.0f;
  uint32_t duty = (uint32_t)(us / 20000.0f * 65535.0f);
  ledcWrite(SERVO_CH, duty);
}

// ---------------------------- 控制律 ----------------------------
// 阈值-斜坡 + 滞回:v>V_ON 起开;回落到 V_ON-HYST 以下才归零(防在阈值附近抖)
float curveTargetPct(float vKmh) {
  static bool armed = false;
  if (!armed) {
    if (vKmh > P.vOn) armed = true; else return 0.0f;
  } else if (vKmh < P.vOn - P.hyst) {
    armed = false; return 0.0f;
  }
  float t = (vKmh - P.vOn) / max(1.0f, P.vFull - P.vOn);
  return constrain(t, 0.0f, 1.0f);
}

void controlStep(float dtS) {
  float tC;
  float paRaw;
  if (ms4525Read(paRaw, tC)) {
    sensFails = 0;
    qPa = paRaw - qZeroPa;
    float q = max(qPa, 0.0f);                          // 负压(软管接反/乱流)按 0
    float v = sqrtf(2.0f * q / 1.225f) * 3.6f;         // IAS km/h,标况密度
    iasKmh += 0.2f * (v - iasKmh);                     // EMA 滤波
  } else if (++sensFails >= 25) {
    state = State::FAULT;                              // 连续失败 → 失效闭合
  }

  float targetDeg = testMode ? testDeg
                             : curveTargetPct(iasKmh) * P.openMaxDeg;
  if (state == State::FAULT) targetDeg = 0.0f;

  float maxStep = P.slewDegS * dtS;                    // 限斜率
  openDeg += constrain(targetDeg - openDeg, -maxStep, maxStep);
  servoWriteDeg(openDeg);
}

// ---------------------------- 传感器套餐(纯记录) ----------------------------
struct Imu { float ax, ay, az, gx, gy, gz, tC; bool ok; };
Imu imuRead() {
  Imu r{}; r.ok = false;
  Wire.beginTransmission(ADDR_MPU6050);
  Wire.write(0x3B);
  if (Wire.endTransmission(false) != 0) return r;
  Wire.requestFrom(ADDR_MPU6050, (uint8_t)14);
  if (Wire.available() < 14) return r;
  auto rd16 = []() { int16_t v = (Wire.read() << 8) | Wire.read(); return v; };
  r.ax = rd16() / 16384.0f; r.ay = rd16() / 16384.0f; r.az = rd16() / 16384.0f;
  r.tC = rd16() / 340.0f + 36.53f;
  r.gx = rd16() / 131.0f;  r.gy = rd16() / 131.0f;  r.gz = rd16() / 131.0f;
  r.ok = true;
  return r;
}
void imuInit() {
  Wire.beginTransmission(ADDR_MPU6050);
  Wire.write(0x6B); Wire.write(0x00);                  // 退出休眠
  Wire.endTransmission();
}

// DS3231:BCD 读时间,给日志文件名与数据行
String rtcNow() {
  Wire.beginTransmission(ADDR_DS3231);
  Wire.write(0x00);
  if (Wire.endTransmission(false) != 0) return "0000-00-00 00:00:00";
  Wire.requestFrom(ADDR_DS3231, (uint8_t)7);
  if (Wire.available() < 7) return "0000-00-00 00:00:00";
  auto bcd = [](uint8_t v) { return (v >> 4) * 10 + (v & 0x0F); };
  int ss = bcd(Wire.read()), mi = bcd(Wire.read()), hh = bcd(Wire.read() & 0x3F);
  Wire.read();                                         // 星期,不用
  int dd = bcd(Wire.read()), mo = bcd(Wire.read() & 0x1F), yy = bcd(Wire.read());
  char buf[24];
  snprintf(buf, sizeof(buf), "20%02d-%02d-%02d %02d:%02d:%02d", yy, mo, dd, hh, mi, ss);
  return String(buf);
}

// TODO(接件时完善):BMP280 需读出厂标定系数做补偿运算,建议直接接 Adafruit_BMP280 库
float bmpPressurePa() { return NAN; }
float bmpTempC()      { return NAN; }

// TODO(接件时完善):GPS NMEA 解析建议接 TinyGPSPlus 库;骨架只开串口
struct Gps { bool fix = false; double lat = 0, lon = 0; float spdKmh = 0; };
Gps gps;
void gpsPoll() {
  while (Serial2.available()) {
    Serial2.read();                                    // TODO:喂给 TinyGPSPlus
  }
}

// ---------------------------- 日志(microSD CSV) ----------------------------
bool sdOk = false;
void logOpen() {
  if (!sdOk) return;
  String ts = rtcNow();
  ts.replace("-", ""); ts.replace(":", ""); ts.replace(" ", "-");
  SD.mkdir("/starling");
  logFile = SD.open("/starling/log-" + ts + ".csv", FILE_WRITE);
  if (logFile)
    logFile.println("ms,rtc,q_pa,ias_kmh,open_pct,servo_deg,"
                    "ax,ay,az,gx,gy,gz,imu_t,baro_pa,baro_t,"
                    "gps_fix,gps_lat,gps_lon,gps_spd_kmh,state");
}
void logStep() {
  if (!logging || !logFile) return;
  Imu m = imuRead();
  char row[256];
  snprintf(row, sizeof(row),
           "%lu,%s,%.1f,%.1f,%.1f,%.1f,%.3f,%.3f,%.3f,%.2f,%.2f,%.2f,%.1f,%.0f,%.1f,%d,%.6f,%.6f,%.1f,%d",
           (unsigned long)millis(), rtcNow().c_str(), qPa, iasKmh,
           openDeg / max(1.0f, P.openMaxDeg) * 100.0f, openDeg,
           m.ax, m.ay, m.az, m.gx, m.gy, m.gz, m.tC,
           bmpPressurePa(), bmpTempC(),
           gps.fix ? 1 : 0, gps.lat, gps.lon, gps.spdKmh, (int)state);
  logFile.println(row);
  static uint32_t lastFlush = 0;
  if (millis() - lastFlush > 1000) { logFile.flush(); lastFlush = millis(); }
}

// ---------------------------- 配置命令台(串口 + 蓝牙共用) ----------------------------
void zeroCal() {
  float sum = 0; int n = 0;
  uint32_t t0 = millis();
  while (millis() - t0 < 2000) {                       // 静止 2s 取均值
    float pa, tC;
    if (ms4525Read(pa, tC)) { sum += pa; n++; }
    delay(10);
  }
  if (n > 50) qZeroPa = sum / n;
}

void handleCmd(Stream &io, String line) {
  line.trim();
  if (line == "help") {
    io.println("help|stat|get|set <k> <v>|save|cal|log on/off|test <deg>|test off|reboot");
  } else if (line == "stat") {
    io.printf("state=%d q=%.1fPa ias=%.1fkm/h open=%.1fdeg sd=%d gps_fix=%d\n",
              (int)state, qPa, iasKmh, openDeg, sdOk ? 1 : 0, gps.fix ? 1 : 0);
  } else if (line == "get") {
    io.printf("vOn=%.1f vFull=%.1f hyst=%.1f openMax=%.0f slew=%.0f us0=%d us90=%d logHz=%d\n",
              P.vOn, P.vFull, P.hyst, P.openMaxDeg, P.slewDegS, P.servoUs0, P.servoUs90, P.logHz);
  } else if (line.startsWith("set ")) {
    int sp = line.indexOf(' ', 4);
    if (sp > 0) {
      String k = line.substring(4, sp); float v = line.substring(sp + 1).toFloat();
      if (k == "vOn") P.vOn = v; else if (k == "vFull") P.vFull = v;
      else if (k == "hyst") P.hyst = v; else if (k == "openMax") P.openMaxDeg = constrain(v, 0.0f, 90.0f);
      else if (k == "slew") P.slewDegS = v; else if (k == "us0") P.servoUs0 = (int)v;
      else if (k == "us90") P.servoUs90 = (int)v; else if (k == "logHz") P.logHz = (int)v;
      else { io.println("未知参数"); return; }
      io.println("ok(save 持久化)");
    }
  } else if (line == "save") {
    paramsSave(); io.println("已保存 NVS");
  } else if (line == "cal") {
    io.println("静止零偏校准 2s..."); zeroCal(); io.printf("zero=%.1fPa\n", qZeroPa);
  } else if (line == "log on")  { logging = true;  io.println("日志开"); }
  else if (line == "log off")   { logging = false; io.println("日志关"); }
  else if (line.startsWith("test")) {
    // ★ §3 边界:test 仅台架(近静止)可用,绝不在骑行中接受外部控制
    if (line == "test off") { testMode = false; io.println("test 退出"); return; }
    if (iasKmh >= 5.0f) { io.println("拒绝:IAS>=5km/h,test 仅限静止台架"); return; }
    testMode = true; testDeg = constrain(line.substring(5).toFloat(), 0.0f, P.openMaxDeg);
    io.printf("test 开度=%.0fdeg\n", testDeg);
  } else if (line == "reboot") { ESP.restart(); }
  else if (line.length()) io.println("未知命令,help 看用法");
}

String bufUsb, bufBt;
void consolePoll(Stream &io, String &buf) {
  while (io.available()) {
    char c = io.read();
    if (c == '\n' || c == '\r') { if (buf.length()) handleCmd(io, buf); buf = ""; }
    else buf += c;
  }
}

// ---------------------------- 主流程 ----------------------------
void setup() {
  Serial.begin(115200);
  SerialBT.begin("Starling-01");                       // 蓝牙 SPP,仅配置+取数
  Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL, 400000);
  Serial2.begin(9600, SERIAL_8N1, PIN_GPS_RX, PIN_GPS_TX);
  paramsLoad();
  servoInit();
  servoWriteDeg(0);                                    // 上电先闭合
  imuInit();
  sdOk = SD.begin(PIN_SD_CS);
  logOpen();
  // TODO:esp_task_wdt 看门狗;BMP280 初始化
  state = State::ZERO_CAL;
  zeroCal();                                           // OQ-4:上电静止零偏
  state = State::RUN;
  Serial.println("Starling 原型一号就绪(help 看命令)");
}

void loop() {
  static uint32_t lastCtl = 0, lastLog = 0;
  uint32_t now = millis();

  if (now - lastCtl >= 20) {                           // 50Hz 控制环
    controlStep((now - lastCtl) / 1000.0f);
    lastCtl = now;
  }
  if (now - lastLog >= (uint32_t)(1000 / max(1, P.logHz))) {
    logStep();
    lastLog = now;
  }
  gpsPoll();
  consolePoll(Serial, bufUsb);
  consolePoll(SerialBT, bufBt);

  if (state == State::FAULT) {                         // 周期重试传感,恢复则回 RUN
    static uint32_t lastRetry = 0;
    if (now - lastRetry > 2000) {
      float pa, tC;
      if (ms4525Read(pa, tC)) { sensFails = 0; state = State::RUN; }
      lastRetry = now;
    }
  }
}
