require "parslet/rig/rspec"

RSpec.describe Pubid::Iso::Parser do
  subject { described_class.new }

  context "Identifiers list from file" do
    it "parses identifiers from iso-pubid-basic.txt" do
      f = open("spec/fixtures/iso-pubid-basic.txt")
      f.readlines.each do |pub_id|
        next if pub_id.match?("^#")
        expect(subject).to parse(pub_id.chomp)
      end
    end

    it "parses identifiers from iso-pubid-nsb.txt" do
      f = open("spec/fixtures/iso-pubid-nsb.txt")
      f.readlines.each do |pub_id|
        next if pub_id.match?("^#")
        expect(subject).to parse(pub_id.chomp)
      end
    end

    it "parses identifiers from iso-pubid-coramd.txt" do
      f = open("spec/fixtures/iso-pubid-coramd.txt")
      f.readlines.each do |pub_id|
        next if pub_id.match?("^#")
        expect(subject).to parse(pub_id.chomp)
      end
    end

    xit "parses identifiers from iso-pubid-languages.txt" do
      f = open("spec/fixtures/iso-pubid-languages.txt")
      f.readlines.each do |pub_id|
        next if pub_id.match?("^#")
        expect(subject).to parse(pub_id.chomp)
      end
    end

    xit "parses identifiers from iwa-pubid.txt" do
      f = open("spec/fixtures/iwa-pubid.txt")
      f.readlines.each do |pub_id|
        next if pub_id.match?("^#")
        expect(subject).to parse(pub_id.chomp)
      end
    end
  end
end
