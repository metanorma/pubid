# frozen_string_literal: true

module Pubid
  module Conformance
    # Executes the pubid-testsuite corpus against this implementation.
    # CLEAN flavors hard-gate (failures abort); DIRTY flavors report as
    # the known reference-defect ledger.
    class Runner
      REGISTRY_KEYS = { "tgpp" => "3gpp" }.freeze

      def run(flavors = corpus_flavors)
        require "pubid"

        Pubid.eager_load_flavors!
        flavors.each_with_object([]) do |flavor, failures|
          failures.concat(run_flavor(flavor))
        end
      end

      private

      def corpus_flavors
        Dir[File.join(corpus_dir, "*")].select { |p| File.directory?(p) }
                                       .map { |p| File.basename(p) }
      end

      def corpus_dir
        File.join(ENV.fetch("PUBID_TESTSUITE_PATH",
                            File.expand_path("../../../../pubid-testsuite",
                                             __dir__)), "tests")
      end

      def run_flavor(flavor)
        flavor_module = Pubid::Registry.get(
          REGISTRY_KEYS.fetch(flavor, flavor)
        )
        raise ArgumentError, "unknown flavor #{flavor}" if flavor_module.nil?

        stats = Hash.new(0)
        failures = []
        Corpus.case_files(flavor, corpus_dir).each do |path|
          Corpus.load_file(path).each do |test_case|
            execute(test_case, flavor_module, stats, failures)
          end
        end
        report(flavor, stats, failures)
        known_dirty?(flavor) ? [] : failures
      end

      def known_dirty?(flavor)
        status = File.join(corpus_dir, flavor, "_status.yaml")
        File.exist?(status) && !YAML.safe_load_file(status)["clean"]
      end

      # Every corpus case lands in exactly one quadrant:
      #   pass | FAIL (not pending, breaks the CLEAN gate) | pending
      #   (explicitly not handled yet, see Conformance::Pending) | review
      #   (the expectation itself is flagged for human verification).
      def execute(test_case, flavor_module, stats, failures)
        id = test_case.id
        return stats[:review] += 1 if test_case.review?

        if Pending.for(id)
          run_pending(id, test_case, flavor_module, stats, failures)
        else
          run_case(test_case, flavor_module, stats, failures)
        end
      end

      # Pending cases still run: a pending case that PASSES is reported as
      # pending-satisfied - a cleanup alarm, the marker must be removed.
      def run_pending(id, test_case, flavor_module, stats, failures)
        stats[:pending] += 1
        before = failures.size
        run_case(test_case, flavor_module, stats, failures)
        return failures.slice!(before..) if failures.size > before

        stats[:pending_satisfied] += 1
        puts "  PENDING-SATISFIED #{id} - remove the marker"
      end

      def run_case(test_case, flavor_module, stats, failures)
        id = test_case.id
        if test_case.error_case?
          execute_error_case(test_case, flavor_module, stats, failures)
          return
        end
        return stats[:quarantined] += 1 if test_case.quarantined?

        identifier = flavor_module.parse(test_case.representations.human)
        stats[:cases] += 1
        check_tree(identifier, test_case, id, stats, failures)
        check_representations(identifier, test_case, id, stats, failures)
        check_aliases(test_case, id, flavor_module, stats, failures)
        check_roundtrip(identifier, flavor_module, test_case, id, stats,
                        failures)
      rescue StandardError => e
        stats[:fail_parse] += 1
        failures << "#{id} raised #{e.class}"
      end

      def execute_error_case(test_case, flavor_module, stats, failures)
        stats[:error_cases] += 1
        flavor_module.parse(test_case.input)
        stats[:fail_error] += 1
        failures << "#{test_case.id} unexpectedly parsed"
      rescue StandardError
        stats[:error_ok] += 1
      end

      def check_tree(identifier, test_case, id, stats, failures)
        actual = Conformance.plainify(identifier.to_hash)
        return if actual == test_case.identifier

        stats[:fail_tree] += 1
        failures << "#{id} canonical hash"
      end

      def check_representations(identifier, test_case, id, stats, failures)
        test_case.representations.to_hash.each do |format, expected|
          actual = represent(identifier, format)
          next if actual == expected

          stats[:"fail_#{format}"] += 1
          failures << "#{id} representation #{format}"
        end
      end

      def check_aliases(test_case, id, flavor_module, stats, failures)
        human = test_case.representations.human
        test_case.non_normalized_aliases.each do |entry|
          aliased = flavor_module.parse(entry.spelling)
          next if aliased.to_s == human

          stats[:fail_alias] += 1
          failures << "#{id} alias #{entry.spelling}"
        rescue StandardError
          stats[:fail_alias] += 1
          failures << "#{id} alias #{entry.spelling} raised"
        end
      end

      def check_roundtrip(identifier, flavor_module, test_case, id, stats,
                          failures)
        return unless test_case.roundtrip_failure_expected?

        hash = identifier.to_hash
        ok = flavor_module::Identifier.from_hash(hash).to_hash == hash
        return if ok

        stats[:fail_roundtrip] += 1
        failures << "#{id} roundtrip"
      rescue StandardError
        stats[:fail_roundtrip] += 1
        failures << "#{id} roundtrip raised"
      end

      def represent(identifier, format)
        case format
        when "human" then identifier.to_s
        when "urn" then identifier.to_urn
        else raise ArgumentError, "unknown representation #{format}"
        end
      end

      def report(flavor, stats, failures)
        puts format(
          "%-6s cases=%-6d err=%-4d quar=%-3d fail=%-4d " \
          "pend=%-4d pendok=%-3d review=%d",
          flavor, stats[:cases], stats[:error_cases], stats[:quarantined],
          failures.size, stats[:pending], stats[:pending_satisfied],
          stats[:review]
        )
        failures.first(10).each { |f| puts "  FAIL #{f}" }
      end
    end
  end
end
