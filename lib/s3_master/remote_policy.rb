module S3Master
  class RemotePolicy
    attr_reader :body

    POLICY_METHODS = {
      "lifecycle" => :lifecycle_configuration,
    }

    def initialize(bucket_name, policy_type)
      @bucket_name = bucket_name
      @policy_type = policy_type
      raise(RuntimeError, "Policy type #{policy_type} not supported") if !POLICY_METHODS.has_key?(policy_type)
      load_policy
    end

    def load_policy
      bkt = Aws::S3::Bucket.new(@bucket_name)
      begin
        @body = bkt.send(POLICY_METHODS[@policy_type]).data.to_hash
      rescue Aws::S3::Errors::NoSuchLifecycleConfiguration => e
        # No policy there currently
        @body = {}
      end
    end
  end
end
