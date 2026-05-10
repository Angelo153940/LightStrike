// Sonidos
/* Hay que añadir la librería de sonido:
   Paso 1: Sketch -> importar biblioteca -> añadir biblioteca
   Paso 2: buscar Sound, debería de aparecer Sound by The Processing Foundation.
   Paso 3: instalar la librería 
*/
import processing.sound.*;
SoundFile sSuccess;
SoundFile sFail;

// Conexión Arduino-Processing
import processing.serial.*;
final int UMBRAL_LDR = 128;
Serial serial;

// Game states
final int MENU = 0;
final int GET_READY = 1;
final int IN_GAME = 2;
final int RESULTS = 3;
int stateGame = MENU;

// Menu variables
PFont font;
String inputPlayerName = "Player";
final String title = "Light Strike";
final String playerName = "Player name:";
int playerNameLabelX, playerNameLabelY;
int playerNameFieldX, playerNameFieldY, playerNameFieldWidth, playerNameFieldHeight;
int playButtonX, playButtonY, playButtonWidth, playButtonHeight;
boolean playerNameFieldHover = false;
boolean playHover = false;
int cursorBlinkRate = 500; // ms

// Get ready variables
int readyStartTime;
int readyDuration = 10; // Segundos

// In game variables
Player player;
Figure currentFigure;
int figureStartTime;
int figureTimeLimit = 3000; // 3 segundos
boolean gameOverPending = false;
int gameOverTime = 0;
int gameOverDelay = 800; // Ponemos un delay para permitir que el jugador vea como su vida llega a cero

// Results variables
int resultsButtonX, resultsButtonY, resultsButtonWidth, resultsButtonHeight;
boolean resultsHover = false;

void setup(){
  size(800, 600);
  surface.setResizable(true); // Habilita el botón de maximizar pantalla
  font = createFont("Arial", 64);
  textFont(font);
  player = new Player();
  
  sSuccess = new SoundFile(this, "success.mp3");
  sFail = new SoundFile(this, "fail.mp3");
  
  // Conexión Arduino-Processing
  String[] sPorts = Serial.list(); // Imprimir lista de puertos disponibles
  printArray(sPorts); 
  final int portIndex = sPorts.length-1; 
  serial = new Serial(this, sPorts[portIndex], 115200); 
  serial.clear(); 
}

void draw(){
  background(0);
  if(stateGame == MENU) drawMenu();
  if(stateGame == GET_READY) drawGetReady();
  if(stateGame == IN_GAME) drawInGame();
  if(stateGame == RESULTS) drawResults();
}

void drawMenu() {
  playerNameLabelX = width/2 - 85;
  playerNameLabelY = height/2 + 50;
  playerNameFieldX = playerNameLabelX + 90;
  playerNameFieldY = playerNameLabelY - 14;
  playerNameFieldWidth = 200;
  playerNameFieldHeight = 30;
  
  // Title
  textAlign(CENTER, CENTER);
  fill(0, 255, 255);
  textSize(64);
  text(title, width/2, height/2 - 20);

  // Label
  textSize(24);
  text(playerName, playerNameLabelX, playerNameLabelY);

  // Field text
  fill(playerNameFieldHover ? 250 : 150);
  rect(playerNameFieldX, playerNameFieldY, playerNameFieldWidth, playerNameFieldHeight);

  // Input text
  textAlign(LEFT, CENTER);
  fill(0);
  text(inputPlayerName, playerNameFieldX  + 10, playerNameFieldY + playerNameFieldHeight/2);
  
  // Cursor
  if(playerNameFieldHover) {
    boolean showCursor = (millis() / cursorBlinkRate) % 2 == 0;
    if(showCursor) {
      float textWidthValue = textWidth(inputPlayerName);
      stroke(0);
      line(
        playerNameFieldX + 10 + textWidthValue,
        playerNameFieldY + 5,
        playerNameFieldX + 10 + textWidthValue,
        playerNameFieldY + playerNameFieldHeight - 5
      );
    }
  }
  
  // Button PLAY
  playButtonWidth = 120;
  playButtonHeight = 50;
  playButtonX = width - 150;
  playButtonY = height - playButtonHeight - 20;
  
  // Button hover
  playHover = mouseX > playButtonX && mouseX < playButtonX + playButtonWidth &&
              mouseY > playButtonY && mouseY < playButtonY + playButtonHeight;
  
  // Draw button
  fill(playHover ? color(0, 255, 255) : color(0, 170, 170));
  rect(playButtonX, playButtonY, playButtonWidth, playButtonHeight, 10);
  
  // Text button
  fill(0);
  textAlign(CENTER, CENTER);
  textSize(24);
  text("Play", playButtonX + playButtonWidth/2, playButtonY + playButtonHeight/2);
}

