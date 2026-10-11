# frozen_string_literal: true

require "spec_helper"

RSpec.describe "corrigendum narrative bases" do
  it "builds a corrigendum whose base subtree binds as a sequence array" do
    id = Pubid::Ieee.parse(
      "IEEE Std 1484.12.1-2002/Cor 1-2011 " \
      "(Corrigendum to IEEE Std 1484.12.1-2002)",
    )
    expect(id).to be_a(Pubid::Ieee::Identifiers::Corrigendum)
    expect(id.to_s).to eq("IEEE Std 1484.12.1-2002/Cor. 1-2011")
  end

  it "accepts the dash-glued Cor spelling with a narrative" do
    id = Pubid::Ieee.parse(
      "IEEE Std C57.12.31-2010-Cor 1-2014 (Corrigendum to IEEE Std C57.12.31-2010)",
    )
    expect(id.to_s).to eq("IEEE Std C57.12.31-2010/Cor. 1-2014")
  end

  it "keeps the amendment narrative bounded on a corrigendum tail" do
    id = Pubid::Ieee.parse(
      "IEEE Std 802.15.4-2015/Cor 1-2018 (Amendment to IEEE Std 802.15.4-2015)",
    )
    expect(id).to be_a(Pubid::Ieee::Identifiers::Corrigendum)
    expect(id.to_s).to eq("IEEE Std 802.15.4-2015/Cor. 1-2018")
  end

  it "round-trips the built corrigendum through its hash" do
    id = Pubid::Ieee.parse(
      "IEEE Std C37.20.7-2007/Cor 1-2010 (Corrigendum to IEEE Std C37.20.7-2007)",
    )
    expect(Pubid::Ieee::Identifier.from_hash(id.to_hash).to_hash).to eq(id.to_hash)
  end
end
