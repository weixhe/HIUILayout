#
# Be sure to run `pod lib lint HIUILayout.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'HIUILayout'
  s.version          = '0.1.0'
  s.summary          = 'iOS 简易布局'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
HIUILayout 是一个简易的布局工具，旨在简化业务员布局
                       DESC

  s.homepage         = 'https://github.com/weixhe/HIUILayout'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'weixhe' => 'xiaohe.wei@fumubang.com' }
  s.source           = { :git => 'https://github.com/weixhe/HIUILayout.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'HIUILayout/Classes/**/*'
  
  # s.resource_bundles = {
  #   'HIUILayout' => ['HIUILayout/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
