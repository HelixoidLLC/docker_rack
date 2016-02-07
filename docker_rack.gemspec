# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'docker_rack/version'

Gem::Specification.new do |spec|
  spec.name          = 'docker_rack'
  spec.version       = DockerRack::VERSION
  spec.authors       = ['Igor Moochnick']
  spec.email         = %w(igor.moochnick@gmail.com)
  spec.description   = 'Simple Docker Orchestration'
  spec.summary       = 'This gem will orchestrate local Docker containers'
  spec.homepage      = 'https://github.com/igorshare/docker_rack'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($RS)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  ENV['NOKOGIRI_USE_SYSTEM_LIBRARIES'] = 'true'

  #  spec.add_dependency 'nokogiri', '~> 1.6.0'
  spec.add_dependency 'rake', '~> 0'
  spec.add_dependency 'thor', '~> 0.18', '>= 0.18.0'
  #  spec.add_dependency 'activesupport'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'bump'
  spec.add_development_dependency 'json'
  spec.add_development_dependency 'gem-release'
  #  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-rcov'
  #  spec.add_development_dependency 'kwalify'
  #  spec.add_development_dependency 'equivalent-xml'
  spec.add_development_dependency 'yard-thor'
  spec.add_development_dependency 'yard'
  #  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'rubocop'
end
