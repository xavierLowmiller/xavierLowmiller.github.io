---
layout: post
title: "Deploying a Vapor App Using Docker: The Missing Manual"
date: 2020-02-06
---

One of the the things that made Vapor awesome was the ability to easily deploy to Vapor Cloud in a couple of seconds. The service took care of certificate generation and subdomains, which made it perfect for prototyping backends used in iOS apps, which require TLS. Bringing you backend online was always just a `vapor cloud deploy` away.
Unfortunately, [it’s shutting down February 29th, 2020](https://docs.vapor.cloud/shutdown/), so we have to use another way to deploy our Vapor apps. I recently migrated my [PassKit business cards](https://github.com/xavierLowmiller/business-cards) to my company’s OpenShift platform, so I want to share my experiences working with Swift and Docker.

This article is aimed at developers who aren’t experts with Docker, such as iOS developers playing around with Swift on the server (like me). If you have never used Docker before, this guide should help you!

## Required software

+ [Docker for Mac](https://docs.docker.com/docker-for-mac/install/)
+ The `docker` CLI, which is available on homebrew: 
	```
	brew install docker
	```

## The Dockerfile

Every Vapor application that is created using `vapor new` comes with a fully configured Dockerfile (called `web.Dockerfile`) that works out of the box.

In it, two containers are created:

### The builder image:
This uses the official Swift image and contains all the tools necessary to build (and test) your app. 

### The production image:
This is standard Ubuntu LTS image that copies the build artifacts from the builder, but has none of the build tools, so it will be lighter.

## Building an image

To create the container, run the following command:

```bash
docker build -t app:latest --build-arg env=production -f web.Dockerfile .
```

This is what the arguments do:
+ `-t app:latest`: It’s customary to name a container, and this is the command to do so. Usually, the scheme `<name>:<version>` is used, for example `app:1.0`, `app:latest`, etc. If this option is omitted, a hash for the container is generated.
+ `--build-arg env=production`: Vapor apps have a few default environments (`production`, `development`, and `testing`) which can be checked for. It’s important to set this value, otherwise your app will crash on startup. You could also hardcode this value in the Dockerfile, or set the `ENVIRONMENT` env value when you run the image later.
+ `-f web.Dockerfile`: By default, the Dockerfile is just called `Dockerfile`. If that’s the case, this argument can be omitted, so you could rename `web.Dockerfile` and not pass the argument.

If everything works as planned, the terminal will report success:

```bash
Successfully built 4cb90e95b339
Successfully tagged ledger:latest
```

Let’s take the image for a spin!

## Running the image locally

```bash
docker run -p 8080:80 app:latest
```

You can now hit [localhost:8080](http://localhost:8080) and see your app!

In the Dockerfile, the Vapor app is started on port 80 by default, but that only concerns the container. The `-p 8080:80` argument is necessary to access the port from the outside.

You’ll notice that `cmd+.` and `ctrl+C` won’t stop the Docker process. You can list all containers and use a separate command to stop it again.

```bash
docker container ls
docker stop 00ec27eaafa0
```

Note that this doesn’t remove the container, but only stops it. Remember to run `docker system prune` from time to time to clean up dead containers.

## Deploying

After your image is built, you can publish it to a cloud provider using `docker push <url>`. You probably need to follow some sort of authentication, but that process typically is well documented (at least [OpenShift](https://blog.openshift.com/getting-started-docker-registry/) is).

Choosing a provider is really up to you, and most (all?) of them support Docker in this day and age. Many of them have a free tier available.

## More thoughts

Here’s some things that helped me get started:
+ The Docker Dashboard and Kitematic are great GUI tools to see what Docker is up to. It’s also good for setting environment variables and exposing ports.
+ Restarting a container wipes data unless storage is configured. This, however, is another blog post.
+ Docker is a power tool. It might seem hard to get started, but people who are more experienced are usually willing to help with the basics. Almost none of this is Swift-specific after all.

## Conclusion

Having Swift and Docker play nicely is an important step on the road to ubiquitous Swift. Having an environment like Docker that is completely agnostic of the language and processes running in them enables developers to use their favorite language anywhere.
This article is meant as a Getting Started guide that takes you from knowing nothing about Docker to successfully deploying to a cloud provider.
