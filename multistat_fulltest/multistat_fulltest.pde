#define DATAOUT 12
#define DATAIN 13
#define SPICLOCK  11
#define SLAVESELECTD 10//DAC
#define SLAVESELECTP 7//Pot
#define CNVST 2
#define EOC 3

//DAC Commands
byte dacInit = B00010000;
byte dacUpdateMain1 = B11101111;
byte dacUpdateMain2 = B11110000;

//DAC locations
byte dac0 = B00100000;
byte dac1 = B00110000;
byte dac2 = B01000000;
byte dac3 = B01010000;
byte dac4 = B01100000;
byte dac5 = B01110000;
byte dac6 = B10000000;
byte dacByte; //for the function to use

byte potInit = B101;
byte potData = B10000000;
byte pot1 = B000;
byte pot2 = B001;
byte pot3 = B010;
byte pot4 = B011;
byte pot5 = B100;
byte pot6 = B101;

//Resistance (step)
int res[7];    //res[0] isn't anything
int adc[7];    //out of pot (0 is WE)
int dac[7];    //out of dac
int dacset[7];
int alladcs[16];
//int outvolt=4096;
boolean charging = true;
int sign=1;
int mode = 0;  //0 ocv, 1 pot, 2 galv, 3 manual
boolean pMode = 0; //saved variable to remember if the last mode was pstat or not
int lastData[10]; //previous error values for use in pstat's PID algorithm
int resmove;
boolean rtest;

//Serial Comm Stuff
int incomingByte;
boolean setVoltage;
char serInString[100];
char sendString[99];
char holdString[6];
int output;
//boolean whocares = false;
//boolean positive = false;
boolean gstat = false;
boolean pstat = false;
//boolean cv = false;
int setting[]={0,0,0,0,0,0,0}; 

int throttle = 100;
int countto = 0;

void setup()
{
  millis();
  for(int i=0;i<7;i++)
  {
    dacset[i]=0;
    res[i]=0;
  }
  //initialize serial comm and pins
  Serial.begin(57600);
  Serial.println("Hi Barry!");
  delay(500);

  //initialize pins, disable everything
  pinMode(DATAOUT,OUTPUT);
  pinMode(SPICLOCK,OUTPUT);
  pinMode(SLAVESELECTD,OUTPUT);
  pinMode(SLAVESELECTP,OUTPUT);
  pinMode(CNVST,OUTPUT);
  pinMode(DATAIN,INPUT);
  pinMode(EOC,INPUT);
  digitalWrite(SLAVESELECTD,HIGH);
  digitalWrite(SLAVESELECTP,HIGH);
  digitalWrite(CNVST,HIGH);

  //MAX-chip setup register
  digitalWrite(SLAVESELECTD,LOW);
  sendByte(B01000000,HIGH);
  digitalWrite(SLAVESELECTD,HIGH);
  delay(100);
  Serial.println("MAX setup");

  //turn on the DACs
  //counterOn();
  delay(100);
  //workGround();
  delay(100);

  //ADC Conversion Register
  digitalWrite(SLAVESELECTD,LOW);
  sendByte(B11111000,HIGH);
  digitalWrite(SLAVESELECTD,HIGH);
  delay(100);
  Serial.println("ADC conversion");

  //ADC Averaging Register
  digitalWrite(SLAVESELECTD,LOW);
  sendByte(B00110000,HIGH);
  digitalWrite(SLAVESELECTD,HIGH);
  delay(100);
  Serial.println("ADC averaging");

  digitalWrite(SLAVESELECTD,LOW);
  sendByte(dacInit,HIGH);      //set dacs to 0 to start
  sendByte(B10100000,HIGH);
  sendByte(B00000000,HIGH);
  digitalWrite(SLAVESELECTD,HIGH);
}


