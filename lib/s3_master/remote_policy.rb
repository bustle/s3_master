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
    }
    POLICY_TYPES = POLICIES.keys.freeze

    def initialize(bucket_name, policy_type)
      @client = Aws::S3::Client.new
      @bucket_name = bucket_name
      @policy_type = policy_type.to_sym
      raise(RuntimeError, "Policy type #{policy_type} not supported") if !POLICIES.has_key?(@policy_type)
      load_policy
    end

    def load_policy
      begin
        @body = @client.send(POLICIES[@policy_type][:get], {bucket: @bucket_name}).to_hash
      rescue Aws::S3::Errors::NoSuchLifecycleConfiguration, Aws::S3::Errors::ReplicationConfigurationNotFoundError => e
        # No policy there currently
        @body = {}
      end
    end

    def pretty_body() JSON.neat_generate(body, sort: true) ; end

    def write(local_policy)
      if local_policy.empty?
        @client.send(POLICIES[@policy_type][:delete], {bucket: @bucket_name})
      else
        args = {bucket: @bucket_name}

        if POLICIES[@policy_type][:ensure_versioning]
          self.ensure_versioning!
        end

        if POLICIES[@policy_type][:policy_merge]
          args.merge!(local_policy.body)
        else
          args[POLICIES[@policy_type][:policy_key]] = local_policy.body
        end

        @client.send(POLICIES[@policy_type][:put], args)
      end
    end

    def ensure_versioning!
      bkt = Aws::S3::Bucket.new(@bucket_name)
      bkt.versioning.status == "Enabled" || bkt.versioning.enable
    end
  end
end
