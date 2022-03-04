require "parslet/rig/rspec"

RSpec.describe PubidIso::Parser do
  subject { described_class.new }

  context "Identifiers list from file" do
    it "parses identifiers from iso-sample-identifiers-v2.txt" do
      f = open("spec/fixtures/iso-sample-identifiers-v2.txt")
      f.readlines.each do |pub_id|
        next if pub_id.match?("^#")
        expect(subject).to parse(pub_id.chomp)
      end
    end

    it "parses identifiers from iso-sample-identifiers-additional.txt" do
      f = open("spec/fixtures/iso-sample-identifiers-additional.txt")
      f.readlines.each do |pub_id|
        next if pub_id.match?("^#")
        expect(subject).to parse(pub_id.chomp)
      end
    end
  end
end
