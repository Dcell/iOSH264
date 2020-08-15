#
#  Be sure to run `pod spec lint UIModule.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "iOSH264Compression"
  s.version      = "1.0.0"
  s.summary      = "iOS encode & decode use by VideoToolBox"
  s.description  = <<-DESC
                   iOS encode & decode use by VideoToolBox,DetailInfo:https://github.com/Code-Dogs/iOSH264
                   DESC
  s.homepage     = "https://github.com/Code-Dogs/iOSH264"
  s.license      = "MIT"
  s.author             = { "Dcell" => "" }
  s.source       = { :git => 'https://github.com/Code-Dogs/iOSH264', :tag => "#{s.version}" }
  s.frameworks = "VideoToolBox"
  s.ios.deployment_target  = '8.0'
  s.source_files  = "class/**/*.{h,m,mm,swift}"
  
end
