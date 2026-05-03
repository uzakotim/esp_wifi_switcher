#include <AFMotor.h>

AF_DCMotor motor1(1);
AF_DCMotor motor2(2);
AF_DCMotor motor3(3);
AF_DCMotor motor4(4);

// Global variables
char command = 'k';
char prev_command = 'f';
int speed = 0;

const int IRdPin = 22;
int isFalling = 1;

void setup()
{
  pinMode(IRdPin, INPUT);
  // Set initial speed of the motor & stop
  motor1.setSpeed(0);
  motor2.setSpeed(0);
  motor3.setSpeed(0);
  motor4.setSpeed(0);

  motor1.run(RELEASE);
  motor2.run(RELEASE);
  motor3.run(RELEASE);
  motor4.run(RELEASE);

  // Start serial communication
  Serial.begin(9600);
  Serial3.begin(9600);
}

void loop()
{
  isFalling = digitalRead(IRdPin);
  if (Serial3.available() > 0)
  {
    Serial.println("Received messsage!");
    String receivedString = Serial3.readStringUntil('\n');     // Read the string until newline character
    sscanf(receivedString.c_str(), "%c %d", &command, &speed); // Parse the integers from the string
  }
  else if (Serial.available() > 0)
  {
    String receivedString = Serial.readStringUntil('\n');     // Read the string until newline character
    sscanf(receivedString.c_str(), "%c %d", &command, &speed); // Parse the integers from the string
  }

  if (isFalling == HIGH)
  {
    // Serial.println("Falling");
    speed = 0;
    command = 'k';
  }
  setSpeed(speed);
  if (command != prev_command){
    executeCommand(command);
  }
  prev_command = command;
  delay(100); // delay in milliseconds: 100 microseconds
}


void setSpeed(int speed)
{
  motor1.setSpeed(speed);
  motor2.setSpeed(speed);
  motor3.setSpeed(speed);
  motor4.setSpeed(speed);
}
void executeCommand(char command)
{
  // 1 is right front
  // 3 is left front
  // 2 is right bottom
  // 4 is left bottom
  // switch statement
  switch (command)
  {
  case 'a':
    motor1.run(FORWARD);
    motor2.run(BACKWARD);
    motor3.run(FORWARD);
    motor4.run(BACKWARD);
    break;
  case 'd':
    motor1.run(BACKWARD);
    motor2.run(FORWARD);
    motor3.run(BACKWARD);
    motor4.run(FORWARD);
    break;
  case 'w':
    motor1.run(BACKWARD);
    motor2.run(BACKWARD);
    motor3.run(BACKWARD);
    motor4.run(BACKWARD);
    break;
  case 's':
    motor1.run(FORWARD);
    motor2.run(FORWARD);
    motor3.run(FORWARD);
    motor4.run(FORWARD);
    break;
  case 'q':
    motor1.run(FORWARD);
    motor2.run(FORWARD);
    motor3.run(BACKWARD);
    motor4.run(BACKWARD);
    break;
  case 'e':
    motor1.run(BACKWARD);
    motor2.run(BACKWARD);
    motor3.run(FORWARD);
    motor4.run(FORWARD);
    break;
  case 'z':
    motor1.run(BACKWARD);
    motor2.run(BACKWARD);

    motor3.run(FORWARD);
    motor4.run(FORWARD);
    break;
  case 'c':
    motor1.run(FORWARD);
    motor2.run(FORWARD);

    motor3.run(BACKWARD);  
    motor4.run(BACKWARD);
    break;
  default:
    stopMotors();
    break;
  }
}
void stopMotors()
{
  motor1.run(RELEASE);
  motor2.run(RELEASE);
  motor3.run(RELEASE);
  motor4.run(RELEASE);
}