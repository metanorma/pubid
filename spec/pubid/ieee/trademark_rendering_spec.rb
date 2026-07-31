# frozen_string_literal: true

require "spec_helper"

# `to_s(trademark: true)` appends the IEEE trademark symbol: ® for the
# registered-trademark series (802/2030), ™ for everything else. Plain `to_s`
# is unchanged. relaton emits this as a second "trademark"-scoped docidentifier.
# (hand-off: ieee-trademark-rendering.)
RSpec.describe "IEEE trademark rendering" do
  subject(:klass) { Pubid::Ieee::Identifier }

  # ref => trademarked to_s
  {
    "IEEE Std 802.1AB-2016" => "IEEE Std 802.1AB-2016®",
    "IEEE Std 2030.5-2018" => "IEEE Std 2030.5-2018®",
    "IEEE Std 528-2019" => "IEEE Std 528-2019™",
    "IEEE Std C37.09-2018" => "IEEE Std C37.09-2018™",
  }.each do |ref, trademarked|
    context ref.inspect do
      let(:id) { klass.parse(ref) }

      it "appends the trademark symbol with trademark: true" do
        expect(id.to_s(trademark: true)).to eq(trademarked)
      end

      it "leaves plain to_s unchanged (default off)" do
        expect(id.to_s).to eq(ref)
      end
    end
  end

  it "applies the symbol to a corrigendum wrapper's composed string" do
    id = klass.parse("IEEE Std 802.16-2004/Cor 1-2005")
    expect(id.to_s(trademark: true)).to eq("#{id}®")
  end

  it "does not crash on AIEE and appends ™" do
    id = klass.parse("AIEE No 13-1930")
    expect(id.to_s(trademark: true)).to eq("AIEE No 13-1930™")
  end
end
