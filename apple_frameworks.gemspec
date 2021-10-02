Gem::Specification.new do |spec|
  root = File.expand_path('..', __FILE__)
  require File.join(root, "lib", "apple_frameworks", "version.rb").to_s
  require "pathname"

  spec.name          = "apple_frameworks"
  spec.version       = AppleFrameworks::VERSION
  spec.authors       = ["Daniel Inkpen"]
  spec.email         = ["dan2552@gmail.com"]

  spec.summary       = %q{Creation of .framework and .xcframework for iOS and/or macOS libraries}
  spec.description   = %q{Creation of .framework and .xcframework for iOS and/or macOS libraries}
  spec.homepage      = "https://github.com/Dan2552/apple_frameworks"
  spec.license       = "MIT"

  spec.files = Dir
    .glob(File.join(root, "**", "*.rb"))
    .reject { |f| f.match(%r{^(test|spec|features)/}) }
    .map { |f| Pathname.new(f).relative_path_from(root).to_s }

  if File.directory?(File.join(root, "exe"))
    spec.bindir = "exe"
    spec.executables = Dir.glob(File.join(root, "exe", "*"))
      .map { |f| File.basename(f) }
  end

  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec"
end
