# frozen_string_literal: true

require "spec_helper"

# Historical publisher identity is immutable: documents published by NBS
# (the National Bureau of Standards, renamed NIST in 1988) carry NBS
# identifiers forever. An NBS->NIST rewrite is legitimate ONLY when the
# document itself was published post-1988 (a mislabelled NIST publication).
RSpec.describe "NBS publisher identity" do
  it "update_codes rewrite NBS->NIST only for post-1988 documents" do
    codes = Pubid::Core::UpdateCodes.for_flavor(:nist)
    violations = codes.select do |input, output|
      in_s = input.to_s
      out_s = output.to_s
      has_nbs = in_s.match?(/NBS/)
      has_nist = out_s.match?(/NIST/)
      next false unless has_nbs && has_nist

      years = "#{in_s} #{out_s}".scan(/(?:19|20)\d{2}/).map(&:to_i)
      years.empty? ? true : years.any? { |y| y <= 1988 }
    end
    expect(violations).to be_empty,
                          "date-invalid NBS->NIST rewrites: #{violations.inspect}"
  end

  it "NBS-prefixed identifiers parse and render with NBS preserved" do
    ["NBS HB 105-1", "NBS CIRC 154", "NBS FIPS 140", "NBS CS-E 104"].each do |input|
      expect(Pubid::Nist.parse(input).to_s).to start_with("NBS"), input
    end
  end

  it "corpus never records NBS aliases on NIST canonicals" do
    tests_repo = ENV.fetch("PUBID_TESTS_PATH",
                           File.expand_path("../../../../pubid-tests", __dir__))
    nist = File.join(tests_repo, "tests", "nist")
    skip "pubid-tests not checked out" unless Dir.exist?(nist)

    crossed = []
    Dir[File.join(nist, "*.yaml")].each do |path|
      next if File.basename(path).start_with?("_")

      YAML.safe_load_file(path).each do |t|
        human = t.dig("representations", "human").to_s
        next unless human.start_with?("NIST")

        Array(t["non_normalized_aliases"]).each do |a|
          spelling = a["spelling"].to_s
          if spelling.match?(/\bNBS\b/)
            crossed << [t["id"], spelling, human]
          end
        end
      end
    end
    expect(crossed).to be_empty, "identity crossings: #{crossed.first(3).inspect}"
  end
end
