# frozen_string_literal: true

require "spec_helper"

# The draft reader returns the Draft component, and == compares the raw
# ivars — so the two construction paths must agree on the runtime
# objects, not just the serialized hash. lutaml's from_hash assigns the
# COMPACT serialized value (no leading "/") directly; the parse paths
# store the same compact form, and from_hash materializes the runtime
# components eagerly (pubid#596: the PC-prefixed joint rows compared
# unequal on @code_obj/@draft_obj while their hashes agreed).
RSpec.describe "IEEE draft reader convergence (pubid#596)" do
  let(:ieee) { (Pubid.eager_load_flavors!; Pubid::Registry.get("ieee")) }

  it "converges the compact wire form on every construction path" do
    id = ieee.parse("IEEE P1/D5, Jan, 2026")
    expect(id.draft_obj.to_s).to eq("/D5, Jan 2026")
    expect(id.instance_variable_get(:@draft)).to eq("D5, Jan 2026")
    expect(id.class.from_hash(id.to_hash).instance_variable_get(:@draft)).to eq("D5, Jan 2026")
  end

  it "materializes the runtime components after from_hash" do
    id = ieee.parse("IEEE P1/D5, Jan, 2026")
    rebuilt = id.class.from_hash(id.to_hash)
    expect(rebuilt.draft_obj).to eq(id.draft_obj)
    expect(rebuilt.code_obj).to eq(id.code_obj)
    expect(rebuilt).to eq(id)
  end

  it "keeps the rendered face untouched" do
    id = ieee.parse("IEEE P1/D5, Jan, 2026")
    expect(id.to_s).to eq("IEEE P1/D5, Jan, 2026")
    expect(id.class.from_hash(id.to_hash).to_s).to eq("IEEE P1/D5, Jan, 2026")
  end

  # The residual, documented on pubid#596: on the PC-prefixed joint rows
  # the parse path's Draft splits the designator (version "P62271-111_D6",
  # revision "1") while Draft.parse keeps it verbatim ("P62271-111_D6.1").
  # The rendered face, the serialized hash and the URN are identical — the
  # inequality is confined to the Draft component's internal split, and
  # converging it risks the dot-glued-year faces ("SI 10.1997") and the
  # D2.1.1 verbatim doctrine.
  it "round-trips the PC-prefixed joint row on the identity surfaces" do
    id = ieee.parse("IEC/IEEE PC37.60/DP62271-111_D6.1, Aug 2016")
    rebuilt = id.class.from_hash(id.to_hash)
    expect(rebuilt.to_hash).to eq(id.to_hash)
    expect(rebuilt.to_s).to eq(id.to_s)
    expect(rebuilt.code_obj).to eq(id.code_obj)
  end
end
