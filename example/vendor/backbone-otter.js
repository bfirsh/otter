
var BackboneOtter = window.BackboneOtter = {};

// A sync method which caches results from client to server
BackboneOtter.sync = function(method, model, options) {
  if (window.otter && window.otter.cache && method == 'read') {
    var url = _.result(model, 'url');
    if (window.otter.isServer) {
      var success = options.success;
      options.success = function(resp) {
        if (!window.otter.cache.models) window.otter.cache.models = {};
          window.otter.cache.models[url] = resp
          if (success) success.apply(this, arguments);
      };
    }
    else {
      if (window.otter.cache.models && window.otter.cache.models[url] && options.success) {
        options.success(window.otter.cache.models[url]);
        deferred = jQuery.Deferred();
        deferred.resolve();
        return deferred.promise();
      }
    }
  }
  return Backbone.sync(method, model, options);
};

// A model which caches results from server to client
BackboneOtter.Model = Backbone.Model.extend({
  sync: BackboneOtter.sync
});

// A collection which caches results from server to client
BackboneOtter.Collection = Backbone.Collection.extend({
  sync: BackboneOtter.sync
});


