require 'forwardable'

module S3Master
  class Config
    include Enumerable
    extend Forwardable

    def_delegator :@cfg, :[]

    def initialize(cfg_file)
      @cfg = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(cfg_file))
    end

    def has_subpolicies?(bucket, policy_type)
      @cfg[:buckets][bucket.to_s][policy_type.to_s].kind_of?(Hash)
    end

    def template_relname(bucket, policy_type, policy_id=nil)
      if self.has_subpolicies?(bucket, policy_type)
        raise(RuntimeError, "Bucket #{bucket} policy #{policy_type} has subpolicies so an id is required") if policy_id.nil?
        @cfg[:buckets][bucket][policy_type][policy_id]
      else
        @cfg[:buckets][bucket][policy_type]
      end
    end

    def policy_ids(bucket, policy_type)
      subpolicy = @cfg[:buckets][bucket][policy_type]
      policy_ids = subpolicy.kind_of?(Hash) ? subpolicy.keys : nil
      policy_ids
    end

    def each(&block)
      @cfg[:buckets].each_pair do |bucket, policy_types|
        policy_types.each_pair do |policy_type, subpolicy|
          (policy_ids(bucket, policy_type) || [nil]).each do |policy_id|
            block.call(bucket, policy_type, policy_id)
          end
        end
      end
    end
  end
end
