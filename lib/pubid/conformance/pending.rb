# frozen_string_literal: true

module Pubid
  module Conformance
    # Implementation-side PENDING markers: corpus cases this implementation
    # explicitly cannot handle yet. The testsuite owns expectations; this
    # file owns the admission that they are not met - so a pending case is
    # visible debt, never a silent failure and never a hidden pass.
    #
    # Format (conformance/pending.yaml at the implementation repo root):
    #   "<case-id glob>":
    #     reason: <one line, the root cause>
    #     since: <YYYY-MM-DD>
    #     ref: <TODO.correct-test-suite PR queue entry or contract id>
    #
    # Rules enforced elsewhere: a pending case that passes raises the
    # "pending satisfied - remove the marker" alarm; entries without a ref
    # are rejected at load.
    class Pending
      PATH = File.expand_path("../../../conformance/pending.yaml", __dir__)

      class << self
        def for(case_id)
          entry = registry[case_id]
          return entry if entry

          registry.each do |pattern, meta|
            next if pattern == case_id

            return meta if File.fnmatch(pattern, case_id)
          end
          nil
        end

        def empty?
          registry.empty?
        end

        private

        def registry
          @registry ||= load_registry
        end

        def load_registry
          return {} unless File.exist?(PATH)

          (YAML.safe_load_file(PATH) || {})
            .to_h { |pattern, meta| [pattern, validated(meta, pattern)] }
        end

        def validated(meta, pattern)
          unless meta.is_a?(Hash) && meta["reason"] && meta["ref"]
            raise ArgumentError,
                  "pending entry #{pattern.inspect} needs reason and ref"
          end

          meta
        end
      end
    end
  end
end
