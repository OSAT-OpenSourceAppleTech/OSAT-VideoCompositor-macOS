#
# Be sure to run `pod lib lint OSAT-VideoCompositor-macOS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OSAT-VideoCompositor-macOS'
  s.version          = '0.1.0'
  s.summary          = 'Allow iOS app developers to annotate and augment a video file using Apple native Video composition APIs.'
  s.swift_version    = '5.5'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
OSAT-VideoCompositor is an open source project which allow iOS app developers to annotate and augment a video file using Apple native Video composition APIs.
                       DESC

  s.homepage         = 'https://github.com/OSAT-OpenSourceAppleTech/OSAT-VideoCompositor-macOS.git'
  s.license          = { :type => 'GNU GENERAL PUBLIC LICENSE', :file => 'LICENSE' }
  s.author           = { 'Hem Dutt' => 'hemdutt.developer@gmail.com' }
  s.source           = { :git => 'https://github.com/OSAT-OpenSourceAppleTech/OSAT-VideoCompositor-macOS.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform = :osx
  s.osx.deployment_target = "13.0"

  s.source_files = 'OSAT-VideoCompositor-macOS/Classes/**/*'

  # s.resource_bundles = {
  #   'OSAT-VideoCompositor-macOS' => ['OSAT-VideoCompositor-macOS/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'Cocoa'
end
