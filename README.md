Otter
=====

Otter is an HTTP server that renders your client-side apps.

Wait, what?
-----------

When you write a single page application with the HTML5 history API (e.g., using Backbone), you probably end up with a blank index.html file which the client then fills with content. This sucks for two reasons:

 - It's slow. You have to make at least two round trips to the server to see anything.
 - It's invisible to search engines, curl, browsers with JavaScript disabled, etc.

There's already a solution for this problem. You can write a server that renders what the client renders. This is great, except that now you're writing everything twice.

But what if we could run the client-side code on the server? What if we could manipulate the page with the DOM API and make HTTP requests with XMLHTTPRequest?

Otter does just that. When a client makes a request to Otter, it loads up your app inside Zombie.js, an efficient headless browser. Once the page finishes loading, it renders the DOM to a string and sends it back to the client.

If the client's running JavaScript, they can start up the client-side router and it's business as usual. If the client hasn't got JavaScript, they just see content like a normal web page.

### So I have to write my server in JavaScript?

Nope! You don't have to modify your server.

The app running inside Otter talks to the same thing your client-side app does. If you've got a Backbone app for example, it talks to the server which serves JSON for your models.

### Is it secure?


Getting started
---------------

The app inside `example/` is a simple example of a Backbone app that uses Otter. The first page load runs server-side, then the client instantiates Backbone's router to handle subsequent requests.

    $ ./bin/otter example/
    Server started on port 8000.

Point your browser at [http://localhost:8000](http://localhost:8000).

Complex example
---------------

Using it as part of an Express app
----------------------------------

Running the test suite
----------------------

    $ npm test

