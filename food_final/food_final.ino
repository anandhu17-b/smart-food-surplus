#include <WiFi.h>
#include <HTTPClient.h>
#include "HX711.h"
#include <OneWire.h>
#include <DallasTemperature.h>

// 🔹 WIFI DETAILS
const char* ssid = "AILAB-70 1336";
const char* password = "Admin@123";

// 🔹 FIREBASE URL
String firebaseUrl = "https://smartfood-iot-default-rtdb.asia-southeast1.firebasedatabase.app/esp_data.json";

// 🔹 LOAD CELL
#define DT 18
#define SCK 19
HX711 scale;
float calibration_factor = 77.0;

// 🔹 TEMP SENSOR
#define ONE_WIRE_BUS 21
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

float weight = 0;
float temperature = 0;

void setup() {
  Serial.begin(115200);

  // Load cell
  scale.begin(DT, SCK);
  scale.set_scale();
  scale.tare();

  // Temp sensor
  sensors.begin();

  // WiFi connect
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nConnected to WiFi");
}

void loop() {

  // 🔹 READ WEIGHT
  weight = scale.get_units(10) / calibration_factor;

  if (weight < 5 && weight > -5) {
    weight = 0;
  }

  // 🔹 READ TEMP
  sensors.requestTemperatures();
  temperature = sensors.getTempCByIndex(0);

  Serial.println("------");
  Serial.print("Weight: ");
  Serial.println(weight);
  Serial.print("Temp: ");
  Serial.println(temperature);

  // 🔹 SEND TO FIREBASE
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;

    String jsonData = "{";
    jsonData += "\"weight\":" + String(weight) + ",";
    jsonData += "\"temperature\":" + String(temperature);
    jsonData += "}";

    http.begin(firebaseUrl);
    http.addHeader("Content-Type", "application/json");

    int response = http.PUT(jsonData);

    Serial.print("Firebase Response: ");
    Serial.println(response);

    http.end();
  }

  delay(5000); // send every 5 sec
}