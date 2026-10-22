# frozen_string_literal: true

require "spec_helper"

# pubid#555: the NCSTAR/NBS-HR letter part suffixes the corpus renders as
# "n<A>" (Part type "n") — 179 published relaton-data-nist rows. The
# rendered spelling raised ParseError before the n_letter_part rule.
RSpec.describe Pubid::Nist do
  {
    "NIST NCSTAR 1nA" => "1",
    "NBS HR 1-1nA" => "1-1",
    "NBS HR 10nA" => "10",
  }.each do |input, number|
    describe input do
      subject { described_class.parse(input) }

      it "parses" do
        expect(subject).not_to be_nil
      end

      it "carries the letter part as type n" do
        expect(subject.part.value).to eq("A")
        expect(subject.part.type).to eq("n")
      end

      it "carries the number without the suffix" do
        expect(subject.number.to_s).to eq(number)
      end

      it "round-trips" do
        expect(described_class.parse(subject.to_s)).to eq(subject)
      end
    end
  end

  it "keeps the plain letter suffix (type-less) form unchanged" do
    id = described_class.parse("NIST NCSTAR 1A")
    expect(id.part.value).to eq("A")
    expect(id.part.type).to be_nil.or eq("")
    expect(id.to_s).to eq("NIST NCSTAR 1A")
  end
end
