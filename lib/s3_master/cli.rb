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

  desc "diff <bucket> <policy-type> [policy-id]", "Show differences between the current and the desired policy."
  def diff(bucket, policy_type, policy_id=nil)
    config = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(options[:"config-file"]))

    @remote_policy = S3Master::RemotePolicy.new(bucket, policy_type, {id: policy_id})
    @local_policy = S3Master::LocalPolicy.new(config, bucket, policy_type, options.merge(id: policy_id))

    #byebug
    if options[:debug]
      bkt = Aws::S3::Bucket.new(bucket)
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

  desc "apply <bucket> <policy-type> [policy-id]", "Appies the local policy to the bucket."
  def apply(bucket, policy_type, policy_id=nil)
    policy_diff = diff(bucket, policy_type, policy_id)

    exit 0 if policy_diff.identical? || ! (options[:force] || yes?("Proceed? (y/N)"))
    
    config = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(options[:"config-file"]))

    local_policy = S3Master::LocalPolicy.new(config, bucket, policy_type, options.merge(id: policy_id))
    remote_policy = S3Master::RemotePolicy.new(bucket, policy_type, {id: policy_id})
    remote_policy.write(local_policy)
  end

  desc "fetch <bucket> <policy-type> [policy-id]", "Retrieves the specified policy for the bucket and saves it in the config-specified file"
  def fetch(buckets=nil, policy_types=S3Master::RemotePolicy::POLICY_TYPES, policy_id=nil)
    config = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(options[:"config-file"]))
    buckets ||= config[:buckets].keys

    Array(buckets).each do |bucket|
      Array(policy_types).each do |policy_type|
        local_policy = S3Master::LocalPolicy.new(config, bucket, policy_type, options.merge(skip_load: true, id: policy_id))
        remote_policy = S3Master::RemotePolicy.new(bucket, policy_type, {id: policy_id})

        if !local_policy.basename.nil?
          local_policy.write(remote_policy)
        else
          puts "%s policy:\n%s" % [policy_type, remote_policy.pretty_body]
        end
      end
    end
  end
end
