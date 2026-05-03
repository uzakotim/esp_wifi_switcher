#include <EEPROM.h>
#include <ESP8266WebServer.h>
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#define LED 2

// Default Settings (used if EEPROM is empty)
const char *DEFAULT_AP_SSID = "OMNI_ESP";
const char *DEFAULT_AP_PASS = "12345678";
const uint16_t DEFAULT_PORT = 8080;
const IPAddress DEFAULT_IP(192, 168, 1, 100);
const IPAddress DEFAULT_GW(192, 168, 1, 1);
const IPAddress DEFAULT_SUB(255, 255, 255, 0);

// Runtime Variables
String sta_ssid = "";
String sta_password = "";
String device_mac = "";
uint16_t localUdpPort;
IPAddress staticIP;
IPAddress gateway;
IPAddress subnet;

// UDP Settings
WiFiUDP udp;
char packetBuffer[255];

// Server Settings
ESP8266WebServer server(80); // HTTP server on port 80

const char *html = R"rawliteral(
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>Robot Controller</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <style>
      * {
        box-sizing: border-box;
      }
      html, body {
        margin: 0;
        padding: 0;
        background: #0a1f44;
        color: white;
        font-family: sans-serif;
        height: 100vh;
        width: 100vw;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        overflow: hidden;
      }
      h2 {
        margin-top: 20px;
        margin-bottom: 5px;
      }
      #speedValue {
        font-size: 30px;
        margin-bottom: 30px;
      }
      #speedSlider {
        -webkit-appearance: none;
        width: 70%;
        height: 5px;
        border-radius: 10px;
        background: #fff;
        outline: none;
        transition: opacity 0.2s;
        margin-bottom: 50px;
      }
      #speedSlider::-webkit-slider-thumb {
        -webkit-appearance: none;
        appearance: none;
        width: 25px;
        height: 25px;
        border-radius: 50%;
        background: orange;
        cursor: pointer;
      }
      .grid {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 20px;
        width: 100%;
        margin-top: 30px;
      }
      button {
        width: 100%;
        aspect-ratio: 1;
        font-size: 35px;
        font-weight: bold;
        border: none;
        border-radius: 12px;
        background-color: transparent;
        color: white;
        cursor: pointer;
        transition: background-color 0.2s;
      }
      button:hover {
        background-color: rgba(255, 255, 255, 0.1);
      }
      button:active {
        background-color: rgba(255, 255, 255, 0.2);
      }
      button.center {
        color: orange;
      }
    </style>
  </head>
  <body>
    <h2>SPEED</h2>
    <div id="speedValue">150</div>
    <input
      type="range"
      min="50"
      max="250"
      step="10"
      value="150"
      id="speedSlider"
    />
    <div class="grid">
      <button onclick="send('q')">&#8598;</button> <!-- ↖ -->
      <button onclick="send('w')">&#8593;</button> <!-- ↑ -->
      <button onclick="send('e')">&#8599;</button> <!-- ↗ -->

      <button onclick="send('a')">&#8592;</button> <!-- ← -->
      <button class="center" onclick="send('k')">&#9711;</button> <!-- stop -->
      <button onclick="send('d')">&#8594;</button> <!-- → -->

      <button onclick="send('z')">&#8601;</button> <!-- ↙ -->
      <button onclick="send('s')">&#8595;</button> <!-- ↓ -->
      <button onclick="send('c')">&#8600;</button> <!-- ↘ -->
    </div>

    <script>
      const slider = document.getElementById("speedSlider");
      const speedValue = document.getElementById("speedValue");

      slider.addEventListener("input", () => {
        speedValue.textContent = slider.value;
      });

      function send(cmd) {
        const speed = slider.value;
        fetch(`/cmd?dir=${cmd}&speed=${speed}`);
      }




      let lastTouchEnd = 0;
      document.addEventListener('touchend', function (event) {
        const now = new Date().getTime();
        if (now - lastTouchEnd <= 300) {
          event.preventDefault(); // Prevent double-tap
        }
        lastTouchEnd = now;
      }, false);

    </script>
  </body>
</html>
)rawliteral";
void handleRoot() { server.send(200, "text/html", html); }

