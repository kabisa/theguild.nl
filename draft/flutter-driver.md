# Extending Flutter Driver with custom commands

[Flutter Driver](https://flutter.dev/docs/cookbook/testing/integration/introduction) is a library to write end-to-end integration tests for Flutter apps. It's similar to Selenium WebDriver (for web apps), Espresso (for native Android apps) and Earl Grey (for native iOS apps). It works by instrumenting the Flutter app, deploying it on a real device or emulator and then 'driving' the application using a suite of Dart [tests](https://pub.dev/packages/test).

A typical, basic Flutter Driver test looks like this:

```dart
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Counter App', () {
    final counterTextFinder = find.byValueKey('counter');
    final buttonFinder = find.byValueKey('increment');

    FlutterDriver driver;

    // Connect to the Flutter driver before running any tests.
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    // Close the connection to the driver after the tests have completed.
    tearDownAll(() async {
      driver?.close();
    });

    test('starts at 0', () async {
      expect(await driver.getText(counterTextFinder), "0");
    });

    test('increments the counter', () async {
      await driver.tap(buttonFinder);
      
      expect(await driver.getText(counterTextFinder), "1");
    });
  });
}
```

In the `setUpAll` hook a connection between the test and the running application is setup via the Flutter Driver API. This works because the application is instrumented with a Flutter Driver extension; basically an API injected into your app that can receive requests from our tests to "drive" the application.

The instrumentation of the Flutter app works by wrapping your app's `main` function like this:

```dart
import 'package:flutter_driver/driver_extension.dart';
import 'package:my_app/main.dart' as app;

void main() {
  enableFlutterDriverExtension(); // <-- ENABLE INSTRUMENTATION
  app.main();
}
```

Flutter Driver supports a handful of API's to communicate with the running app. For example `getText`, `tap`, `waitFor` etc. For me, coming from [Nightwatch.js](http://nightwatchjs.org/), the number of things that can be done to drive the application is quite limited.

Fortunately it's possible to extend Flutter Driver to support custom commands. These commands allow you to communicate between your tests and the application and are also the foundation for all of Flutter Driver's own API's like `getText`, `tap` etc.

### Extending Flutter Driver

To extend Flutter Driver with a custom command we need to provide a [`DataHandler`](https://api.flutter.dev/flutter/flutter_driver_extension/DataHandler.html). As the docs say:

```
Optionally you can pass a [DataHandler] callback. It will be called if the
test calls [FlutterDriver.requestData].
```

Flutter Driver will pass whatever is sent from test with `driver.requestData(...)` to the DataHandler. DataHandler only supports sending and receiving Strings, so you might want to encode your messages using JSON.

To demonstrate this, let's implement a handler to navigate back to the root route of our app. This way we can ensure that every test starts from the root page of our application.

The first step is to provide a `DataHandler` to Flutter Driver:

```dart
enableFlutterDriverExtension(handler: (payload) async {
  print(payload);
});
```

The handler will receive a String payload and can optionally return a String response.

For the sake of simplicity let's use a String as payload for now:

```dart
enableFlutterDriverExtension(handler: (payload) async {
  if(payload == "navigate_to_root") {
    // do something smart here
  }
});
```

From here, we need to implement something that will allow us to navigate to the root of our app. I'm not sure if the following is necessarily the best way to do this (if you know a better way please let me know!), but it works and is relatively straightforward.

We'll use a [NavigationObserver](https://api.flutter.dev/flutter/widgets/NavigatorObserver-class.html) to get a hold of the [NavigatorState](https://api.flutter.dev/flutter/widgets/NavigatorState-class.html), which we can use to push and pop routes. We need to be able to pass in a NavigationObserver from our test entry point,  so we can access it when we receive a command to navigate to root.

Change the `main` function of your app as follows:

```dart
void main() {
  _main(null);
}

void mainTest(NavigatorObserver navigatorObserver) {
  _main(navigatorObserver);
}

void _main(NavigatorObserver navigatorObserver) {
  runApp(MyApp(
    navigatorObserver: navigatorObserver,
  ));
}

class MyApp extends StatelessWidget {
  final NavigatorObserver navigatorObserver;

  const MyApp({Key key, this.navigatorObserver}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // all other MaterialApp initialisation here
      navigatorObservers: navigatorObserver == null ? [] : [navigatorObserver],
    );
  }
}
```

This allows us to hook up a NavigationObserver from our test wrapper like so:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:my_app/main.dart' as app;

void main() {
  final navigationObserver = NavigatorObserver();

  enableFlutterDriverExtension(handler: (payload) async {
    if (payload == "navigate_to_root") {
      navigationObserver.navigator.popUntil(ModalRoute.withName('/'));
    }

    return null;
  });

  app.mainTest(navigationObserver);
}

```

Now from our tests we can send our custom command, for example in a `setUp` hook:

```dart
void main() {
  FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    driver?.close();
  });

  setUp(() async {
    await driver.requestData("navigate_to_root");
  });	

  /* Actual tests here */
}
```

This will make sure that before every test, the app navigates back to the root route no matter where we navigated to in our tests.

Of course, this is just an example of how you can implement communication between your Driver tests and your app. If you're going to send more complex commands that require arguments you might want to send JSON data, but I'll leave that as an exercise to you, dear reader ;-)