void loop()
{
  //read the serial port and create a string out of what you read
  readSerialString(serInString);
  if( isStringEmpty(serInString) == false) { //this check is optional

    //delay(500);
    holdString[0] = serInString[0];
    holdString[1] = serInString[1];
    holdString[2] = serInString[2];
    holdString[3] = serInString[3];
    holdString[4] = serInString[4];
    holdString[5] = serInString[5];
    
    //try to print out collected information. it will do it only if there actually is some info.
    if (serInString[0] == 100 || serInString[0] == 45 || serInString[0] == 112 || serInString[0]==107 ||
        serInString[0]==48 || serInString[0]==49 || serInString[0]==50 || serInString[0]==51 || serInString[0]==103 ||
        serInString[0]==52 || serInString[0]==53 || serInString[0]==54 || serInString[0]==114 || serInString[0]==82)
    {
      //if (serInString[0] == 43) positive = true;
      //else if (serInString[0] == 45) positive = false;
      pstat = false;
      gstat = false;
      //if (serInString[0] != 114) gstat = false;
      //dactest = false;
      rtest = false;
      charging = true;
      for (int i = 0; i < 98; i++)
      {
        sendString [i] = serInString[i+1];
      }
      int out =  stringToNumber(sendString,4);
      
      if(serInString[0]!=100) pMode=false;
      
      switch (serInString[0])
      {
        case 48:  mode=0;        //0
                  setting[0]=out;
                  write_dac(0,out);
                  if (out==0) workGround();
                  else workOn();
                  break;
        case 49:  mode=1;        //1
                  //mode=3;
                  pstat=true;
                  setting[1]=out;
                  counterOn();
                  write_pot(1,255);
                  write_dac(1,out);
                  break;
        case 50:  mode=1;        //2
                  pstat=true;
                  setting[2]=out;
                  counterOn();
                  write_pot(2,255);
                  write_dac(2,out);
                  break;
        case 51:  mode=1;        //3
                  pstat=true;
                  setting[3]=out;
                  counterOn();
                  write_pot(3,255);
                  write_dac(3,out);
                  break;
        case 52:  mode=1;        //4
                  pstat=true;
                  setting[4]=out;
                  counterOn();
                  write_pot(4,255);
                  write_dac(4,out);
                  break;
        case 53:  mode=1;        //5
                  pstat=true;
                  setting[5]=out;
                  counterOn();
                  write_pot(5,255);
                  write_dac(5,out);
                  break;
        case 54:  mode=1;        //6
                  pstat=true;
                  setting[6]=out;
                  counterOn();
                  write_pot(6,255);
                  write_dac(6,out);
                  break;
        case 100: mode=3;        //d
                  write_dacs(out); 
                  break;
        case 45:                 //-      //incomplete
                  //counterFloat();
                  write_dacs(0);
                  dac_update();//for good luck
                  out=0;
                  break;
        case 112: mode=1;        //p
                  pstat=true;
                  counterOn();
                  setting[1] = out;
                  setting[2] = out;
                  setting[3] = out;
                  setting[4] = out;
                  setting[5] = out;
                  setting[6] = out;
                  write_pots(255);
                  write_dacs(out);
                  break;
        case 103: mode=2;      //g
                  gstat=true;
                  counterOn();
                  if(out>5000)
                  {
                    sign=-1;
                    setting[1] = out-5000;
                    setting[2] = out-5000;
                    setting[3] = out-5000;
                    setting[4] = out-5000;
                    setting[5] = out-5000;
                    setting[6] = out-5000;
                    write_dacs(out-5000);
                  }else{
                    sign=1;
                    setting[1] = out;
                    setting[2] = out;
                    setting[3] = out;
                    setting[4] = out;
                    setting[5] = out;
                    setting[6] = out;
                    write_dacs(out);
                  }
                  break;
        case 107: mode = 0;    //k
                  counterGround();
                  write_dacs(0);
                  break;
        case 114: {int potnum = floor(out/1000);  //r
                  if(potnum==0) write_pots(out);
                  else write_pot(potnum,out-(potnum*1000));}
                  break;
        case 82:  rtest=true;  //R
                  counterOn();
                  write_dacs(4095);
                  dac_update();
                  break;
        default:  break;
        //still need to add r, g (above, too)
      }
      dac_update();
      flushSerialString(serInString);
    }
  }
  //Work Section
  getADC(alladcs);
  adc[0]=alladcs[0];
  adc[1]=alladcs[1];
  adc[2]=alladcs[2];
  adc[3]=alladcs[3];
  adc[4]=alladcs[4];
  adc[5]=alladcs[5];
  adc[6]=alladcs[6];
  dac[1]=alladcs[7];
  dac[2]=alladcs[8];
  dac[3]=alladcs[9];
  dac[4]=alladcs[10];
  dac[5]=alladcs[11];
  dac[6]=alladcs[12];
  //dac[6]=alladcs[13];
  sendout();
  if (pstat) potentiostat();
  if (gstat) galvanostat();
  holdGround();
  //if (cv)
  //if (dactest) testdac();
  // if (rtest) testr();
  delay(throttle);
}

