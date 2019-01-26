Pod::Spec.new do |s|
  s.name             = 'SDDatabase'
  s.version          = '1.0.0'
  s.summary          = 'A simple yet powerful wrapper over the famous FMDB. Provides fast and easy access to sqlite database operations in iOS eliminating all the boilerplate code.'

  s.homepage         = 'https://github.com/SagarSDagdu/SDDatabase'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sagar Dagdu' => 'shags032@gmail.com' }
  s.source           = { :git => 'https://github.com/Sagar Dagdu/SDDatabase.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.swift_version = '4.2'
  s.source_files = 'SDDatabase/Classes/**/*'
  s.dependency 'FMDB/SQLCipher'
end
