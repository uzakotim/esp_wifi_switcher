// Most ESP32 boards have the built-in LED on GPIO 2
#define LED_PIN 2

void setup() {
  // Initialize the LED pin as an output
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  digitalWrite(LED_PIN, HIGH);  // Turn the LED on
  delay(1000);                  // Wait for 1 second
  digitalWrite(LED_PIN, LOW);   // Turn the LED off
  delay(1000);                  // Wait for 1 second
}
