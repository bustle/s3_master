
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "s3_master/version"

Gem::Specification.new do |spec|
  spec.name          = "s3_master"
  spec.version       = S3Master::VERSION
  spec.authors       = ["Dave Steinberg"]
  spec.email         = ["dave@steinbergcomputing.com"]

  spec.summary       = %q{Cohesive S3 bucket policy management}
  #spec.description   = %q{TODO: Write a longer description or delete this line.}
  #spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|bin/console|bin/setup)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "activesupport", ">= 4.0"
  spec.add_dependency "aws-sdk-resources", ">= 2.6"
  spec.add_dependency "diffy"
  spec.add_dependency "neatjson"
  spec.add_dependency "thor"
end
