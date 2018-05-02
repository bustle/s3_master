require 'rubygems'
require 'bundler/setup'

require 'active_support/core_ext/hash'
require 'aws-sdk-resources'
require 'diffy'
require 'json'
require 'neatjson'
require 'thor'
require 'yaml'

require 's3_master'

Diffy::Diff.default_format = :color

class S3MasterCli < Thor
  include Thor::Shell

  class_option "config-file".to_sym, type: :string, aliases: %w(c), default: "s3_policies.yml"
  class_option "policy-dir".to_sym, type: :string, aliases: %w(d), default: "policies"
  class_option :debug, type: :boolean
  class_option :force, type: :boolean

  desc "diff <bucket> <policy-type> [policy-id]", "Show differences between the current and the desired policy."
  def diff(bucket, policy_type, policy_id=nil)
    config = S3Master::Config.new(options[:"config-file"])

    remote_policy = S3Master::RemotePolicy.new(bucket, policy_type, {id: policy_id, region: config.region(bucket)})
    local_policy = S3Master::LocalPolicy.new(config, bucket, policy_type, options.merge(id: policy_id).symbolize_keys)

    if options[:debug]
      bkt = Aws::S3::Bucket.new(bucket)
      puts "%s: %s" % [bkt.name, bkt.url]
      puts "=== Remote Policy:\n%s" % [JSON.neat_generate(remote_policy.body, sort: true)]
      puts "=== Local Policy:\n%s" % [JSON.neat_generate(local_policy.body, sort: true)]
    end

    policy_diff = S3Master::PolicyDiffer.new(remote_policy.body, local_policy.body)
    prefix = "#{bucket}/#{policy_type}"
    prefix += "/#{policy_id}" if policy_id

    if policy_diff.identical?
      puts "#{prefix}: Local and remote policies match."
    else
      puts "#{prefix} diff:\n%s" % [policy_diff.to_s]
    end
    policy_diff
  end

  desc "apply [<bucket>] [<policy-type>] [policy-id]", "Appies the local policy to the bucket."
  def apply(cli_bucket=nil, cli_policy_type=nil, cli_policy_id=nil)
    config = S3Master::Config.new(options[:"config-file"])
    config.each do |bucket, policy_type, policy_id|
      next if !cli_bucket.nil? && cli_bucket != bucket ||
              !cli_policy_type.nil? && cli_policy_type != policy_type ||
              !cli_policy_id.nil? && cli_policy_id != policy_id

      policy_diff = diff(bucket, policy_type, policy_id)

      next if policy_diff.identical? || ! (options[:force] || yes?("Proceed? (y/N)"))

      local_policy = S3Master::LocalPolicy.new(config, bucket, policy_type, options.merge(id: policy_id).symbolize_keys)
      remote_policy = S3Master::RemotePolicy.new(bucket, policy_type, {id: policy_id, region: config.region(bucket)})
      remote_policy.write(local_policy)
    end
  end

  desc "fetch <bucket> <policy-type> [policy-id]", "Retrieves the specified policy for the bucket and saves it in the config-specified file"
  def fetch(buckets=nil, policy_types=S3Master::RemotePolicy::POLICY_TYPES, policy_id=nil)
    config = S3Master::Config.new(options[:"config-file"])
    buckets ||= config[:buckets].keys

    Array(buckets).each do |bucket|
      Array(policy_types).each do |policy_type|
        next if ! S3Master::RemotePolicy.known_policy_type?(policy_type)
        local_policy = S3Master::LocalPolicy.new(config, bucket, policy_type, options.merge(skip_load: true, id: policy_id).symbolize_keys)
        remote_policy = S3Master::RemotePolicy.new(bucket, policy_type, {id: policy_id, region: config.region(bucket)})

        if !local_policy.basename.nil?
          local_policy.write(remote_policy)
        else
          puts "%s policy:\n%s" % [policy_type, remote_policy.pretty_body]
        end
      end
    end
  end

  desc "status [<bucket>]", "Checks if the policies have differences"
  def status(user_bucket=nil)
    config = S3Master::Config.new(options[:"config-file"])

    any_differences = false
    config.each do |bucket, policy_type, policy_id|
      next if !user_bucket.nil? && user_bucket != bucket
      local_policy = S3Master::LocalPolicy.new(config, bucket, policy_type, options.merge(id: policy_id).symbolize_keys)
      remote_policy = S3Master::RemotePolicy.new(bucket, policy_type, {id: policy_id, region: config.region(bucket)})

      policy_diff = S3Master::PolicyDiffer.new(remote_policy.body, local_policy.body)
      if !policy_diff.identical?
        any_differences = true

        if policy_id.nil?
          puts "* %s: %s" % [bucket, policy_type]
        else
          puts "* %s: %s %s" % [bucket, policy_type, policy_id]
        end
      end
    end

    puts "No differences detected." if !any_differences
  end
end
