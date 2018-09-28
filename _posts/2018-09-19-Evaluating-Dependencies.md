---
layout: post
title: "Evaluating Dependencies"
date: 2018-09-19
---

`<Some interesting introduction paragraph>`

## Peks & Problems

As in all things in software engineering, there are tradeoffs:

### Perks

* Access to well-written, well-tested code
* Code reuse
* Consistency across projects

### Problems

* You give up sovereignty
* Things you own end up owning you
* They tend to break when updates happen

When choosing dependencies, you want most of the perks while avoiding problems.
Here are some questions you should ask:

## Are you going to need it?

Here are some features of [Alamofire][]:
* `multipart/form-data` upload
* Pause and resume network requests
* Request Retrying
* cURL command output
* TLS certificate pinning

While all of these are handy and I wouldn't want to implement this myself,
you should take a moment and consider. <br>
To quote *Start With No* from [Getting Real][]:
> Each time you say yes to a feature, you’re adopting a child.
> You have to take your baby through a whole chain of events
> (e.g. design, implementation, testing, etc.).
> And once that feature’s out there, you’re stuck with it.
> Just try to take a released feature away from customers and
> see how pissed off they get.

The same is true for dependencies.
They are much harder to remove than to add to a codebase.
You wouldn't believe in what ways an app can depend on libraries,
and what breaks when you remove them.

So, I try to start with no by default:
Implement that bar chart yourself before you pull in a 
[feature-rich 17000 LoC package][Charts].
Consume your 3 endpoints using URLSession instead of Alamofire.

You can always say yes to the dependency later, when things get more complex.

## Does it have tests?

Alamofire currently has 439 unit test cases.

Should your home grown network stack pass most of these? Do you think it does?

The benefit of unit testing goes beyond ensuring the (future) quality of a
software project.
It's a sign that the project is intended for the long game.
It's a sign that people thought about their APIs. 
It's a sign that somebody cares.

This extends to other marks of quality.
Look for documentation, roadmaps, project vision, and general health.
Carthage (or even SPM) support is also a big mark of quality to me.

Dependencies have bugs, too.
When you add a dependency, these bugs become your bugs affecting your users.

## What happens if you take it away?

You should always have a backup plan.

`<Tweet of John Sundell about support contracts>`

Ideally, you can take over the dependency by contributing or even becoming a
maintainer. This helps out other people, too.

In other cases, you can try to replace it with something of your own.
This is easy for a [Result][Result Pod], and hard-to-impossible for
Firebase (or [Parse][Parse Shutdown]).

Another important question here is:

Is it a framework or a library?

You call a library, but a framework calls you.

Libraries can be abstracted away and easily replaced.
Libraries like [Realm][] can be contained.
You can isolate all calls to it in a special module in your app.
When it goes away, you know what parts of your app will break.

Frameworks like [React Native][] will change the way you write code. 
This is the opposite of being contained.
When it goes away, all of your app will break.

## Is it worth the cost?

Some SDKs cost money.
While this should be considered, open source packages have a price as well:

[Some libraries][RxSwift] are harder to learn and integrate than others.
Others are tough to integrate, to update, or to maintain during 
operating system upgrades.

Always run a cost/benefit analysis in your head to see if a dependency is
making your life easier, or harder.

## Does it have dependencies?

Dependencies tend to require even more dependencies.
You have to decide if you agree with the choices.
Since you never really asked for these, you don't get much benefit from them
while having to pay the costs.

Furthermore, some clients require all dependencies to be audited.
Can you do this for the hundreds of npm packages that [React Native][]
depends on?

---

[Alamofire]: https://github.com/Alamofire/Alamofire/blob/master/README.md#features
[Getting Real]: https://basecamp.com/books/Getting%20Real.pdf
[Charts]: https://github.com/danielgindi/Charts
[Parse Shutdown]: https://duckduckgo.com/?q=parse+shutdown
[Moya Vision]: https://
[Result Pod]: https://
[RxSwift]: https://
[Realm]: https://
[React Native]: https://
