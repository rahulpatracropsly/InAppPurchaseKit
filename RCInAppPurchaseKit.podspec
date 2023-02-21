
Pod::Spec.new do |spec|

  spec.platform = :ios
  spec.ios.deployment_target = "11.0"
  spec.swift_version = "5.3"
  spec.name         = "RCInAppPurchaseKit"
  spec.version      = "0.2.1"
  spec.summary      = "A modern In-App Purchases management framework for iOS developers."

  spec.homepage     = "https://git.cropsly.com/rahul.patra/InAppPurchaseKit"
  
  spec.license = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "Rahul Patra" => "rahul.patra@cropsly.com" }
  spec.source       = { :git => "https://git.cropsly.com/rahul.patra/InAppPurchaseKit", :tag => "#{spec.version}" }

  spec.frameworks = "CoreFoundation", "StoreKit"
  spec.source_files  = "Sources/**/*.{swift,h,m}"
  
end

