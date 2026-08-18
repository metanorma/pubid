# frozen_string_literal: true

module Pubid
  module Conformance
    # Executes the neutral corpus against this implementation. Gates per
    # case: the parse must rebuild the recorded component tree and reproduce
    # every recorded representation; roundtrip must hold where recorded.
    # Debt and negative files are executed as error expectations. Exits
    # non-zero on any gate failure.
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
        @current_flavor = Pubid::Registry.get(flavor)
        if @current_flavor.nil?
          raise ArgumentError, "unknown flavor #{flavor}"
        end

        stats = Hash.new(0)
        failures = []
        files = Dir[File.join(corpus_dir, flavor, "*.yml")]
        files.each do |path|
          YAML.safe_load_file(path).each do |test_case|
            execute(test_case, @current_flavor, stats, failures)
          end
        end
        report(flavor, stats, failures)
        failures
      end

      def execute(test_case, @current_flavor, stats, failures)
        id = test_case.fetch("id")
        expectation = test_case["expect"]
        if expectation&.key?("error")
          execute_error_case(test_case, @current_flavor, stats, failures)
          return
        end

        if test_case["expect"].nil? && test_case["identifier"].nil?
          stats[:reclassify] += 1
          return
        end

        identifier = @current_flavor.parse(test_case.fetch("input"))
        stats[:cases] += 1
        check_aliases(identifier, test_case, id, stats, failures)
        check_tree(identifier, test_case, id, stats, failures)
        check_representations(identifier, test_case, id, stats, failures)
        check_roundtrip(identifier, @current_flavor, test_case, id, stats,
                        failures)
      rescue StandardError => e
        stats[:fail_parse] += 1
        failures << "#{id} raised #{e.class}"
      end

      def execute_error_case(test_case, @current_flavor, stats, failures)
        stats[:error_cases] += 1
        @current_flavor.parse(test_case.fetch("input"))
        stats[:fail_error] += 1
        failures << "#{test_case['id']} unexpectedly parsed"
      rescue StandardError
        stats[:error_ok] += 1
      end

      def check_aliases(identifier, test_case, id, stats, failures)
        Array(test_case["non_normalized_aliases"]).each do |alias_entry|
          aliased = flavor_parse(alias_entry["input"])
          next if aliased && aliased.to_s == test_case.dig("representations", 
                                                           "human")

          stats[:fail_alias] += 1
          failures << "#{id} alias #{alias_entry['input']}"
        end
      end

      def flavor_parse(input)
        @current_flavor.parse(input)
      rescue StandardError
        nil
      end

      def check_tree(identifier, test_case, id, stats, failures)
        actual = Conformance.component_tree(identifier.to_hash)
        return if actual == test_case.fetch("identifier")

        stats[:fail_tree] += 1
        failures << "#{id} component tree"
      end

      def check_representations(identifier, test_case, id, stats, failures)
        test_case.fetch("representations").each do |format, expected|
          actual = represent(identifier, format)
          next if actual == expected

          stats[:"fail_#{format}"] += 1
          failures << "#{id} representation #{format}"
        end
      end

      def check_roundtrip(identifier, @current_flavor, test_case, id, stats,
                          failures)
        return unless test_case["roundtrip"]

        hash = identifier.to_hash
        return if @current_flavor::Identifier.from_hash(hash).to_hash == hash

        stats[:fail_roundtrip] += 1
        failures << "#{id} roundtrip"
      rescue StandardError
        stats[:fail_roundtrip] += 1
        failures << "#{id} roundtrip raised"
      end

      def represent(identifier, format)
        case format
        when "human" then identifier.to_s
        when "urn" then safe_urn(identifier)
        else raise ArgumentError, "unknown representation #{format}"
        end
      end

      def safe_urn(identifier)
        identifier.to_urn
      rescue StandardError
        nil
      end

      def report(flavor, stats, failures)
        puts format("%-6s cases=%-6d error=%-4d reclassify=%-3d failures=%d",
                    flavor, stats[:cases], stats[:error_cases],
                    stats[:reclassify], failures.size)
        failures.first(10).each { |f| puts "  FAIL #{f}" }
        return if failures.size <= 10

        puts "  ... and #{failures.size - 10} more"
      end
    end
  end
end
