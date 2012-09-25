var User = Backbone.Model.extend({
    url: function() {
        return 'http://api.twitter.com/1/users/show/'+this.id+'.json?callback=?'
    },
})

var IndexView = Backbone.View.extend({
    render: function() {
        this.$el.html('<h1>Twitter!</h1><a href="users/14510231">bfirsh</a> <a href="users/14149919">aanand</a>')
    }
})

var UserView = Backbone.View.extend({
    initialize: function() {
        this.model.on('change', this.render, this)
    },

    render: function() {
        if (this.model.get('name')) {
            this.$el.html('<h1>'+this.model.get('name')+'</h1>')
            this.$el.append('<p>'+this.model.get('description')+'</p>')
            this.$el.append('<p>'+this.model.get('location')+'</p>')
        }
        else {
            this.$el.html('Loading...')
        }

    }
})

var Router = Backbone.Router.extend({
    routes: {
        '': 'index',
        'users/:id': 'user',
    },

    index: function() {
        var view = new IndexView({el: $('.content')});
        view.render();
    },

    user: function(id) {
        var user = new User({id: id})
        var view = new UserView({el: $('.content'), model: user});
        user.fetch()
        view.render();
    },
})

$(function() {
    var router = new Router();
    var options = {pushState: true}
    // Already rendered server-side, don't render first route
    if ($('.content').children().length) {
        options['silent'] = true;
    }
    Backbone.history.start(options);

    $(document).on('click', 'a', function(e) {
        router.navigate($(this).attr('href'), true);
        return false;
    });
})

