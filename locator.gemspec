# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "lib/version"

Gem::Specification.new do |spec|
  spec.name          = "locator"
  spec.version       = Sinatra::Locator::VERSION
  spec.authors       = ["Karolin Edigkaufer", "Lukas Essig", "Benedikt Bock"]
  spec.email         = ["kedigkaufer@gmail.com", "rocky.frei@gmail.com", "mail@benedikt1992.de"]

  spec.summary       = %q{short summary} #TODO
  spec.description   = %q{description} #TODO
  spec.homepage      = "https://github.com/DieKonsonanten/locator"
  spec.license       = 'GPL-3.0'
  spec.required_ruby_version = '>= 2.3.0'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'sinatra'
  spec.add_dependency 'thin'
  spec.add_dependency 'colorize'
  spec.add_dependency 'bcrypt'
  spec.add_dependency 'mail', '~> 2.7'
  spec.add_dependency 'pony', '~> 1.12'
  spec.add_dependency 'sinatra-config-file'
  spec.add_dependency 'rack-ssl'

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency 'yard'
end
