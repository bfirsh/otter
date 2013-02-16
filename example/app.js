
var User = BackboneOtter.Model.extend({
    url: function() {
        return 'http://api.twitter.com/1/users/show/'+this.id+'.json?callback=?'
    },
});

var BaseView = Backbone.View.extend({
    render: function() {
        this.$el.html(this.template(this.templateData()));
        return this;
    },

    templateData: function() {
        return {};
    }
});

var IndexView = BaseView.extend({
    template: _.template('<h1>Twitter!</h1><a href="users/14510231">bfirsh</a> <a href="users/14149919">aanand</a>')
});

var UserView = BaseView.extend({
    template: _.template("<h1><%= name %></h1><p><%= description %></p><p><%= location %></p>"),

    initialize: function() {
        this.model.on('change', this.render, this);
    },

    templateData: function() {
        return this.model.attributes;
    }
})

var Router = Backbone.Router.extend({
    routes: {
        '': 'index',
        'users/:id': 'user'
    },

    index: function() {
        var view = new IndexView({el: $('.content')});
        view.render();
    },

    user: function(id) {
        var user = new User({id: id});
        var view = new UserView({el: $('.content'), model: user});
        user.fetch();
        view.render();
    }
});

$(function() {
    var router = new Router();
    Backbone.history.start({pushState: true});

    $(document).on('click', 'a', function(e) {
        e.preventDefault();
        router.navigate($(this).attr('href'), true);
    });
});

