//takes in mouse input as a knock
  
import processing.sound.*;
SinOsc soundEffect;
float volume=0;
color bg = 0;
ArrayList<Ripple> rippleknocks = new ArrayList<Ripple>();//large visual effect circles
ArrayList<Tally> tallycount = new ArrayList<Tally>();//little dots at the top that keep track of whats going on

FloatList knockTimes;// records the actual millis times that the knock was recieved (cleared each time re-entry)
FloatList knockIntervals;// calculates from knockTimes the time-elapsed (intervals) in millis between each knock (cleared each timwe)
FloatList allIntervalRatios;//store how all the intervals compare to every other interval eventually used to calculate Standard Deviation over all the entries..



int totalknocking=0;//# of total knocks ever inputted
int howManyTimesInput=0; //how many times has the user repeated their pattern input?

void setup(){
  knockTimes = new FloatList();
  knockIntervals = new FloatList();
  allIntervalRatios = new FloatList();
  size(800,800);
  
  //create the sine oscillator for sound effects
  soundEffect = new SinOsc(this);
  soundEffect.freq(100);
  soundEffect.play();
}
void draw(){
  background(bg);
  audio();//creates knocking sound effect
  visualEffects();//creates ripples and tally marks
}
void mousePressed(){//a mouse click is a knock
  knockJustHappened();
}
void keyPressed(){//when key is pressed the program knows the knocking pattern is done. 
//the rhythm information is then added to a JSON array and is exported as a JSON file to another program when the key 'esc' is pressed

  calculateRhythm();//calculates exact time, intervals between each knock, the ratios of intervals to each other, and the standard deviation 
  //that each interval has to the next time that interval is reiterated in a series of knocks to verify pattern
  //stndard dev = sqr rt of the average of the squared differences from the mean
  if(key == ENTER || key == ESC){
    exportRhythm();
  }
  reset();//background color changes, and tallies are reset

}




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void knockJustHappened(){
  totalknocking++;
  
  float currentTime = millis();//current time is registered and stored
  knockTimes.append(currentTime);
  
  int howManyKnocks = knockTimes.size();
  if(howManyKnocks>1){
    float earlierKnock = knockTimes.get(howManyKnocks-2);
    float laterKnock = knockTimes.get(howManyKnocks-1);
    float interval = laterKnock - earlierKnock;
    knockIntervals.append(interval);//intervals are calculated and put into floatlist
  }
  addNewEffects();
}
void calculateRhythm(){
  howManyTimesInput++;//how any times have we reinput a password? used later for average calculation
  //println("times in millis");
  for(int i = 0; i < knockTimes.size(); i++){ println("time of knock "+(i+1)+": "+knockTimes.get(i));}
  //println("intervals in millis");
   for(int i = 0; i < knockIntervals.size(); i++){ float interval = knockIntervals.get(i); //println("interval "+(i+1)+"."+(i+2)+":"+interval);
  }
  //calculate interval ratios
  for(int i = 0; i < knockIntervals.size() - 1; i++){
    for(int j = i + 1; j < knockIntervals.size(); j++){
       float intervalRelation = knockIntervals.get(i)/knockIntervals.get(j);
       allIntervalRatios.append(intervalRelation);
       //println("intervalratios "+(i)+"."+(j)+": "+intervalRelation);
     }
   };
  
  //set all the current tally marks to fade away
  for(int i=0; i<tallycount.size();i++){ tallycount.get(i).currentKnockIteration = false; }
}
void exportRhythm(){//calculate standard deviation across several inputs - this is the average of the squared differences each ratio has to the average of the raitos
  howManyTimesInput++;
  JSONArray rhythmCollection = new JSONArray();
  JSONArray standardDeviations = new JSONArray();//holds the expected standard deviation from average for each ratio 
  JSONArray averageIntervalRatio = new JSONArray();//holds the averages for each ratio across all entries
  int howManyRatioCombos = int((knockTimes.size() - 2) / 2f * (knockTimes.size() - 1));
  for (int col = 0; col < howManyRatioCombos; col++ ){
    
    float average = 0;
    for(int row = 0; row < howManyTimesInput - 1; row++){//every combo pair should have an equivalent across each entry, trying to find index
      println(col+row*(knockIntervals.size()-1));
      average += allIntervalRatios.get(col+row*(knockIntervals.size()-1));
    }
    average = average/howManyTimesInput;//this is the average of the interval ratios oflike, say the first knock of the pattern
    averageIntervalRatio.setFloat(col,average);
    
    float averageOfSquaredDif=0;
    for(int row = 0; row < howManyTimesInput-1; row++){
      float squaredDiff = pow(average-allIntervalRatios.get(col+row*(knockIntervals.size()-1)),2);
      averageOfSquaredDif+=squaredDiff;
    }
    averageOfSquaredDif = averageOfSquaredDif / howManyTimesInput;//THIS IS VARIANCE
    
    float SD = pow(averageOfSquaredDif,0.5);//standard deviation of this part of the knock
    standardDeviations.setFloat(col,SD);
  }
  JSONObject rhythm = new JSONObject();
  rhythm.setJSONArray("StandardDeviationsOfIntervalRatios", standardDeviations);
  rhythm.setJSONArray("AverageIntervalRatio", averageIntervalRatio);
  
  rhythmCollection.setJSONObject(0,rhythm);
  saveJSONArray(rhythmCollection, "data/passwords.json");
}
///////////////////////////////VISUAL/SOUND EFFECTS/////////////////////////////////////////////////////////////////////
void addNewEffects(){//add new ripples and tallies to the array of both
  Ripple anotherKnock = new Ripple(mouseX, mouseY);
  rippleknocks.add(anotherKnock);
  volume=1;
  int howManySoFar = knockTimes.size();
  Tally anotherTally = new Tally(howManySoFar);
  tallycount.add(anotherTally);
}
void reset(){
  bg = color(random(10,245), random(10,245),random(10,240));
  //clear the float lists for the next round
  knockTimes.clear(); knockIntervals.clear();//clears the current floatLists of knock times and intervals
}
void visualEffects(){
  //RIPPLE 
  for (int i = 0; i < rippleknocks.size(); i++) {
    if(rippleknocks.get(i).keep){//if the ripple is still viable to grow, continue drawing it out
      rippleknocks.get(i).draw();
      rippleknocks.get(i).update();
    }else{
      rippleknocks.remove(i);
    }
  }
  for (int i = 0; i < tallycount.size(); i++) {
    tallycount.get(i).draw();
  }
}
void audio(){
  soundEffect.pan(map(mouseX,0,width,-1,1));//x position determines what side the osund comes out from
  soundEffect.freq(map(mouseY,0,height,300,80));//y position determines pitch
  soundEffect.amp(volume);
  volume=volume/1.2;
}
class Tally{
  float x=35;
  float y=35;
  float size = 6;
  boolean currentKnockIteration = true;
  int opacity;
  int maxSpacing=width/4;
  int maxSpread; //max spread is determiend by the first pattern input
  //color thisbg;
  color filling = color(255);
  Tally(int howMany){
    if (howMany == 1){
      x=35;
    }else{
      float timing = knockIntervals.get(howMany-2);
      float spacing = map(timing, 0,5000,0,maxSpacing);
      x=tallycount.get(totalknocking-2).x+spacing;
    }
    //x=;
  }
  void draw(){
    if(currentKnockIteration){
        opacity = 255;
        //thisbg = bg;
    }else{opacity=40; filling = 0;}
    fill(filling, opacity);
    ellipse(x,y,size,size);
  }
}
//------visual effects_--------------------------------------------------------
class Ripple{
  float x;
  float y;
  int size=1;
  float increase = width/25; 
  int strokeC=255;
  boolean keep = true;
  Ripple(float xx, float yy){
    x=xx;
    y=yy;
  }
  void update() {
    increase-=width/2222.22;
    size+=increase;
    strokeC-=5;
    if (strokeC<=0){
      keep = false;
    }
  }
  void draw(){
    noStroke();
    fill(255,strokeC);
    ellipse(x,y,size,size);
  }
}