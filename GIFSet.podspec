#
# Be sure to run `pod lib lint ${POD_NAME}.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "GIFSet"
  s.version          = "1.0.0"
  s.summary          = "A simple toolset for creating GIFs and GIF-like videos."
  s.description      = <<-DESC
                        A collection of NSOperation subclasses that leverage AVFoundation tools to create GIFs and GIF-like videos from one or many AVAssets or UIImages.
                       DESC

  s.homepage         = "https://github.com/alfiehanssen/GIFSet"
  s.license          = 'MIT'
  s.author           = { "Alfie Hanssen" => "alfiehanssen@gmail.com" }
  s.social_media_url = 'https://twitter.com/alfiehanssen'

  s.source           = { :git => "https://github.com/alfiehanssen/GIFSet.git", :tag => s.version.to_s }

  s.platform     = :ios, '9.0'
  s.requires_arc = true
  s.source_files = 'GIFSet-Source/**/*.{h,m}'

  s.frameworks = 'Foundation', 'MobileCoreServices', 'AVFoundation', 'CoreGraphics', 'UIKit', 'ImageIO'

  # s.public_header_files = 'Pod/Classes/**/*.h'
end
