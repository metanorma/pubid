# frozen_string_literal: true

require "spec_helper"

# pubid used to silently drop digits from multi-part / hyphenated draft
# designators — the parser splits "1.2.6" into ["1.2", ".6"] and the builder's
# array merge kept only the last part, so "P754/D1.2.6" rendered as "…/D.6".
# The draft designator is now held verbatim (all parts concatenated, a leading
# hyphen normalized away), so no digit is ever lost and every draft round-trips.
# (hand-off: ieee-draft-string-attr.)
RSpec.describe "IEEE verbatim draft designator" do
  subject(:klass) { Pubid::Ieee::Identifier }

  # ref => the draft fragment that must survive in to_s
  {
    "IEEE Std P754/D1.2.6" => "D1.2.6",
    "IEEE Std P1666/D2.1.1" => "D2.1.1",
    "IEEE Std P802.8/D-3.0" => "D3.0", # leading hyphen normalized away
    "IEEE Std P802.8/D3.0" => "D3.0",
    "IEEE Std PC37.90/D15" => "D15",
  }.each do |ref, fragment|
    context ref.inspect do
      let(:id) { klass.parse(ref) }

      it "preserves every draft digit in to_s" do
        expect(id.to_s).to include(fragment)
      end

      it "round-trips through to_hash/from_hash" do
        h = id.to_hash
        expect(klass.from_hash(h).to_hash).to eq(h)
      end
    end
  end
end
