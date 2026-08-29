# frozen_string_literal: true

require "spec_helper"

# `#root` must reach the origin document for every flavor, regardless of how a
# wrapper stores its parent. After the base_identifier -> base rename the parent
# accessor is uniformly `base`, and `#root` walks it. This spec locks the
# contract across all camps:
#   - base camp: every wrapper exposes `base`; #root walks it to the origin
#   - consolidated bundles (`identifiers` collection): #root -> first id's root
#   - CSA containers: real identifiers too, walking `base`/`identifiers`
Pubid.eager_load_flavors!

RSpec.describe Pubid::Identifier do
  describe "#root" do
    context "ISO (nested supplements)" do
      it "returns base for amendment" do
        expect(Pubid::Iso.parse("ISO 9001:2015/Amd 1:2020").root.to_s)
          .to eq("ISO 9001:2015")
      end

      it "returns base for corrigendum" do
        expect(Pubid::Iso.parse("ISO 9001:2015/Cor 1:2020").root.to_s)
          .to eq("ISO 9001:2015")
      end

      it "peels nested supplements to the origin" do
        id = Pubid::Iso.parse("ISO 9001:2015/Amd 1:2020/Cor 1:2021")
        expect(id.root.to_s).to eq("ISO 9001:2015")
      end

      it "returns self for a plain standard" do
        id = Pubid::Iso.parse("ISO 9001:2015")
        expect(id.root).to eq(id)
      end

      it "returns self for an undated standard" do
        id = Pubid::Iso.parse("ISO 9001")
        expect(id.root).to eq(id)
      end
    end

    # These flavors store the parent under `base`; before the rename #root
    # walked only the old accessor and wrongly returned self for them.
    context "flavors that store the parent under `base`" do
      {
        "Etsi" => "ETSI ETR 108/A1 ed.1 (1995-08)",
        "Itu" => "Annex to ITU OB No. 1283",
        "Jis" => "JIS A 0001:1999/AMD 1:2000",
        "Gost" => "ГОСТ 25346-2013 (ISO 286-1:2010)",
      }.each do |mod, string|
        it "#{mod}: #root reaches the origin (not self)" do
          id = Pubid.const_get(mod).parse(string)
          expect(id.root).not_to equal(id)
          # fully peeled: the origin document has no further parent
          expect(id.root.base).to be_nil
        end
      end

      it "JIS amendment root is the base standard" do
        expect(Pubid::Jis.parse("JIS A 0001:1999/AMD 1:2000").root.to_s)
          .to eq("JIS A 0001:1999")
      end
    end

    context "consolidated bundles (identifiers collection)" do
      it "IEC consolidated root is the first bundled identifier" do
        id = Pubid::Iec.parse("IEC 60529:1989+AMD1:1999")
        expect(id).to be_a(Pubid::Iec::Identifiers::ConsolidatedIdentifier)
        expect(id.root).not_to equal(id)
        expect(id.root.to_s).to eq("IEC 60529:1989")
      end
    end

    context "CSA container types" do
      it "a Canadian adoption roots to the standard it wraps" do
        id = Pubid::Csa.parse("CAN/CSA-A123.2-03")
        expect(id.root).not_to equal(id)
        expect(id.root).to be_a(Pubid::Csa::Identifiers::Standard)
        expect(id.root.number.to_s).to eq("A123.2")
      end

      it "a combined id roots to its primary designation" do
        id = Pubid::Csa.parse("CSA A23.1:24/CSA A23.2:24")
        expect(id.root.to_s).to eq("CSA A23.1:24")
      end
    end
  end

  describe "uniform `base` accessor" do
    it "ISO amendment exposes its parent under #base" do
      id = Pubid::Iso.parse("ISO 9001:2015/Amd 1:2020")
      expect(id.base).to be_a(Pubid::Iso::Identifiers::InternationalStandard)
      expect(id.base.to_s).to eq("ISO 9001:2015")
    end

    it "chains through nested supplements via #base" do
      id = Pubid::Iso.parse("ISO 9001:2015/Amd 1:2020/Cor 1:2021")
      expect(id.base.base.to_s).to eq("ISO 9001:2015")
    end

    it "a plain standard has a nil #base" do
      expect(Pubid::Iso.parse("ISO 9001:2015").base).to be_nil
    end
  end

  describe "base_identifier is fully removed" do
    it "wrappers no longer respond to base_identifier" do
      id = Pubid::Iso.parse("ISO 9001:2015/Amd 1:2020")
      expect(id).not_to respond_to(:base_identifier)
    end
  end

  describe "every registered flavor's Identifier responds to #root" do
    Pubid::Registry.flavor_names.each do |flavor_name|
      it "#{flavor_name}::Identifier responds to #root" do
        mod = Pubid::Registry.get(flavor_name)
        expect(mod.const_get(:Identifier).instance_methods).to include(:root)
      end
    end
  end
end
