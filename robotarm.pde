
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
boolean recording = false;
int recordingNumber = 0;

import processing.serial.*;

import cc.arduino.*;

import java.util.List;

List<List<Integer>> recordingValues;

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
     resetArm();
   }
}

void resetArm() {
  for (int i = 0; i < NSERVO; i++) {
      servo_val[i] = (servo_max[i] - servo_min[i])/2 + servo_min[i];
      arduino.pinMode(pins[i], Arduino.SERVO);
      arduino.servoWrite(pins[i], servo_val[i]);
   }
}

static final String findPort() {
  String[] ports = Serial.list();
  println(ports);
  println(ports.length);
 
  for (String p : ports) {
    if (match(p,"^COM") != null || match(p,"^/dev/ttyUSB") != null || match(p,"^/dev/tty.wchusbserial1410") != null) return p;
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
     
   }
}

void control_absolute() {
  int xx = (int)map(mouseX / 2, 0, width / 2, servo_min[0], servo_max[0]);
  int yy = (int)map(mouseY / 2, height / 2, 0, servo_min[1], servo_max[1]);
  servo_abs(0, xx); 
  servo_abs(1, yy); 
}

void drawLabel() {
  if (recording) {
    fill(204, 102, 0);
    text("Recording #" + recordingNumber, 20, 75);
  } else {
    fill(204, 102, 0);
    text("#" + recordingNumber, 20, 75);
  }
}

void draw() {
  background(200, 200, 200);
  
  control_absolute();
  
  drawLabel();
}

void servo_abs(int servoNum, int x) {
  if ((x >= servo_min[servoNum]) && (x <= servo_max[servoNum]) && servo_val[servoNum] != x) {    
    servo_val[servoNum] = x;
    arduino.servoWrite(pins[servoNum], x);
    println("Servocommand:", servoNum, x);
    
    if (recording) {
      addRecordingValue();
    }
  }
}

void servo_rel(int servoNum, int x) {
  int s = servo_val[servoNum] + x;
  if ((s >= servo_min[servoNum]) && (s <= servo_max[servoNum]) && servo_val[servoNum] != x) {
    servo_val[servoNum] = s;
    arduino.servoWrite(pins[servoNum], s);
    println(servoNum, s);
    
    if (recording) {
      addRecordingValue();
    }
  }
}

void addRecordingValue() {
  if (recordingValues == null) {
    recordingValues = new ArrayList();
  }
  
  List<Integer> list = new ArrayList<Integer>();
  
  for (int value : servo_val) {
    list.add(value);
  }
  
  recordingValues.add(list);
}

void keyPressed() {
  if (keyCode == 17) {
    SERVO_INDEX++;
    SERVO_INDEX %= 4;
  };
  
  println("Servo index:", SERVO_INDEX);
    
  if (key == 'r' || key == 'R') {
    recording = !recording;
    
    if (!recording) {
      saveFile(recordingNumber);
    }
    
    drawLabel();
  }  
  
  if (keyCode >= '0' && keyCode <= '9') {
    recordingNumber = keyCode - 48;
  }
  
  if (key == 'p' || key == 'P') {
    playRecording();
  }
  
  if (key == 'b' || key == 'B') {
    playRecordingBackwards();
  }
}

int signum(int f) {
  if (f > 0) return 1;
  if (f < 0) return -1;
  return 0;
} 

void saveFile(int number) {
  String[] values = new String[recordingValues.size()];
  
  int i = 0;
  for (List<Integer> positions : recordingValues) {
    values[i++] = toCsv(positions);
  }
  
  saveStrings("recording" + number + ".txt", values);
  
  recordingValues = null;
}

private static final String SEPARATOR = ",";

String toCsv(List<Integer> list) {
  StringBuilder csvBuilder = new StringBuilder();
  for(Integer i : list){
    csvBuilder.append(i);
    csvBuilder.append(SEPARATOR);
  }
  String csv = csvBuilder.toString();
  return csv.substring(0, csv.length() - SEPARATOR.length());
}

void playRecording() {
  String[] lines = loadStrings("recording" + recordingNumber +  ".txt");
  
  int prevGripper = -1;
  
  for (int i = 0; i < lines.length; i++) {
    drawLabel();
    
    String[] line = lines[i].split(",");
    servo_abs(0, Integer.valueOf(line[0]));
    servo_abs(1, Integer.valueOf(line[1]));
    servo_abs(2, Integer.valueOf(line[2]));
    servo_abs(3, Integer.valueOf(line[3]));
    delay(10);
    
    if (prevGripper != -1 && Integer.valueOf(line[2]) != prevGripper) {
      delay(200); // otherwise grip open/close would be too fast if there are no movements in between
    }
    
    prevGripper = Integer.valueOf(line[2]);
  }
}

void playRecordingBackwards() {
  String[] lines = loadStrings("recording" + recordingNumber +  ".txt");
  
  int prevGripper = -1;
  
  for (int i = lines.length - 1; i >= 0 ; i--) {
    String[] line = lines[i].split(",");
    servo_abs(0, Integer.valueOf(line[0]));
    servo_abs(1, Integer.valueOf(line[1]));
    servo_abs(2, Integer.valueOf(line[2]));
    servo_abs(3, Integer.valueOf(line[3]));
    delay(10);
    
    if (prevGripper != -1 && Integer.valueOf(line[2]) != prevGripper) {
      delay(200); // otherwise grip open/close would be too fast if there are no movements in between
    }
    
    prevGripper = Integer.valueOf(line[2]);
  }
}
