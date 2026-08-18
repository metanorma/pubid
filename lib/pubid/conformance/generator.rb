# frozen_string_literal: true

module Pubid
  module Conformance
    # Migrates the ground-truth fixture library (spec/fixtures/{flavor}/
    # identifiers/{pass,fail}/*.txt) into the neutral corpus by running the
    # reference implementation. Every non-empty, non-comment fixture line
    # becomes exactly one entry; unparseable pass lines are recorded as
    # visible debt (_unparsed.yml); fail lines become negative cases
    # (_negative.yml). Nothing is sampled, filtered, or dropped.
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
        results = { files: 0, cases: 0, negative: 0, debt: 0,
                    roundtrip_failures: 0 }
        debt = []
        pass_files.each do |path|
          type = File.basename(path, ".txt")
          cases, type_debt = build_pass_cases(path, type, results)
          debt.concat(type_debt)
          next if cases.empty?

          write_yaml(File.join(output_dir, "#{type}.yml"), cases)
          results[:files] += 1
        end
        results[:debt] = debt.size
        write_yaml(File.join(output_dir, "_unparsed.yml"), debt) if debt.any?
        negative = build_negative_cases(results)
        if negative.any?
          write_yaml(File.join(output_dir, "_negative.yml"), negative)
        end
        results
      end

      private

      def pass_files
        Dir[File.join(fixtures_dir, "identifiers", "pass", "*.txt")]
      end

      def fail_files
        Dir[File.join(fixtures_dir, "identifiers", "fail", "*.txt")]
      end

      def fixtures_dir
        File.expand_path("../../../spec/fixtures/#{@flavor}", __dir__)
      end

      def fixture_lines(path)
        File.readlines(path).map(&:strip).reject do |line|
          line.empty? || line.start_with?("#")
        end
      end

      def build_pass_cases(path, type, results)
        cases = []
        debt = []
        fixture_lines(path).each_with_index do |input, index|
          id = format("%s.%s.%04d", @flavor, type, index + 1)
          record = build_record(input, id)
          if record.key?(:debt)
            debt << record[:debt]
            next
          end
          results[:roundtrip_failures] += 1 unless record[:case]["roundtrip"]
          cases << record[:case]
          results[:cases] += 1
        end
        [cases, debt]
      end

      def build_record(input, id)
        identifier = @flavor_module.parse(input)
        hash = identifier.to_hash
        representations = { "human" => identifier.to_s }
        urn = safe_urn(identifier)
        representations["urn"] = urn if urn
        { case: { "id" => id,
                  "input" => input,
                  "identifier" => Conformance.component_tree(hash),
                  "representations" => representations,
                  "roundtrip" => round_trips?(hash) } }
      rescue StandardError => e
        { debt: { "id" => "#{id}.debt", "input" => input,
                  "expect" => { "error" => { "class_name" => e.class.name } },
                  "notes" => "unparsed ground-truth fixture: " \
                             "#{e.class}: #{e.message.to_s[0, 200]}" } }
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
          fixture_lines(path).each_with_index do |input, index|
            cases << negative_case(format("%s.neg.%s.%04d",
                                          @flavor, type, index + 1), input)
            results[:negative] += 1
          end
        end
        cases
      end

      def negative_case(id, input)
        @flavor_module.parse(input)
        { "id" => id, "input" => input,
          "notes" => "fail fixture unexpectedly parsed - reclassify" }
      rescue StandardError => e
        { "id" => id, "input" => input,
          "expect" => { "error" => { "class_name" => e.class.name } } }
      end

      def write_yaml(path, entries)
        File.write(path, YAML.dump(entries))
      end
    end
  end
end
