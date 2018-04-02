module S3Master
  class LocalPolicy
    attr_reader :body

    def initialize(cfg, bucket_name, policy_type, options={})
      @config = cfg
      @bucket_name = bucket_name
      @policy_type = policy_type
      @options = options
      load_policy
    end

    def empty?() @body.nil? || @body.empty? ; end

    def path
      File.join(@options[:"policy-dir"], @config["buckets"][@bucket_name][@policy_type])
    end
    def load_policy
      @body = JSON.parse(File.binread(path)).deep_transform_keys{|k| k.underscore.to_sym }
    end
  end
end
