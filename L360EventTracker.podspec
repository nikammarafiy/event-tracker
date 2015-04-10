Pod::Spec.new do |s|
  s.name             = "L360EventTracker"
  s.version          = "0.1.0"
  s.summary          = "Keep track of what your user is doing within your app and then execute code based on their behavior"
  s.description      = <<-DESC
                       <p>Think of this as your local app rating class.. but better.</p>
                       <p>You define your own events and then trigger them at the right parts of your app</p>
                       <p>Then register execution blocks that will get evaluated and then executed when certain events are triggered.
                       DESC
  s.homepage         = "https://github.com/life360/event-tracker"
# s.screenshots      = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = { :type => "Apache License, Version 2.0", :file => "L360EventTracker/LICENSE.md" }
  s.author           = { "Mohammed Islam" => "mohammed@life360.com" }
  s.source           = { :git => "https://github.com/life360/event-tracker.git", :tag => s.version.to_s }

  s.platform         = :ios, '7.0'
  s.requires_arc     = true

  s.source_files     = 'L360EventTracker/Classes'

# s.frameworks = 'UIKit'
# s.dependency 'AFNetworking', '~> 2.3'
end
