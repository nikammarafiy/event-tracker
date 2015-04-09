#
# Be sure to run `pod lib lint L360EventTracker.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "L360EventTracker"
  s.version          = "0.1.0"
  s.summary          = "A short description of L360EventTracker."
  s.description      = <<-DESC
                       An optional longer description of L360EventTracker

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/life360/event-tracker"
# s.screenshots      = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = { :type => "Apache License, Version 2.0", :file => "LICENSE.md" }
  s.author           = { "Mohammed Islam" => "mohammed@life360.com" }
  s.source           = { :git => "https://github.com/life360/event-tracker.git", :tag => s.version.to_s }
  s.source_files     = "L360EventTracker"
# s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform         = :ios, '7.0'
  s.requires_arc     = true

  s.source_files     = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'L360EventTracker' => ['Pod/Assets/*.png']
  }

# s.public_header_files = 'Pod/Classes/**/*.h'
# s.frameworks = 'UIKit'
# s.dependency 'AFNetworking', '~> 2.3'
end
