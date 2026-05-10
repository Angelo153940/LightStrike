// LEDs
#include <Adafruit_NeoPixel.h>
#define PIN_NEO_PIXEL  2   
#define NUM_PIXELS     6  
#define DELAY_INTERVAL 200

// LDRs
#define NUM_LDR 6
#define NUM_PIN_INPUT 6
#define UMBRAL_LDR 128

Adafruit_NeoPixel neoPixel(NUM_PIXELS, PIN_NEO_PIXEL, NEO_GRB + NEO_KHZ800);
byte PIN_INPUT[] = {A0, A1, A2, A3, A4, A5};

void setup() {
  Serial.begin(115200);
  for(int i = 0; i < NUM_PIN_INPUT; i++) {
    pinMode(PIN_INPUT[i], INPUT);
  }
  neoPixel.begin(); 

  while(!Serial) {
    ; // Esperar
  }
  // Limpiamos el buffer serie de cualquier dato residual o ruido
  while(Serial.available() > 0) {
    Serial.read();
  }
  // Pequeña pausa para permitir que Processing abra el puerto y se estabilice
  delay(200);
}

void loop() {
  neoPixel.clear(); 
  
  int activeLDRs = 0;
  for(int i = 0; i < NUM_LDR; i++) {
    int val = analogRead(PIN_INPUT[i]);
    if(val >= UMBRAL_LDR)
      activeLDRs++;

    // Enviamos a Processing
    Serial.print(val);
    if(i < NUM_LDR - 1) {
      Serial.print(","); // Separador
    }
  }
  Serial.println(); // Marcamos el fin del mensaje
  delay(10); // Pausa corta para no saturar el buffer serie del PC/Processing
  
  for (int pixel = 0; pixel < activeLDRs; pixel++) { 
    neoPixel.setPixelColor(pixel, neoPixel.Color(0, 255, 0));   
  }
  
  for (int pixel = activeLDRs; pixel < NUM_PIXELS; pixel++) { 
    neoPixel.setPixelColor(pixel, neoPixel.Color(255, 0, 0)); 
  }
  
  neoPixel.show();   
}
