#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'advanced_background_locator'
  s.version          = '0.1.3'
  s.summary          = 'A Flutter plugin for getting location updates even when the app is in the background.'
  s.description      = <<-DESC
Flutter plugin for background location tracking.
                       DESC
  s.homepage         = 'https://github.com/AbdurrahmanKaraoglu/advanced_background_locator'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Abdurrahman' => 'abdurrahmank118@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'advanced_background_locator/Sources/advanced_background_locator/**/*.{h,m}'
  s.public_header_files = 'advanced_background_locator/Sources/advanced_background_locator/include/**/*.h'
  s.dependency 'Flutter'
  s.frameworks = 'CoreLocation'
  s.resource_bundles = { 'advanced_background_locator_privacy' => ['advanced_background_locator/Sources/advanced_background_locator/PrivacyInfo.xcprivacy'] }

  s.ios.deployment_target = '13.0'
end
