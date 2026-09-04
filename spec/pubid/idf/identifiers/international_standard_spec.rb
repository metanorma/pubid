require "spec_helper"

RSpec.describe Pubid::Idf::Identifiers::InternationalStandard do
  subject { described_class }

  describe "parse identifiers from examples" do
    shared_examples "parse identifiers from file" do
      it "parse identifiers from file" do
        f = open("spec/fixtures/#{examples_file}")
        f.readlines.each do |pub_id|
          next if pub_id.match?("^#")
          next if pub_id.strip.empty?

          pub_id_str = pub_id.split("#").first.strip.chomp
          expect { described_class.parse(pub_id_str) }.not_to raise_error
        end
      end
    end

    context "parses identifiers from is.txt" do
      let(:examples_file) { "idf/identifiers/full/idf-is.txt" }

      it_behaves_like "parse identifiers from file"
    end
  end

  # IDF 125A:1988
  describe "parse IDF 125A:1988" do
    subject { "IDF 125A:1988" }

    let (:parsed) { described_class.parse(subject) }

    it "parses publisher" do
      expect(parsed.publisher.body).to eq("IDF")
    end

    it "parses number" do
      expect(parsed.number).to eq("125A")
    end

    it "parses date" do
      expect(parsed.date.year).to eq("1988")
    end

    it "round-trips" do
      expect(parsed.to_s).to eq(subject)
    end
  end

  # IDF 124-2:2005
  describe "parse IDF 124-2:2005" do
    subject { "IDF 124-2:2005" }

    let (:parsed) { described_class.parse(subject) }

    it "parses publisher" do
      expect(parsed.publisher.body).to eq("IDF")
    end

    it "parses number" do
      expect(parsed.number).to eq("124")
    end

    it "parses part" do
      expect(parsed.part).to eq("2")
    end

    it "parses date" do
      expect(parsed.date.year).to eq("2005")
    end

    it "round-trips" do
      expect(parsed.to_s).to eq(subject)
    end
  end

  # IDF 259
  describe "parse IDF 259" do
    subject { "IDF 259" }

    let (:parsed) { described_class.parse(subject) }

    it "parses publisher" do
      expect(parsed.publisher.body).to eq("IDF")
    end

    it "parses number" do
      expect(parsed.number).to eq("259")
    end

    it "has no part" do
      expect(parsed.part).to be_nil
    end

    it "has no date" do
      expect(parsed.date).to be_nil
    end

    it "round-trips" do
      expect(parsed.to_s).to eq(subject)
    end
  end
end
