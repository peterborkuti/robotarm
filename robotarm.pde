
byte NSERVO = 4;
int pins[] = {5, 6, 8, 7};
int servo_min[] = {20, 20, 30, 20};
int servo_max[] = {160, 160, 90, 160};
int servo_val[] = {0, 0, 0, 0};

int SERVO_INDEX = 0;

int x = 0;
int y = 0;
int roller = 0;
boolean gripperClosed = false;

import processing.serial.*;

import cc.arduino.*;

Arduino arduino;

void settings() {
  //fullScreen();
  size(600, 800);
}

void setup() {
   String port = findPort();
   if (port == null) {
     println("Can not find port");
     exit();
   }
   else {
     arduino = new Arduino(this, port, 57600);
     for (int i = 0; i < NSERVO; i++) {
        servo_val[i] = (servo_max[i] - servo_min[i])/2 + servo_min[i];
        arduino.pinMode(pins[i], Arduino.SERVO);
        arduino.servoWrite(pins[i], servo_val[i]);
     }
   }
}



static final String findPort() {
  String[] ports = Serial.list();
  println(ports);
  println(ports.length);
 
  for (String p : ports) {
    if (match(p,"^COM") != null || match(p,"^/dev/ttyUSB") != null) return p;
  }

  return null;
}

void control_relative() {
    int servoIndex = 0;
  if (mousePressed && (mouseButton == LEFT)) {
    servoIndex = 2;
  }
  int xx = mouseX / 2;
  int yy = mouseY / 2;
  int dx = signum(xx - x);
  int dy = signum(yy - y);
  if (servoIndex == 0) dy = -dy;
  x = xx;
  y = yy;

  if (mousePressed && (mouseButton == LEFT)) {
    servoIndex = 2;
  }
  if (dx != 0) {
     servo_rel(servoIndex, dx); 
  }
  if (dy != 0) {
     servo_rel(servoIndex + 1, dy); 
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  println(e);
  servo_rel(3, (int)e);
}

void mousePressed() {
   if (mouseButton == LEFT) {
     gripperClosed = !gripperClosed;
     servo_abs(2, gripperClosed ? servo_max[2] : servo_min[2]);
   }
   if (mouseButton == RIGHT) {
     //storeValues();
   }
   if (mouseButton == CENTER) {
     //playValues();
   }
}

void control_absolute() {
  int xx = (int)map(mouseX / 2, 0, width / 2, servo_min[0], servo_max[0]);
  int yy = (int)map(mouseY / 2, height / 2, 0, servo_min[1], servo_max[1]);
  servo_abs(0, xx); 
  servo_abs(1, yy); 
}

void draw() {
  control_absolute();
}

void servo_abs(int servoNum, int x) {
  if ((x >= servo_min[servoNum]) && (x <= servo_max[servoNum])) {
    servo_val[servoNum] = x;
    arduino.servoWrite(pins[servoNum], x);
    println("Servocommand:", servoNum, x);
  }
}

void servo_rel(int servoNum, int x) {
  int s = servo_val[servoNum] + x;
  if ((s >= servo_min[servoNum]) && (s <= servo_max[servoNum])) {
    servo_val[servoNum] = s;
    arduino.servoWrite(pins[servoNum], s);
    println(servoNum, s);
  }
}

void keyPressed() {
  if (keyCode == 17) {
    SERVO_INDEX++;
    SERVO_INDEX %= 4;
  };
  
  println("Servo index:", SERVO_INDEX);
    
}

int signum(int f) {
  if (f > 0) return 1;
  if (f < 0) return -1;
  return 0;
} 