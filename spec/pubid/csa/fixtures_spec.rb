# frozen_string_literal: true

require "spec_helper"

module CsaFixturesSpec
  # __dir__ is spec/pubid/csa, so the fixtures are two levels up, not three,
  # and the directory is lowercase. The old path ("../../../fixtures/CSA")
  # pointed at a non-existent repo-root fixtures/ and made this whole spec a
  # no-op: it iterated an empty file list and reported 0 examples. The
  # uppercase half of the same defect resolves only on a case-insensitive
  # filesystem, so it would still have run 0 examples on Linux CI.
  FIXTURES_DIR = File.expand_path("../../fixtures/csa/identifiers", __dir__)

  PASS_FILES = Dir.glob(File.join(FIXTURES_DIR, "pass", "*.txt")).freeze
  FAIL_FILES = Dir.glob(File.join(FIXTURES_DIR, "fail", "*.txt")).freeze
  FULL_FILE = File.join(FIXTURES_DIR, "full", "identifiers.txt")
end

RSpec.describe "CSA fixture round-trip" do
  include FixtureFileHelper

  def passing_inputs
    CsaFixturesSpec::PASS_FILES.flat_map do |file|
      read_pass_fixture_entries(file).map(&:first)
    end
  end

  def failing_inputs
    CsaFixturesSpec::FAIL_FILES.flat_map do |file|
      read_fail_fixture_inputs(file)
    end
  end

  # The tripwire. Every example below is generated from a glob, so a wrong
  # path yields zero examples and zero failures — the failure mode this spec
  # spent its whole life in. This example fails instead.
  it "finds the generated fixture files" do
    expect(CsaFixturesSpec::PASS_FILES).not_to be_empty
    expect(CsaFixturesSpec::FAIL_FILES).not_to be_empty
  end

  CsaFixturesSpec::PASS_FILES.each do |fixture_file|
    describe "pass/#{File.basename(fixture_file)}" do
      it "parses every identifier and renders it as recorded" do
        entries = read_pass_fixture_entries(fixture_file)
        expect(entries).not_to be_empty

        failures = entries.filter_map do |input, expected|
          rendered = Pubid::Csa.parse(input).to_s
          if rendered == expected
            nil
          else
            { input: input, expected: expected, rendered: rendered }
          end
        rescue StandardError => e
          { input: input, expected: expected,
            error: "#{e.class}: #{e.message}" }
        end

        expect(failures).to be_empty,
                            "CSA pass fixtures did not round-trip: " \
                            "#{failures.first(10).inspect}"
      end
    end
  end

  CsaFixturesSpec::FAIL_FILES.each do |fixture_file|
    describe "fail/#{File.basename(fixture_file)}" do
      it "rejects every identifier" do
        inputs = read_fail_fixture_inputs(fixture_file)
        expect(inputs).not_to be_empty

        accepted = inputs.select do |input|
          Pubid::Csa.parse(input)
          true
        rescue StandardError
          false
        end

        expect(accepted).to be_empty,
                            "recorded as unparseable but now parses: " \
                            "#{accepted.inspect}"
      end
    end
  end

  # The conservation law. `classify_fixtures.rb` rebuilds pass/ and fail/ from
  # full/identifiers.txt, so the two sides must account for exactly the same
  # identifiers. A half-written classification run, or a fixture hand-added to
  # pass/ without being added to full/ (which the next run would silently
  # delete), breaks this equality and nothing else does.
  it "classifies every identifier in full/, and no others" do
    # Both sides are uniqued because full/identifiers.txt carries a few
    # duplicate lines and the classifier itself dedupes before classifying.
    source = read_pass_fixture_entries(CsaFixturesSpec::FULL_FILE).map(&:first)

    expect((passing_inputs + failing_inputs).uniq.sort).to eq(source.uniq.sort)
  end

  # Uniquing the union above would absorb an identifier recorded on both
  # sides, so the partition is asserted separately. An identifier cannot be
  # both parseable and unparseable.
  it "records no identifier as both passing and failing" do
    expect(passing_inputs & failing_inputs).to be_empty
  end
end
