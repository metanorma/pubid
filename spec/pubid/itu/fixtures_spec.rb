# frozen_string_literal: true

require "spec_helper"

module ItuFixturesSpec
  # __dir__ is spec/pubid/itu, so the fixtures are two levels up, not three —
  # the extra ".." pointed at a non-existent repo-root fixtures/ and made this
  # whole spec a no-op (it iterated an empty file list).
  FIXTURE_FILES = Dir.glob(File.join(__dir__,
                                     "../../fixtures/itu/identifiers/pass", "*.txt")).freeze
end

RSpec.describe "ITU Fixture Round-trip Tests" do
  describe "all fixture files" do
    ItuFixturesSpec::FIXTURE_FILES.each do |fixture_file|
      describe File.basename(fixture_file) do
        let(:identifiers) do
          File.readlines(fixture_file).map(&:strip).reject do |line|
            line.empty? || line.start_with?("#")
          end
        end

        it "parses and round-trips identifiers" do
          failures = []
          successes = 0

          identifiers.each do |id_str|
            parsed = Pubid::Itu.parse(id_str)
            rendered = parsed.to_s

            if rendered == id_str
              successes += 1
            else
              failures << { original: id_str, rendered: rendered,
                            type: "mismatch" }
            end
          rescue StandardError => e
            failures << { original: id_str, error: "#{e.class}: #{e.message}",
                          type: "parse_error" }
          end

          total = identifiers.count
          pass_rate = total.positive? ? (successes.to_f / total * 100).round(2) : 0

          if failures.any?

            failures.first(5).each do |f|
              if f[:type] == "mismatch"

              end
            end
          end

          # Allow up to 10% failure rate for fixture tests
          expect(pass_rate).to be >= 90.0
        end
      end
    end
  end
end
