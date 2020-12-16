angular
  .module('eliSensor', [])
  .factory('$eliSensor', ['$q', function ($q) {

    return {
      getCurrent: function () {
        var q = $q.defer();

        if (angular.isUndefined(navigator.eliSensor) ||
          !angular.isFunction(navigator.eliSensor.getCurrent)) {
          q.reject('Device do not support watch');
        }

        navigator.eliSensor.getCurrent(function (result) {
          q.resolve(result);
        }, function (err) {
          q.reject(err);
        });

        return q.promise;
      },

      watch: function (options) {
        var q = $q.defer();

        if (angular.isUndefined(navigator.eliSensor) ||
          !angular.isFunction(navigator.eliSensor.watch)) {
          q.reject('Device do not support watchEliSensor');
        }

        var watchID = navigator.eliSensor.watch(function (result) {
          q.notify(result);
        }, function (err) {
          q.reject(err);
        }, options);

        q.promise.cancel = function () {
          navigator.eliSensor.clearWatch(watchID);
        };

        q.promise.clearWatch = function (id) {
          navigator.eliSensor.clearWatch(id || watchID);
        };

        q.promise.watchID = watchID;

        return q.promise;
      },

      clearWatch: function (watchID) {
        return navigator.eliSensor.clearWatch(watchID);
      }
    };
  }]);
