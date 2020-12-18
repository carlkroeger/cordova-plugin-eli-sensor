// Copyright (c) 2020, Elinous.

package com.android.plugins;

import java.util.List;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.lang.Math;

import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;

import android.os.Handler;
import android.os.Looper;

/**
 * This class listens to the eliSensor sensor and stores the latest
 * sensor_data value.
 */
public class EliSensor extends CordovaPlugin implements SensorEventListener {

    public static int STOPPED = 0;
    public static int STARTING = 1;
    public static int RUNNING = 2;
    public static int ERROR_FAILED_TO_START = 3;
    Map<Integer, String> sensor_dict = new HashMap<Integer, String>() {{
        put(1,"TYPE_ACCELEROMETER");
        //put(35,"TYPE_ACCELEROMETER_UNCALIBRATED");
        put(4,"TYPE_GYROSCOPE");
        //put(16,"TYPE_GYROSCOPE_UNCALIBRATED");
        //put(2,"TYPE_MAGNETIC_FIELD");
        //put(14,"TYPE_MAGNETIC_FIELD_UNCALIBRATED");
        put(11,"TYPE_ROTATION_VECTOR");
        //put(28,"TYPE_POSE_6DOF");
        put(15,"TYPE_GAME_ROTATION_VECTOR");
    }};
    private int SENSOR_TYPE;
    private JSONArray sensor_list;
    private JSONArray data;  // most recent sensor_data values
    private long timestamp;  // time of most recent value
    private int status;  // status of listener
    private int accuracy = SensorManager.SENSOR_STATUS_UNRELIABLE;

    private SensorManager sensorManager;  // Sensor manager
    private Sensor mSensor;  // Orientation sensor returned by sensor manager

    private CallbackContext callbackContext;  // Keeps track of the JS callback context.

    private Handler mainHandler=null;
    private Runnable mainRunnable = new Runnable() {
        public void run() {
            EliSensor.this.timeout();
        }
    };

    /**
     * Create an eliSensor listener.
     */
    public EliSensor() {
        //this.data = new Array();
        this.timestamp = 0;
        this.setStatus(EliSensor.STOPPED);
     }
     private int getSensorType(){
         return this.SENSOR_TYPE;
     }

