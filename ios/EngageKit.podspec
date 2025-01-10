#
# Be sure to run `pod lib lint EngageKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'EngageKit'
  s.version          = '4.1.0'
  s.summary          = 'Engage'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://www.firstorion.com/'
  s.license      = { :type => 'proprietary', :text => <<-LICENSE
                    This software is only permitted to be used
                    by employees of <COMPANY> or
                    of its partners.
                    LICENSE
                  }
  s.author           = { 'First Orion' => 'support@firstorion.com' }
  # :path key is valid for pods distributed outside of the public Cocoapods podspec repo
  s.source = { :http => 'https://firstorion.jfrog.io/firstorion/api/pods/cocoapods-local/EngageKit/4.1.0/EngageKit.tar.gz', :type => 'tgz'}

  s.ios.deployment_target = '10.0'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
  s.swift_version = '4.0'

  # Used instead of source_files as delivering compiled framework and not source to be compiled by hosting app
  s.preserve_paths = "EngageKit.xcframework*"
  s.vendored_frameworks = 'EngageKit.xcframework'

end
