# frozen_string_literal: true

require "spec_helper"

# The flavor that parses a foreign adoption ("GOST 1437-2024 (ASTM
# D129-18)") must not depend on which flavor module the host application
# happened to load first. Registry insertion order is module-load order,
# and IEEE's grammar also accepts "ASTM D129-18" (ASTM as a publisher
# token, D129-18 as an IEEE code), so the old first-success loop routed
# the same adoption to Pubid::Ieee::Identifiers::Standard in processes
# where IEEE registered first and to Pubid::Astm::Identifiers::Standard
# in the rest - a per-process, run-to-run corpus flake.
RSpec.describe "Pubid::Gost foreign adoption routing" do
  # Force the adversarial registration order (IEEE before ASTM) by moving
  # both to the end of the registry hash in that order, and restore the
  # original order afterwards: the registry is process-global shared state.
  around do |example|
    Pubid.eager_load_flavors! # registry fills lazily; snapshot it complete
    original = Pubid::Registry.flavors.to_a
    registry = Pubid::Registry.flavors
    %w[ieee astm].each do |name|
      mod = registry.delete(name)
      registry[name] = mod if mod
    end
    example.run
    registry.clear
    original.each { |name, mod| registry[name] = mod }
  end

  it "routes by owning prefix, not registry load order" do
    adopted = Pubid::Gost.parse("GOST 1437-2024 (ASTM D129-18)")
      .adopted_identifiers.first
    expect(adopted).to be_a(Pubid::Astm::Identifiers::Standard)
    expect(adopted.to_s).to eq("ASTM D129-18")
  end

  it "routes identically without adversarial ordering" do
    adopted = Pubid::Gost.parse("GOST 1437-2024 (ASTM D129-18)")
      .adopted_identifiers.first
    expect(adopted).to be_a(Pubid::Astm::Identifiers::Standard)
  end

  it "falls back to a ForeignReference for an unregistered owner" do
    adopted = Pubid::Gost.parse("ГОСТ 34853-2022 (OECD 460:2017)")
      .adopted_identifiers.first
    expect(adopted).to be_a(Pubid::Gost::Identifiers::ForeignReference)
  end

  it "routes slash adoptions through the owning flavor" do
    adopted = Pubid::Gost.parse("ГОСТ 31610.18-2016/IEC 60079-18:2014").adopted
    expect(adopted).to be_a(Pubid::Iec::Identifier)
  end
end
