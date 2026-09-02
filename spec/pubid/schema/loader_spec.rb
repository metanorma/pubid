# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Schema::Loader do
  describe ".for" do
    it "loads the iso declaration" do
      declaration = described_class.for(:iso)
      expect(declaration.flavor).to eq("iso")
      expect(declaration.prefixes).to eq(["ISO"])
      expect(declaration.types_count).to eq(18)
      expect(declaration.type_for("amendment").title).to eq("Amendment")
    end

    it "loads the iec declaration" do
      declaration = described_class.for(:iec)
      expect(declaration.types_count).to eq(19)
      expect(declaration.prefixes)
        .to eq(%w[IEC CISPR IECEE IECEx IECQ])
    end

    it "merges joint prefixes from core" do
      expect(described_class.for(:iso).merged_prefixes)
        .to eq(%w[ISO ISO/IEC IEC/ISO ISO/IEC/IEEE])
    end

    it "memoizes declarations" do
      expect(described_class.for(:iso)).to equal(described_class.for("iso"))
    end

    it "freezes declarations deeply" do
      declaration = described_class.for(:iec)
      expect(declaration).to be_frozen
      expect(declaration.prefixes).to be_frozen
      expect(declaration.identifier_types).to be_frozen
    end

    it "raises NotFoundError for unknown flavors" do
      expect { described_class.for(:nonexistent) }
        .to raise_error(Pubid::Schema::NotFoundError)
    end

    it "resolves typed stages by abbreviation" do
      stage = described_class.for(:iso).type_for("amendment")
        .typed_stage_for_abbr("FDAM")
      expect(stage.stage_code).to eq("fdamd")
      expect(stage.harmonized_stages).to include("50.00")
    end
  end
end