void drawGetReady() {
  background(0);

  int elapsedTime = (millis() - readyStartTime) / 1000;
  int remainingTime = readyDuration - elapsedTime;

  textAlign(CENTER, CENTER);
  fill(0, 255, 255);
  textSize(64);
  text("GET READY", width/2, height/2 - 100);

  textSize(120);
  if (remainingTime > 0) {
    text(remainingTime, width/2, height/2 + 20);
  } 
  else if (remainingTime <= 0 && remainingTime > -1) {
    textSize(100);
    text("GO!", width/2, height/2);
  } 
  else {
    stateGame = IN_GAME;
    player.setName(inputPlayerName);
    generateNewFigure();
  }
}

void drawInGame() {
  background(0);
  currentFigure.move();
  currentFigure.draw();
  player.hp.draw();
  fill(255);
  textAlign(LEFT, CENTER);
  textSize(24);
  text("Score: " + player.score, 20, 70);
  int remainingTime = figureTimeLimit - (millis() - figureStartTime);

  textAlign(CENTER, CENTER);
  fill(255);
  textSize(32);
  if(remainingTime < 0) remainingTime = 0;
  text(int(ceil(remainingTime / 1000.0)) + "s", width/2, 30);
  
  if(gameOverPending) {
    if (millis() - gameOverTime > gameOverDelay) {
      stateGame = RESULTS;
    }
  }
  else {
    if (remainingTime <= 0) {
      if(player.allLDRsActive()) success();
      else fail();
    }
  }
}

void drawResults() {
  background(0);

  // GAME OVER title
  textAlign(CENTER, CENTER);
  fill(0, 255, 255);
  textSize(64);
  text("GAME OVER", width/2, height/2 - 150);

  // Player info
  textSize(28);
  fill(255);

  textAlign(CENTER, CENTER);
  text("Player name: " + player.name, width/2, height/2 - 50);
  text("Score: " + player.score, width/2, height/2);

  // Button
  resultsButtonWidth = 160;
  resultsButtonHeight = 50;
  resultsButtonX = width - 180;
  resultsButtonY = height - resultsButtonHeight - 20;

  resultsHover = mouseX > resultsButtonX && mouseX < resultsButtonX + resultsButtonWidth &&
                 mouseY > resultsButtonY && mouseY < resultsButtonY + resultsButtonHeight;

  fill(resultsHover ? color(0, 255, 255) : color(0, 170, 170));
  rect(resultsButtonX, resultsButtonY, resultsButtonWidth, resultsButtonHeight, 10);

  fill(0);
  textSize(20);
  textAlign(CENTER, CENTER);
  text("Back to Menu", resultsButtonX + resultsButtonWidth/2, resultsButtonY + resultsButtonHeight/2);
}

void generateNewFigure() {
  currentFigure = new Figure();
  figureStartTime = millis();
}

void fail() {
  sFail.play();
  player.hp.loseHP();
  if(player.hp.currentHP <= 0) {
    gameOverPending = true;
    gameOverTime = millis();
  }
  else {
    generateNewFigure();
  }
}

void success() {
  sSuccess.play();
  player.score++;
  generateNewFigure();
}

void mouseClicked() {
  if(stateGame == MENU) {
    playerNameFieldHover = (mouseX > playerNameFieldX && mouseX < playerNameFieldX + playerNameFieldWidth &&
             mouseY > playerNameFieldY && mouseY < playerNameFieldY + playerNameFieldHeight);
    if(playHover) {
      stateGame = GET_READY;
      readyStartTime = millis();
    }
    return;
  }
  
  if(stateGame == RESULTS) {
    if(resultsHover) resetGame();
    return;
  }
}

void resetGame() {
  stateGame = MENU;
  inputPlayerName = "Player";
  playerNameFieldHover = false;
  playHover = false;
  gameOverPending = false;
  gameOverTime = 0;
  resultsHover = false;
  currentFigure = null;
  player = new Player();
}

