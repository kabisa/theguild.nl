# HTTP caching gotcha: Heuristic Freshness

I recently ran into an issue where after deployment of an SPA (Single Page Application), a situation would occur where the page looked broken because CSS could not be loaded.

During analysis of the issue I ran into a thing I had never heard of: *Heuristic Freshness*.

## Context

For context, the application is a typical SPA. The compiled application consists of a bunch of files looking something like this (simplified):

```
├── index.html
    └── styles.4a3f9848037579025b00.css
    └── main.31f7dadf6d2b01fc08c7.js
```

The browser loads `index.html`, which includes various CSS and JS files.

Caching related headers for the CSS and JS looked like this:

```
Date: Fri, 06 Dec 2019 13:09:03 GMT
Etag: "31957a05a5df3c3b315b728b40b6e10e"
Last-Modified: Mon, 02 Dec 2019 14:12:09 GMT
Expires:	Sat, 07 Dec 2019 03:09:03 GMT
```

 `index.html` :

```
Date:	Fri, 06 Dec 2019 13:09:03 GMT
Etag: "c4238385fe77f826b5584fed1f1f1659"
Last-Modified: Tue, 03 Dec 2019 10:50:54 GMT
```

At first sight things looked okay, but then I noticed there weren't any `Cache-Control` or `Expires` on the `index.html` file.

I'm quite well aware what all these caching headers do when they _are_ present, but I wasn't sure what would happen if they are **not** present 🤔.

## Heuristic Freshness

This brings us to `Heuristic Freshness`. The HTTP specification [defines](https://tools.ietf.org/html/rfc7234#section-4.2.2) that, when a server does *not* explicitly specify expiration times, the client (browser) can use heuristics to estimate a plausible expiration time itself.

How exactly this 'plausible' expiration time is determined is left up to the client, but it seems that in practise most browsers use the following algorithm: `(now() - Last-Modified) * 0.10`. This means two things:

1. You have no control over how long your files are cached in the browser.
2. The files will be cached longer as time passes after deployment (assuming your `Last-Modified` headers reflect the time of the last deployment).

As you can see, this can result in some pretty nasty caching issues that are hard to diagnose as the duration for which files are cached will differ case by case depending on time and potentially browser used.

## Cache-Control and Expires headers to the rescue!

The lesson I take away from this is that it's crucial to set either `Cache-Control` or `Expires`, to ensure *you* control how long files can be cached by the browser.

For single page apps like I outlined above where you have an `index.html` and a bunch of assets with hashed filenames, the following is a good, safe practise:

`index.html`:

```
Cache-control: private, max-age=0, no-cache
```

This will ensure that the browser will never use a cached copy of your `index.html`, without checking with the server if the cache is still valid via a [conditional GET request](https://tools.ietf.org/html/rfc7234#section-4.3).

For other assets with hashed filenames, you want the opposite:

```
Cache-Control: public, max-age=31557600
```

These files can be cached for a long, long time, as when they change their filenames will change as well.

With this in place the following will happen during and after a deployment:

1. A new `index.html` will be uploaded to the server.
2. When a user loads your application, the browser will send a conditional GET request `If-Modified-Since: <previous Last-Modified value>` , and the server will respond with the new version of your `index.html`, since the file was modified by the deployment.
3. The browser will NOT use the old cached page, store the page in cache and will continue sending conditional GET requests in the future.

Problem solved!
