#include <ESP8266WiFi.h>
#include <Firebase_ESP_Client.h>

// ==== CONFIGURAÇÃO WI-FI ====
#define WIFI_SSID "Casa das Primas"
#define WIFI_PASSWORD "computaria"

// ==== CONFIGURAÇÃO FIREBASE ====
#define DATABASE_SECRET "jOGaYzN1AzVS39z9QX22nt7Mm9XkEPmNZ7tqs1jG"
#define DATABASE_URL "umidade-solo-default-rtdb.firebaseio.com"

FirebaseData fbdoStream; // Objeto exclusivo para o Stream instantâneo
FirebaseData fbdoData;   // Objeto para envio dos dados do sensor
FirebaseConfig config;
FirebaseAuth auth;

// ==== PINOS ====
const int SENSOR_PIN = A0;
const int LED_VERDE  = 5;
const int LED_AZUL   = 2;
const int RELE       = 14; // GPIO14 = D5 no NodeMCU

// ==== CALIBRAÇÃO SENSOR ====
const int DRY_VALUE = 1024;
const int WET_VALUE = 422;

// ==== VARIÁVEIS ====
unsigned long lastRead = 0;
const int READ_INTERVAL = 10000; // Envio dos sensores continua a cada 10s

// Função que roda INSTANTANEAMENTE quando o Firebase muda de valor
void streamCallback(FirebaseStream data) {
  Serial.printf("Stream disparado: %s %s %s\n", data.streamPath().c_str(), data.dataPath().c_str(), data.dataType().c_str());
  
  if (data.dataType() == "boolean") {
    bool bombaLigada = data.boolData();
    
    if (bombaLigada) {
      Serial.println("🌊 Comando Instantâneo: LIGAR BOMBA");
      digitalWrite(RELE, LOW);  // Liga o relé (Lógica Invertida)
    } else {
      Serial.println("🛑 Comando Instantâneo: DESLIGAR BOMBA");
      digitalWrite(RELE, HIGH); // Desliga o relé (Lógica Invertida)
    }
  }
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) Serial.println("Stream timeout, reconectando...");
}

void setup() {
  Serial.begin(115200);
  
  pinMode(LED_VERDE, OUTPUT);
  pinMode(LED_AZUL, OUTPUT);
  pinMode(RELE, OUTPUT);
  
  // Garante bomba iniciada como DESLIGADA
  digitalWrite(RELE, HIGH); 
  
  digitalWrite(LED_VERDE, LOW);
  digitalWrite(LED_AZUL, HIGH);
  
  Serial.println("Iniciando ESP8266...");
  
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

  config.database_url = DATABASE_URL;
  config.signer.tokens.legacy_token = DATABASE_SECRET;
  
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  delay(1000);
  
  // Teste inicial de escrita
  Firebase.RTDB.setInt(&fbdoData, "/status", 1);

  // ---- ATIVAÇÃO DO STREAM INSTANTÂNEO ----
  // Monitora especificamente o caminho "/bomba/on"
  if (!Firebase.RTDB.beginStream(&fbdoStream, "/bomba/on")) {
    Serial.printf("Erro no Stream: %s\n", fbdoStream.errorReason().c_str());
  } else {
    Serial.println("🔥 Monitoramento instantâneo da bomba ATIVADO!");
  }
  
  // Define a função que será chamada quando o valor alterar
  Firebase.RTDB.setStreamCallback(&fbdoStream, streamCallback, streamTimeoutCallback);
}

void loop() {
  unsigned long currentTime = millis();
  
  // O envio dos dados do sensor continua ordenado a cada 10 segundos
  if (currentTime - lastRead >= READ_INTERVAL) {
    lastRead = currentTime;
    
    int rawValue = analogRead(SENSOR_PIN);
    int umidade = map(rawValue, DRY_VALUE, WET_VALUE, 0, 100);
    umidade = constrain(umidade, 0, 100);
    
    digitalWrite(LED_VERDE, (umidade <= 50) ? HIGH : LOW);
    digitalWrite(LED_AZUL, (umidade < 30) ? LOW : HIGH);
    
    Serial.printf("Umidade: %d%% | RAW: %d\n", umidade, rawValue);
    
    if (WiFi.status() == WL_CONNECTED) {
      Firebase.RTDB.setInt(&fbdoData, "/sensor/umidade", umidade);
      delay(50);
      Firebase.RTDB.setInt(&fbdoData, "/sensor/raw", rawValue);
      delay(50);
      Firebase.RTDB.setInt(&fbdoData, "/sensor/timestamp", millis()/1000);
    } else {
      Serial.println("WiFi desconectado! Reconectando...");
      WiFi.reconnect();
    }
  }
}