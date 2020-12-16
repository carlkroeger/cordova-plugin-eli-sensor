// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var SensorData = function (data, timestamp) {
    this.data = data;
    this.timestamp = timestamp || (new Date()).getTime();
};

module.exports = SensorData;
