import processing.net.*; 
//import org.json.*;
Client myClient; 
String dataIn; 
float qx = 0;
float qy = 0;
float qz = 0;
float qw = 0;

float pqz = 0;
float pqy = 0;
String activation;
boolean clicked = false;

int hoverSize = 5;
 
void setupConnection() { 
  myClient = new Client(this, "127.0.0.1", 13375); 
} 
 
void parseData() { 
  if (myClient.available() > 0) { 
    dataIn = myClient.readString(); 
  } 
  try{
      JSONObject data = JSONObject.parse(dataIn);
  JSONObject filteredFrames = data.getJSONObject("filteredFrames");
  JSONObject motionSilencer = filteredFrames.getJSONObject("MotionSilencer");
  JSONArray yValues = motionSilencer.getJSONArray("channels");
  JSONObject imu = data.getJSONObject("imuQuat");
  pqy = qy;
  pqz = qz;
  qx = imu.getFloat("qx");
  qy = imu.getFloat("qy");
  qz = imu.getFloat("qz");
  qw = imu.getFloat("qw");
  activation = data.getString("activation");
  //println(qx + " " + qy + " " + qz + " " + activation);
  //println(data.getString("activation"));
  if(activation.equals("HOLD"))
  {
    clicked = true;
    hoverSize+=1;
    onHover(hoverSize, hoverSize);//affordance to realize that tap will be made
  }else{
    boolean clickToSendToRhythm = false;
    if(clickToSendToRhythm !=clicked){
      println("deviceData detected a tap "+ frameCount);
      knockJustHappened();
      hoverSize = 5;
    }
    clicked = false; 
  }
  }catch (Exception e)
  {
  }

} 
