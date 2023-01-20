
Pod::Spec.new do |spec|

  spec.platform = :ios
  spec.ios.deployment_target = "13.0"
  spec.swift_version = "5.3"
  spec.name         = "InAppPurchaseKit"
  spec.version      = "0.0.1"
  spec.summary      = "A modern In-App Purchases management framework for iOS developers."
  spec.requires_arc = true

  spec.homepage     = "https://git.cropsly.com/rahul.patra/InAppPurchaseKit"
  
  spec.license = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "Rahul Patra" => "rahul.patra@cropsly.com" }
  spec.source       = { :git => "https://git.cropsly.com/rahul.patra/InAppPurchaseKit", :tag => "#{spec.version}" }

  spec.frameworks = "CoreFoundation", "StoreKit"
  spec.source_files  = "InAppPurchaseKit", "InAppPurchaseKit/**/*.{h,m}"
  
end

