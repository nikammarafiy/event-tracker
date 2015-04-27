# L360EventTracker iOS

Let's say that you want an alert to pop-up when the user has opened your app 3 times AND takes an action within your app twice. How would you do it?

Maybe you would start off by storing information about number of app opens (Core data, User Defaults, etc.). Then you might have another to keep track of the actions. Then whenever the user takes that action, you do the logic to determine the times it's occurred and pop up the alert.

**"Easy, so why would I need L360EventTracker?"**

What if the logic changes and you need to keep track of one more user event? 
<br>What if there is another alert for something else in your app? 
<br>How many different actions and events can you keep track of before your code base is squigly with these one-off events?

### How L360EventTracker makes things easier

1. You register events on app start. 
2. Then you trigger these events at various parts of your app, kind of like logging metrics for analytics.
3. Register execution blocks that will be evaluated when any of the events it cares about is triggered. If the evaluation returns true, it will execute the block of code.

Using L360EventTracker, you can have a single place where all your exectuion blocks (usually for marketing) are registered, and little bits of triggers throughout the rest of your codebase, not blocking anyone's way. It is easily understandable, re-usable, and change-able.

Or lets say you get a remote push notification that you want to take some action in your app, but on startup you have some syncing to do or maybe you need to log-in the user first. You can then register a one-off event that will fire when the app has stabalized and you can take whatever action the push notification was supposed to take.

Or maybe you need something more flexible and customizable than iRate or Appirater? 

L360EventTracker is built for all those cases. An [example](https://github.com/life360/event-tracker/tree/master/L360EventTracker/L360EventTrackerExample) can be found in this repo.

## Installation

L360EventTracker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "L360EventTracker", :git => 'https://github.com/life360/event-tracker.git'
```

## Using L360EventTracker

L360EventTracker has two main components:
<br>1. Events
<br>2. Execution blocks

**Events** have an inital value and a current value. These are `id` values so can be `NSNumber` or `NSArray`, `NSDictionary`, etc.

**Execution blocks** are registered with an **evaluation block** and a set of events to listen for.

Anytime that the current value of the event is changed, this sets off the evalutation blocks that are listening to this event. If the evaluation block returns YES, then the execution block is ran.

### Events

```
[[L360EventTracker sharedInstance] registerEvent:@"numberActions" withInitialValue:@0 andScope:L360EventTrackerScopeSession];
[[L360EventTracker sharedInstance] registerEvent:@"numberOfBackgrounds" withInitialValue:@0 andScope:L360EventTrackerScopeApp];
```

To make things easy, there are **scopes** tied to each event. These help determine when the events are reset back to it's inital values. This comes in useful, trust us.
The scopes are:
* **L360EventTrackerScopeInstance**: These events are reset when the app is backgrounded (and of course if ever killed or uninstalled)
* **L360EventTrackerScopeSession**: These are reset when the app is killed. They act like static variables in your code.
* **L360EventTrackerScopeApp**: These are never reset unless you un-install the app. They're based on User Defaults.

Another necessary component to the event is the **initial value**. This is what the events will be reset to when they run out of their scope.

For L360EventTrackerScopeApp, re-registering the event will NOT reset the current value.

You should put these registrations as early in app run-time as possible so that they can be used as soon as possible. Registering the event multiple times within the same run-time will not change anything. Only the first registration in the app's run-time will count.

#### Triggering Events

You can trigger the events in two ways:
<br>1. You can trigger an event by calling `[[L360EventTracker sharedInstance] triggerEvent:@"numberActions"];`
<br>2. Or you can trigger an event by setting it's value with `[[L360EventTracker sharedInstance] setEvent:@"numberOfBackgrounds" withValue:@10];`

**triggerEvent:** is only useful for events that are type NSNumber and will increment the value of that event by 1. 
Otherwise for any other type it won't work. (Note: If you think it should be some way, please bring it up!)

#### Changing Events without Triggering

The following are self explanatory and they will **not** trigger any evaluations:
```
- (void)resetEvents;
- (void)resetEvent:(NSString *)event;
```

#### Reading Events

There are a few helper methods to quickly get the current value of events:
```
- (NSInteger)integerValueForEvent:(NSString *)event;
- (BOOL)boolValueForEvent:(NSString *)event;
- (NSArray *)arrayValueForEvent:(NSString *)event;
- (NSDictionary *)dictionaryValueForEvent:(NSString *)event;
```

If any of the events aren't the type that you're requesting (like you set the event with NSArrays but then try to call boolValueForEvent), or the event doesn't exist, they will return *nil*.

And for the ones with non-standard values (for example, NSValues are useful for encoding structs into Objective-C objects), you can use:
```
- (id)valueForEvent:(NSString *)event;
```

### Registering, Evaluating, and Running Executions

```
[[L360EventTracker sharedInstance] addExecutionBlock:^(NSString *triggerEvent, L360EventTracker *tracker) {
		// Do some action
	}
										whenValidated:^BOOL(NSString *triggerEvent, L360EventTracker *tracker) {
		NSInteger backgroundedCount = [tracker integerValueForEvent:@"numberOfBackgrounds"];
		NSInteger buttonTapCount = [tracker integerValueForEvent:@"numberActions"];

		if (backgroundedCount == 3 &&
			buttonTapCount == 2) {
			return YES;
		}

		return NO;
	}
									withExecutionID:@"actionExectuion"
								listeningToEvents:@[@"numberOfBackgrounds", @"numberActions"]
										keepAlive:NO
							validateImmediately:NO];
}
```

An execution block is registered with an array of events (**listeningToEvents**) that will trigger the evaluation block (**whenValidated**), which will determine whether the execution block should be run or not.

Normally once the block is added, it will remain in queue and the evaluation block will run repeatedly every time one of the events is triggered. When the evaluation block returns `YES`, the execution block will run and then be taken off the queue. To keep the execution block in queue, set `keepAlive` to YES.

Sometimes you may also want to run the evaluation and possible execution as soon as you register the execution. For that set `validateImmediately` to YES.

## Open Issues

Please help us resolve these issues with the L360EventTracker:
* [Mapping Events with Executions for faster performance](https://github.com/life360/event-tracker/issues/1): Currently it is a shameful piece of code that is basically **O(n^2)!!** <-The '!' are exclamations, not factorials.

## License

L360EventTracker is available under the MIT license. See the LICENSE file for more info.