void sendout()
{
  //Serial.print("ST");
  Serial.print(millis());
  //DAC Setting 0-6
  Serial.print("|");
  for(int i=0;i<7;i++)
  {
    Serial.print(dacset[i]);
    Serial.print(",");
  }
  //DAC Reading 0-6
  Serial.print("|");
  for(int i=0;i<7;i++)
  {
    Serial.print(dac[i]);
    Serial.print(",");
  }
  //ADC Reading 0-6
  Serial.print("|");
  for(int i=0;i<7;i++)
  {
    Serial.print(adc[i]);
    Serial.print(",");
  }
  //Pot Setting 1-6
  Serial.print("|");
  for(int i=1;i<7;i++)
  {
    Serial.print(res[i]);
    Serial.print(",");
  }
  //mode
  //Main Setting
  //Working DAC Setting
  //Working Reading
  Serial.println("");
  
}

void holdGround()
{
  //try to maintain ground's set potential
  if (setting[0]==0) workGround();
  else workOn();
  int move = int(0.9*(setting[0]-adc[0]));
  dacset[0] = dacset[0]+move;
  if(dacset[0]<0) dacset[0]=0;
  if(dacset[0]>4090) dacset[0]=4090;
  write_dac(0,dacset[0]);
}

void potentiostat()
{
  for(int j=1;j<7;j++)
    {
      float diff_adc_ref = adc[j] - adc[0];
      float err = setting[j] - diff_adc_ref;  
      int move = 0;
      //for (int i=2;i<=11;i++) lastData[i-1]=lastData[i];
      //lastData[10] = err;
      //PID
      float p = 1*err;  //4/1.7
      //float i = 10*getIntegral(); //8/2
      //float d = 3.5*(lastData[10]-lastData[9]); //8/8
      //move = int(p+i+d);
      move = int(p);
      dacset[j] = dacset[j] + move;
      if (dacset[j]>4090)
      {
        res[j] = res[j] - 2;
        dacset[j] = 4000;
        //res = res-res/6;
        if (res[j]<1) res[j]=1;
      }else if (dacset[j]<0){
        res[j] = res[j]-2;
        dacset[j] = 1;
        //res = res - res/6;
        if (res[j]<1) res[j]=1;
      }
      if (abs(dacset[j]-diff_adc_ref)>100){
        res[j] = res[j] + 2;
        if (res[j]>255) res[j] = 255;
      }
      write_pot(j,res[j]);
      write_dac(j,dacset[j]);
    }
    dac_update();
}

/*void galvanostat()
{
  float move;
  float diff;
  float err;
  float p;
  float i;
  float d;
  float Kp = 1;
  float Ki = 1;
  float Kd = 1;
   for(int j=1;j<7;j++)
   {
     if(charging)
     {
       diff=dac[j]-adc[j];
       if(diff>0) err = setting-diff;
       else err = setting;
       p = Kp*err;
       move = (p);
     }else{
       diff=adc[j]-dac[j];
       if(diff>0) err = setting-diff;
       else err = setting;
       p = Kp*err;
       move = (p);
     }
     if(dacset[j]+move>4090) dacset[j]=4090;
     else dacset[j]=dacset[j]+move;
     write_dac(j,dacset[j]);
   }
   dac_update();
}*/