     private void setSensorType(int sensor_type){
        this.SENSOR_TYPE = sensor_type;
        // if(sensor_type.equals("PROXIMITY")){
        //     this.SENSOR_TYPE = Sensor.TYPE_PROXIMITY;
        // } else if(sensor_type.equals("ACCELEROMETER")){
        //     this.SENSOR_TYPE = Sensor.TYPE_ACCELEROMETER;
        // } else if(sensor_type.equals("GRAVITY")){
        //     this.SENSOR_TYPE = Sensor.TYPE_GRAVITY;
        // } else if(sensor_type.equals("GYROSCOPE")){
        //     this.SENSOR_TYPE = Sensor.TYPE_GYROSCOPE;
        // } else if(sensor_type.equals("GYROSCOPE_UNCALIBRATED")){
        //     this.SENSOR_TYPE = Sensor.TYPE_GYROSCOPE_UNCALIBRATED;
        // } else if(sensor_type.equals("LINEAR_ACCELERATION")){
        //     this.SENSOR_TYPE = Sensor.TYPE_LINEAR_ACCELERATION;
        // } else if(sensor_type.equals("ROTATION_VECTOR")){
        //     this.SENSOR_TYPE = Sensor.TYPE_ROTATION_VECTOR;
        // } else if(sensor_type.equals("SIGNIFICANT_MOTION")){
        //     this.SENSOR_TYPE = Sensor.TYPE_SIGNIFICANT_MOTION;
        // } else if(sensor_type.equals("STEP_COUNTER")){
        //     this.SENSOR_TYPE = Sensor.TYPE_STEP_COUNTER;
        // } else if(sensor_type.equals("STEP_DETECTOR")){
        //     this.SENSOR_TYPE = Sensor.TYPE_STEP_DETECTOR;
        // } else if(sensor_type.equals("GAME_ROTATION_VECTOR")){
        //     this.SENSOR_TYPE = Sensor.TYPE_GAME_ROTATION_VECTOR;
        // } else if(sensor_type.equals("GEOMAGNETIC_ROTATION_VECTOR")){
        //     this.SENSOR_TYPE = Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR;
        // } else if(sensor_type.equals("MAGNETIC_FIELD")){
        //     this.SENSOR_TYPE = Sensor.TYPE_MAGNETIC_FIELD;
        // } else if(sensor_type.equals("MAGNETIC_FIELD_UNCALIBRATED")){
        //     this.SENSOR_TYPE = Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED;
        // } else if(sensor_type.equals("ORIENTATION")){
        //     this.SENSOR_TYPE = Sensor.TYPE_ORIENTATION;
        // } else if(sensor_type.equals("AMBIENT_TEMPERATURE")){
        //     this.SENSOR_TYPE = Sensor.TYPE_AMBIENT_TEMPERATURE;
        // } else if(sensor_type.equals("LIGHT")){
        //     this.SENSOR_TYPE = Sensor.TYPE_LIGHT;
        // } else if(sensor_type.equals("PRESSURE")){
        //     this.SENSOR_TYPE = Sensor.TYPE_PRESSURE;
        // } else if(sensor_type.equals("RELATIVE_HUMIDITY")){
        //     this.SENSOR_TYPE = Sensor.TYPE_RELATIVE_HUMIDITY;
        // } else if(sensor_type.equals("TEMPERATURE")){
        //     this.SENSOR_TYPE = Sensor.TYPE_TEMPERATURE;
        // }
     }
     public JSONArray getSensorList(){
         return this.sensor_list;
     }
     public void setSensorList(List<Sensor> list){
        try {        
            this.sensor_list = new JSONArray();
            ArrayList<Integer> alreadyAdded = new ArrayList<Integer>();
            for (Sensor sensor : list) {
                Integer type = sensor.getType();
                if(!alreadyAdded.contains(type) && this.sensor_dict.containsKey(type))
                {
                    alreadyAdded.add(type);
                    JSONObject json = new JSONObject();
                    json.put("string_type", sensor.getStringType());
                    json.put("type", type);
                    json.put("name", this.sensor_dict.get(type));
                    this.sensor_list.put(json);
                }
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
     }

    /**
     * Sets the context of the Command. This can then be used to do things like
     * get file paths associated with the Activity.
     *
     * @param cordova The context of the main Activity.
     * @param webView The associated CordovaWebView.
     */
    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        this.sensorManager = (SensorManager) cordova.getActivity().getSystemService(Context.SENSOR_SERVICE);
        this.setSensorList(this.sensorManager.getSensorList(Sensor.TYPE_ALL));
    }

    /**
     * Executes the request.
     *
     * @param action        The action to execute.
     * @param args          The exec() arguments.
     * @param callbackId    The callback id used when calling back into JavaScript.
     * @return              Whether the action was valid.
     */
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {
        if (action.equals("sensor_list")) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, this.sensor_list);
            result.setKeepCallback(true);
            callbackContext.sendPluginResult(result);
            return true;
        } else if (action.equals("start")) {            
            try {
                int sensor_type = args.getInt(0);
                this.setSensorType(sensor_type);
            } catch (JSONException e) {
                e.printStackTrace();
            }
            this.callbackContext = callbackContext;
            if (this.status != EliSensor.RUNNING) {
                // If not running, then this is an async call, so don't worry about waiting
                // We drop the callback onto our stack, call start, and let start and the sensor callback fire off the callback down the road
                this.start();
            }
        } else if (action.equals("stop")) {
            if (this.status == EliSensor.RUNNING) {
                this.stop();
            }
        } else {
          // Unsupported action
            return false;
        }

        PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT, "");
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
        return true;
    }

    /**
     * Called by EliSensorBroker when listener is to be shut down.
     * Stop listener.
     */
    public void onDestroy() {
        this.stop();
    }

    //--------------------------------------------------------------------------
    // LOCAL METHODS
    //--------------------------------------------------------------------------
    //
    /**
     * Start listening for sensor_data.
     *
     * @return          status of listener
    */
    private int start() {
        // If already starting or running, then just return
        if ((this.status == EliSensor.RUNNING) || (this.status == EliSensor.STARTING)) {
            return this.status;
        }

        this.setStatus(EliSensor.STARTING);

        // Get eliSensor from sensor manager
        List<Sensor> list = this.sensorManager.getSensorList(this.getSensorType());

        // If found, then register as listener
        if ((list != null) && (list.size() > 0)) {
          this.mSensor = list.get(0);
          this.sensorManager.registerListener(this, this.mSensor, SensorManager.SENSOR_DELAY_UI);
          this.setStatus(EliSensor.STARTING);
        } else {
          this.setStatus(EliSensor.ERROR_FAILED_TO_START);
          this.fail(EliSensor.ERROR_FAILED_TO_START, "No sensors found to register eliSensor listening to.");
          return this.status;
        }

        // Set a timeout callback on the main thread.
        stopTimeout();
        mainHandler = new Handler(Looper.getMainLooper());
        mainHandler.postDelayed(mainRunnable, 2000);

        return this.status;
    }
    private void stopTimeout() {
        if(mainHandler!=null){
            mainHandler.removeCallbacks(mainRunnable);
        }
    }
    /**
     * Stop listening to eliSensor sensor.
     */
    private void stop() {
        stopTimeout();
        if (this.status != EliSensor.STOPPED) {
            this.sensorManager.unregisterListener(this);
        }
        this.setStatus(EliSensor.STOPPED);
        this.accuracy = SensorManager.SENSOR_STATUS_UNRELIABLE;
    }

    /**
     * Returns an error if the sensor hasn't started.
     *
     * Called two seconds after starting the listener.
     */
    private void timeout() {
        if (this.status == EliSensor.STARTING) {
            this.setStatus(EliSensor.ERROR_FAILED_TO_START);
            this.fail(EliSensor.ERROR_FAILED_TO_START, "EliSensor could not be started.");
        }
    }

    /**
     * Called when the accuracy of the sensor has changed.
     *
     * @param sensor
     * @param accuracy
     */
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        // Only look at eliSensor events
        if (sensor.getType() != this.getSensorType()) {
            return;
        }

        // If not running, then just return
        if (this.status == EliSensor.STOPPED) {
            return;
        }
        this.accuracy = accuracy;
    }

    /**
     * Sensor listener event.
     *
     * @param SensorEvent event
     */
    public void onSensorChanged(SensorEvent event) {
        try {
            // Only look at selected sensor type
            if (event.sensor.getType() != this.getSensorType()) {
                return;
            }

            // If not running, then just return
            if (this.status == EliSensor.STOPPED) {
                return;
            }
            this.setStatus(EliSensor.RUNNING);

            if (this.accuracy >= SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM) {

                // Save time that event was received
                this.timestamp = System.currentTimeMillis();
                JSONArray data = new JSONArray(); /*para retornar como json*/
                if(event.sensor.getType() == 11 || event.sensor.getType() == 15){
                    /*rotation vectors deben ser convertidos a angulos*/
                    float[] vectorInDegrees = this.calculateAngles(event.values);
                    /*y luego añadidos al json*/
                    for(int i=0;i<vectorInDegrees.length;i++){
                        data.put(Float.parseFloat(vectorInDegrees[i]+""));
                    }
                }else{
                    /*añadir resultado del sensor al json*/
                    for(int i=0;i<event.values.length;i++){
                        data.put(Float.parseFloat(event.values[i]+""));
                    }
                }
                this.data = data;

                this.win();
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
    public float[] calculateAngles(float[] rVector){
        float[] result = new float[3];
        float[] rMatrix = new float[9]; // para recibir la matriz
        //caculate rotation matrix from rotation vector first
        SensorManager.getRotationMatrixFromVector(rMatrix, rVector);
    
        //calculate Euler angles now
        SensorManager.getOrientation(rMatrix, result);
    
        //The results are in radians, need to convert it to degrees

        /**convert result to degrees**/
        for (int i = 0; i < result.length; i++){
            result[i] = Math.round(Math.toDegrees(result[i]));
        }
        return result;
    }

    /**
     * Called when the view navigates.
     */
    @Override
    public void onReset() {
        if (this.status == EliSensor.RUNNING) {
            this.stop();
        }
    }
    @Override
    public void onResume(boolean multitasking) {
        if (this.status == EliSensor.STOPPED) {
            this.start();
        }
    }
    @Override
    public void onPause(boolean multitasking) {
        if (this.status == EliSensor.RUNNING) {
            this.stop();
        }
    }


    // Sends an error back to JS
    private void fail(int code, String message) {
        // Error object
        JSONObject errorObj = new JSONObject();
        try {
            errorObj.put("code", code);
            errorObj.put("message", message);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        PluginResult err = new PluginResult(PluginResult.Status.ERROR, errorObj);
        err.setKeepCallback(true);
        callbackContext.sendPluginResult(err);
    }

    private void win() {
        // Success return object
        PluginResult result = new PluginResult(PluginResult.Status.OK, this.getOrientationJSON());
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

    private void setStatus(int status) {
        this.status = status;
    }
    private JSONObject getOrientationJSON() {
        JSONObject r = new JSONObject();
        try {
            r.put("data", this.data);
            r.put("timestamp", this.timestamp);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return r;
    }
}
