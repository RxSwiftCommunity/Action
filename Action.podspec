Pod::Spec.new do |s|
  s.name         = "Action"
  s.version      = "3.5.0"
  s.summary      = "Abstracts actions to be performed in RxSwift."
  s.description  = <<-DESC
    Encapsulates an action to be performed, usually by a button press, but also useful to pass actions to execute later
	(once or multiple times) without having to expose other objects.
                   DESC
  s.homepage     = "https://github.com/RxSwiftCommunity/Action"
  s.license      = { :type => "MIT", :file => "License.md" }
  s.author             = { "Ash Furrow" => "ash@ashfurrow.com" }
  s.social_media_url   = "http://twitter.com/ashfurrow"

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

  s.source       = { :git => "https://github.com/RxSwiftCommunity/Action.git", :tag => s.version.to_s }
  s.source_files  = "Sources/**/*.{swift}"

  s.frameworks  = "Foundation"
  s.dependency "RxSwift", "~> 4.0"
  s.dependency "RxCocoa", "~> 4.0"

  s.watchos.exclude_files = "Control+Action.swift", "Button+Action.swift", "UIBarButtonItem+Action.swift", "UIAlertAction+Action.swift"
  s.osx.exclude_files = "UIBarButtonItem+Action.swift", "UIAlertAction+Action.swift"
  s.tvos.exclude_files = "UIBarButtonItem+Action.swift", "UIAlertAction+Action.swift"
end
