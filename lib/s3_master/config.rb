require 'forwardable'

module S3Master
  class Config
    include Enumerable
    extend Forwardable

    def_delegator :@cfg, :[]

    def initialize(cfg_file)
      @cfg = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(cfg_file))
    end

    def each(&block)
      @cfg[:buckets].each_pair do |bucket, policy_types|
        policy_types.each_pair do |policy_type, subpolicy|
          policy_ids = subpolicy.kind_of?(Hash) ? subpolicy.keys : [nil]
          policy_ids.each do |policy_id|
            block.call(bucket, policy_type, policy_id)
          end
        end
      end
    end
  end
end