void galvanostat()
{
  int move;
  int diff;
   for(int j=1;j<7;j++)
   {
      if (sign>0) diff = dac[j]-adc[j];
      else diff = adc[j]-dac[j];
      
      move = gainer(diff,setting[j],dacset[j]);
      if (sign>0) dacset[j] = dacset[j]-move;
      else dacset[j] = dacset[j]+move;
      dacset[j] = constrain(dacset[j],0,4000);
      write_dac(j,dacset[j]);
   }
}
int gainer(int whatitis, int whatitshouldbe, int huh)
{
  int move;
  int err = whatitis-whatitshouldbe;
  for (int i=2;i<=11;i++) lastData[i-1]=lastData[i];
  lastData[10] = err;
  int p = 0.5*err;
  int i = 0*err;
  int d = 0*err;
  move = (p+i+d);
  //if (sign>0) move = constrain(huh-move,0,4000)+huh;
  //*else*/ move = constrain(huh+move,0,4000)-huh;
  return move;
}
     

void testr()
{
  for(int i=1;i<7;i++)
  {
    res[i] = res[i]+1;
    if(res[i]>255) res[i]=0;
    write_pot(i,res[i]);
  }
}

void write_dac(int dac, int value)
{  
  switch(dac)
  {
  case 0: 
    dacByte = dac0;
    break;
  case 1: 
    dacByte = dac1;
    break;
  case 2: 
    dacByte = dac2;
    break;
  case 3: 
    dacByte = dac3;
    break;
  case 4: 
    dacByte = dac4;
    break;
  case 5: 
    dacByte = dac5;
    break;
  case 6: 
    dacByte = dac6;
    break;
  default: 
    return;
  }
  dacset[dac]=value;
  digitalWrite(SLAVESELECTD,LOW);
  sendByte(dacInit,HIGH);
  sendByte(dacByte+(value>>8),HIGH);
  sendByte(value-((value>>8)*256),HIGH);
  digitalWrite(SLAVESELECTD,HIGH);
  delayMicroseconds(10);
}

void write_dacs(int value)
{
  for(int i=1;i<7;i++)
  {
    write_dac(i,value);
  }
}

void dac_update()
{
  digitalWrite(SLAVESELECTD,LOW);
  sendByte(dacInit,HIGH);
  sendByte(dacUpdateMain1,HIGH);
  sendByte(dacUpdateMain2,HIGH);
  digitalWrite(SLAVESELECTD,HIGH);
}

void write_pots(int value)
{
  for (int i=1;i<7;i++)
  {
    write_pot(i,value);
  }
}

void write_pot(int pot,int value)
{
  res[pot] = value;
  value = 255-value;
  byte potnum;
  switch(pot)
  {
    case 1: potnum = pot1;
            break;
    case 2: potnum = pot2;
            break;
    case 3: potnum = pot3;
            break;
    case 4: potnum = pot4;
            break;
    case 5: potnum = pot5;
            break;
    case 6: potnum = pot6;
            break;
  }
  digitalWrite(SLAVESELECTP,LOW);
  sendBit(HIGH && (potnum & B100),LOW);
  sendBit(HIGH && (potnum & B010),LOW);
  sendBit(HIGH && (potnum & B001),LOW);
  sendByte(value,LOW);
  digitalWrite(SLAVESELECTP,HIGH);
  delayMicroseconds(10);
} 
  
byte sendBit(boolean state, boolean clk)
{
  // clk indicates on what edge data is sent
  digitalWrite(SPICLOCK,clk);
  //delayMicroseconds(10);
  digitalWrite(DATAOUT,state);
  digitalWrite(SPICLOCK,!clk);
  delayMicroseconds(1);
}

byte sendByte(int val,boolean clk)
{
  delayMicroseconds(10);
  //data
  byte value = byte(val);
  sendBit(HIGH && (value & B10000000),clk);
  sendBit(HIGH && (value & B01000000),clk);
  sendBit(HIGH && (value & B00100000),clk);
  sendBit(HIGH && (value & B00010000),clk);
  sendBit(HIGH && (value & B00001000),clk);
  sendBit(HIGH && (value & B00000100),clk);
  sendBit(HIGH && (value & B00000010),clk);
  sendBit(HIGH && (value & B00000001),clk);
}

