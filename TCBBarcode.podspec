#
# Be sure to run `pod lib lint TCBBarcode.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TCBBarcode'
  s.version          = '0.1.3'
  s.summary          = 'TCBBarcode offers a quick way to setup a scanner and a generator for supported barcodes'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  TCBBarcode offers a quick way to setup a scanner and a generator for supported barcodes. Configuration made easy.
                       DESC

  s.homepage         = 'https://github.com/TheCodingBug/TCBBarcode'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'nferocious76' => 'nferocious76@gmail.com' }
  s.source           = { :git => 'https://github.com/TheCodingBug/TCBBarcode.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/nferocious76'

  s.ios.deployment_target = '13.0'
  s.swift_version = "5.0"
  s.source_files = 'TCBBarcode/Classes/**/*'
  # s.resources = 'TCBBarcode/Assets/**'
    
  # s.dependency 'NFImageView', '~> 0.2.3'

end
