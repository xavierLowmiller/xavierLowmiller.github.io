---
layout: post
title: "Configure Apps at Build Time"
date: 2018-11-18
---

In many modern, networked apps, dealing with multiple configurations is a fact
of life. Many backends in development have multiple stages with different
versions of the code or feature flags that all need to be supported by clients.
All of these stages have different URLs that need to be accsible by the iOS app.
This extends to API keys, private oauth keys, etc.

Xcode's Configurations seem like a natural fit for this:

![Xcode Configurations][]

There are, however, a couple of problems with this:

- Private information is now part of the repo.
You might not want to share all secrets with everybody who has access to 
the code base (especially if it is open source)
- Changing data in a config is a nontrivial task for developers 
not familiar with Xcode
- Mixing of orthogonal concepts:
What stages should be addressed with apps that have the `#DEBUG` flag on?
- It gets confusing: What is the difference between `Release` and `Production`?
- You have to re-run cocoapods each time you add, remove, or rename a config

To avoid these issues, sites like [iOS-factor][] recommend separating the config
from the code. Unfortunately, they don't provide an example on how to inject
configs at build time. This blog post does just that.

There will be multiple parts to this. Part one (this post) will detail how to
factor out configs from code and inject it during CI. Part two will show how
configurations can be changed at run time. In the third and final part, we will
implement a solution for over-the-air (OTA) updates.

## Step one: Extract all configs to a separate file

Extract all the things that can change between stages to a single file.
I chose JSON here because pretty much any build system can manipulate it easily,
(and it's much easier to feature in a blog post) but a property list can do the
job as well.

```json
{
    "backendUrl": "https://dev.example.com",
    "analyticsKey": "s3cr3t-k3y",
    "redesignedLoginEnabled": false
}
```

## Step two: Load the file and use the configs in the app:

Load the file and parse its data. I chose to include it using [NSDataAsset][]
because it loads trivially and applies a minimal layer of obfuscation to the
contents:

```swift
enum Configuration {
    private static let json: NSDictionary = {
        guard let data = NSDataAsset(name: "Config")?.data,
            let json = (try? JSONSerialization.jsonObject(with: data)) as? NSDictionary
            else { fatalError("Malformed config.json file") }

        return json
    }()
}
```

Notice that the actual dictionary is marked `private`. Since JSONs and property
lists don't have strong typing, I like to write accessors for the keys expected
in the config files:

```swift
extension Configuration {
    static var backendUrl: URL {
        guard let urlString = json["backendUrl"] as? String,
            let url = URL(string: urlString)
            else { fatalError("Invalid/missing backend URL") }

        return url
    }

    static var analyticsKey: String {
        guard let analyticsKey = json["analyticsKey"] as? String
            else { fatalError("Invalid/missing analytics key") }

        return analyticsKey
    }

    static var redesignedLoginEnabled: Bool {
        guard let redesignedLoginEnabled = json["redesignedLoginEnabled"] as? Bool
            else { return false }

        return redesignedLoginEnabled
    }
}
```

There's a lot of `fatalError` going on here. That's because I consider errors
in the config file programmer errors and there's no sensible way an app can
recover from a missing URL or key.
The exception here is the feature toggle, where you can easily provide a good
fallback value.

Once these accessors are in place, using the data from the config file is a
piece of cake:

```swift
Configuration.backendUrl // https://dev.example.com
Configuration.analyticsKey // s3cr3t-k3y
Configuration.redesignedLoginEnabled // true
```

## Step three: Modify the config file from CI

The idea here is to modify the JSON file before building the app.
How you do this really depends on what CI system is in place. We use fastlane,
so here's how you modify JSON in Ruby:

```ruby
path = '/path/to/app/Assets.xcassets/Config.dataset/config.json'
file = File.read(path)
json = JSON.parse file
json['backendURL'] = 'https://test.example.com'
json['analyticsKey'] = 'k3y-for-t3st1ng-3nv'
File.open(path, 'w') { |file| file.write(JSON.pretty_generate json) }
```

This example sets the values in code, but you might as well read them from an
ENV or pass it to the build script some other way.

## Recap

In today's article, we learned how to extract app configurations from the code.
Once all the configurations are isolated to the `config.json` file, there's no
more need to include URLs or secrets in the repository.

If you're worried that you might forget to set a required value in the file
when running the code locally, you can generate [Xcode warnings][] in a build
script to inform you about the missing keys.

[Xcode Configurations]: {{ "/assets/2018-11-18-Xcode-Configurations.png" }}
[iOS-factor]: https://ios-factor.com/config
[NSDataAsset]: https://nshipster.com/nsdataasset/
[Xcode warnings]: https://github.com/spacepandas/cineaste-ios/pull/42
