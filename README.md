Otter
=====

A server that runs your client-side apps.

Wait, what?
-----------

Web apps are shifting client-side. More and more logic is moving from the server to the client, but this often ends up with your server becoming just a JSON API and a blank index.html which gets filled with content client-side. This sucks for two reasons:

 - It's slow. You have to make at least two round trips to the server before any content is displayed.
 - It's invisible to search engines, curl, browsers with JavaScript disabled, etc.

The typically solution to this problem is to write code on your server that renders some of what the client would render. This works, but now you're writing everything twice.

But what if we could use client-side APIs on the server? What if we could generate pages with the DOM instead of templates? And make HTTP requests with XMLHTTPRequest? This would mean we could run client-side code on the server without modification.

Otter does just that. When a client makes a request to Otter, it loads up your app inside Zombie.js, a Node implementation of the browser APIs. Once the page finishes loading, it renders the DOM to a string and sends it back to the client.

If the client supports JavaScript, they can start up the client-side router and it's business as usual. If the client can't run JavaScript, they just see the content like a normal web page.

### So I have to write my server in JavaScript?

Nope! You don't have to modify your server.

Otter's a standalone server that runs client-side JavaScript. The app running inside Otter talks to the same thing your browser does. If you've got a Backbone app, it talks to the same server which serves JSON for your models.

### So I have to write my client-side code with Backbone?

Nope! Unlike other techniques which allow you to run the same code on the server and in the browser, Otter is framework agnostic. It is an implementation of the browser APIs on the server, so almost any code which runs inside the browser will run inside Otter.

### Is it secure?

Otter is far more paranoid than a browser so you don't trip up on common client-side vulnerabilities. 

All code runs inside a sandbox. Node's sandboxes are not perfect, though – you must still make sure you always run trusted code. To help with that, Otter will only allow HTTP requests to the local server by default. If you wish to load data from other domains, you must explicitly allow them.

Install
-------

    $ sudo npm install -g otter

(Or your preferred way of installing npm packages.)

Getting started
---------------

Otter is, at a basic level, an HTTP server. Pointed at a directory, it will serve the files inside it. Only when it is asked to serve a file that doesn't exist does it start doing clever things.

When asked to serve a file that doesn't exist, it will load the file `index.html` and open that up in Zombie.js. When Zombie.js has finished running the page (all Ajax requests have finished, etc), it will send `document.outerHTML` as the HTTP response back to the client.

To demonstrate how Otter works, an example app is included in `example/`. It is a simple Twitter client written in Backbone. The first page load runs server-side, then the client instantiates Backbone's router to handle subsequent requests. It uses [backbone-otter](https://github.com/bfirsh/backbone-otter) to handle caching between server and client.

Run Otter on that directory, allowing requests to `api.twitter.com`:

    $ otter -a api.twitter.com example/
    Server started on port 8000.

Point your browser at [http://localhost:8000](http://localhost:8000).

Usage
-----

    $ otter [options] <path>

Otter is passed a path to a directory which is expected to contain an `index.html` file. It takes these options:

#### -a `host1,host2`

A comma-separated list of hosts to allow connections to (e.g. `api.example.com,api.twitter.com`). By default, Otter will not allow connections to be made to any host except itself. If you want to allow Ajax connections to your API, for example, you will need to add it to this list.

#### -p `port`

The port to listen on. Default: 8000

API
---

Otter provides an API to use inside your apps, exposed as `window.otter` on both the server and the client.

### `window.otter.isServer`

`true` or `false`, whether or not the page is running on the server or client.

### `window.otter.cache`

An object that can be used to pass data from the server to the client. You can set values in this object on the server, then when Otter has finished rendering a page, it serialises it to JSON and passes it to the client. It is injected into the top of the page so it is also available as `window.otter.cache`.


Writing an app for Otter
------------------------

Writing an app for Otter is almost the same as writing a single-page app just for the browser, but there are a few things you need to take into account.

### Running code only on the server or the client

Some code only makes sense to run on the client. For example, handling user interaction, drawing to canvases etc. You can use the `window.otter.isServer` variable to check if you are running on the server:

```javascript
if (window.otter && window.otter.isServer) {
    // Running on the server
}
else {
    // Running in the browser
}

```

### Resuming your app on the client

A tricky problem is reinstantiating the app on the client after the app has been run on the server so it can handle user interaction and route future pages. Otter is framework agnostic, so it doesn't prescribe a solution. Though it does provide tools, such as `window.otter.cache` (see [API](#api)) and [backbone-otter](http://github.com/bfirsh/backbone-otter) if you're using Backbone.

The brute-force solution is to just reroute the URL, completely rebuilding the page client-side. This isn't as scary as it sounds if you cache the data that was fetched on the server, but the downsides of this are its obvious inefficiency and perhaps some odd side-effects of loading a new copy of the DOM in if the user has already interacted with the initial DOM.

We can be smarter, though. We can cache the data fetched server-side and pass it to the client. If we then rebuild a set of models and views attached to the correct DOM elements that the server has generated, we can then efficiently "boot up" the application again. In Backbone, this would be a matter of only rendering a view if it hasn't already been rendered by the server. See the included example app for a simple example of how this can be done.

I am working on some [Backbone tools for Otter](https://github.com/bfirsh/backbone-otter) to make this process easier.

### Redirects

Whenever the app running inside Otter causes a change in location (e.g. setting `window.location`), Otter will intercept this and immediately respond with a 302 redirect to that location.

### Cookies

Cookies in an HTTP request to Otter will be passed through to `document.cookie` so they are available inside Otter. Similarly, any cookies set in `document.cookie` will be sent back with the HTTP response to the browser.


Extending Otter
---------------

Instead of running Otter standalone, it can also be extended by using it as part of a Node.js app. See `lib/otter/server.coffee` for the Express app that is used internally. The renderer is available as `require('otter').renderer`.


Running the test suite
----------------------

    $ npm test



