# frozen_string_literal: true

module Pubid
  module Conformance
    # Executes the neutral corpus against this implementation. Gates per
    # case: the parse must rebuild the recorded component tree, reproduce
    # every recorded representation, normalize every alias to the canonical
    # human form, and round-trip where recorded. Debt and negative files
    # are executed as error expectations. Exits non-zero on any failure.
    class Runner
      def run(flavors = corpus_flavors)
        require "pubid"

        Pubid.eager_load_flavors!
        flavors.each_with_object([]) do |flavor, failures|
          failures.concat(run_flavor(flavor))
        end
      end

      private

      def corpus_flavors
        Dir[File.join(corpus_dir, "*")].select { |path| File.directory?(path) }
                                       .map { |p| File.basename(p) }
      end

      def corpus_dir
        File.expand_path("../../../conformance", __dir__)
      end

      def run_flavor(flavor)
        flavor_module = Pubid::Registry.get(flavor)
        raise ArgumentError, "unknown flavor #{flavor}" if flavor_module.nil?

        stats = Hash.new(0)
        failures = []
        Dir[File.join(corpus_dir, flavor, "*.yml")].each do |path|
          YAML.safe_load_file(path).each do |test_case|
            execute(test_case, flavor_module, stats, failures)
          end
        end
        report(flavor, stats, failures)
        failures
      end

      def execute(test_case, flavor_module, stats, failures)
        id = test_case.fetch("id")
        expectation = test_case["expect"]
        if expectation&.key?("error")
          execute_error_case(test_case, flavor_module, stats, failures)
          return
        end
        return stats[:quarantined] += 1 if test_case["identifier"].nil?

        identifier = flavor_module.parse(test_case.fetch("input"))
        stats[:cases] += 1
        check_tree(identifier, test_case, id, stats, failures)
        check_aliases(identifier, test_case, id, flavor_module, stats,
                      failures)
        check_representations(identifier, test_case, id, stats, failures)
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
        actual = Conformance.component_tree(identifier.to_hash)
        return if actual == test_case.fetch("identifier")

        stats[:fail_tree] += 1
        failures << "#{id} component tree"
      end

      def check_aliases(identifier, test_case, id, flavor_module, stats,
                        failures)
        Array(test_case["non_normalized_aliases"]).each do |entry|
          aliased = flavor_module.parse(entry["input"])
          next if aliased.to_s == test_case.dig("representations", "human")

          stats[:fail_alias] += 1
          failures << "#{id} alias #{entry['input']}"
        rescue StandardError
          stats[:fail_alias] += 1
          failures << "#{id} alias #{entry['input']} raised"
        end
      end

      def check_representations(identifier, test_case, id, stats, failures)
        test_case.fetch("representations").each do |format, expected|
          actual = represent(identifier, format)
          next if actual == expected

          stats[:"fail_#{format}"] += 1
          failures << "#{id} representation #{format}"
        end
      end

      def check_roundtrip(identifier, flavor_module, test_case, id, stats,
                          failures)
        return unless test_case["roundtrip"]

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
