Otter
=====

A server that runs your client-side apps.

Wait, what?
-----------

Web apps are shifting client-side. More and more logic is moving from the server to the client, but this often ends up with your server being just a JSON API and a blank index.html which gets filled with content client-side. This sucks for two reasons:

 - It's slow. You have to make at least two round trips to the server before any content is displayed.
 - It's invisible to search engines, curl, browsers with JavaScript disabled, etc.

The typically solution to this problem is to extend your server so it renders some of what the client-side code would render. This works, but now you're writing everything twice.

But what if we could use client-side APIs on the server? What if we could generate pages with the DOM instead of templates? And make HTTP requests with XMLHTTPRequest? This would mean we could run client-side code on the server without modification.

Otter does just that. When a client makes a request to Otter, it loads up your app inside Zombie.js, a Node implementation of the browser APIs. Once the page finishes loading, it renders the DOM to a string and sends it back to the client.

If the client supports JavaScript, they can start up the client-side router and it's business as usual. If the client can't run JavaScript, they just see the content like a normal web page.

### So I have to write my server in JavaScript?

Nope! You don't have to modify your server.

Otter's a standalone server. The app running inside Otter talks to the same thing your client-side app does. If you've got a Backbone app, it talks to the same server which serves JSON for your models.

### So I have to write my client-side code with Backbone?

Nope! Unlike other techniques which allow you to run the same code server- and client-side, Otter is *framework agnostic*. It is an implementation of the browser APIs on the server, so almost any code which runs inside the browser will run inside Otter.

### Is it secure?

Otter is far more paranoid than a browser so you don't trip up on common client-side vulnerabilities. 

All code runs inside a sandbox. Node's sandboxes are not perfect, though - you must still make sure you always run trusted code. To help with that, Otter will only allow HTTP requests to made to the local server by default. If you wish to load data from other domains, you must explicitly allow them.

Install
-------

    $ sudo npm install -g otter

(Or your preferred way of installing npm packages.)

Getting started
---------------

Otter is, at a basic level, an HTTP server. Pointed at a directory, it will serve the files inside it. It starts doing clever things, however, when it is asked to serve a file that *doesn't exist*.

When asked to serve a file that doesn't exist in the directory it is pointed at, it will load `index.html` and open that up in Zombie.js. When Zombie.js has finished running the page (all Ajax requests have finished, etc), it will send `document.outerHTML` as the HTTP response.

The app inside `example/` is a simple Twitter client written in Backbone. The first page load runs server-side, then the client instantiates Backbone's router to handle subsequent requests. It uses [backbone-otter](https://github.com/bfirsh/backbone-otter) to handle caching between server and client.

Run Otter on that directory, allowing requests to `api.twitter.com`:

    $ ./bin/otter -a api.twitter.com example/
    Server started on port 8000.

Point your browser at [http://localhost:8000](http://localhost:8000).

Resuming your app on the client
-------------------------------

When the server generates your app's HTML and sends it to the client, the client then needs to reload the application so it can handle user interation and route future pages.

The brute-force approach is to just reroute the URL, completely rebuilding the page client-side. This isn't as scary as it sounds if you cache all the data fetched on page load, but the downsides of this are its obvious ineffciency and perhaps some odd side-effects of loading a new copy of the DOM in if the user has already interacted with the initial DOM.

We can be smarter, though. We can cache the data fetched server-side and pass it to the client. If we then rebuild a set of models and views attached to the correct DOM elements that the server has generated, we can then efficiently "boot up" the application again. In Backbone, this would be a matter of only rendering a view if it hasn't already been populated by the server.

I am working on some [Backbone tools for Otter](https://github.com/bfirsh/backbone-otter) to make this process easier.

API
---

Otter provides an API to use inside your apps, exposed as `window.otter` on both the server and the client.

### `window.otter.isServer`

`true` or `false`, whether or not the page is running on the server or client.

### `window.otter.cache`

An object that can be used to pass data from the server to the client. You can set values in this object on the server, then when Otter has finished rendering a page, it serialises it to JSON and passes it to the client. It is injected into the top of the page so it is also available as `window.otter.cache`.

Extending Otter
---------------

Instead of running Otter standalone, it can also be extended by using it as part of a Node.js app. See `lib/otter/server.coffee` for the Express app that is used internally. The renderer is available as `require('otter').renderer`.


Running the test suite
----------------------

    $ npm test
