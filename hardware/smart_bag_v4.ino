#include <Ticker.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_NeoPixel.h>
#include <Wire.h>
#include <CircularBuffer.hpp>
#include <math.h>
#include <vector>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// === BLE ===
BLECharacteristic *hrCharacteristic;
#define SERVICE_UUID        "12345678-1234-1234-1234-1234567890AB"
#define HR_CHAR_UUID        "ABCD1234-5678-1234-5678-ABCDEF123456"

// === PIN 定义 ===
#define INPUT_PIN      2
#define BUTTON_PIN     21
#define PIXEL_PIN      10
#define OLED_SDA       6
#define OLED_SCL       7
#define NUMPIXELS      8
#define OLED_ADDR      0x3C

#define SAMPLE_RATE        125
#define SAMPLE_INTERVAL_MS (1000 / SAMPLE_RATE)
#define DATA_LENGTH        28

bool systemRunning = false;
unsigned long systemStartTime = 0;
unsigned long lastButtonPress = 0;
const unsigned long SYSTEM_DURATION = 60UL * 60UL * 1000UL;
const unsigned long HRV_DELAY     = 10UL * 60UL * 1000UL;

Ticker sampleTicker;
Adafruit_SSD1306 display(128, 64, &Wire, -1);
Adafruit_NeoPixel pixels(NUMPIXELS, PIXEL_PIN, NEO_GRB + NEO_KHZ800);
CircularBuffer<int, 5> RR_buffer;
std::vector<int> RR_full_record;

bool tickFlag = false;
bool peak = false;
bool IgnoreReading = false;
bool FirstPulseDetected = false;
unsigned long FirstPulseTime = 0, SecondPulseTime = 0, PulseInterval = 0;
float sig_data = 0, HR = 0, HRV = 0;

bool Getpeak(float);
float Filter(float);

void tickerISR() {
  tickFlag = true;
}

void setup() {
  Serial.begin(115200);
  pinMode(INPUT_PIN, INPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  sampleTicker.attach_ms(SAMPLE_INTERVAL_MS, tickerISR);

  Wire.begin(OLED_SDA, OLED_SCL);
  display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR);
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.print("Waiting for button...");
  display.display();

  pixels.begin();
  pixels.clear();
  pixels.show();

  BLEDevice::init("SmartStressBag");
  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);

  hrCharacteristic = pService->createCharacteristic(
                      HR_CHAR_UUID,
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_NOTIFY);
  hrCharacteristic->addDescriptor(new BLE2902());

  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->start();
  Serial.println("BLE started, waiting for connection...");
}

void loop() {
  static unsigned long lastBLEUpdate = 0;
  if (millis() - lastBLEUpdate >= 5000) {
    lastBLEUpdate = millis();

    if (!isnan(HR) && !isnan(HRV) && !isnan(sig_data) &&
        !isinf(HR) && !isinf(HRV) && !isinf(sig_data)) {
      char dataBuffer[32];  // 用原始 CSV，保证不超 MTU
      snprintf(dataBuffer, sizeof(dataBuffer), "%.1f,%.1f,%.3f", HR, HRV, sig_data);

      hrCharacteristic->setValue(dataBuffer);
      hrCharacteristic->notify();

      Serial.print("✅ BLE Sent: ");
      Serial.println(dataBuffer);
    } else {
      Serial.println("⚠️ Invalid data, skipped BLE notify");
    }
  }

  checkButton();
  if (!systemRunning) return;
  if (millis() - systemStartTime >= SYSTEM_DURATION) {
    stopSystem();
    return;
  }

  if (tickFlag) {
    tickFlag = false;
    int sensor_value = analogRead(INPUT_PIN);
    sig_data = Filter(sensor_value) / 2048.0;
    peak = Getpeak(sig_data);

    if (peak && !IgnoreReading) {
      if (!FirstPulseDetected) {
        FirstPulseTime = millis();
        FirstPulseDetected = true;
      } else {
        SecondPulseTime = millis();
        PulseInterval = SecondPulseTime - FirstPulseTime;
        RR_buffer.unshift(PulseInterval);
        RR_full_record.push_back(PulseInterval);
        FirstPulseTime = SecondPulseTime;
      }
      IgnoreReading = true;
    }
    if (!peak) IgnoreReading = false;

    if (RR_buffer.isFull()) {
      int RR_avg = 0;
      for (int i = 0; i < RR_buffer.size(); i++) RR_avg += RR_buffer[i];
      RR_avg /= RR_buffer.size();
      HR = 1000.0 * 60.0 / RR_avg;
      RR_buffer.pop();
    }

    if (millis() - systemStartTime >= HRV_DELAY && RR_full_record.size() >= 30) {
      float mean = 0;
      for (int rr : RR_full_record) mean += rr;
      mean /= RR_full_record.size();
      float sum_sq_diff = 0;
      for (int rr : RR_full_record)
        sum_sq_diff += pow(rr - mean, 2);
      HRV = sqrt(sum_sq_diff / (RR_full_record.size() - 1));
    }

    updateDisplay();
    updateNeoPixel();

    Serial.print("Raw: ");
    Serial.print(sensor_value);
    Serial.print("  HR: ");
    Serial.print(HR);
    Serial.print("  HRV: ");
    Serial.println(HRV);
  }
}

