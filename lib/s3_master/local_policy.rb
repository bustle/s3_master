module S3Master
  class LocalPolicy
    attr_reader :body

    def initialize(cfg, bucket_name, policy_type, options={})
      @config = cfg
      @bucket_name = bucket_name
      @policy_type = policy_type.to_sym
      @options = options

      if @config["buckets"][@bucket_name].nil?
        raise(RuntimeError, "No bucket named '#{@bucket_name}' found in loaded config.")
      end

      load_policy if !options[:skip_load]
    end

    def preserve_keys?() S3Master::RemotePolicy::POLICIES[@policy_type][:preserve_keys] ; end
    def empty?() @body.nil? || @body.empty? ; end
    def pretty_body() JSON.neat_generate(body, sort: (self.preserve_keys? ? false : true)) ; end

    def basename()
      possible_basename = @config["buckets"][@bucket_name][@policy_type.to_s]

      if possible_basename.kind_of?(String)
        possible_basename
      elsif @options[:id]
        possible_basename[@options[:id]] || raise(RuntimeError, "Unable to locate policy with id '#{@options[:id]}' in config #{possible_basename}")
      else
        raise(RuntimeError, "Can't determine the path to the policy: #{@bucket_name} / #{@policy_type}")
      end
    end
    def path() File.join(@options[:"policy-dir"], self.basename) ; end

    def load_policy
      @body = if basename == false
                # Empty policy
                {}
              else
                JSON.parse(File.binread(path))
              end

      if ! self.preserve_keys?
        @body.deep_transform_keys!{|k| k.underscore.to_sym }
      end

      @body
    end

    def write(other_policy)
      File.open(self.path, "wb") do |fh|
        fh.puts other_policy.pretty_body
      end
    end
  end
end
