/*
 * RFID Reader Simple
 * 
 * Este código lee el UUID de una tarjeta RFID con un lector MFRC522
 * y lo muestra en el monitor serie.
 */

#include <SPI.h>
#include <MFRC522.h>

// Definir pines para ESP32
#define SS_PIN 5    // SDA/SS conectado al pin GPIO5
#define RST_PIN 27  // RST conectado al pin GPIO27

MFRC522 rfid(SS_PIN, RST_PIN); // Crear instancia MFRC522

void setup() {
  Serial.begin(115200);
  SPI.begin();      // Iniciar SPI
  rfid.PCD_Init();  // Iniciar MFRC522
  
  Serial.println("Lector RFID iniciado. Acerca una tarjeta para leer su UUID.");
  Serial.println("-----------------------------------------------------------");
}

void loop() {
  // Buscar tarjetas nuevas
  if (!rfid.PICC_IsNewCardPresent()) {
    return;
  }
  
  // Leer el ID
  if (!rfid.PICC_ReadCardSerial()) {
    return;
  }
  
  // Mostrar UUID
  Serial.print("UUID de tarjeta detectada: ");
  String uid = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    uid += (rfid.uid.uidByte[i] < 0x10 ? "0" : "");
    uid += String(rfid.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();
  Serial.println(uid);
  
  Serial.println("-----------------------------------------------------------");
  
  // Detener lectura de PICC
  rfid.PICC_HaltA();
  
  // Detener encriptación del PCD
  rfid.PCD_StopCrypto1();
  
  // Esperar un momento antes de la siguiente lectura
  delay(1000);
}
