angular.module('api', [])
  .controller('ApiController', function($http) {
    var api = this;

    api.files = [];
    api.file;

    api.refresh = function () {
      $http({
        method: 'GET', 
        url: '/files'
      }).then(function successCallBack(response) {
        api.files = response.data;
      }, function errorCallBack(response) {
        Materialize.toast('Impossible to get files', 2000);
      });
    };

    function getFile(name, callback) {
      $http({
        method: 'GET', 
        url: '/files/' + name
      }).then(function successCallBack(response) {
        callback(response.data);
      }, function errorCallBack(response) {
        Materialize.toast('Impossible to get the file', 2000);
      });
    };

    api.edit = function (file) {
      getFile(file, function(data) {
        api.file = data;
        $('#editFile').openModal();
      });
    };

    api.newFile = function(name) {
      if (name == undefined || name == "")
        return;

      $http({
        method: 'PUT', 
        url: '/files/' + name
      }).then(function successCallBack(response) {
        api.refresh()
      }, function errorCallBack(response) {
        Materialize.toast('Impossible to create the file', 2000);
      });
    };

    api.saveFile = function() {
      $.ajax({
        type: 'POST', 
        url: '/files/' + api.file.name, 
        data: {
          content: api.file.content
        }, 
        success: function() {
          Materialize.toast('File successfully updated', 2000);
        }, error: function() {
          Materialize.toast('Impossible to create the file', 2000);
        }
      });
    };

    api.refresh();
  });
