Pod::Spec.new do |s|
  s.name             = 'easemob_flutter_callkit'
  s.version          = '1.0.0'
  s.summary          = 'Easemob CallKit Flutter plugin'
  s.description      = 'A Flutter plugin for integrating Easemob CallKit on iOS and Android.'
  s.homepage         = 'https://github.com/easemob/easemob_flutter_callkit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Easemob' => 'support@easemob.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'EaseCallUIKit', '4.23.0'
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.9'
  s.static_framework = true
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end