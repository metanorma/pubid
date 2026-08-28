# frozen_string_literal: true

module Pubid
  module Conformance
    # The single check core shared by the conformance runner and the rspec
    # corpus gate. One corpus case in, its mismatch list out (empty ==
    # passing). The list shape is load-bearing: RSpec's aggregate_failures
    # does not raise on a failed expectation, so exception-based control
    # flow would misread real failures as passes - and the runner needs to
    # accumulate across cases rather than abort.
    module Checks
      class << self
        # @param test_case [Pubid::Conformance::Corpus::Case]
        # @param flavor_module [Module] the flavor owning the case
        # @return [Array<String>] mismatch descriptions, empty when passing
        def check_case(test_case, flavor_module)
          parsed = parse_or_mismatch(test_case, flavor_module)
          return parsed if parsed.is_a?(Array)

          identifier = parsed
          mismatchers(identifier, test_case, flavor_module)
            .flat_map(&:call)
        end

        def parse_or_mismatch(test_case, flavor_module)
          [flavor_module.parse(test_case.representations.human)]
        rescue StandardError => e
          ["#{test_case.id} raised #{e.class}"]
        end

        # Each checker returns the case's mismatch list for its concern.
        def mismatchers(identifier, test_case, flavor_module)
          label = test_case.id.to_s
          [
            -> { canonical_mismatches(identifier, test_case, label) },
            -> { representation_mismatches(identifier, test_case, label) },
            -> { alias_mismatches(test_case, flavor_module, label) },
            -> { deserialize_mismatches(identifier, flavor_module, label) },
          ]
        end

        def canonical_mismatches(identifier, test_case, label)
          actual = Conformance.plainify(identifier.to_hash)
          actual == test_case.identifier ? [] : ["#{label} canonical hash"]
        end

        private

        def representation_mismatches(identifier, test_case, label)
          mismatches = []
          reps = test_case.representations
          mismatches << "#{label} human" if identifier.to_s != reps.human
          if reps.urn && identifier.to_urn != reps.urn
            mismatches << "#{label} urn"
          end
          mismatches
        end

        def alias_mismatches(test_case, flavor_module, label)
          human = test_case.representations.human
          test_case.non_normalized_aliases.filter_map do |entry|
            aliased = flavor_module.parse(entry.spelling)
            "#{label} alias #{entry.spelling}" if aliased.to_s != human
          rescue StandardError
            "#{label} alias #{entry.spelling} raised"
          end
        end

        def deserialize_mismatches(identifier, flavor_module, label)
          hash = identifier.to_hash
          ok = flavor_module::Identifier.from_hash(hash).to_hash == hash
          ok ? [] : ["#{label} deserialize"]
        rescue StandardError
          ["#{label} deserialize raised"]
        end
      end
    end
  end
end