int getADC(int results[])
{
  int result;

  digitalWrite(SLAVESELECTD,LOW);
  sendByte(B11111000,HIGH);
  digitalWrite(SLAVESELECTD,HIGH);

  digitalWrite(SPICLOCK,HIGH); //needs to start high 
  digitalWrite(CNVST,LOW); //start the conversion
  //delayMicroseconds(1);
  digitalWrite(CNVST,HIGH);

  countto = 0;
  while (true)
  {
    //Serial.println("haisdf");
    delay(1);
    if(!digitalRead(EOC)) break;
    if (countto>20)
    {
      digitalWrite(SLAVESELECTD,LOW);
      sendByte(B11111000,HIGH);
      digitalWrite(SLAVESELECTD,HIGH);
    
      digitalWrite(SPICLOCK,HIGH); //needs to start high 
      digitalWrite(CNVST,LOW); //start the conversion
      delayMicroseconds(1);
      digitalWrite(CNVST,HIGH);
      countto=0;
    }
    else countto++;
  } 

  for(int i=0;i<16;i++)
  {
    result = 0; 

    digitalWrite(SLAVESELECTD,LOW);
    for (int i=0;i<8;i++)
    {
      digitalWrite(SPICLOCK,LOW);
      if(digitalRead(DATAIN)) result = result*2 + 1;
      else result = result*2;
      digitalWrite(SPICLOCK,HIGH);
    }
    digitalWrite(SLAVESELECTD,HIGH);
    digitalWrite(SLAVESELECTD,LOW);
    for (int i=0;i<8;i++)
    {
      digitalWrite(SPICLOCK,LOW);
      if(digitalRead(DATAIN)) result = result*2 + 1;
      else result = result*2;
      digitalWrite(SPICLOCK,HIGH);
      //Serial.println(result);
    }
    digitalWrite(SLAVESELECTD,HIGH);
    results[i]=result;
  }
}

void workGround()
{
  digitalWrite(SLAVESELECTD,LOW);
  sendByte(dacInit,HIGH);
  sendByte(B11110000,HIGH);
  sendByte(B00011000,HIGH);
  digitalWrite(SLAVESELECTD,HIGH);
}

void workOn()
{
  digitalWrite(SLAVESELECTD,LOW);
  sendByte(dacInit,HIGH);
  sendByte(B11110000,HIGH);
  sendByte(B00010010,HIGH);
  digitalWrite(SLAVESELECTD,HIGH); 
}

void counterGround()
{
  digitalWrite(SLAVESELECTD,LOW);
  sendByte(dacInit,HIGH);
  sendByte(B11111111,HIGH);
  sendByte(B11101000,HIGH);
  digitalWrite(SLAVESELECTD,HIGH);
}

void counterOn()
{
  digitalWrite(SLAVESELECTD,LOW);
  sendByte(dacInit,HIGH);
  sendByte(B11110111,HIGH);
  sendByte(B11100010,HIGH);
  digitalWrite(SLAVESELECTD,HIGH);
  delayMicroseconds(10);
}

void counter()
{
  digitalWrite(SLAVESELECTD,LOW);
  sendByte(dacInit,HIGH);
  sendByte(B11110111,HIGH);
  sendByte(B11100100,HIGH);
  digitalWrite(SLAVESELECTD,HIGH);
}

boolean isStringEmpty(char *strArray) {
  if (strArray[0] == 0) {
    return true;
  }
  else {
    return false;
  }
}

//Flush String
void flushSerialString(char *strArray) {
  int i=0;
  if (strArray[i] != 0) {
    while(strArray[i] != 0) {
      strArray[i] = 0;                  // optional: flush the content
      i++;
    }
  }
}

//Read String In
void readSerialString (char *strArray) {
  int i = 0;
  if(Serial.available()) {
    Serial.println("    ");  //optional: for confirmation
    while (Serial.available()){
      strArray[i] = Serial.read();
      i++;

    }
  }
}

int stringToNumber(char thisString[], int length) {
  int thisChar = 0;
  int value = 0;

  for (thisChar = length-1; thisChar >=0; thisChar--) {
    char thisByte = thisString[thisChar] - 48;
    value = value + powerOfTen(thisByte, (length-1)-thisChar);
  }
  return value;
}

/*
 This method takes a number between 0 and 9,
 and multiplies it by ten raised to a second number.
 */

long powerOfTen(char digit, int power) {
  long val = 1;
  if (power == 0) {
    return digit;
  }
  else {
    for (int i = power; i >=1 ; i--) {
      val = 10 * val;
    }
    return digit * val;
  }
}


