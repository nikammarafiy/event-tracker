# L360EventTracker

Let's say that you want an alert to pop-up when the user has opened your app 3 times, then takes an action within your app twice. How would you do it?

I would probably start off by adding a User Defaults key to keep track of app opens. Then I would have another User Default to keep track of the actions. (User Defaults, Core Data, whatever will persist even if the app is terminated). Then whenever the user takes that action, I'll do the logic to determine the times it's occurred and pop up the alert.

**Easy, why need L360Event tracker?**

It was an easy sample. You can do it in a matter of minutes. But then what if the logic changes and you need to keep track of one more user event? Or what if there is another alert for something else in your app? How many different actions and events can you keep track of before your code base is squigly with these one-off events?

## How L360EventTracker works

You register events during app start. Then you trigger these events at various parts of your app, kind of like placing pieces of code to log metrics for Flurry or Google Analytics.

Then you add an execution block that will be evaluated when any of the events it's listening for is triggered. If the evaluation returns true, it will execute the block of code.

### Events

To make things easy, there are three types of

## Installation

L360EventTracker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "L360EventTracker"
```

## License

L360EventTracker is available under the MIT license. See the LICENSE file for more info.
