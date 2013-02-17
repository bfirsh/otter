
var User = BackboneOtter.Model.extend({
    url: function() {
        return 'http://api.twitter.com/1/users/show/'+this.id+'.json?callback=?';
    },
});

var BaseView = Backbone.View.extend({
    hasRendered: function() {
        return this.$el.children().length > 0;
    },

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
    template: _.template("<% if (name) { %><h1><%= name %></h1><p><%= description %></p><p><%= location %></p><% } else { %><p>Loading...</p> <% } %>"),

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
        // Render this view if server has filled content.
        if (this.previousView || !view.hasRendered()) view.render();
        this.previousView = view;
    },

    user: function(id) {
        var user = new User({id: id});
        user.fetch();
        var view = new UserView({el: $('.content'), model: user});
        if (this.previousView || !view.hasRendered()) view.render();
        this.previousView = view;
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

