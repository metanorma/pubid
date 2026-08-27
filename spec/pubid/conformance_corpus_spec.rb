# frozen_string_literal: true

require "spec_helper"
require "yaml"

# Executes the neutral corpus from the pubid-testsuite repository
# (tests/{flavor}/*.yaml) against the Ruby reference implementation.
# Negatives (tests/{flavor}/_negative.yaml, expect.error rows) gate
# rejection behavior here; reclassification rows (fail fixtures the
# reference now parses) are report-only in rake conformance:run, and
# debt (_debt.yaml) stays a visible ledger in the testsuite.
RSpec.describe "pubid-testsuite corpus" do
  corpus_repo = ENV.fetch("PUBID_TESTSUITE_PATH",
    File.expand_path("../../../pubid-testsuite", __dir__))
  corpus_present = File.directory?(File.join(corpus_repo, "tests"))
  if !corpus_present && ENV["GITHUB_WORKFLOW"] && ENV["GITHUB_WORKFLOW"] != "conformance"
    # The rake matrix does not carry a pubid-testsuite checkout; the dedicated
    # conformance workflow gates the corpus. Skip loudly here - never
    # silently pass, never fail an unrelated matrix.
    before { skip "pubid-testsuite corpus absent; gated by the conformance workflow" }
  elsif !corpus_present
    raise "pubid-testsuite corpus not found at #{corpus_repo}: " \
          "clone pubid/pubid-testsuite as a sibling or set PUBID_TESTSUITE_PATH"
  end
  tests_repo = ENV.fetch("PUBID_TESTSUITE_PATH",
                         File.expand_path("../../../pubid-testsuite", __dir__))
  flavors = Dir[File.join(tests_repo, "tests", "*")]
             .select { |path| File.directory?(path) }
             .map { |path| File.basename(path) }

  flavors = flavors.reject do |flavor|
    status = File.join(tests_repo, "tests", flavor, "_status.yaml")
    next true if File.exist?(status) && !YAML.safe_load_file(status)["clean"]

    type = Dir[File.join(tests_repo, "tests", flavor, "*.yaml")]
           .reject { |path| File.basename(path).start_with?("_") }
    type.empty? # flavors with only fail-fixtures have no cases to gate
  end

  flavors.each do |flavor|
    it "passes every #{flavor} case", :aggregate_failures do
      Pubid.eager_load_flavors!
      registry_key = { "tgpp" => "3gpp" }.fetch(flavor, flavor)
      flavor_module = Pubid::Registry.get(registry_key)
      expect(flavor_module).not_to be_nil, "unknown flavor #{flavor}"

      type_files = Dir[File.join(tests_repo, "tests", flavor, "*.yaml")]
                   .reject { |path| File.basename(path).start_with?("_") }
      expect(type_files).not_to be_empty

      # Returns the case's mismatch list (empty == passing). Deliberately
      # NOT built from `expect`: under :aggregate_failures a failed
      # expectation does not raise, so exception-based control flow would
      # misread real failures as passes (and pending cases as satisfied).
      check = lambda do |test_case|
        label = "#{flavor}/#{test_case.id}"
        reps = test_case.representations
        mismatches = []

        begin
          identifier = flavor_module.parse(reps.human)
        rescue StandardError => e
          next mismatches << "#{label} raised #{e.class}"
        end

        actual = Pubid::Conformance.plainify(identifier.to_hash)
        mismatches << "#{label} canonical hash" if actual != test_case.identifier
        mismatches << "#{label} human" if identifier.to_s != reps.human
        mismatches << "#{label} urn" if reps.urn && identifier.to_urn != reps.urn

        if test_case.roundtrip_failure_expected?
          begin
            hash = identifier.to_hash
            mismatches << "#{label} round-trip exception recorded" if
              flavor_module::Identifier.from_hash(hash).to_hash != hash
          rescue StandardError
            mismatches << "#{label} round-trip raised"
          end
        end

        mismatches
      end

      negative_file = File.join(tests_repo, "tests", flavor, "_negative.yaml")
      if File.exist?(negative_file)
        Pubid::Conformance::Corpus.load_file(negative_file).each do |test_case|
          # Rows without expect.error are reclassification alarms
          # (fail fixtures the reference now parses) - runner territory.
          next unless test_case.error_case?

          expect { flavor_module.parse(test_case.input) }
            .to raise_error(StandardError),
                "#{flavor}/#{test_case.id} unexpectedly parsed"
        end
      end

      pending_satisfied = []
      type_files.each do |path|
        Pubid::Conformance::Corpus.load_file(path).each do |test_case|
          # review: the EXPECTATION is flagged for human verification -
          # reported, never executed as a gate.
          next if test_case.review?
          next if test_case.quarantined? # reference-bug debt

          if Pubid::Conformance::Pending.for(test_case.id)
            pending_satisfied << test_case.id if check.call(test_case).empty?
            next
          end

          expect(check.call(test_case)).to be_empty
        end
      end

      expect(pending_satisfied).to be_empty,
                                  "pending markers satisfied (remove them): " \
                                  "#{pending_satisfied.first(5).join(', ')}"
    end
  end
end
