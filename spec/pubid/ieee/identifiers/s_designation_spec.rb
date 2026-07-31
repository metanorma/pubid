# frozen_string_literal: true

require "spec_helper"

# Historical IEEE/IPCEA co-published cable designation, e.g. S-135
# (IEEE Xplore doc 8694198, "S-135/IPCEA P-46-426-1962"). The "S-<digits>"
# number carries a dash between the letter series and the digits, which the
# shared `number` rule intentionally rejects (that tightening is what makes a
# bare "IEEE S" fail — see root_number_spec.rb). So this family gets its own
# parser rule and builds a plain Standard whose code carries the whole "S-135"
# string as `number` (prefix nil) — the shape that renders the dash back and
# keeps `root.number` non-empty for the relaton index.
RSpec.describe "IEEE S-designation (IPCEA cable) identifier" do
  subject(:klass) { Pubid::Ieee::Identifier }

  # ref => canonical to_s
  {
    "IEEE S-135/IPCEA P-46-426-1962" => "IEEE Std S-135/IPCEA P-46-426-1962",
    "S-135/IPCEA P-46-426-1962" => "IEEE Std S-135/IPCEA P-46-426-1962",
    "IEEE S-135 (IPCEA P46-426)" => "IEEE Std S-135 (IPCEA P46-426)",
    "IEEE Std S-135" => "IEEE Std S-135",
    "IEEE S-135" => "IEEE Std S-135",
  }.each do |ref, canonical|
    context ref.inspect do
      let(:id) { klass.parse(ref) }

      it "parses to a plain Standard" do
        expect(id).to be_a(Pubid::Ieee::Identifiers::Standard)
      end

      it "serializes with _type pubid:ieee:standard" do
        expect(id.to_hash["_type"]).to eq("pubid:ieee:standard")
      end

      it "has a non-empty root.number (the index key)" do
        expect(id.root.number).to eq("S-135")
      end

      it "compacts the stage to \"Std\"" do
        h = id.to_hash
        expect(h["stage"]).to eq("Std")
        expect(h).not_to have_key("typed_stage")
      end

      it "renders canonically" do
        expect(id.to_s).to eq(canonical)
      end

      it "round-trips through to_hash/from_hash" do
        h = id.to_hash
        expect(klass.from_hash(h).to_hash).to eq(h)
      end

      it "renders identically after a from_hash round-trip" do
        expect(klass.from_hash(id.to_hash).to_s).to eq(id.to_s)
      end
    end
  end

  # The Defect-1 fix (numberless reject) must NOT be loosened: a bare letter
  # series with no dash+digit is still not a valid identifier.
  it "still rejects the numberless \"IEEE S\"" do
    expect { klass.parse("IEEE S") }.to raise_error(Parslet::ParseFailed)
  end
end
