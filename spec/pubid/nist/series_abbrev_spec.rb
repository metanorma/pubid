# frozen_string_literal: true

require "spec_helper"

RSpec.describe "NIST series abbreviation coverage — issue #150" do
  let(:config) { Pubid::Nist.configuration }

  it "every registered series has a non-empty abbreviation" do
    missing = config.all_series_codes.select do |code|
      config.series_abbrev(code).to_s.empty?
    end
    expect(missing).to be_empty,
                       "these series are missing abbreviations: #{missing.inspect}"
  end

  # Spot-check the new entries from the issue body
  {
    "BH" => "Bldg. & Hous.",
    "BMS" => "Bldg. Mat. Struct.",
    "CIRC" => "Circ.",
    "EAB" => "Econ. Anal. Br.",
    "GCR" => "Grant/Contract Rpt.",
    "MP" => "Misc. Publ.",
    "OWMWP" => "Off. Weights Meas. WP",
    "RPT" => "Rpt.",
    "TTB" => "Tech. Transf. Br.",
  }.each do |code, expected|
    it "#{code} -> #{expected.inspect}" do
      expect(config.series_abbrev(code)).to eq(expected)
    end
  end

  it "the configuration loads from the monorepo data path" do
    expect(File).to exist(File.expand_path("../../../data/nist/series.yaml", __dir__))
  end
end