void handleCommand() {
  if (server.hasArg("dir") && server.hasArg("speed")) {
    String dir = server.arg("dir");
    String speed = server.arg("speed");
    if (dir == "k") {
      speed = "0";
    }
    String message = dir + " " + speed;
    Serial.println(message);
    digitalWrite(LED, LOW);
    delay(5);
    digitalWrite(LED, HIGH);
    server.send(200, "text/plain", "OK");
  } else {
    server.send(400, "text/plain", "Missing parameters");
  }
}

// EEPROM Addresses
const int ADDR_MODE = 0;   // 1 byte
const int ADDR_SSID = 1;   // 32 bytes
const int ADDR_PASS = 33;  // 64 bytes
const int ADDR_MAC = 97;   // 18 bytes
const int ADDR_IP = 115;   // 4 bytes
const int ADDR_PORT = 119; // 2 bytes
const int ADDR_GW = 121;   // 4 bytes
const int ADDR_SUB = 125;  // 4 bytes

// --- EEPROM HELPERS ---

void writeStringToEEPROM(int addr, String data, int maxLength) {
  for (int i = 0; i < maxLength; i++) {
    EEPROM.write(addr + i, (i < data.length()) ? data[i] : 0);
  }
  EEPROM.commit();
}

String readStringFromEEPROM(int addr, int maxLength) {
  char data[maxLength + 1];
  for (int i = 0; i < maxLength; i++)
    data[i] = EEPROM.read(addr + i);
  data[maxLength] = '\0';
  return String(data);
}

void writeIPToEEPROM(int addr, IPAddress ip) {
  for (int i = 0; i < 4; i++)
    EEPROM.write(addr + i, ip[i]);
  EEPROM.commit();
}

IPAddress readIPFromEEPROM(int addr) {
  return IPAddress(EEPROM.read(addr), EEPROM.read(addr + 1),
                   EEPROM.read(addr + 2), EEPROM.read(addr + 3));
}

void writeUint16ToEEPROM(int addr, uint16_t val) {
  EEPROM.write(addr, val >> 8);
  EEPROM.write(addr + 1, val & 0xFF);
  EEPROM.commit();
}

uint16_t readUint16FromEEPROM(int addr) {
  return (EEPROM.read(addr) << 8) | EEPROM.read(addr + 1);
}

// Helper to parse IP from string
IPAddress parseIP(String ipStr) {
  IPAddress ip;
  ip.fromString(ipStr);
  return ip;
}

void setup() {
  Serial.begin(9600);
  delay(10);
  //   Serial.println();
  EEPROM.begin(512);

  // 1. Read Mode
  byte mode = EEPROM.read(ADDR_MODE);
  if (mode > 1) {
    mode = 0;
    EEPROM.write(ADDR_MODE, mode);
    EEPROM.commit();
  }

  // 2. Read WiFi Credentials
  sta_ssid = readStringFromEEPROM(ADDR_SSID, 32);
  sta_password = readStringFromEEPROM(ADDR_PASS, 64);

  // 3. Read Network Config (IP, Port, etc.)
  staticIP = readIPFromEEPROM(ADDR_IP);
  if (staticIP[0] == 0 || staticIP[0] == 255)
    staticIP = DEFAULT_IP;

  gateway = readIPFromEEPROM(ADDR_GW);
  if (gateway[0] == 0 || gateway[0] == 255)
    gateway = DEFAULT_GW;

  subnet = readIPFromEEPROM(ADDR_SUB);
  if (subnet[0] == 0 || subnet[0] == 255)
    subnet = DEFAULT_SUB;

  localUdpPort = readUint16FromEEPROM(ADDR_PORT);
  if (localUdpPort == 0 || localUdpPort == 65535)
    localUdpPort = DEFAULT_PORT;

  // 4. Handle MAC
  device_mac = WiFi.macAddress();
  if (readStringFromEEPROM(ADDR_MAC, 18) != device_mac) {
    writeStringToEEPROM(ADDR_MAC, device_mac, 18);
  }

  //   Serial.println("--- Boot Config ---");
  //   Serial.printf("MAC: %s | Mode: %s\n", device_mac.c_str(),
  // mode == 0 ? "AP" : "STA");
  //   Serial.printf("IP: %s | Port: %d\n", staticIP.toString().c_str(),
  // localUdpPort);
  //   Serial.println("-------------------");

  if (mode == 0) {
    WiFi.mode(WIFI_AP);
    WiFi.softAPConfig(staticIP, gateway, subnet);
    WiFi.softAP(DEFAULT_AP_SSID, DEFAULT_AP_PASS);
    // Serial.print("AP Active. IP: ");
    // Serial.println(WiFi.softAPIP());
  } else {
    WiFi.mode(WIFI_STA);
    WiFi.config(staticIP, gateway, subnet);
    if (sta_ssid.length() > 0) {
      WiFi.begin(sta_ssid.c_str(), sta_password.c_str());
      //   Serial.print("STA Connecting to " + sta_ssid);
      int retries = 0;
      while (WiFi.status() != WL_CONNECTED && retries++ < 20) {
        delay(500);
        // Serial.print(".");
      }
      if (WiFi.status() == WL_CONNECTED) {
        // Serial.println("\nConnected! IP: " + WiFi.localIP().toString());
      } else {
        // Serial.println("\nConnection Failed.");
        EEPROM.write(ADDR_MODE, 0);
        EEPROM.commit();
        // Serial.println("\nSwitched to AP mode.");
        ESP.restart();
      }
    }
  }

  udp.begin(localUdpPort);
  server.on("/", handleRoot);
  server.on("/cmd", handleCommand);
  server.begin();
  pinMode(LED, OUTPUT); // Ensure LED is initialized
  //   Serial.printf("UDP Listening on %d\n", localUdpPort);
}

