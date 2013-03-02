Otter
=====

A server that runs your client-side apps.

Wait, what?
-----------

Web apps are shifting client-side. More and more logic is moving from server to client, but that often ends up with your server just serving up a JSON API and a blank index.html which gets filled with content client-side. This sucks for two reasons:

 - It's slow. You must make at least two round trips to the server before any content is displayed.
 - Your content is invisible to search engines, curl, browsers with JavaScript disabled, etc.

A typical solution to this problem is to write server-side code that renders some of what the client would render. This works, but now you're writing everything twice.

But what if we could use client-side APIs on the server? What if we could generate HTML with the DOM and jQuery? Make HTTP requests with XMLHTTPRequest? This would mean you could run your client-side code on the server without modification.

Otter does just that. When a client makes a request to Otter, it loads up your app inside Zombie.js, a Node implementation of the browser APIs. After it has finished loading a page, it renders the DOM to a string and sends it back to the client.

If the client supports JavaScript, they can start up the client-side router, and it's business as usual. If the client can't run JavaScript, they just see the content as a normal web page.

You've now got an application which behaves like it was written in a server-side language, but actually shares its code with the client.


### So I'll have to write my server in JavaScript?

Nope! You won't have to modify your server.

Otter is a stand-alone server which runs client-side JavaScript. The app running inside Otter talks to the same server that your browser does. If you've got a Backbone app, it talks to the same server which serves JSON for your models.

### So I'll have to write my client-side code with Backbone?

Nope! Unlike other techniques that allow running the same code on the server and in the browser, Otter is framework agnostic. It's an implementation of the browser APIs on the server, so almost any code which runs inside the browser will run inside Otter.

### Is it secure?

Otter is far more paranoid than a browser, so you won't trip up on common client-side vulnerabilities. 

All code runs inside a sandbox. Node's sandboxes aren't perfect though – you must still ensure that you always run trusted code – but to help with that, Otter only allows HTTP requests to the local server by default. If you wish to load data from other domains, you must allow them explicitly.

Install
-------

    $ sudo npm install -g otter

(Or use your preferred way of installing npm packages.)

Getting started
---------------

Otter is, at a basic level, an HTTP server. Pointed at a directory, it will serve the files inside it. It only starts doing clever things when it is asked to serve a file that doesn't exist.

Instead of showing a 404, it will open the file `index.html` in Zombie.js. When Zombie.js finishes loading the page (all Ajax requests have finished, etc) it sends `document.outerHTML` as the HTTP response back to the browser.

To demonstrate how Otter works, an example app is included in `example/`. It's a simple Twitter client written in Backbone. The first page load runs server-side, then the client instantiates Backbone's router to handle subsequent requests. It uses [backbone-otter](https://github.com/bfirsh/backbone-otter) to handle caching between server and client.

Run Otter on that directory, allowing requests to `api.twitter.com`:

    $ otter -a api.twitter.com example/
    Server started on port 8000.

Point your browser at [http://localhost:8000](http://localhost:8000).

Usage
-----

    $ otter [options] <path>

Otter is passed a path to a directory which is expected to contain an `index.html` file. It takes these options:

#### -a `host1,host2`

A comma-separated list of hosts to allow connections to (e.g. `api.example.com,api.twitter.com`). By default, Otter will not allow connections to any host except itself. If you want to allow Ajax connections to your API, for example, you will need to add it to this list.

#### -p `port`

The port to listen on. Default: 8000

#### -w `num`

The number of worker processes to spawn, defaulting to the number of CPUs.

API
---

Otter provides an API to use inside your apps, exposed as `window.otter` on both the server and the client.

### `window.otter.isServer`

`true` or `false`, whether or not the page is running on the server or client.

### `window.otter.cache`

An object that can be used to pass data from the server to the client.

When your app is running inside Otter, it can set keys on this object. The object is serialised to JSON and injected into the top of the page sent to the browser. When the browser opens the page, the value of `window.otter.cache` is restored from the serialised JSON.

See the section *Resuming your app on the client* for an example of how this object can be used.


Writing an app for Otter
------------------------

Writing an app for Otter is almost the same as writing a single-page app just for the browser, but there are a few things you need to take into account.

### Running code only on the server or the client

Some code only makes sense to run on the client; for example, handling user interactions, drawing to canvases etc. You can use the `window.otter.isServer` variable to check if you are running on the server:

```javascript
if (window.otter && window.otter.isServer) {
    // Running on the server
}
else {
    // Running in the browser
}
```

### Resuming your app on the client

Reinstantiating the app on the client after the app has been run on the server, in order that it can handle user interaction and route future pages, is a tricky problem. Otter is framework agnostic, so it doesn't prescribe a solution. It does, however, provide tools, such as `window.otter.cache` (see [API](#api)) and [backbone-otter](http://github.com/bfirsh/backbone-otter) if you're using Backbone.

The brute-force approach is to reroute the URL, completely rebuilding the page client-side. This isn't as scary as it sounds if you cache the data that was fetched on the server, but the downsides of this are obvious inefficiency, and possibly odd side-effects of loading in a new copy of the DOM, if the user has already interacted with the initial DOM.

If you want a more efficient solution, we can work smarter. We can cache data that Otter fetches from your API, and pass it on to the client. If we then rebuild a set of models and views attached to the correct DOM elements that the server has generated, we can "boot up" the application again without having to regenerate the HTML. In Backbone, this is a matter of only rendering a view if it hasn't already been rendered by the server. See the included example app for a simple demonstration of how this can be done.

I am working on some [Backbone tools for Otter](https://github.com/bfirsh/backbone-otter) to make this process easier.

### Redirects

Otter will intercept changes in location (e.g. setting `window.location`) and immediately respond with a 302 redirect. This causes the browser to change location as you would expect if the code was running client-side.

### Cookies

Cookies in an HTTP request to Otter will be passed through to `document.cookie` so that they are available inside Otter. Similarly, any cookies set in `document.cookie` will be sent back with the HTTP response to the browser.

Deployment
----------

Otter is pretty easy to deploy on Heroku.

You'll first want to create a `package.json` file that specifies Otter as a dependency:

```json
    {
      "name": "otter-example",
      "version": "0.1.0",
      "dependencies" : {
        "otter": "*"
      }
    }
```

You'll also need a `Procfile` to tell Heroku how to run Otter, assuming your app is in a directory called `app/`:

```
    web: ./node_modules/.bin/otter -p $PORT app/
```

Then [deploy to Heroku as usual](https://devcenter.heroku.com/articles/nodejs).

Take a look at [Hao-kang Den's kawauso](https://github.com/hden/kawauso) for a more complete example.


Extending Otter
---------------

Instead of running Otter standalone, it can also be extended by using it as part of a Node.js app. See `lib/otter/server.coffee` for the Express app that is used internally. The renderer used in this file is available externally as `require('otter').renderer`.


Running the test suite
----------------------

    $ npm test

