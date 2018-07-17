require 'aws-sdk-s3'

module S3Master
  class RemotePolicy
    attr_reader :body

    POLICIES = {
      lifecycle: {
        get: :get_bucket_lifecycle_configuration,
        put: :put_bucket_lifecycle_configuration,
        delete: :delete_bucket_lifecycle,
        policy_key: :lifecycle_configuration,
      },
      replication: {
        get: :get_bucket_replication,
        put: :put_bucket_replication,
        delete: :delete_bucket_replication,
        policy_merge: true,
        ensure_versioning: true,
      },
      inventory: {
        get: :get_bucket_inventory_configuration,
        put: :put_bucket_inventory_configuration,
        delete: :delete_bucket_inventory_configuration,
        policy_merge: true,
        requires_id: true,
      },
      access: {
        get: :get_bucket_policy,
        put: :put_bucket_policy,
        delete: :delete_bucket_policy,
        policy_key: :policy,
        preserve_keys: true,
      },
      events: {
        get: :get_bucket_notification_configuration,
        put: :put_bucket_notification_configuration,
        policy_key: :notification_configuration,
      },
    }
    POLICY_TYPES = POLICIES.keys.freeze

    NO_POLICY_EXCEPTIONS = [
      Aws::S3::Errors::NoSuchBucketPolicy,
      Aws::S3::Errors::NoSuchConfiguration,
      Aws::S3::Errors::NoSuchLifecycleConfiguration,
      Aws::S3::Errors::ReplicationConfigurationNotFoundError,
    ]

    def initialize(bucket_name, policy_type, options={})
      @client = options[:region].nil? ? Aws::S3::Client.new() : Aws::S3::Client.new(region: options[:region])
      @bucket_name = bucket_name
      @policy_type = policy_type.to_sym
      @options = options
      raise(RuntimeError, "Policy type #{policy_type} not supported") if !POLICIES.has_key?(@policy_type)
      load_policy
    end

    def policy_key() POLICIES[@policy_type][:policy_key] ; end
    def parse_as_string() POLICIES[@policy_type][:parse_as_string] || false ; end

    def inflate(read_policy)
      if @policy_type == :access_policy
        JSON.parse(read_policy[policy_key].string)
      else
        read_policy
      end
    end

    def deflate(policy_hash)
      case @policy_type
      when :access_policy
        policy_hash[policy_key] = JSON.generate(policy_hash[policy_key])
      end
      policy_hash
    end

    def load_policy
      begin
        args = base_args
        @body = self.inflate(@client.send(POLICIES[@policy_type][:get], args).to_hash)
      rescue *NO_POLICY_EXCEPTIONS => e
        # No policy there currently
        @body = {}
      end
    end

    def pretty_body() JSON.neat_generate(body, sort: true) ; end

    def write(local_policy)
      args = base_args

      if local_policy.empty? && POLICIES[@policy_type].has_key?(:delete)
        @client.send(POLICIES[@policy_type][:delete], args)
      else
        if POLICIES[@policy_type][:ensure_versioning]
          self.ensure_versioning!
        end

        if POLICIES[@policy_type][:policy_merge]
          args.merge!(local_policy.body)
        else
          args[policy_key] = local_policy.body
        end

        @client.send(POLICIES[@policy_type][:put], self.deflate(args))
      end
    end

    def ensure_versioning!
      bkt = Aws::S3::Bucket.new(@bucket_name, client: @client)
      bkt.versioning.status == "Enabled" || bkt.versioning.enable
    end

    def base_args
      args = {bucket: @bucket_name}
      if POLICIES[@policy_type][:requires_id]
        args[:id] = @options[:id]
      end
      args
    end

    def self.known_policy_type?(policy) POLICIES.has_key?(policy.to_sym) ; end
    def known_policy_type?(policy) self.class.known_policy_type(policy) ; end
  end
end