void keyPressed() {
  final int LIMIT = 14;
  if (playerNameFieldHover) {
    if(inputPlayerName.length() < LIMIT || key == BACKSPACE) {
      if (key == BACKSPACE) {
        if (inputPlayerName.length() > 0) {
          inputPlayerName = inputPlayerName.substring(0, inputPlayerName.length() - 1);
        }
      } else if (key != CODED && key != ENTER && key != RETURN) {
        inputPlayerName += key; 
        if(inputPlayerName.length() > LIMIT) {
          inputPlayerName = inputPlayerName.substring(0, inputPlayerName.length() - 1);
        }
      }
    }
    
    if(key == ENTER && inputPlayerName.length() > 0) {
      println(inputPlayerName);
    }
  }
}

class Player {
  String name;
  HP hp;
  int score;
  int[] ldrsValues;

  Player() {
    this.name = "Player";
    this.hp = new HP(10);
    this.score = 0;
    this.ldrsValues = new int[6];
  }
  
  void setName(String name) {
    if(name == "") this.name = "Player";
    else this.name = name;
  }
  
  boolean allLDRsActive() {
    for (int i = 0; i < ldrsValues.length; i++) {
      println("LDR " + i + ": " + ldrsValues[i]);
      if (ldrsValues[i] < UMBRAL_LDR) {
        return false;
      }
    }
    return true;
  }
}

class HP {
  int maxHP;
  int currentHP;
  int x = 20;
  int y = 30;
  int w = 200;
  int h = 20;

  HP(int maxHP) {
    this.maxHP= maxHP;
    this.currentHP = maxHP;
  }
  
  void draw() {
    fill(255);
    textAlign(LEFT, CENTER);
    textSize(24);
    text("HP", x, y);
  

    fill(80);
    noStroke();
    rect(x + 40, y - 9, w, h);
  
    fill(120, 0, 0);
    rect(x + 40, y - 9, w * (float)currentHP / maxHP, h);
  }

  void loseHP() {
    if(currentHP > 0) currentHP--;
  }
}

class Figure {
  int type;
  color col;
  
  // Posición
  float x, y;
  // Velocidad de movimiento
  float vx, vy;
  // Rotación actual y velocidad de rotación
  float angle;
  float rotationSpeed;
  
  Figure() {
    type = int(random(4));
    col = color(random(220, 255), random(220, 255), random(220, 255));
    
    x = width/2;
    y = height/2;
    
    //Inicializar una velocidad aleatoria para la figura
    float speed = random(0.1, 0.8);
    float dir = random(TWO_PI);
    vx = cos(dir) * speed;
    vy = sin(dir) * speed;
    
    // Rotación inicial aleatoria y velocidad de rotación
    angle = random(TWO_PI);
    rotationSpeed = random(-0.013, 0.013);
  }

  void draw() {
    pushMatrix(); // Guarda el estado del sistema. Se usa antes de hacer transformaciones como translate.
    translate(x, y); // Traslada el origen al (0,0).
    rotate(angle);
  
    fill(col);
    noStroke();
    rectMode(CENTER); // Hace que el origen de coordenadas de todos los rectángulos esté en el centro. Se usa para luego rotarlos respecto al centro.
    if(type == 0) {  
      rect(0, 0, 200, 10); // Horizontal
    } 
    else if(type == 1) {
      rect(0, 0, 10, 200); // Vertical
    } 
    else if(type == 2){
      rotate(PI / 4);
      rect(0, 0, 200, 10); // Diagonal \
    }
    else if(type == 3){
      rotate(-PI / 4);
      rect(0, 0, 200, 10); // Diagonal /
    }
  
    popMatrix(); // Restaurar estado del sistema
    rectMode(CORNER); // Cambiar el origen de los rectágulos a su valor por defecto
  }
  void move() {
    x += vx;
    y += vy;
    angle += rotationSpeed;
    
    if (x < 0 || x > width)  vx *= -1;
    if (y < 0 || y > height) vy *= -1;
  }
}

void serialEvent(Serial p) {
  try{
    final String msg = p.readStringUntil('\n');    
    if(msg == null || msg.trim().isEmpty()) return;
    final String[] parts = msg.trim().split(",");
    if(parts.length < 6) return;
    
    for(int i = 0; i < 6; i++) {
      player.ldrsValues[i] = int(parts[i]);
    }
  }
  catch(Exception e){
    System.out.println("Error al procesar datos serie: " + e.getMessage());
  }
}
