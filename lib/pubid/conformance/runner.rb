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
        case_files(flavor).each do |path|
          YAML.safe_load_file(path).each do |test_case|
            execute(test_case, flavor_module, stats, failures)
          end
        end
        report(flavor, stats, failures)
        known_dirty?(flavor) ? [] : failures
      end

      def case_files(flavor)
        Dir[File.join(corpus_dir, flavor, "*.yaml")]
          .reject { |path| File.basename(path).start_with?("_") }.sort
      end

      def known_dirty?(flavor)
        status = File.join(corpus_dir, flavor, "_status.yaml")
        File.exist?(status) && !YAML.safe_load_file(status)["clean"]
      end

      def execute(test_case, flavor_module, stats, failures)
        id = test_case.fetch("id")
        if test_case["expect"]&.key?("error")
          execute_error_case(test_case, flavor_module, stats, failures)
          return
        end
        return stats[:quarantined] += 1 if test_case["identifier"].nil?

        human = test_case.dig("representations", "human")
        identifier = flavor_module.parse(human)
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
        flavor_module.parse(test_case.fetch("input"))
        stats[:fail_error] += 1
        failures << "#{test_case['id']} unexpectedly parsed"
      rescue StandardError
        stats[:error_ok] += 1
      end

      def check_tree(identifier, test_case, id, stats, failures)
        actual = Conformance.plainify(identifier.to_hash)
        return if actual == test_case.fetch("identifier")

        stats[:fail_tree] += 1
        failures << "#{id} canonical hash"
      end

      def check_representations(identifier, test_case, id, stats, failures)
        test_case.fetch("representations").each do |format, expected|
          actual = represent(identifier, format)
          next if actual == expected

          stats[:"fail_#{format}"] += 1
          failures << "#{id} representation #{format}"
        end
      end

      def check_aliases(test_case, id, flavor_module, stats, failures)
        human = test_case.dig("representations", "human")
        Array(test_case["non_normalized_aliases"]).each do |entry|
          aliased = flavor_module.parse(entry["spelling"])
          next if aliased.to_s == human

          stats[:fail_alias] += 1
          failures << "#{id} alias #{entry['spelling']}"
        rescue StandardError
          stats[:fail_alias] += 1
          failures << "#{id} alias #{entry['spelling']} raised"
        end
      end

      def check_roundtrip(identifier, flavor_module, test_case, id, stats,
                          failures)
        return unless test_case["roundtrip"] == false

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
        puts format("%-6s cases=%-6d err=%-4d quar=%-3d fail=%d",
                    flavor, stats[:cases], stats[:error_cases],
                    stats[:quarantined], failures.size)
        failures.first(10).each { |f| puts "  FAIL #{f}" }
      end
    end
  end
end
