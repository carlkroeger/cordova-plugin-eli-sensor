// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This class provides access to device eliSensor data.
 * @constructor
 */
var argscheck = require('cordova/argscheck'),
    utils = require("cordova/utils"),
    exec = require("cordova/exec"),
    SensorData = require('./SensorData');

// Is the eliSensor sensor running?
var running = false;

// Keeps reference to watch calls.
var timers = {};

// Array of listeners; used to keep track of when we should call start and stop.
var listeners = [];
var eventTimerId = null;

// Last returned sensor_data object from native
var sensor_data = null;

// Tells native to start.
function start(sensor_type) {
    exec(function (a) {
        var tempListeners = listeners.slice(0);
        sensor_data = new SensorData(a.data, a.timestamp);
        for (var i = 0, l = tempListeners.length; i < l; i++) {
            tempListeners[i].win(sensor_data);
        }
    }, function (e) {
        var tempListeners = listeners.slice(0);
        for (var i = 0, l = tempListeners.length; i < l; i++) {
            tempListeners[i].fail(e);
        }
    }, "EliSensor", "start", [sensor_type]);
    running = true;
}

// Tells native to stop.
function stop() {
    exec(null, null, "EliSensor", "stop", []);
    running = false;
}

// Adds a callback pair to the listeners array
function createCallbackPair(win, fail) {
    return { win: win, fail: fail };
}

// Removes a win/fail listener pair from the listeners array
function removeListeners(l) {
    var idx = listeners.indexOf(l);
    if (idx > -1) {
        listeners.splice(idx, 1);
        if (listeners.length === 0) {
            stop();
        }
    }
}

var eliSensor = {
    /**
     * Asynchronously acquires the current sensor_data.
     *
     * @param {Function} successCallback    The function to call when the sensor_data data is available
     * @param {Function} errorCallback      The function to call when there is an error getting the sensor_data data. (OPTIONAL)
     * @param {EliSensorOptions} options    The options for getting the eliSensor data such as frequency. (OPTIONAL)
     */
    getCurrent: function (successCallback, errorCallback, options) {
        argscheck.checkArgs('fFO', 'eliSensor.getCurrent', arguments);

        var sensor_type = (options && options.sensor_type && typeof options.sensor_type == 'string') ? options.sensor_type : "ROTATION_VECTOR";

        var p;
        var win = function (a) {
            removeListeners(p);
            successCallback(a);
        };
        var fail = function (e) {
            removeListeners(p);
            errorCallback && errorCallback(e);
        };

        p = createCallbackPair(win, fail);
        listeners.push(p);

        if (!running) {
            start(sensor_type);
        }
    },

    /**
     * Asynchronously acquires the sensor_data repeatedly at a given interval.
     *
     * @param {Function} successCallback    The function to call each time the sensor_data is available
     * @param {Function} errorCallback      The function to call when there is an error getting the sensor_data. (OPTIONAL)
     * @param {EliSensorOptions} options    The options for getting the eliSensor data such as frequency. (OPTIONAL)
     * @return String                       The watch id that must be passed to #clearWatch to stop watching.
     */
    watch: function (successCallback, errorCallback, options) {
        argscheck.checkArgs('fFO', 'eliSensor.watch', arguments);
        // Default interval (10 sec)
        var frequency = (options && options.frequency && typeof options.frequency == 'number') ? options.frequency : 10000;
        var sensor_type = (options && options.sensor_type && typeof options.sensor_type == 'string') ? options.sensor_type : "ROTATION_VECTOR";

        // Keep reference to watch id, and report sensor_data readings as often as defined in frequency
        var id = utils.createUUID();

        var p = createCallbackPair(function () { }, function (e) {
            removeListeners(p);
            errorCallback && errorCallback(e);
        });
        listeners.push(p);

        timers[id] = {
            timer: window.setInterval(function () {
                if (sensor_data) {
                    successCallback(sensor_data);
                }
            }, frequency),
            listeners: p
        };

        if (running) {
            // If we're already running then immediately invoke the success callback
            // but only if we have retrieved a value, sample code does not check for null ...
            if (sensor_data) {
                successCallback(sensor_data);
            }
        } else {
            start(sensor_type);
        }

        if (cordova.platformId === "browser" && !eventTimerId) {
            // Start firing devicemotion events if we haven't already
            var eliSensorEvent = new Event('eliSensor');
            eventTimerId = window.setInterval(function () {
                window.dispatchEvent(eliSensorEvent);
            }, 200);
        }

        return id;
    },

    /**
     * Clears the specified eliSensor watch.
     *
     * @param {String} id       The id of the watch returned from #watch.
     */
    clearWatch: function (id) {
        // Stop javascript timer & remove from timer list
        if (id && timers[id]) {
            window.clearInterval(timers[id].timer);
            removeListeners(timers[id].listeners);
            delete timers[id];

            if (eventTimerId && Object.keys(timers).length === 0) {
                // No more watchers, so stop firing 'devicemotion' events
                window.clearInterval(eventTimerId);
                eventTimerId = null;
            }
        }
    }
};
module.exports = eliSensor;
