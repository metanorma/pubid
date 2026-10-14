# frozen_string_literal: true

require "spec_helper"

# The parenthetical revision target is a printed identifier and the model
# types revision_of as one — feeding the raw string crashed to_hash with
# Lutaml::Model::IncorrectModelError (16 debt rows, incl. the Redline
# twins). "Revision to" classifies the same as "Revision of".
RSpec.describe "IEEE revision-relationship modeling" do
  subject(:klass) { Pubid::Ieee::Identifier }

  {
    "IEEE Std 1207-2011 (Revision to IEEE Std 1207-2004)" => "IEEE Std 1207-2011",
    "IEEE Std C57.12.60-2009 ( Revision of IEEE Std C57.12.60-1998)" =>
      "IEEE Std C57.12.60-2009",
    "IEEE Std 1207-2011 (Revision to IEEE Std 1207-2004) - Redline" =>
      "IEEE Std 1207-2011 - Redline",
  }.each do |input, canonical|
    it "round-trips #{canonical.inspect}" do
      id = klass.parse(input)
      expect(id.to_s).to eq(canonical)
      expect { id.to_hash }.not_to raise_error
    end

    it "models the target as an identifier" do
      expect(klass.parse(input).revision_of).to be_a(Pubid::Ieee::Identifier)
    end
  end

  it "parses the printed target with its year" do
    id = klass.parse("IEEE Std 1207-2011 (Revision to IEEE Std 1207-2004)")
    expect(id.revision_of.to_s).to eq("IEEE Std 1207-2004")
  end
end
