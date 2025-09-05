#include <ESP8266WiFi.h>
#include <Firebase_ESP_Client.h>

// ==== CONFIGURAÇÃO WI-FI ====
#define WIFI_SSID "Casa das Primas"
#define WIFI_PASSWORD "computaria"

// ==== CONFIGURAÇÃO FIREBASE ====
#define DATABASE_SECRET "jOGaYzN1AzVS39z9QX22nt7Mm9XkEPmNZ7tqs1jG" // COLE O SECRET AQUI
#define DATABASE_URL "umidade-solo-default-rtdb.firebaseio.com"

FirebaseData fbdo;
FirebaseConfig config;
FirebaseAuth auth;

// ==== PINOS ====
const int SENSOR_PIN = A0;
const int LED_VERDE  = 5;
const int LED_AZUL   = 2;

// ==== CALIBRAÇÃO SENSOR ====
const int DRY_VALUE = 1024;
const int WET_VALUE = 422;

// ==== VARIÁVEIS ====
unsigned long lastRead = 0;
const int READ_INTERVAL = 10000; // 10 segundos

void setup() {
  Serial.begin(115200);

  pinMode(LED_VERDE, OUTPUT);
  pinMode(LED_AZUL, OUTPUT);
  digitalWrite(LED_VERDE, LOW);
  digitalWrite(LED_AZUL, HIGH);

  Serial.println("Iniciando ESP8266...");

  // Conexão Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Conectando ao WiFi");
  int tentativas = 0;
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    tentativas++;
    if (tentativas > 40) {
      Serial.println("\nFalha ao conectar ao WiFi!");
      digitalWrite(LED_VERDE, HIGH);
      while(1) { delay(1000); }
    }
  }

  Serial.println("\nWiFi conectado!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());

  // ---- Configuração Firebase COM SECRET ----  
  config.database_url = DATABASE_URL;
  config.signer.tokens.legacy_token = DATABASE_SECRET;
  
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  delay(3000);
  
  // Teste final de conexão
  if (Firebase.RTDB.setInt(&fbdo, "/status", 1)) {
    Serial.println("✅ Firebase conectado com sucesso!");
    digitalWrite(LED_VERDE, HIGH);
  } else {
    Serial.print("❌ Erro: ");
    Serial.println(fbdo.errorReason());
  }
}

void loop() {
  unsigned long currentTime = millis();

  if (currentTime - lastRead >= READ_INTERVAL) {
    lastRead = currentTime;

    // Ler sensor
    int rawValue = analogRead(SENSOR_PIN);
    int umidade = map(rawValue, DRY_VALUE, WET_VALUE, 0, 100);
    umidade = constrain(umidade, 0, 100);

    // Controle de LEDs
    digitalWrite(LED_VERDE, (umidade <= 50) ? HIGH : LOW);
    digitalWrite(LED_AZUL, (umidade < 30) ? LOW : HIGH);

    // Serial Monitor
    Serial.print("Umidade: ");
    Serial.print(umidade);
    Serial.print("% | RAW: ");
    Serial.println(rawValue);

    // ---- ENVIO PARA FIREBASE ----
    if (WiFi.status() == WL_CONNECTED) {
      
      // Enviar umidade
      if (Firebase.RTDB.setInt(&fbdo, "/sensor/umidade", umidade)) {
        Serial.println("✅ Umidade enviada!");
      } else {
        Serial.print("❌ Erro umidade: ");
        Serial.println(fbdo.errorReason());
      }

      delay(100);
      
      // Enviar valor raw
      if (Firebase.RTDB.setInt(&fbdo, "/sensor/raw", rawValue)) {
        Serial.println("✅ RAW enviado!");
      } else {
        Serial.print("❌ Erro RAW: ");
        Serial.println(fbdo.errorReason());
      }
      
      // Enviar timestamp (opcional)
      if (Firebase.RTDB.setInt(&fbdo, "/sensor/timestamp", millis()/1000)) {
        Serial.println("✅ Timestamp enviado!");
      }
      
    } else {
      Serial.println("WiFi desconectado! Reconectando...");
      WiFi.reconnect();
    }
  }
}