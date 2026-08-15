# frozen_string_literal: true

require "spec_helper"

# ITU stores the document number on the `code` component. Relaton::Index keys
# its sort and bsearch narrowing on `id.root.number.to_s`, so every ITU type
# must surface a non-empty number at its root.
RSpec.describe "Pubid::Itu #root.number" do
  {
    "ITU-R P.530-19" => "530",              # recommendation
    "ITU-R 234-1/7:" => "234",              # numeric question
    "ITU-R P.3/BL/7" => "3",                # letter-series question
    "ITU-R 23.HDB" => "23",                 # handbook
    "Report ITU-R BT.2020-1 (2000)" => "2020",     # report
    "Report ITU-R BT.2020-1 Suppl. 1" => "2020",   # supplement -> report base
    "ITU-T G.780/Y.1351" => "780",          # combined (primary)
    "ITU-T E.156 Suppl. 2" => "156",        # supplement -> root is the base
    "ITU-T Z.100 (1999) Cor. 1 (10/2001)" => "100", # corrigendum -> base
    "ITU OB No. 1283 (01/2024)" => "1283",  # special publication
    "Annex to ITU OB No. 1000" => "1000",   # annex -> root is the base
    "ITU-T H.264 (V14) (08/2021)" => "264", # versioned recommendation
    "ITU-T A.23 Annex A (06/2014)" => "23", # labelled annex -> base
    # corrigendum -> annex -> base
    "ITU-T G.729 Annex B (1996) Cor. 3 (03/2001)" => "729",
  }.each do |ref, expected_number|
    context ref do
      let(:parsed) { Pubid::Itu.parse(ref) }

      it "exposes root.number as #{expected_number.inspect}" do
        expect(parsed.root.number.to_s).to eq(expected_number)
      end

      it "keys non-empty for Relaton::Index" do
        expect(parsed.root.number.to_s).not_to be_empty
      end
    end
  end

  it "leaves a plain recommendation's #number reading through to code.number" do
    expect(Pubid::Itu.parse("ITU-R P.530-19").number).to eq("530")
  end

  it "keeps a supplement's own #number as its ordinal" do
    # Supplement declares its own :string `number` (the ordinal); the base's
    # code number is reached via root.
    supplement = Pubid::Itu.parse("ITU-T E.156 Suppl. 2")
    expect(supplement.number).to eq("2")
    expect(supplement.root.number.to_s).to eq("156")
  end
end
