# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'boulevard/version'

Gem::Specification.new do |spec|
  spec.name          = "boulevard"
  spec.version       = Boulevard::VERSION
  spec.authors       = ["Mike Nicholaides"]
  spec.email         = ["mike@promptworks.com"]

  spec.summary       = %q{Don't call us. We'll call you.}
  spec.description   = %q{Send code to a server for it to run.}
  spec.homepage      = "https://github.com/promptworks/boulevard/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "commander", "~> 4.0"
end
