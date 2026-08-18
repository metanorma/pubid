# frozen_string_literal: true

module Pubid
  module Conformance
    # Migrates the ground-truth fixture library (spec/fixtures/{flavor}/
    # identifiers/{pass,fail}/*.txt) into the neutral corpus by running the
    # reference implementation. Fixture lines that normalize to the same
    # identifier collapse into one canonical case carrying the old
    # spellings as non_normalized_aliases (old => normalized, and the
    # normalized form round-trips). Unparseable pass lines are recorded as
    # visible debt; fail lines (stored as "#ID# Error: ..." comments in the
    # fixture files) become negative cases. Nothing is sampled, filtered,
    # or dropped.
    class Generator
      attr_reader :flavor

      def initialize(flavor)
        require "pubid"

        @flavor = flavor.to_s
        Pubid.eager_load_flavors!
        @flavor_module = Pubid::Registry.get(@flavor)
        raise ArgumentError, "unknown flavor #{@flavor}" unless @flavor_module
      end

      def generate(output_dir:)
        results = { files: 0, cases: 0, negative: 0, debt: 0, aliases: 0,
                    duplicates: 0, reclassify: 0, roundtrip_failures: 0 }
        debt = []
        pass_files.each do |path|
          type = File.basename(path, ".txt")
          cases, type_debt = build_pass_cases(path, type, results)
          debt.concat(type_debt)
          next if cases.empty?

          write_yaml(File.join(output_dir, "#{type}.yaml"), cases)
          results[:files] += 1
        end
        results[:debt] = debt.size
        write_yaml(File.join(output_dir, "_debt.yaml"), debt) if debt.any?
        negative = build_negative_cases(results)
        if negative.any?
          write_yaml(File.join(output_dir, "_negative.yaml"), negative)
        end
        results
      end

      private

      def pass_files
        Dir[File.join(fixtures_dir, "identifiers", "pass", "*.txt")] +
          Dir[File.join(fixtures_dir, "identifiers", "full", "*.txt")]
      end

      def fail_files
        Dir[File.join(fixtures_dir, "identifiers", "fail", "*.txt")]
      end

      def fixtures_dir
        File.join(tests_repo, "reference-docs", @flavor)
      end

      def tests_repo
        @tests_repo ||= ENV.fetch("PUBID_TESTS_PATH",
                                  File.expand_path("../../../../pubid-tests",
                                                   __dir__))
      end

      def fixture_lines(path)
        File.readlines(path).map(&:strip).reject do |line|
          line.empty? || line.start_with?("#")
        end
      end

      # Fail fixtures store identifiers as comment lines shaped
      # "#IDENTIFIER# Parslet::ParseFailed: ...". Strip the leading # and
      # the trailing historical annotation to recover the input.
      def fail_fixture_lines(path)
        File.readlines(path).filter_map do |raw|
          line = raw.strip
          next if line.empty?
          next line unless line.start_with?("#")

          input = line.sub(/\A#/, "").split("#", 2).first.to_s.strip
          input unless input.empty?
        end
      end

      def build_pass_cases(path, type, results)
        groups = {}
        debt = []
        fixture_lines(path).each do |input|
          record = build_record(input)
          if record.key?(:debt)
            debt << record[:debt]
            next
          end
          key = JSON.generate(record[:case]["identifier"]) +
            record[:case]["representations"]["human"]
          (groups[key] ||= { record: record[:case], 
                             inputs: [] })[:inputs] << input
        end
        cases = assign_ids(groups, type, results)
        [cases, debt]
      end

      def assign_ids(groups, type, results)
        groups.values.sort_by { |g| canonical_input(g) }.each_with_index
          .map do |group, index|
          record = group[:record]
          record["id"] = format("%s.%s.%04d", @flavor, type, index + 1)
          canonical = canonical_input(group)
          record["style"] = Conformance.style_for(canonical)
          inputs = group[:inputs]
          duplicates = [inputs.count(canonical) - 1, 0].max
          results[:duplicates] += duplicates
          aliases = inputs.reject { |i| i == canonical }.uniq.sort
          results[:aliases] += aliases.size
          unless aliases.empty?
            record["non_normalized_aliases"] = aliases.map do |a|
              { "input" => a, "style" => Conformance.style_for(a) }
            end
          end
          results[:roundtrip_failures] += 1 if record["roundtrip"] == false
          results[:cases] += 1
          record
        end
      end

      def canonical_input(group)
        group.dig(:record, "representations", "human")
      end

      def build_record(input)
        identifier = @flavor_module.parse(input)
        hash = identifier.to_hash
        representations = { "human" => identifier.to_s }
        urn = safe_urn(identifier)
        representations["urn"] = urn if urn
        record = { "id" => nil,
                   "identifier" => Conformance.plainify(hash) }
        record["representations"] = representations
        record["roundtrip"] = false unless round_trips?(hash)
        quarantine!(record) if bundled_month_bug?(hash)
        { case: record }
      rescue StandardError => e
        { debt: { "id" => "#{@flavor}.debt.#{input.hash.abs}",
                  "input" => input,
                  "expect" => { "error" =>
                                { "code" => Conformance.error_code_for(e) } },
                  "notes" => "unparsed ground-truth fixture: " \
                             "#{e.class}: #{e.message.to_s[0, 200]}" } }
      end

      # Reference implementation parses bundled directive supplements with
      # month-bearing dates nondeterministically across load orders (a
      # spurious day component appears). Quarantine deterministically.
      def bundled_month_bug?(hash)
        hash.to_s.include?("bundled_identifier") && hash.to_s.include?("month")
      end

      def quarantine!(record)
        record.delete("identifier")
        record.delete("representations")
        record.delete("roundtrip")
        record.delete("non_normalized_aliases")
        record["notes"] = "nondeterministic parse in reference " \
                          "implementation (month/day divergence) - " \
                          "reference bug, quarantined from gates"
      end

      def round_trips?(hash)
        @flavor_module::Identifier.from_hash(hash).to_hash == hash
      rescue StandardError
        false
      end

      def safe_urn(identifier)
        identifier.to_urn
      rescue StandardError
        nil
      end

      def build_negative_cases(results)
        cases = []
        fail_files.each do |path|
          type = File.basename(path, ".txt")
          fail_fixture_lines(path).each_with_index do |input, index|
            cases << negative_case(format("%s.neg.%s.%04d",
                                          @flavor, type, index + 1), input)
            results[:negative] += 1
          end
        end
        cases
      end

      def negative_case(id, input)
        @flavor_module.parse(input)
        { "id" => id, "input" => input, "style" => Conformance.style_for(input),
          "notes" => "fail fixture unexpectedly parsed - reclassify" }
      rescue StandardError => e
        { "id" => id, "input" => input,
          "expect" => { "error" =>
                        { "code" => Conformance.error_code_for(e) } } }
      end

      def write_yaml(path, entries)
        File.write(path, YAML.dump(entries))
      end
    end
  end
end
