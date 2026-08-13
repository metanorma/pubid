# frozen_string_literal: true

require "spec_helper"

# `to_s(trademark: true)` renders the IEEE trademark symbol: ® for the
# registered-trademark series (802/8802/2030), ™ for everything else. The mark
# attaches to the document number, before the year and every suffix — see
# spec/pubid/ieee/trademark_position_spec.rb and metanorma/pubid#322. Plain
# `to_s` is unchanged. relaton emits this as a second "trademark"-scoped
# docidentifier. (hand-off: ieee-trademark-rendering.)
RSpec.describe "IEEE trademark rendering" do
  subject(:klass) { Pubid::Ieee::Identifier }

  # ref => trademarked to_s
  {
    "IEEE Std 802.1AB-2016" => "IEEE Std 802.1AB®-2016",
    "IEEE Std 2030.5-2018" => "IEEE Std 2030.5®-2018",
    "IEEE Std 528-2019" => "IEEE Std 528™-2019",
    "IEEE Std C37.09-2018" => "IEEE Std C37.09™-2018",
  }.each do |ref, trademarked|
    context ref.inspect do
      let(:id) { klass.parse(ref) }

      it "renders the trademark symbol with trademark: true" do
        expect(id.to_s(trademark: true)).to eq(trademarked)
      end

      it "leaves plain to_s unchanged (default off)" do
        expect(id.to_s).to eq(ref)
      end
    end
  end

  it "marks the base number of a corrigendum wrapper, before the suffix" do
    id = klass.parse("IEEE Std 802.16-2004/Cor 1-2005")
    expect(id.to_s(trademark: true)).to eq("IEEE Std 802.16®-2004/Cor. 1-2005")
  end

  it "does not crash on AIEE and renders ™" do
    id = klass.parse("AIEE No 13-1930")
    expect(id.to_s(trademark: true)).to eq("AIEE No 13™-1930")
  end
end
