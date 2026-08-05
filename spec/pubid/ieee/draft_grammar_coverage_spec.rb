# frozen_string_literal: true

require "spec_helper"

# Closes the 3 draft-parsing gaps from the relaton-data-ieee index-v2 build:
# status-word prefixes, draft-then-corrigendum, and day/numeric-month draft
# dates (hand-off: ieee-draft-grammar-coverage). The relaton index gate is a
# successful parse + a non-empty root.number + a to_hash/from_hash round-trip,
# so every case asserts exactly those.
RSpec.describe "IEEE draft grammar coverage" do
  subject(:klass) { Pubid::Ieee::Identifier }

  def round_trips?(id)
    Pubid::Ieee::Identifier.from_hash(id.to_hash).to_hash == id.to_hash
  end

  describe "gap 1: status-word prefix on a P-draft" do
    status_forms = [
      "IEEE Active Unapproved Draft P1562/D11, July 2007",
      "IEEE Active Approved Draft P1562/D11, July 2007",
      "IEEE Unapproved Draft P1562/D11, July 2007",
      "IEEE Approved Draft P1562/D11, July 2007",
    ]

    status_forms.each do |ref|
      it "parses and round-trips #{ref.inspect}" do
        id = klass.parse(ref)
        expect(id.root.number.to_s).not_to be_empty
        expect(round_trips?(id)).to be true
      end
    end

    it "keeps the plain 'Draft P' form working (no status prefix)" do
      id = klass.parse("IEEE Draft P1562/D11, July 2007")
      expect(round_trips?(id)).to be true
    end
  end

  describe "gap 2: draft then trailing corrigendum /Cor. N" do
    cor_forms = [
      "IEEE Approved P1015/D1, Jan 2007/Cor. 1",
      "IEEE P1015/D1, Jan 2007/Cor. 1",
      "IEEE P1015/D1, Jan 2007/Cor 1",
    ]

    cor_forms.each do |ref|
      it "parses #{ref.inspect} as a Corrigendum with a base" do
        id = klass.parse(ref)
        expect(id).to be_a(Pubid::Ieee::Identifiers::Corrigendum)
        expect(id.base).not_to be_nil
        expect(id.root.number.to_s).not_to be_empty
        expect(round_trips?(id)).to be true
      end
    end
  end

  describe "gap 3: draft date with a day (no comma) or numeric month" do
    date_forms = [
      "IEEE P1143/D7, July 15 2012",
      "IEEE P1484.20.1/D7, 05 2007",
    ]

    date_forms.each do |ref|
      it "parses and round-trips #{ref.inspect}" do
        id = klass.parse(ref)
        expect(id.root.number.to_s).not_to be_empty
        expect(round_trips?(id)).to be true
      end
    end
  end
end
