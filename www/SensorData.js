var SensorData = function (data, timestamp) {
    this.data = data;
    this.timestamp = timestamp || (new Date()).getTime();
};

module.exports = SensorData;
