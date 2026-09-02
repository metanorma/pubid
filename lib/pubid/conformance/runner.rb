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

        if flavors.empty?
          raise ArgumentError, "no corpus flavors found at #{corpus_dir} - " \
                               "refusing to report vacuous success"
        end

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
        Corpus.negative_file(flavor, corpus_dir).each do |path|
          Corpus.load_file(path).each do |test_case|
            execute_negative(test_case, flavor_module, stats, failures)
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
        if test_case.error_case?
          execute_error_case(test_case, flavor_module, stats, failures)
          return
        end
        return stats[:quarantined] += 1 if test_case.quarantined?

        stats[:cases] += 1
        Checks.check_case(test_case, flavor_module).each do |mismatch|
          stat_for(mismatch, stats)
          failures << mismatch
        end
      end

      def stat_for(mismatch, stats)
        case mismatch
        when / raised\z/ then stats[:fail_parse] += 1
        when /canonical hash/ then stats[:fail_tree] += 1
        when / human\z/, / urn\z/ then stats[:"fail_#{mismatch.split.last}"] += 1
        when / alias/ then stats[:fail_alias] += 1
        else stats[:fail_roundtrip] += 1
        end
      end

      # Negatives (fail fixtures decoded by the exporter). A row with
      # expect.error must be rejected by the reference; a row without it
      # is the exporter's reclassification alarm - the fail-fixture line
      # now parses, so the fixture belongs in pass/ - reported, never
      # gated, like the PENDING-SATISFIED alarm.
      def execute_negative(test_case, flavor_module, stats, failures)
        return stats[:reclass] += 1 unless test_case.error_case?

        execute_error_case(test_case, flavor_module, stats, failures)
      end

      def execute_error_case(test_case, flavor_module, stats, failures)
        stats[:error_cases] += 1
        flavor_module.parse(test_case.input)
        stats[:fail_error] += 1
        failures << "#{test_case.id} unexpectedly parsed"
      rescue StandardError
        stats[:error_ok] += 1
      end






      def report(flavor, stats, failures)
        puts format(
          "%-6s cases=%-6d err=%-4d quar=%-3d fail=%-4d " \
          "pend=%-4d pendok=%-3d reclass=%-4d review=%d",
          flavor, stats[:cases], stats[:error_cases], stats[:quarantined],
          failures.size, stats[:pending], stats[:pending_satisfied],
          stats[:reclass], stats[:review]
        )
        failures.first(10).each { |f| puts "  FAIL #{f}" }
      end
    end
  end
end
