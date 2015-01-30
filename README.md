# Nodelike [![Build Status](https://travis-ci.org/node-app/Nodelike.png?branch=master)](https://travis-ci.org/node-app/Nodelike) [![Coverage Status](https://coveralls.io/repos/node-app/Nodelike/badge.png?branch=master)](https://coveralls.io/r/node-app/Nodelike?branch=master) [![Gitter chat](https://badges.gitter.im/node-app/Nodelike.png)](https://gitter.im/node-app/Nodelike)

_Nodelike_ the core framework of the _Node.app_ project. The _Node.app_ project has the goal to implement a roughly Node.JS-compatible interface using JavaScriptCore.framework on iOS 7 and OS X Mavericks.

(JavaScriptCore hasn't been available before iOS 7, and on OS X the project makes extensive use of the newly-updated 10.9-only Objective-C API. Previously on 10.8 there existed only a very low-level and very verbose C API.)

This is currently in an incomplete state, and not yet viable for serious use.


## The goals

_Node.app_ aims to provide a way to create or enrich applications for iOS and OS X Mavericks using Javascript with a Node.JS-compatible API. This will be done lightweight manner, because Node.app utilises the JavaScriptCore system framework and doesn't need to bundle a heavy-weight third-party javascript engine.

Specifically the goals are:

- to be _drop-in compatible_ with node.js 0.11.11
- to be _very lightweight_
- to _reuse javascript code from node_ (/lib)
- to provide the _most minimal binding_ that is possible (via libuv)
- NOT to archieve Node.js performance (this is meant as a client-side, not a server-side application)
- NOT to be backwards-compatible (newest iOS/OS X required)


## How it compares to existing approaches

### node-webkit

The [_node-webkit_](https://github.com/rogerwang/node-webkit) project lets you create desktop applications for OS X by combining a Chromium web view with the Node.js project, both using the V8 javascript engine.

The _Node.app_ project also lets you create desktop applications for OS X, but by enriching a JavaScriptCore context (e.g. a WebKit web view context) with Node.js-compatible interfaces. By doing that, the resulting applications are **more lightweight**, since no engine needs to be bundled. Another important difference is that applications using _Node.app_ technology are **fully AppStore compatible**, unlike _node-webkit_ applications.

### MacGap / Phonegap-mac

The [_MacGap_](https://github.com/maccman/macgap) project provides a way to create desktop applications for OS X using JavaScript. It enriches a WebKit context with functions to operate OS X desktop functions, such as hiding/closing/resizing windows, playing sound or operating the dock.

As such, it can be combined with the _Node.app_ project, to get the best of both worlds, Node.js compatibility as well as OS X specific desktop functions.

### Apache Cordova / PhoneGap

[_Apache Cordova_](https://cordova.apache.org/) is a set of device APIs that allow a mobile app developer to access native device function such as the camera or accelerometer from JavaScript.

Apache Cordova is available for multiple platforms, but when focussing on the iOS platform, it too can be combined with the _Node.app_ project to get the best of both worlds.

## What's working right now

- `console.log()`
- `process`: `.argv`, `.env`, `.exit()`, `.nextTick()`
- `require()`
- `fs`
- `net`
- `http`
- `timers`
- `util`
- `url`
- `events`
- `path`
- `stream`
- `querystring`
- `punycode`
- `assert`

## Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C. See the ["Getting Started" guide for more information](https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking).

### Podfile

```ruby
pod 'Nodelike', :git => 'https://github.com/node-app/Nodelike.git', :branch => 'stable', :submodules => true
```

## How to compile

You most likely want to use the stable brach, by `git checkout stable`.

You then need to fetch the nodejs submodule. Do so by:
1. `git submodule init`
2. `git submodule update`

Afterwards, just open `Nodelike.xcodeproj`, build the framework and you're all set!

## How to use

First, attach Nodelike to a Javascript Context by `NLContext#attachToContext:(JSContext *)`. This exposes the Node APIs to the global object of the context.

You can then execute some javascript via `JSContext#evaluateScript:(NSString *)`.

Afterwards, you need to run the event loop via `NLContext#runEventLoopSync` or `NLContext#runEventLoopAsync`.

In the end, when you executed all scripts you wanted to, you can simulate the shutdown of the Node.js process via `NLContext#emitExit:(JSContext *)`.

For more information, [take a look at the wiki](//github.com/node-app/Nodelike/wiki).
