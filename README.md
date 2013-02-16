Otter
=====

Otter runs your client-side apps server-side.

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

Otter is far more paranoid than a browser so you don't trip up on the usual client-side vulnerabilities. 

All code runs inside a sandbox. Node's sandboxes are not perfect, though - you must still make sure you always run trusted code. To help with that, Otter will only allow HTTP requests to made to the local server by default. If you wish to load data from other domains, you must explicitly allow them.

Getting started
---------------

The app inside `example/` is a simple example of a Backbone app that uses Otter. The first page load runs server-side, then the client instantiates Backbone's router to handle subsequent requests.

    $ ./bin/otter -a api.twitter.com example/
    Server started on port 8000.

Point your browser at [http://localhost:8000](http://localhost:8000).

Complex example
---------------

Using it as part of an Express app
----------------------------------

Running the test suite
----------------------

    $ npm test

