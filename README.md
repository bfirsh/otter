Otter
=====

Otter is an HTTP server that renders your client-side apps with Zombie.js.

Wait, what?
-----------

When you write a single-page web application with pushState, the server normally serves a blank HTML document and the client fills it with content. This sucks for two reasons:

 - It's slow. The client has to make two requests to display anything on the page.
 - It doesn't work with search engines, browsers with JavaScript disabled, curl, etc etc. They just see a blank page.

If you want to get the server to display content and use client-side routing, you probably have to write everything twice: once for the server, once for the client.

But what if we could run the client-side code on the server? When a client makes a request to Otter, it loads up your app inside Zombie.js, a headless browser. Once all the Ajax requests and so on have finished, it sends the page as rendered by your app back to the client. 

If the client's running JavaScript, they can start up the client-side router and it's business as usual. If the client hasn't got JavaScript, they just see the content like a normal web page.

So I have to write my server in JavaScript?
-------------------------------------------

Nope! You don't have to modify your server.

The app running inside Otter talks to the same thing your client-side app does - the server which serves JSON for Backbone models, for example.

Is it secure?
-------------


Getting started
---------------

The app inside `example/` is a naive example of a Backbone app that uses Otter. The first page load runs server-side, then the client instantiates Backbone's router to handle subsequent requests.

    $ sudo npm install otter
    $ otter example/
    Server started on port 8000.

Point your browser at [http://localhost:8000](http://localhost:8000).

Complex example
---------------



Using it as part of an Express app
----------------------------------

Running the test suite
----------------------


