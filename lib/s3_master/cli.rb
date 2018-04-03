require 'active_support/core_ext/hash'
require 'aws-sdk-resources'
require 'diffy'
require 'json'
require 'neatjson'
require 'thor'
require 'yaml'

require 's3_master/local_policy'
require 's3_master/policy_differ'
require 's3_master/remote_policy'

require 'byebug'

Diffy::Diff.default_format = :color

class S3MasterCli < Thor
  include Thor::Shell

  class_option "config-file".to_sym, type: :string, aliases: %w(c), default: "s3_policies.yml"
  class_option "policy-dir".to_sym, type: :string, aliases: %w(d), default: "policies"
  class_option :debug, type: :boolean
  class_option :force, type: :boolean

  desc "diff <bucket> <policy-type>", "Show differences between the current and the desired policy."
  def diff(bucket, policy_type)
    bkt = Aws::S3::Bucket.new(bucket)
    config = YAML.load_file(options[:"config-file"])

    @remote_policy = S3Master::RemotePolicy.new(bucket, policy_type)
    @local_policy = S3Master::LocalPolicy.new(config, bucket, policy_type, options)

    #byebug
    if options[:debug]
      puts "%s: %s" % [bkt.name, bkt.url]
      puts "=== Remote Policy:\n%s" % [JSON.neat_generate(@remote_policy.body, sort: true)]
      puts "=== Local Policy:\n%s" % [JSON.neat_generate(@local_policy.body, sort: true)]
    end

    policy_diff = S3Master::PolicyDiffer.new(@remote_policy.body, @local_policy.body)
    if policy_diff.identical?
      puts "Local and remote policies match."
    else
      puts "Policy diff:\n%s" % [policy_diff.to_s]
    end
    policy_diff
  end

  desc "apply <bucket> <policy-type>", "Appies the local policy to the bucket."
  def apply(bucket, policy_type)
    policy_diff = diff(bucket, policy_type)

    exit 0 if policy_diff.identical? || ! (options[:force] || yes?("Proceed? (y/N)"))
    
    bkt = Aws::S3::Bucket.new(bucket)
    config = YAML.load_file(options[:"config-file"])

    local_policy = S3Master::LocalPolicy.new(config, bucket, policy_type, options)
    remote_policy = S3Master::RemotePolicy.new(bucket, policy_type)
    remote_policy.write(local_policy)
  end
end
