require "spec_helper"

RSpec.describe Pubid::Idf::Identifiers::ReviewedMethod do
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

    context "parses identifiers from rm.txt" do
      let(:examples_file) { "idf/identifiers/full/idf-rm.txt" }

      it_behaves_like "parse identifiers from file"
    end
  end

  # IDF/RM 254:2022
  describe "parse IDF/RM 254:2022" do
    subject { "IDF/RM 254:2022" }

    let (:parsed) { described_class.parse(subject) }

    it "parses publisher" do
      expect(parsed.publisher.body).to eq("IDF")
    end

    it "parses number" do
      expect(parsed.number).to eq("254")
    end

    it "parses part" do
      expect(parsed.part).to be_nil
    end

    it "parses date" do
      expect(parsed.date.year).to eq("2022")
    end

    it "round-trips" do
      expect(parsed.to_s).to eq(subject)
    end
  end

  # IDF/RM 233-1:2017
  describe "parse IDF/RM 233-1:2017" do
    subject { "IDF/RM 233-1:2017" }

    let (:parsed) { described_class.parse(subject) }

    it "parses publisher" do
      expect(parsed.publisher.body).to eq("IDF")
    end

    it "parses number" do
      expect(parsed.number).to eq("233")
    end

    it "parses part" do
      expect(parsed.part).to eq("1")
    end

    it "parses date" do
      expect(parsed.date.year).to eq("2017")
    end

    it "round-trips" do
      expect(parsed.to_s).to eq(subject)
    end
  end
end