// === 防重复触发的按钮逻辑 ===
void checkButton() {
  static bool wasPressed = false;  // 状态锁

  if (digitalRead(BUTTON_PIN) == LOW) {
    if (!wasPressed && millis() - lastButtonPress > 500) {
      lastButtonPress = millis();
      wasPressed = true;  // 锁住

      systemRunning = true;
      systemStartTime = millis();
      FirstPulseDetected = false;
      IgnoreReading = false;  // 顺带清空
      RR_buffer.clear();
      RR_full_record.clear();
      pixels.clear();
      pixels.show();
      display.clearDisplay();
      display.display();
      Serial.println("🟢 Button Pressed. System Started.");
    }
  } else {
    wasPressed = false;  // 松开后解锁
  }
}

void stopSystem() {
  systemRunning = false;
  pixels.clear();
  pixels.show();
  display.clearDisplay();
  display.setCursor(0, 0);
  display.print("Session ended.");
  display.display();
  Serial.println("🛑 System stopped after 1 hour.");
}

void updateDisplay() {
  display.clearDisplay();
  display.setCursor(0, 0);
  display.printf("HR: %.1f bpm\n", HR);
  if (millis() - systemStartTime >= HRV_DELAY)
    display.printf("HRV: %.1f ms\n", HRV);
  else
    display.print("HRV: -- ms\n");
  display.display();
}

void updateNeoPixel() {
  bool signalOK = peak;
  if (signalOK) {
    pixels.setPixelColor(0, pixels.Color(0, 255, 0));
    if (millis() - systemStartTime > 120000UL) {
      pixels.setBrightness(10);
    } else {
      pixels.setBrightness(100);
    }
  } else {
    pixels.setPixelColor(0, pixels.Color(255, 0, 0));
    pixels.setBrightness(100);
  }
  pixels.show();
}

float Filter(float input) {
  float output = input;
  static float z1a, z2a, z1b, z2b;
  float x1 = output - (0.74471448 * z1a) - (0.16831887 * z2a);
  output = 0.30239179 * x1 + (0.60478358 * z1a) + (0.30239179 * z2a);
  z2a = z1a; z1a = x1;
  float x2 = output - (0.98454301 * z1b) - (0.54456536 * z2b);
  output = 1.00000000 * x2 + (2.00000000 * z1b) + (1.00000000 * z2b);
  z2b = z1b; z1b = x2;
  static float ma_buf[3] = {0};
  static int ma_index = 0;
  ma_buf[ma_index] = output;
  ma_index = (ma_index + 1) % 3;
  float sum = 0;
  for (int i = 0; i < 3; i++) sum += ma_buf[i];
  return sum / 3.0;
}

bool Getpeak(float new_sample) {
  static unsigned long last_peak_time = 0;
  static float data_buffer[DATA_LENGTH];
  static int data_index = 0;

  data_buffer[data_index] = new_sample;
  float mean = 0, stddev = 0;
  for (int i = 0; i < DATA_LENGTH; i++) mean += data_buffer[i];
  mean /= DATA_LENGTH;
  for (int i = 0; i < DATA_LENGTH; i++)
    stddev += pow(data_buffer[i] - mean, 2);
  stddev = sqrt(stddev / DATA_LENGTH);

  bool result = (new_sample - mean > 1.2 * stddev);
  unsigned long now = millis();
  if (result && FirstPulseDetected && (now - last_peak_time < 500)) return false;
  if (result) last_peak_time = now;
  if (result) Serial.println("✨ Peak detected");
  data_index = (data_index + 1) % DATA_LENGTH;
  return result;
}
