---
layout: post
title: "Evaluating Dependencies"
date: 2018-09-19
---

As software engineers, we stand on the shoulders of giants. We are so far from
the iconic Ones and Zeros that our profession is supposedly all about. Sure,
sometimes we write some C code (which, as a Swift developer, might as well be
assembly), but C is already so many layers away from the metal you can barely
see the ground.

With many of today's technologies, it doesn't make sense to even consider not
using them. Sure, you might be able to write an iOS app in pure C (or even
assembly) without using UIKit, but this has little more merit beyond the
[academic exercise][Link to C iOS app].

With the open source movement, it's common to rely on the code other people
publish. Package managers like Cocoapods and Carthage make this easy for us.
Maven Central offers <x> packages to JVM developers.
Our friends in web development are the butts of many npm-related jokes.

The maintainers on GitHub are our modern giants.

The difference here is that we have a choice. And whenever we have a choice,
there are tradeoffs. <Insert Kent Beck here>

This post lists the questions I ask myself before dropping in a framework.

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

So, try to start with no by default:
Implement that bar chart yourself before you pull in a 
[feature-rich 17000 LoC package][Charts].
Consume your 3 endpoints using URLSession instead of Alamofire.

You can always say yes to the dependency later, when things get more complex.

Don't write your own cURL logger.
Don't invent you own asynchronous image cache.
And, whatever you do, don't implement cryptography yourself
(unless you really know what you're doing).

## Is it well maintained?

Alamofire currently has 439 unit test cases.

Should your home grown network stack pass most of these? Do you think it does?

The benefit of unit testing goes beyond ensuring the (future) quality of a
software project.
It's a sign that the project is intended for the long game.
It's a sign that people thought about their APIs. 
It's a sign that somebody cares.

This extends to other marks of quality.
Look for documentation, roadmaps, [project vision][Moya Vision], 
and general health.
Carthage (or even SPM) support is also a mark of quality to me.

Dependencies have bugs, too.
When you add a dependency, these bugs become your bugs affecting your users.

## What happens if you take it away?

You should always have a backup plan.

<blockquote class="twitter-tweet" data-lang="en">
<p lang="en" dir="ltr">Much of the debate about whether or not to use 3rd party 
frameworks disappear when teams take ownership of their dependencies.<br><br>
Open source != a support contract. If you’re not prepared to fix issues in your 
dependencies then they’re basically tech debt the minute you add them 🙂</p>
&mdash; John Sundell (@johnsundell)
<a href="https://twitter.com/johnsundell/status/1041669114882940928?ref_src=twsrc%5Etfw">
September 17, 2018</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

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

[Some libraries][RxSwift] can have a steep learning curve for you and your team.
Others are tough to integrate, to update, or to maintain during 
operating system upgrades.

Always run a cost/benefit analysis in your head to see if a dependency is
actually making your life easier, or harder.

## Does it have dependencies?

Dependencies tend to require even more dependencies.
You have to decide if you agree with the choices.
Since you never really asked for these, you typically
don't get much benefit from them while having to pay all the costs.

Furthermore, some clients require all dependencies to be audited.
Can this be done for the hundreds of npm packages that [React Native][]
depends on?

## Recap: A handy chart of some dependencies I use

|                                   | Result | RxSwift | Moya |   |
|-----------------------------------|--------|---------|------|---|
| Are you going to need it?         |    🚫  |         |      |   |
| What happens if you take it away? |        |      🚫 |      |   |
| Is it worth the cost?             |        |      ✅ |    ✅ |   |
| Does it have dependencies?        |     0  |      0  |    ⚠️ |   |

---

[Alamofire]: https://github.com/Alamofire/Alamofire/blob/master/README.md#features
[Getting Real]: https://basecamp.com/books/Getting%20Real.pdf
[Charts]: https://github.com/danielgindi/Charts
[Parse Shutdown]: https://duckduckgo.com/?q=parse+shutdown
[Moya Vision]: https://github.com/Moya/Moya/blob/master/Vision.md
[Result Pod]: https://github.com/antitypical/Result
[RxSwift]: https://github.com/ReactiveX/RxSwift/blob/master/Documentation/GettingStarted.md#getting-started
[Realm]: https://github.com/realm/realm-cocoa
[React Native]: https://facebook.github.io/react-native/
