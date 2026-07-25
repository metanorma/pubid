# frozen_string_literal: true

require "spec_helper"

RSpec.describe "CEN/CENELEC stage codes — issue #251" do
  let(:all_stages) { Pubid::CenCenelec.all_typed_stages }
  let(:all_harmonized) { all_stages.flat_map(&:harmonized_stages).sort.uniq }

  ISSUE_CODES = %w[
    00.60 10.98 10.99 20.60 30.97 30.98 30.99
    40.20 40.60 40.97 40.98 40.99
    43.20 43.60 43.97 43.98 45.97 45.98 45.99
    50.20 50.60 50.97 50.98
    60.55 60.60 65.31 65.51 65.62
    90.00 90.20 90.60 90.92 90.93 90.98 96.60 99.60
  ].freeze

  it "covers every stage code from the issue body" do
    missing = ISSUE_CODES - all_harmonized
    expect(missing).to be_empty,
                           "these codes are not in any typed stage: #{missing.inspect}"
  end

  it "has the new typed stages (pwien, fven, ven, rven, racen, wden)" do
    codes = all_stages.map(&:code).map(&:to_s)
    %w[pwien fven ven rven racen wden].each do |code|
      expect(codes).to include(code), "missing typed stage #{code}"
    end
  end

  it "extends puben with 60.55 and 65.xx publication milestones" do
    puben = all_stages.find { |s| s.code.to_s == "puben" }
    expect(puben.harmonized_stages).to include("60.55", "65.31", "65.51", "65.62")
  end

  it "extends pren with 30.97 (split/merge)" do
    pren = all_stages.find { |s| s.code.to_s == "pren" }
    expect(pren.harmonized_stages).to include("30.97")
  end
end
