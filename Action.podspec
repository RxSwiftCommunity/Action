Pod::Spec.new do |s|
  s.name         = "Action"
  s.version      = "1.2.0"
  s.summary      = "Abstracts actions to be performed in RxSwift."
  s.description  = <<-DESC
    Encapsulates an action to be performed, usually by a UIButton press.

    But who knows what could have an action – the possibilities are endless!
                   DESC
  s.homepage     = "https://github.com/ashfurrow/Action"
  s.license      = { :type => "MIT", :file => "License.md" }
  s.author             = { "Ash Furrow" => "ash@ashfurrow.com" }
  s.social_media_url   = "http://twitter.com/ashfurrow"

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

  s.source       = { :git => "https://github.com/RxSwiftCommunity/Action.git", :tag => s.version }
  s.source_files  = "*.{swift}"

  s.frameworks  = "Foundation"
  s.dependency "RxSwift", '~> 2.1.0'
  s.dependency "RxCocoa", '~> 2.1.0'

  s.watchos.exclude_files = "UIButton+Rx.swift", "UIBarButtonItem+Action.swift", "AlertAction.swift"
  s.osx.exclude_files = "UIButton+Rx.swift", "UIBarButtonItem+Action.swift", "AlertAction.swift"
  s.tvos.exclude_files = "UIBarButtonItem+Action.swift", "AlertAction.swift"
end
