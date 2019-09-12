---
layout: post
title: "iOS 13 Modal Presentation Styles"
date: 2019-09-12
---

As the release of iOS 13 draws near, it’s high time to update your apps to the latest SDK. One thing you will notice immediately (besides the new dark mode) is that all the modals are different.

There’s a great [WWDC video](https://developer.apple.com/videos/play/wwdc2019/224) that covers the design update. This post is meant to be a TLDR overview of the new modal styles.

By default, a UIViewController will have a `modalPresentationStyle` of `.automatic`. On iOS and iPadOS, this will mostly behave like `.pageSheet`.

## What’s actually happening here?

iOS 13 brings the `.pageSheet` style to modals on all iPhones in portrait orientation and makes it the new default. On earlier versions, `.pageSheet` only worked on some iPhones in landscape, such as on an iPhone 8 Plus:

![][ios 12 modals]

There are four common use cases for modals in iOS 13:

## iOS 12 Style:

To get back the iOS 12 style, just set the `modalPresentationStyle` back to `.fullScreen`, which used to be the default.

You can do this in a storyboard:

![][storyboard full screen]

Or programmatically:

```swift
let viewController = UIViewController()
viewController.modalPresentationStyle = .fullScreen
present(viewController, animated: true)
```

If you are using segues, it’s also possible to set this property in `prepare(for:sender)`:

```swift
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    segue.destination.modalPresentationStyle = .fullScreen
}
```

Using this style is a great idea for views that should take up the whole screen, for example when showing an image or reading modes.

## iOS 13 Page Sheet styles

The new iOS 13 only styles are more interesting, as they can be dismissed by pull down out of the box. There are different use cases that you might want to support:

### Pull To Dismiss

Great news: Since this is the new default (`.automatic`), you don’t have to implement anything!
The same effect can be achieved when you set the `modalPresentationStyle` to `.pageSheet`.

### Prevent Pull To Dismiss

In cases where the user should not be able to dismiss the modal just by swiping, but you still want the new page sheet style, dismissal can be prevented.

The simplest way to implement this style is to set the UIViewController’s `isModalInPresentation` flag to `true`:

```swift
final class NonDismissableViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        isModalInPresentation = true
    }
}
```

It’s also possible to set the `delegate` of the UIViewController’s `presentationController` and forbid the dismissal there:

```swift
final class NonDismissableViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
}
```

### Pull To Dismiss with Action Sheet Confirmation

If you want to support the user pulling to dismiss, but need to perform an action (such as ask for confirmation), you can hook into the dismissal attempt.

There is a new method in `UIAdaptivePresentationControllerDelegate` that will inform you that the user attempted to dismiss the modal by pulling down:

```swift
final class ActionDismissableViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        present(actionSheet, animated: true)
    }

    private var actionSheet: UIAlertController {
        let actionSheet = UIAlertController(
            title: "",
            message: "Discard Changes?",
            preferredStyle: .actionSheet
        )
        actionSheet.addAction(.init(
            title: "Yes", 
            style: .destructive, 
            handler: { _ in self.dismiss(animated: true) }
        ))
        actionSheet.addAction(.init(
            title: "No", 
            style: .default
        ))
        return actionSheet
    }
}
```

Note that `presentationControllerDidAttemptToDismiss` will only be called if `presentationControllerShouldDismiss` returns `false`.

## Working with `UINavigationController`

A common use case is to wrap view controllers inside of a navigation controller and present the navigation controller modally.

If you do that, be careful to set the *navigation controller’s* delegate (and not the delegate of the view controller contained inside.

Note that this only applies to the delegate, setting the `isModalInPresentation` property to `true` on the contained works 🤷‍♀️.

## Conclusion

It’s really simple to adopt the new modal styles once you know where to look. At first, it might seem confusing what properties to set, but this overview should help you.

As a user, I’m looking forward to having these in many apps!

[ios 12 modals]: {{ "/assets/2019-09-12-ios-12-page-sheet.png" }}
[storyboard full screen]: {{ "/assets/2019-09-12-storyboard-full-screen.png" }}
