require 'diffy'

module S3Master
  class PolicyDiffer
    attr_reader :remote, :local, :diff

    def initialize(remote_policy, local_policy)
      @remote = remote_policy
      @local = local_policy
      compute_diff
    end

    def compute_diff
      rj = JSON.neat_generate(@remote, sort: true)
      lj = JSON.neat_generate(@local, sort: true)
      @diff = Diffy::Diff.new(rj, lj, context: 7, include_diff_info: true)
    end

    def identical?() diff.to_s == "\n" ; end
    def to_s() diff.to_s ; end
  end
end
