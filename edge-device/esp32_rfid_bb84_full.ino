/*
 * ESP32 RFID BB84 Control de Acceso
 * 
 * Este código integra un lector RFID con el sistema de control de acceso
 * basado en el protocolo de encriptación cuántica BB84.
 */

#include <SPI.h>
#include <MFRC522.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// Definir pines para ESP32
#define SS_PIN 5    // SDA/SS conectado al pin GPIO5
#define RST_PIN 27  // RST conectado al pin GPIO27

// LED y buzzer para indicación de acceso
#define LED_GREEN 13
#define LED_RED 12
#define BUZZER 14

// Configuración WiFi
const char* ssid = "TU_WIFI_SSID";
const char* password = "TU_WIFI_PASSWORD";

// Configuración MQTT
const char* mqttServer = "192.168.100.244"; // IP de la Raspberry Pi
const int mqttPort = 1883;
const char* mqttRequestTopic = "quantum/access/request";
const char* mqttResponseTopic = "quantum/access/response";

// Instancias
MFRC522 rfid(SS_PIN, RST_PIN);
WiFiClient espClient;
PubSubClient client(espClient);

// Variables globales
unsigned long lastReadTime = 0;
const unsigned long readDelay = 3000; // 3 segundos entre lecturas
String lastUid = "";
bool accessGranted = false;

// Función para conectar a WiFi
void setupWiFi() {
  Serial.println("Conectando a WiFi...");
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println("");
  Serial.println("WiFi conectado");
  Serial.println("Dirección IP: ");
  Serial.println(WiFi.localIP());
}

// Callback para mensajes MQTT recibidos
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Mensaje recibido [");
  Serial.print(topic);
  Serial.print("] ");
  
  char message[length + 1];
  for (int i = 0; i < length; i++) {
    message[i] = (char)payload[i];
  }
  message[length] = '\0';
  Serial.println(message);
  
  // Parsear JSON
  StaticJsonDocument<512> doc;
  DeserializationError error = deserializeJson(doc, message);
  
  if (error) {
    Serial.print("Error al deserializar JSON: ");
    Serial.println(error.c_str());
    return;
  }
  
  // Verificar respuesta de acceso
  if (doc.containsKey("uid") && doc.containsKey("access")) {
    String uid = doc["uid"].as<String>();
    String access = doc["access"].as<String>();
    String key = doc["key"].as<String>();
    
    // Verificar que sea para nuestra última tarjeta leída
    if (uid.equals(lastUid)) {
      if (access.equals("granted")) {
        Serial.println("Acceso permitido");
        Serial.print("Clave cuántica compartida: ");
        Serial.println(key);
        
        // Indicar acceso permitido
        digitalWrite(LED_GREEN, HIGH);
        digitalWrite(LED_RED, LOW);
        tone(BUZZER, 1000, 500); // Tono agudo - acceso permitido
        accessGranted = true;
      } else {
        Serial.println("Acceso denegado");
        
        // Indicar acceso denegado
        digitalWrite(LED_GREEN, LOW);
        digitalWrite(LED_RED, HIGH);
        tone(BUZZER, 200, 1000); // Tono grave - acceso denegado
        accessGranted = false;
      }
      
      // Restablecer después de 3 segundos
      delay(3000);
      digitalWrite(LED_GREEN, LOW);
      digitalWrite(LED_RED, LOW);
    }
  }
}

// Función para reconectar a MQTT
void reconnect() {
  while (!client.connected()) {
    Serial.print("Conectando a MQTT...");
    // Crear un ID de cliente aleatorio
    String clientId = "ESP32Client-";
    clientId += String(random(0xffff), HEX);
    
    if (client.connect(clientId.c_str())) {
      Serial.println("conectado");
      // Suscribirse al topic de respuestas
      client.subscribe(mqttResponseTopic);
    } else {
      Serial.print("falló, rc=");
      Serial.print(client.state());
      Serial.println(" intentando de nuevo en 5 segundos");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  
  // Configurar pines
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_RED, OUTPUT);
  pinMode(BUZZER, OUTPUT);
  
  // Inicializar conexiones
  SPI.begin();
  rfid.PCD_Init();
  
  // Conectar a WiFi
  setupWiFi();
  
  // Configurar MQTT
  client.setServer(mqttServer, mqttPort);
  client.setCallback(callback);
  
  Serial.println("Sistema de control de acceso RFID con BB84 iniciado");
  Serial.println("-------------------------------------------");
  
  // Parpadeo inicial para indicar que el sistema está listo
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_GREEN, HIGH);
    digitalWrite(LED_RED, HIGH);
    delay(200);
    digitalWrite(LED_GREEN, LOW);
    digitalWrite(LED_RED, LOW);
    delay(200);
  }
}

void loop() {
  // Mantener conexión MQTT
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
  
  // Verificar si hay una nueva tarjeta y si ha pasado suficiente tiempo desde la última lectura
  unsigned long currentTime = millis();
  if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial() && 
      (currentTime - lastReadTime > readDelay)) {
    
    lastReadTime = currentTime;
    
    // Leer UID
    String uid = "";
    for (byte i = 0; i < rfid.uid.size; i++) {
      uid += (rfid.uid.uidByte[i] < 0x10 ? "0" : "");
      uid += String(rfid.uid.uidByte[i], HEX);
    }
    uid.toUpperCase();
    lastUid = uid;
    
    Serial.print("Tarjeta detectada con UID: ");
    Serial.println(uid);
    
    // Preparar solicitud JSON
    StaticJsonDocument<256> doc;
    doc["uid"] = uid;
    
    char jsonBuffer[256];
    serializeJson(doc, jsonBuffer);
    
    // Enviar solicitud por MQTT
    Serial.print("Enviando solicitud de acceso: ");
    Serial.println(jsonBuffer);
    client.publish(mqttRequestTopic, jsonBuffer);
    
    // Detener la lectura de la tarjeta
    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();
    
    // Indicador visual de lectura
    digitalWrite(LED_RED, HIGH);
    digitalWrite(LED_GREEN, HIGH);
    delay(500);
    digitalWrite(LED_RED, LOW);
    digitalWrite(LED_GREEN, LOW);
  }
}
