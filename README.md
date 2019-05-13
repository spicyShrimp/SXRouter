# SXRouter
Refactor hhrouter with swift language

## Usage

### Warm Up

Map URL patterns to viewController. Better in AppDelegate.

```swift
SXRouter.map(route: "/user/:userId/", vcClass: ViewController.self)
```

### Exciting Time
Get viewController instance from URL. Params will be parsed automatically.

```swift
SXRouter.matchToVC(route: "/user/1/")
```

### URL Query Params

URL Query Params is also supported, which will make things VERY flexible.

```swift
SXRouter.matchToVC(route: "/user/1/?tabIndex=3")
```

### One More Thing

If your app has defined some URL schemes, SXRouter will know.

```swift
SXRouter.matchToVC(route: "sxrouter://user/1/")
```
