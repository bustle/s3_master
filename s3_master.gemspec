lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "s3_master/version"

Gem::Specification.new do |spec|
  spec.name          = "s3_master"
  spec.version       = S3Master::VERSION
  spec.authors       = ["Dave Steinberg"]
  spec.email         = ["dave@steinbergcomputing.com"]

  spec.summary       = %q{Cohesive S3 bucket policy management}
  spec.description   = %q{s3_master aims to provide a git-based workflow for managing policy documents on legacy (e.g. non-cloudformation) S3 buckets.}
  spec.homepage      = "https://github.com/bustle/s3_master"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|bin/console|bin/setup)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "activesupport", ">= 4.0"
  spec.add_dependency "aws-sdk-s3", "~> 1"
  spec.add_dependency "diffy"
  spec.add_dependency "neatjson"
  spec.add_dependency "thor"
end
