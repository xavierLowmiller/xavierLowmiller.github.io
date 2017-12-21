---
layout: post
title: "Reliable UI Tests"
date: 2017-07-17
---

Xcode's UI testing framework is a marketer's dream: You can generate a comprehensive test suite that has a fantastic code coverage by recording a few taps *without any coding knowledge*.

If this sounds to good to be true, it is. UI tests in Xcode have the notion to be remarkably flaky. This has a number of reasons:

  - They usually hit the network
  - It's hard to stub out dependencies
  - Long run times make them unwieldy to debug

You shouldn't discard the idea of UI tests entirely: There are further reasons to test your app with UI tests: Aside from the obvious benefits of testing (like preventing regressions) you can check with betas of major OS updates if your app will still work in the future. Also, they are the driver for the great [fastlane snapshot](https://github.com/fastlane/fastlane/tree/master/snapshot) action.

Let's find out how we can make up for some of the drawbacks.

## The Network

Hitting the network violates multiple of the [F.I.R.S.T.](https://www.objc.io/issues/15-testing/bad-testing-practices/) principles of unit testing: Your tests obviously will be slower if they need to make calls to a remote entity. Also, your tests now also depend on the server, its dependencies, the network, VPN setups, maybe even Wifi connections, all of which doesn't exactly benefit the repeatability and isolation benefits.

The best way to kill all of the problems of the network is to kill the network.

There is a number of ways this can be done: You could run your tests against some `localhost` server that answers your requests as intended. Also, you could stub all of your requests in iOS itself using [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs).

My preferred way of stubbing these days is [Moya](https://github.com/Moya/Moya). It is written and maintained by great people, uses [Alamofire](https://github.com/Alamofire/Alamofire) under the hood, and plays nicely with other popular libraries (such as [RxSwift](https://github.com/Moya/Moya/blob/master/docs/RxSwift.md), [ReactiveSwift](https://github.com/Moya/Moya/blob/master/docs/Examples/ReactiveCocoa.md), and [Argo](https://github.com/wattson12/Moya-Argo))

But the best part is that it goes a long way to force you to provide stub data for every endpoint. When you [define](https://github.com/Moya/Moya/blob/master/docs/Examples/Basic.md) your list of endpoints, Moya requires you to provide a `Data` struct for each endpoint you want to call:

```swift
var sampleData: Data {
  switch self {
  case .endpoint1:
      return "A string encoded as Data".utf8Encoded
  case .endpoint2:
      return "{\"a\": \(json), \"as\": \"data (inline)\"}".utf8Encoded
  }
}
```

But I usually like to save a separate JSON with the intended return data, which I load using the following helper function:

```swift
func loadJSON(named name: String) -> Data? {
  guard let path = Bundle.main.path(forResource: name, ofType: "json")
    else { return nil }

  return try? Data(contentsOf: URL(fileURLWithPath: path))
}

// Usage:
var sampleData: Data {
  switch self {
  case .endpoint:
    return loadJSON(named: "user")!
  }
}
```
