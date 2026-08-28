# frozen_string_literal: true

require "spec_helper"

# The flavor that parses a foreign adoption ("GOST 1437-2024 (ASTM
# D129-18)") must not depend on which flavor module the host application
# happened to load first. Two structural guarantees keep it that way:
# routing goes through the registered prefix index (longest single-owner
# prefix first, sorted fallback), and Registry.flavors is a key-sorted
# frozen view - registration (= module load) order is not observable.
RSpec.describe "Pubid::Gost foreign adoption routing" do
  it "routes by owning prefix" do
    adopted = Pubid::Gost
      .parse("GOST 1437-2024 (ASTM D129-18)").adopted_identifiers.first
    expect(adopted).to be_a(Pubid::Astm::Identifiers::Standard)
    expect(adopted.to_s).to eq("ASTM D129-18")
  end

  it "falls back to a ForeignReference for an unregistered owner" do
    adopted = Pubid::Gost
      .parse("ГОСТ 34853-2022 (OECD 460:2017)").adopted_identifiers.first
    expect(adopted).to be_a(Pubid::Gost::Identifiers::ForeignReference)
  end

  it "routes slash adoptions through the owning flavor" do
    adopted = Pubid::Gost.parse("ГОСТ 31610.18-2016/IEC 60079-18:2014").adopted
    expect(adopted).to be_a(Pubid::Iec::Identifier)
  end

  describe "Pubid::Registry flavor view" do
    it "hides registration order behind a sorted frozen view" do
      # A late registration (hosts autoload flavors in any order) must not
      # shift any consumer's iteration: the view stays key-sorted, and the
      # raw table is not public mutable state.
      Pubid::Registry.register(:zz_probe, Pubid::Astm)
      names = Pubid::Registry.flavors.keys
      expect(names).to eq(names.sort)
      expect(names.last).to eq("zz_probe")
      expect(Pubid::Registry.flavors).to be_frozen
      expect { Pubid::Registry.flavors[:hack] = Pubid::Astm }
        .to raise_error(FrozenError)
    end
  end
end
