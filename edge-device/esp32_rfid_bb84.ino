#include <Arduino.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <MFRC522.h>
#include <SPI.h>
#include <ArduinoJson.h>

// RFID pins
#define SS_PIN  5
#define RST_PIN 27

// WiFi credentials
const char* ssid = "NETLIFE-TOBAR";
const char* password = "0925042368";

// MQTT broker
const char* mqtt_server = "192.168.100.244";  // Raspberry Pi gateway
const int mqtt_port = 1883;
const char* mqtt_topic = "qsensor/rfid";
const char* mqtt_username = "mqttuser";
const char* mqtt_password = "mqttpassword";

// Initialize RFID
MFRC522 rfid(SS_PIN, RST_PIN);

// Initialize WiFi and MQTT clients
WiFiClient espClient;
PubSubClient client(espClient);

// BB84 protocol simplified for ESP32
// This is a simplified version of the quantum BB84 protocol
// In a real quantum system, we would use quantum hardware

// Generate random bits for BB84
byte generateRandomBits(int numBits) {
  byte result = 0;
  for (int i = 0; i < numBits && i < 8; i++) {
    // ESP32 has a true random number generator
    if (esp_random() % 2) {
      result |= (1 << i);
    }
  }
  return result;
}

// Generate random bases for BB84
byte generateRandomBases(int numBases) {
  return generateRandomBits(numBases);
}

// XOR encryption (classical equivalent for demo)
String xorEncrypt(String data, String key) {
  String result = "";
  for (unsigned int i = 0; i < data.length(); i++) {
    result += char(data[i] ^ key[i % key.length()]);
  }
  return result;
}

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    String clientId = "ESP32Client-";
    clientId += String(random(0xffff), HEX);
    
    if (client.connect(clientId.c_str(), mqtt_username, mqtt_password)) {
      Serial.println("connected");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  
  // Initialize RFID
  SPI.begin();
  rfid.PCD_Init();
  Serial.println("RFID reader initialized");
  
  // Setup WiFi
  setup_wifi();
  
  // Setup MQTT
  client.setServer(mqtt_server, mqtt_port);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Check if a new card is present
  if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
    Serial.println("Card detected!");
    
    // Get RFID UID
    String cardUID = "";
    for (byte i = 0; i < rfid.uid.size; i++) {
      cardUID += String(rfid.uid.uidByte[i], HEX);
    }
    Serial.print("Card UID: ");
    Serial.println(cardUID);
    
    // Simulate BB84 protocol
    byte aliceBits = generateRandomBits(8);
    byte aliceBases = generateRandomBases(8);
    
    // In a real quantum system, we'd send quantum states
    // Here we just simulate by sending classical bits and bases
    
    // Create a JSON document
    StaticJsonDocument<200> doc;
    
    // Add card information
    doc["card_id"] = cardUID;
    doc["timestamp"] = millis();
    
    // Add BB84 information (this would be quantum in a real system)
    doc["alice_bits"] = aliceBits;
    doc["alice_bases"] = aliceBases;
    
    // Serialize JSON to string
    String jsonString;
    serializeJson(doc, jsonString);
    
    // Simple encryption (in a real system this would be quantum-secured)
    String sharedKey = "01101101";  // This would be derived from BB84 in a real system
    String encryptedData = xorEncrypt(jsonString, sharedKey);
    
    // Publish to MQTT
    String message = "{\"data\":\"" + encryptedData + "\", \"device_id\":\"esp32-rfid-1\"}";
    client.publish(mqtt_topic, message.c_str());
    
    Serial.println("Data sent to MQTT broker");
    delay(1000);
    
    // Halt PICC and stop encryption
    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();
  }
  
  delay(100);
}
