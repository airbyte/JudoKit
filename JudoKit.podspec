Pod::Spec.new do |s|
  s.name             = 'JudoKit'
  s.version          = '5.0.1'
  s.summary          = 'Judo Pay Full iOS Client Kit'
  s.homepage         = 'http://judopay.com/'
  s.license          = 'MIT'
  s.author           = { "Hamon Ben Riazy" => 'hamon.riazy@judopayments.com' }
  s.source           = { :git => 'https://github.com/JudoPay/JudoKit.git',
                         :tag => "v#{s.version}" }
  s.ios.deployment_target = '8.0'
  s.ios.platform          = '9.0'
  s.requires_arc     = true
  s.source_files     = 'Source/**/*.swift'
  s.dependency 'Judo'
  s.dependency 'JudoShield'
  s.frameworks       = 'CoreLocation', 'Security', 'CoreTelephony'
  s.xcconfig         = { 'FRAMEWORK_SEARCH_PATHS'   => '"${PODS_ROOT}/JudoShield/Framework"' }
end
