Pod::Spec.new do |s|
  s.name         = "MBAlertView"
  s.version      = "0.0.1"
  s.summary      = "Fast, fun, and simple block-based alerts and HUDs."
  s.description  = <<-DESC
                    MBAlertView is a fun and simple block-based alert and HUD library for iOS, as seen in Notestand.
                   DESC
  s.homepage     = "https://github.com/mobitar/MBAlertView"
  s.license      = 'MIT'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Mo Bitar" => "me@mbbitar.com" }
  s.source       = { :git => 'https://github.com/100grams/MBAlertView.git' }
  s.platform     = :ios

  s.source_files = 'MBAlertView/**/*.{h,m}'

  s.framework  = 'QuartzCore'

  s.requires_arc = true
end
