# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'encrypt_env'
  spec.version = '0.0.1'
  spec.required_ruby_version = '>= 2.6.0'
  spec.summary = 'Ecrypt secrets.yml file'
  spec.description = 'Encrypts and decrypts environment variables'
  spec.homepage = 'https://rubygems.org/gems/encrypt_env'
  spec.email = 'nhutan2001@gmail.com'
  spec.author = 'Nhu Tan'
  spec.license = 'MIT'
  spec.platform = Gem::Platform::RUBY
  spec.files = ['lib/encrypt_env.rb']
  # spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.executables << 'encrypt_env'
end
