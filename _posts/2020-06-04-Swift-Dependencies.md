---
layout: post
title: "What Adding Dependencies Will Do To Your App in 2020"
date: 2020-06-04
---

With Xcode 11’s support for Swift Package Manager and the coming changes in Swift 5.3, there’s a lot of discussion on what dependency manager to use. I’d like to take you on a tour to see what happens to an app when dependencies are managed using the various tools.

To do this, I measured various metrics around dependencies to see what adding dependencies looks like in the various options in 2020.

Dependency Management has come a long way on iOS. In the early days, it was expected to manually add libraries and frameworks, and update them by hand. Git Submodules can be of some help here, but integrating them into Xcode projects is still tedious.

## The managers

### CocoaPods

As the community grew and more libraries were written, discoverability was another concern. Enter CocoaPods, which fixed all these problems: There’s a central index where pods can be discovered, and the integration into projects is now a breeze.
The value of CocoaPods to the iOS community cannot be described by words. It’s such a great example of what a community can do, and has been the de facto default package manager for iOS projects for years.
Its impact on the whole iOS ecosystem can’t be overstated. The [website](https://CocoaPods.org) is the go-to place for discovering iOS dependencies. Publishing a library or framework for iOS without CocoaPods support is barely imaginable.

This is the Podfile used for the experiments can be found [here](https://github.com/xavierLowmiller/Swift-Dependency-Analysis/blob/main/Cocoapods/Podfile).

### Carthage

Shortly after Swift came around, Carthage was born. It’s written in Swift itself, and has some [different opinions](https://www.quora.com/CocoaPods-is-opinionated-whereas-Carthage-is-not-Why-does-that-make-it-better-What-specific-problems-did-the-Carthage-authors-experience-with-CocoaPods?share=1) than CocoaPods. It focuses on simplicity and ease of understanding how it works. This means there’s less magic, both in the good and in the bad sense.
It’s the simple ([not easy](https://www.infoq.com/presentations/Simple-Made-Easy/)) dependency manager for Swift projects. There’s some beautiful ideas behind Carthage, like being decentralized and imposing as few changes to your Xcode project as possible.
There’s a [great writeup](https://github.com/Carthage/Carthage#differences-between-carthage-and-CocoaPods) on their GitHub page that I don’t need to repeat here. The bottom line is that it’s simpler than CocoaPods but doesn’t have (and won’t ever have) as many features. This makes the setup a little more work, but once it’s done it’s unlikely to need adjustments in the future.

This is the Cartfile used for the experiments can be found [here](https://github.com/xavierLowmiller/Swift-Dependency-Analysis/blob/main/Carthage/Cartfile).

### Swift Package Manager

The new kid on the block for dependency management on iOS. 
At WWDC 2019, Apple announced that the Swift Package Manager (which has been around since late 2015) would be fully integrated in Xcode and could manage iOS projects. This is big news for a platform that never had a truly official package manager!
A lot of popular libraries have since adopted SPM and it’s only going to grow bigger as important features land in SPM in Swift 5.3, such as [support for assets](https://github.com/apple/swift-evolution/blob/master/proposals/0271-package-manager-resources.md).

## Alternatives Considered

In this post, I drilled down the most popular ways to manage dependencies using their most basic configurations. But of course, there’s many more ways to manage dependencies.

### Manual Dependency Management

A.k.a. just adding files to your project. It would have been nice to do this so I could have a baseline without any kind of module/framework/Swift Package for the measurements.
This probably works nicely with single-file dependencies ([RNCryptor even recommends this technique](https://github.com/RNCryptor/RNCryptor#installing-manually)), but managing more complex dependencies is tedious, especially since there’s not way to easily update things.
I tried this, but it’s just not feasible with so many dependencies, I had too many name clashes and other issues, like libraries expecting to be embedded in modules.

### Git Submodules

The dependency manager when there is no dependency manager. The idea here is to add projects as git submodules and integrate their .xcodeproj files into your project’s project file or workspace.
This is a lot of setup work, and should have similar results as CocoaPods.

### CocoaPods with static libraries

In the early days of Swift, it was only possible to package Swift Modules as dynamic frameworks. This is still the default for most CocoaPods, so I used that in my measurements.

## The dependencies

To do my measurements, I chose 10 dependencies that should be a somewhat realistic mix of popular libraries. They must be compatible with all dependency managers and for simplicity’s sake should be on GitHub. Some of them have dependencies themselves. They range from small (Reachability.swift, 1 file, 275 LoC) to large (RxSwift, 141 files, 10330 LoC).  

Here’s the list:
- [Alamofire](https://github.com/Alamofire/Alamofire)
- [Eureka](https://github.com/xmartlabs/Eureka)
- [Moya](https://github.com/Moya/Moya)
- [PromiseKit](https://github.com/mxcl/PromiseKit)
- [Reachability](https://github.com/ashleymills/Reachability.swift)
- [ReSwift](https://github.com/ReSwift/ReSwift)
- [RNCryptor](https://github.com/RNCryptor/RNCryptor)
- [RxSwift](https://www.github.com/ReactiveX/RxSwift)
- [Starscream](https://github.com/daltoniam/Starscream)
- [Yams](https://github.com/jpsim/Yams)

All measurements were done on my developer machine, a MacBook Pro (15-inch, 2017), using Xcode 11.5 and iOS 13.5. If you’d like to follow along, all of my experiments are [on GitHub](https://github.com/xavierLowmiller/Swift-Dependency-Analysis).

## Round 1: App Launch Times

Historically, app launch speed has been negatively impacted, especially if you [have a lot of libraries](https://github.com/artsy/eigen/issues/586). With the arrival of [dyld 3](https://developer.apple.com/videos/play/wwdc2017/413/), a lot has changed here. Let’s see if launch times are still an issue for todays iOS dependency setups.

I tested this using the new default launch test on both a physical iPhone 11 Pro as well as the iOS Simulator.

This is the test case:
```swift
func testLaunchPerformance() throws {
  measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
    XCUIApplication().launch()
  }
}
```

The hypothesis is that an app with 10 dependencies launches slower than an app that has no dependencies at all.
The results, however, show that there is no longer much of a measurable impact:

|               | No dependencies | CocoaPods | Carthage | SPM                   |
| ------------- | --------------- | --------- | -------- | --------------------- |
| iPhone 11 Pro | 1.009s          | 1.021s    | 1.105s   | 1.032s                |
| Simulator     | 1.056s          | 1.105s    | 1.118s   | 1.080s                |

There’s still a little difference between the different methods, but that can very well be a measurement error. All setups that use dependencies launch a little slower than the “No dependencies” setup, but it’s not any serious amount of time. At 10 dependencies, it’s probably not worth optimizing for.

**Winner**: Tie!

## Round 2: App Size

App download size has always been an important metric, especially before Apple effectively dropped the mobile app download size limit.

Let’s find out how integrating dependencies will affect your app’s size!

### Round 2a: xcodebuild build

Running `xcodebuild` will create a build product in the DerivedData directory that basically is a runnable app. We use this command to generate it:

```bash
xcodebuild build \
  -quiet \
  -scheme Dependencies \
  -configuration Release \
  -derivedDataPath DerivedData
```

We can measure the file size of the artifact using `du`:

```bash
du -sh DerivedData/Build/Products/Release-iphoneos/Dependencies.app
```

Here are the results:

|                        | No dependencies | CocoaPods | Carthage | SPM                   |
| ---------------------- | --------------- | --------- | -------- | --------------------- |
| Total Size             | 140 KB          | 14 MB     | 84 MB    | 12 MB                 |
| Executable Size        | 104 KB          | 104 KB    | 104 KB   | 12 MB                 |
| Frameworks Folder Size | No Frameworks   | 14 MB     | 84 MB    | No Frameworks         |

84 Megabytes! Yikes!

I measured the binary executable size separately from the `Frameworks` folder, which are the two places where compiled code lives.
It looks like SPM wins this round, but apps are normally not distributed in a universal, uncompressed way.
Let's see what a thinned app looks like!

### Round 2b: App Thinning

iOS 9 introduced [App Thinning](https://developer.apple.com/videos/play/wwdc2015/404/), which is a technique to reduce .ipa file sizes: By default, the App Store will generate specialized versions for each kind of device, stripping away unneeded assets and executable code. Let’s see how using App Thinning changes the numbers!

First, we build and export an archive so we can export thinned apps locally:

```bash
xcodebuild archive \
  -quiet \
  -scheme Dependencies \
  -configuration Release \
  -archivePath 'DerivedData/archive.xcarchive' \
  -derivedDataPath DerivedData
```

Then, we can build thinned versions for specific devices:

```bash
xcodebuild build \
  -quiet \
  -configuration Release \
  -exportArchive \
  -archivePath 'DerivedData/archive.xcarchive' \
  -exportPath 'DerivedData/thinned-ipa' \
  -exportOptionsPlist ../exportOptions.plist
```

The `exportOptions.plist` contains the [device identifier](https://www.theiphonewiki.com/wiki/Models#iPhone) of the model we’d like to thin for, in this case it’s an iPhone 11 Pro:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>thinning</key>
        <string>iPhone12,3</string>
</dict>
</plist>
```

This will create a thinned, zipped .ipa file that we can measure again:

|                        | No dependencies | CocoaPods | Carthage | SPM                   |
| ---------------------- | --------------- | --------- | -------- | --------------------- |
| Total Size             | 24 KB           | 2.1 MB    | 2.2 MB   | 1.7 MB                |
| Total Size (unzipped)  | 136 KB          | 6.2 MB    | 6.5 MB   | 5.0 MB                |
| Executable Size        | 88 KB           | 88 KB     | 88 KB    | 5.0 MB                |
| Frameworks Folder Size | No Frameworks   | 6.4 MB    | 6.0 MB   | No Frameworks         |

This is a pretty neat result! Carthage still produces the largest artifacts, but it’s nowhere near the difference as in the un-thinned test.
SPM is definitely a good option when in comes to size, as it produces the smallest files. The ipa produced here is around 20% smaller than the others.
This might be due to embedding dependencies statically, so a similar result can might be achieved using CocoaPods in the static library mode.

**Winner**: Swift Package Manager!

## Round 3: Build Times

Having fast feedback from CI and quick builds on developer machines is always a goal worth spending time on. Let’s see how the different package managers perform!

I measured the following things:

- Dependency Resolution
- Clean Build
- Incremental Build
- Dependency Resolution + Build (a.k.a. What you’d do in CI)

|                       | No dependencies | CocoaPods | Carthage | SPM                   |
| --------------------- | --------------- | --------- | -------- | --------------------- |
| Dependency Resolution | -               | 1m 38s    | 13m 25s  | 2m 23s                |
| Clean Build           | 3s              | 1m 10s    | 5s       | 1m 20s                |
| Incremental Build     | 2s              | 3s        | 2s       | 3s                    |
| DR + Build            | 3s              | 2m 32s    | 12m 39s  | 2m 31s                |

The clear outlier here is Carthage. With it building all the frameworks during the dependency resolution phase (which is far slower than the others), it wins at clean builds.

During day-to-day development (where you’re mostly doing incremental builds), there’s almost no difference, at least in this rather artificial project.

Please take these results with a grain of salt. There’s no caching involved, so especially the CI use case is probably not a realistic scenario.

**Winner**: Hard to say, but probably Cocoapods with Swift Package Manager as a close second.

## Conclusion

Things are looking pretty good for Swift Package Manager. It produces small binaries and builds as fast as Cocoapods. Once all your dependencies are available on SPM, there’s no reason not to switch to it.
That said, all three dependency managers I compared are definitely viable in 2020, so there’s also no compelling reason to change dependency managers.

I think it ultimately comes down to team preference or some nuances from the random tidbits section which one they should use, with Swift Package Manager being my recommendation if you can get away with it.

## Random Tidbits

- [XcodeGen](https://github.com/yonaskolb/XcodeGen) can make the initial Carthage setup a breeze
- When running on CI such as GitHub Actions, strongly consider [caching your dependencies](https://github.com/actions/cache/blob/master/examples.md#swift-objective-c---carthage)
- Many people have been bitten by CocoaPods when merging branches or updating pod versions
- Both Carthage and SPM don’t require any ruby setup on the build machines
- In fact, SPM works with Xcode out of the box! If CI simplicity is a concern, consider using SPM
- SPM doesn’t give you the option to check in dependencies out of the box
- Some “important” dependencies like [Firebase](https://github.com/firebase/firebase-ios-sdk) don’t support all package managers (yet)
- SPM is pretty GUI-heavy, there’s no straightforward way to use CLI to manage dependencies
