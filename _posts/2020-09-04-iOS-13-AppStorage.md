---
layout: post
title: "Porting @AppStorage to iOS 13"
date: 2020-09-04
---

A couple of weeks ago, a few friends and I were out having beers. We told the barman to make sure our glasses are filled, and we’d figure the tap out later.
After a while, somebody said “you know, I’d love an app for my watch to keep track of how many I’ve had”. My answer was that for watchOS 7, that app would probably fit in a tweet, including persistence and all ([it didn’t](https://gist.github.com/xavierLowmiller/378e63c22aee6a07a650fe01305e2f6e), but it’s not so far off). When porting it back to watchOS 6, I noticed that the thing I missed most was the `@AppStorage` property wrapper.

While there’s a lot of `UserDefaults` wrappers out there, I couldn’t find one that had a 100% identical API to the “real” SwiftUI thing. So of course, [I had to write one](https://github.com/xavierLowmiller/AppStorage).

This post collects some of the obstacles and surprises I faced implementing it. While it’s specifically about `@AppStorage`, any property wrapper that implements a simple side effect can probably be implemented in a similar manner.

## Starting out

Since I had a specific target in mind, I started by copying the exact signature:
```swift
@frozen @propertyWrapper public struct AppStorage<Value> : DynamicProperty {
  public var wrappedValue: Value { get nonmutating set }
  public var projectedValue: Binding<Value> { get }
}
```

The thing that immediately caught my eye was the `nonmutating set`. It’s a modifier that is used very rarely in day-to-day Swift, but makes total sense: In SwiftUI, views are value types, and mutating them doesn’t make much sense. They just get copied on mutation, and nothing happens in the SwiftUI update engine since the original is just the same.
First I’ve tried wrapping an `@State` property, but that had some issues later. The trick here is to borrow from Swift’s Copy-on-Write types and make the backing storage a reference type:

```swift
private class Storage<Value>: ObservableObject {
  @Published var value: Value

  init(value: Value) {
    self.value = value
  }
}

struct AppStorage<Value> : DynamicProperty {
  @ObservedObject private var _value: Storage<Value>
  public var wrappedValue: Value { 
    get { _value.value }
    nonmutating set { _value.value = newValue }
  }
}
```

This way, the compiler is happy since mutations to the reference type don’t cause the struct itself to mutate, and SwiftUI will know to update views because of the `ObservedObject`. I image that `@State` is implemented similarly.

## Actually saving values

SwiftUI’s `@AppStorage` takes two arguments: A `key` (a simple String), and a `store` (an optional `UserDefaults` instance).

There are multiple initializers for all the types that are supported, such as:
```swift
extension AppStorage where Value == Int {

  public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) {
    let store = (store ?? .standard)
    let value = store.value(forKey: key) as? Value ?? wrappedValue
    self.init(_value: Storage(value: value), store: store, key: key)
  }
}
```

We can forward this store to the property wrapper so we can persistently store values as a side effect when setting new values:
```swift
struct AppStorage<Value> : DynamicProperty {

  @ObservedObject private var _value: Storage<Value>
  private let store: UserDefaults
  private let key: String

  public var wrappedValue: Value { 
    get { _value.value }
    nonmutating set {
      store.set(newValue, forKey: key)
      _value.value = newValue
    }
  }
}
```

This works quite nicely for simple types like `Int`, `String`, and `Bool`, that can be stored and retrieved from `UserDefaults` directly. In addition to those types, SwiftUI supports `RawRepresentable`s, such as enums and `URL`s. Since I was going for a 100% compatible API, I wanted to do this as well.

## A little type erasure

I was stuck at this point for a couple of days. There are two failures:
1. In the initializer, a cast from `Int` to an enum with RawValue `Int` fails: `store.value(forKey: key) as? Value` just never works.
2. There’s a crash when trying to set an enum in `UserDefaults`.

After some research, I found that this is a case for type erasure: Instead of directly casting to `Value` and writing that to `UserDefaults`, the property wrapper gets two closures: One for saving to and one for reading from `UserDefaults`. This way, there’s no need to know how to (de-)serialize arbitrary types: this information can be captured in the initializer, where we know which concrete type we’re dealing with:

```swift
extension AppStorage where Value : RawRepresentable, Value.RawValue == String {

  public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) {
    let store = (store ?? .standard)
    let rawValue = store.value(forKey: key) as? String
    let initialValue = rawValue.flatMap(Value.init) ?? wrappedValue

    self.init(_value: Storage(value: initialValue), saveValue: { newValue in
      store.setValue(newValue.rawValue, forKey: key)
    })
  }
}
```

This way, the property wrapper itself is becoming really simple, since it doesn’t even have to know about stores and keys anymore: All it needs is a way to somehow save new values:
```swift
public struct AppStorage<Value> : DynamicProperty {

  @ObservedObject private var _value: Storage<Value>
  private let saveValue: (Value) -> Void

  public var wrappedValue: Value {
    get { _value.value }
    nonmutating set {
      saveValue(newValue)
      _value.value = newValue
    }
  }
}
```

It would be easy to extend this idea to more types, such as all `Codable` types. Since the SwiftUI version doesn’t do this, I decided to leave it out (for now).

At this point I thought I was finished: I wrote some tests that ensured I have an identical API, and thought of wrapping up. Then I thought of the possibility of somebody changing `UserDefaults` without letting the property wrapper know (cruel, I know). SwiftUI’s property wrapper still works in this case, so I had to address it, too.

## Key-Value Observing the Store

Luckily, `UserDefaults` is compatible with KVO. It’s easy enough to work with in this case, but requires some things:
1. The observer must subclass `NSObject`
2. The observer must override `observeValue(forKeyPath:of:change:context)`
3. We must be careful to add and remove the observer correctly.
Since we’re already dealing with a reference type as our private backing storage, it can be used to support KVO here:

```swift
private class Storage<Value>: NSObject, ObservableObject {
  @Published var value: Value
  private let defaultValue: Value
  private let store: UserDefaults
  private let keyPath: String
  private let transform: (Any?) -> Value?

  init(value: Value, store: UserDefaults, key: String, transform: @escaping (Any?) -> Value?) {
    self.value = value
    self.defaultValue = value
    self.store = store
    self.keyPath = key
    self.transform = transform
    super.init()

    store.addObserver(self, forKeyPath: key, options: [.new], context: nil)
  }

  deinit {
    store.removeObserver(self, forKeyPath: keyPath)
  }

  override func observeValue(forKeyPath keyPath: String?,
                             of object: Any?,
                             change: [NSKeyValueChangeKey : Any]?,
                             context: UnsafeMutableRawPointer?) {

    value = change?[.newKey].flatMap(transform) ?? defaultValue
  }
}
```

Unfortunately, we have to pass the `UserDefaults` instance which we want to observe, the key we wish to observe on, and the type eraser closures to the backing storage, ruining much of the simplicity of before. I omitted the logistics here, but you can take a look in the [final implementation](https://github.com/xavierLowmiller/AppStorage/blob/main/Sources/AppStorage/AppStorage.swift): Most of the information that `Storage` requires is handed through `AppStorage`’s private initializer.

The upside is that the property wrapper now instantly updates SwiftUI views that depend on it, even if somebody sneakily changes (or deletes) things in the `UserDefaults` instance.

## Naming

Now, since the name `@AppStorage` clashes with SwiftUI’s own property wrapper, I had to change this property wrapper’s name: It’s called `@Persistence`, and I’m not really happy about that.

What I’d really like is some way to make the custom property wrapper go away in iOS 14, watchOS 7, and the likes:

```swift
@unavailable(iOS 14, watchOS 7, macOS 11, tvOS 14, *)
@propertyWrapper public struct AppStorage<Value>
```

…but this only works the other way around. You can make more types available for newer operating systems, but not remove them.

Another thing that would be cool would be a `typealias` based on operating system availability:

```swift
if #available(iOS 14, watchOS 7, macOS 11, tvOS 14, *) {
  typealias AppStorage = SwiftUI.AppStorage
} else {
  typealias AppStorage = Persistence
}
```

…but Swift doesn’t allow top-level statements like this.

If you have any idea about this, please [reach out to me](https://github.com/xavierLowmiller/AppStorage/issues/4)!

## Recap

I learned a couple of things while building my own version of SwiftUI’s `@AppStorage` property wrapper:
1. A simple struct wrapper around a reference type is a pattern Swift really likes, even beyond Copy-on-Write types.
2. Initializer overloads in combination with type erasure enables powerful generic patterns.
3. KVO is very useful, especially when contained in a private type.
4. Swift’s support for type-level programming can be improved.

That’s it for today! Please check out the [final implementation](https://github.com/xavierLowmiller/AppStorage), especially when you can’t drop iOS 13 yet but want the goodness of `@AppStorage`.