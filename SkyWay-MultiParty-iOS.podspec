Pod::Spec.new do |s|
  s.name             = 'SkyWay-MultiParty-iOS'
  s.version          = '0.1.0'
  s.summary          = 'SkyWay MultiParty is a library to simplify group chats using SkyWay.'
  s.homepage         = 'https://nttcom.github.io/skyway'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'NTT Communications' => 'skyway@ntt.com' }
  s.source           = { :git => 'https://github.com/nttcom/SkyWay-MultiParty-iOS', :tag => "v0.1.0" }
  s.ios.deployment_target = '7.0'
  s.source_files = 'MultiParty/*/*.{h,m}'
end
