Pod::Spec.new do |s|
  s.name             = 'push_platform_flutter'
  s.version          = '1.0.1'
  s.summary          = 'PushPilot Flutter SDK'
  s.description      = <<-DESC
Flutter plugin for Push Platform - a thin wrapper over native iOS SDK.
Provides type-safe Dart API for push notifications, VoIP calls, and user management.
                       DESC
  s.homepage         = 'https://github.com/pushplatform/pushpilot-sdk-flutter'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = 'PushPilot contributors'
  s.source           = { :path => '.' }
  # Compile the pinned native SDK in the plugin module; no Trunk dependency.
  s.source_files     = 'Classes/**/*', 'Bundled/PushPlatformSDK/Sources/PushPlatformSDK/**/*.swift'
  s.preserve_paths   = 'Bundled/PushPlatformSDK/LICENSE', 'Bundled/PushPlatformSDK/manifest.json', 'native-sdk.lock.json'
  s.frameworks       = 'Foundation', 'UIKit', 'UserNotifications', 'PushKit', 'CallKit', 'AVFoundation', 'Network', 'Security'

  s.ios.deployment_target = '13.0'
  s.swift_version    = '5.5'

  s.dependency 'Flutter'

  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