void loop() {
  server.handleClient();

  // UDP
  int packetSize = udp.parsePacket();
  if (packetSize) {
    int len = udp.read(packetBuffer, 255);
    if (len > 0)
      packetBuffer[len] = 0;
    String message = String(packetBuffer);
    if (message == "app:reboot") {
      // Serial.println("Rebooting...");
      ESP.restart();
    } else if (message.startsWith("app:mode:")) {
      EEPROM.write(ADDR_MODE, message.substring(9).toInt());
      EEPROM.commit();
      udp.beginPacket(udp.remoteIP(), udp.remotePort());
      udp.write("Mode updated. Reboot needed.\n");
      udp.endPacket();
    }

    else if (message.startsWith("app:set:ssid:")) {
      writeStringToEEPROM(ADDR_SSID, message.substring(13), 32);
      udp.beginPacket(udp.remoteIP(), udp.remotePort());
      udp.write("SSID saved.\n");
      udp.endPacket();
    }

    else if (message.startsWith("app:set:pass:")) {
      writeStringToEEPROM(ADDR_PASS, message.substring(13), 64);
      udp.beginPacket(udp.remoteIP(), udp.remotePort());
      udp.write("Password saved.\n");
      udp.endPacket();
    }

    else if (message.startsWith("app:set:ip:")) {
      writeIPToEEPROM(ADDR_IP, parseIP(message.substring(11)));
      udp.beginPacket(udp.remoteIP(), udp.remotePort());
      udp.write("IP saved.\n");
      udp.endPacket();
    }

    else if (message.startsWith("app:set:port:")) {
      writeUint16ToEEPROM(ADDR_PORT, message.substring(13).toInt());
      udp.beginPacket(udp.remoteIP(), udp.remotePort());
      udp.write("Port saved.\n");
      udp.endPacket();
    }

    else if (message.startsWith("app:set:gw:")) {
      writeIPToEEPROM(ADDR_GW, parseIP(message.substring(11)));
      udp.beginPacket(udp.remoteIP(), udp.remotePort());
      udp.write("Gateway saved.\n");
      udp.endPacket();
    }

    else if (message == "app:get:status") {
      udp.beginPacket(udp.remoteIP(), udp.remotePort());
      // localIP is unset when in AP mode, so use softAPIP
      IPAddress ip = WiFi.localIP();
      if (ip[0] == 0)
        ip = WiFi.softAPIP();
      String response = "MAC:" + device_mac + " | IP:" + ip.toString() +
                        " | Port:" + String(localUdpPort) +
                        " | Mode:" + String(EEPROM.read(ADDR_MODE));
      udp.write(response.c_str());
      udp.endPacket();
    } else {
      // actual motor command
      Serial.println(message);
    }
    digitalWrite(LED, LOW);
    delay(5);
    digitalWrite(LED, HIGH);
  }
}
