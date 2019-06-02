---
layout: post
title: "Five Years of Swift: A Love Letter"
date: 2019-06-02
---
“The language is called Swift, and it totally rules.”
> Craig Federighi on June 2, 2014

Swift’s announcement came as a total surprise to me and everybody watching the WWDC keynote. Somehow, everyone at Apple managed to keep this language that Chris Lattner and others worked on [since 2010](https://github.com/apple/swift/commit/18844bc65229786b96b89a9fc7739c0fc897905e) a total secret (to me, it’s almost an even greater achievement to patiently go through [100 minutes of keynote speech](https://youtu.be/w87fOAG8fjk?t=6234) before telling the world about it).

It has been quite a ride, and I have some words for its fifth birthday.

## The first taste
In the winter semester of 2013, there wasn’t a lot of programming in the curriculum of my computer science studies, so I decided to take the [Stanford iOS course](https://web.stanford.edu/class/cs193p/cgi-bin/drupal/). Before learning about iOS, I had done some C# and Java during the first two semesters, so Objective-C was a bit foreign to me. It was, however, the perfect language for me to learn at the time. I had never really worked with pointers before, Foundation and UIKit have a lot of nice examples of software architecture that came in handy in later classes, and there was a plethora of material for me to read and learn from. At the end of the semester, I finished the course and decided to apply for an internship in iOS at a local company.

The phone interview was to take place on June 3rd. By this time, I was down with nil messaging. I started to grasp the big ideas behind the distinction of `NSString` and `NSMutableString`. I had even typed out my first `valueForKey:` calls.

And then came Swift.

After the keynote, the idea of learning a new language in preparation of the interview seemed a little … distressing. Immediately after the download of the Xcode 6 beta (which took hours on my home internet connection), I opened a Playground and started playing: There’s `let`. Xcode wants me to put exclamation marks everywhere. All the method names are strange all of a sudden. SourceKitService Crashed. Before I got the `map` function working, I went to bed.

(Of course, everyone on the interview had yet to try Swift. I got the job.)

During the internship, I got the chance to build a whole app in Swift 1.0. We never shipped this one before rewriting it in Objective-C, because of some code signing issues that I don’t quite remember. But by then, it was already a burden to go back to the old ways. I replaced `let` with `* const`, tuples became `NSDictionary`, and `map` on arrays turned into `valueForKey:`.

We didn’t really have a Swift project for a while, but on the side we played around with it a lot. Also in my studies, the Programming Languages class featured Swift: At the beginning of the course, the professor unveiled the languages we’d be working with: C/C++ (to learn about pointers and low-level stuff), JavaScript (to learn about interpretation and scripting languages), C# and Java (mainly for the JIT compilation), and Swift: To learn how C# and Java should be implemented, were they designed in 2015, and to see what the future will look like.

Naturally, I liked this class quite a lot, even though a lot of the Swift features we learned about (like tuples and value semantics on arrays) were controversial with my peers. I smiled when tuples, local functions, and pattern matching were touted as a big feature of [C# 7.0](https://devblogs.microsoft.com/dotnet/whats-new-in-csharp-7-0/).

## Swift 2 and opening up
At WWDC 2015, I was surprised to see the announcement of Swift 2.0. Nobody I knew really used Swift in production code, so seeing a major version bump on the language that still felt a little beta was strange to me.

The big features were protocol extensions (which I soon loved), and try/catch based error handling, which I had mixed feelings about. I had previously learned about the `Result` type and the error handling it enables, and discussed with many of my peers why Swift doesn’t need try/catch and why it’s a stupid idea in other languages.

Still the biggest announcement for Swift at WWDC was that it’s going to be open source. This enabled me to write my [bachelor's thesis](https://github.com/xavierLowmiller/Bachelorarbeit) on Swift (which is in German, sorry). It focuses on Swift’s memory management (ARC) and the Copy-on-Write implementations, which heavily use the reference counting mechanism to do its tricks. Writing it was one of the best times in my life, and I got through it pretty well. It was a lot of fun to dig through the source files and find out how everything works under the hood.

While I got an A on the thesis (yay!), the best thing about open source Swift is the discussion about new features. Imagine the incredible amount of change that Swift 3 brought without understanding the reasoning! I can now fully support many decisions (like the removal of C-style for loops), and accept others (like the removal of currying) because I see what made the team arrive at these decisions. This transparency is an invaluable asset that open source and especially the open discussion has brought to the Swift community.

An example of this is the try/catch error handling: After learning how it’s implemented in Swift, I now love it. I still despise the stack-unwinding madness and ‘anything can throw’ mentality of Java (much like I dislike the ‘anything can be null’ mentality).

## Swift 3 and becoming mainstream
During the Swift 3 era, we fully switched to using it over Objective-C. New projects were already started in Swift 2, but we had some legacy projects that we inherited at the agency I’m working at. In early 2017, we made the decision to port over all of them, which works quite well due to the incredible interoperability between Objective-C and Swift, especially when going from the former to the latter.

The impact this decision had on our work was profound. I don’t have a lot of data on bugs, issues, performance, etc., but a big plus was that our internal discussions shifted: Before, we were talking about peculiarities of Objective-C, and all its little gotchas. After making the switch to Swift, it was more about features and architecture.

This seems to also reflect in the broader Swift community: Swift was more and more adopted as the darling of the iOS community and posts that featured Objective-C were getting rarer as time went on. I’m not sure if books like [Advanced Objective-C](https://www.objc.io/books/advanced-swift/) would ever have happened. Many [blog posts](https://machinethink.net/blog/mixins-and-traits-in-swift-2.0/) talk about features that plainly weren’t available in the old world. Most of the issues that the Clang Analyzer is great at finding are simply impossible to write in Swift.

I sometimes jest that I learned everything I need to know about my job on Twitter. While I can’t really say how the community changed with the advent of Swift (because I wasn’t around to see much of it in the Objective-C days), I have never seen such a plethora of high-quality content to learn from. We are truly blessed to have such cool people publishing awesome stuff.

Another big thing that happened in the Swift 3 era is the release of [Vapor](https://vapor.codes). I love using Swift for iOS, and hope it has a place other realms in the future, like on the server. Using Vapor 1.0, we deployed a couple of smallish [web apps](https://github.com/xavierLowmiller/business-cards) to try it out a bit.

True to Swift’s nature, Vapor has had a lot of API and conceptual changes between its major versions, especially going from 2 to 3. Now that it’s based on SwiftNIO and lots of cool Swift 4 features like `Codable` and Key Paths, I think they have found their rhythm and the changes are going to be smoother in the future.

## Swift 4, 5, and the crazy and brilliant future
Speaking of smoother migrations, the Swift 4 migration across all our projects took less than an afternoon (yes, without migrating JSON parsing to use `Codable`). Lots of really cool stuff was introduced that we now take for granted (hello conditional conformance 👋), but it was still a much smoother upgrade than going from 2 to 3. By now I feel like Swift is the mainstream language for iOS apps, and it is stable enough to explore other realms.

I’m not quite sure it’s ready for [world domination](https://oleb.net/blog/2017/06/chris-lattner-wwdc-swift-panel/), but we’ve come a long way. Now that there’s support for Linux, Android, Windows, and many more, it’s time to spread the wings and set for new horizons.

In the future, I’m looking forward to an improved [editing experience outside of Xcode](https://nshipster.com/language-server-protocol/), and the shiny proposal for [asynchronous/concurrent programming](https://gist.github.com/lattner/31ed37682ef1576b16bca1432ea9f782) 🤩.

## To five years
Nothing seems to have had a bigger impact on my career so far (and my whole life, really) than Swift and its community and ecosystem. I couldn’t have imagined a better tool to work with these past years.

So cheers, cheers to five years! Thank you for making it great.

On to the next five!
