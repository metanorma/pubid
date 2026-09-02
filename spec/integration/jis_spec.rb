# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/pubid/jis"

RSpec.describe "JIS Integration" do
  describe "parsing and rendering" do
    shared_examples "parses and renders correctly" do |input, expected_output = nil|
      it "parses and renders #{input}" do
        expected = expected_output || input
        identifier = Pubid::Jis.parse(input)
        expect(identifier.to_s).to eq(expected)
      end
    end

    context "basic standards" do
      it_behaves_like "parses and renders correctly", "JIS A 0001:1999"
      it_behaves_like "parses and renders correctly", "JIS B 0001:2019"
      it_behaves_like "parses and renders correctly", "JIS C 0303:2000"
    end

    context "without year" do
      it_behaves_like "parses and renders correctly", "JIS A 0001"
      it_behaves_like "parses and renders correctly", "JIS B 0060"
    end

    context "with parts" do
      it_behaves_like "parses and renders correctly", "JIS A 1129-1:2010"
      it_behaves_like "parses and renders correctly", "JIS B 0060-1:2015"
      it_behaves_like "parses and renders correctly", "JIS C 61000-3-2:2019"
    end

    context "with language" do
      it_behaves_like "parses and renders correctly", "JIS Z 8301:2019(E)"
      it_behaves_like "parses and renders correctly", "JIS Z 8301:2019(J)"
    end

    context "all-parts notation" do
      it_behaves_like "parses and renders correctly", "JIS C 0617（規格群）"
      it_behaves_like "parses and renders correctly", "JIS B 0060（規格群）"
    end

    context "technical reports" do
      it_behaves_like "parses and renders correctly", "JIS TR Z 8301:2019"
      it_behaves_like "parses and renders correctly", "JIS TR B 0035:2019"
      it_behaves_like "parses and renders correctly", "JIS/TR X 0005:1998",
                      "JIS TR X 0005:1998"
      it_behaves_like "parses and renders correctly", "TR B 0035:2019",
                      "JIS TR B 0035:2019"
    end

    context "technical specifications" do
      it_behaves_like "parses and renders correctly", "JIS TS Z 8301:2019"
      it_behaves_like "parses and renders correctly", "JIS TS Z 0030-1:2017"
      it_behaves_like "parses and renders correctly", "TS Z0030-1:2017",
                      "JIS TS Z 0030-1:2017"
    end

    context "amendments" do
      it_behaves_like "parses and renders correctly",
                      "JIS A 0001:1999/AMD 1:2000"
      it_behaves_like "parses and renders correctly",
                      "JIS X 0208:1997/AMENDMENT 1:2012", "JIS X 0208:1997/AMD 1:2012"
    end

    context "explanations" do
      it_behaves_like "parses and renders correctly", "JIS K 2151:2004/EXPL"
      it_behaves_like "parses and renders correctly",
                      "JIS K 2249-4:2011/EXPL 4"
      it_behaves_like "parses and renders correctly",
                      "JIS K 2249-4:2011/EXPLANATION 4", "JIS K 2249-4:2011/EXPL 4"
    end

    context "corrigenda" do
      it_behaves_like "parses and renders correctly",
                      "JIS B 3700-11:1996/CORRIGENDUM 1:2002"
      it_behaves_like "parses and renders correctly",
                      "JIS A 0001:1999/CORR 1:2002",
                      "JIS A 0001:1999/CORRIGENDUM 1:2002"
    end

    context "reaffirmation (R suffix)" do
      it_behaves_like "parses and renders correctly", "JIS C 9901:2019R"
      it_behaves_like "parses and renders correctly", "JIS L 4107:2000R"
      it_behaves_like "parses and renders correctly",
                      "JIS K 6912:1995/AMENDMENT 2:2006R",
                      "JIS K 6912:1995/AMD 2:2006R"
      it_behaves_like "parses and renders correctly",
                      "JIS L 4107:2000R/AMENDMENT 1:2020",
                      "JIS L 4107:2000R/AMD 1:2020"
    end

    context "graphical-symbol sub-reference (SYMBOL)" do
      it_behaves_like "parses and renders correctly",
                      "JIS Z 8210:2017 SYMBOL 61700"
      it_behaves_like "parses and renders correctly",
                      "JIS L 0001:2024 SYMBOL New and revised"
      it_behaves_like "parses and renders correctly",
                      "JIS Z 8211-1:2025 SYMBOL"
      it_behaves_like "parses and renders correctly",
                      "JIS Z 8210:2017/AMENDMENT 1:2019 SYMBOL 51590",
                      "JIS Z 8210:2017/AMD 1:2019 SYMBOL 51590"
      it_behaves_like "parses and renders correctly",
                      "JIS Z 8210:2017/AMENDMENT 2:2019R SYMBOL JE210",
                      "JIS Z 8210:2017/AMD 2:2019R SYMBOL JE210"
    end

    context "Japanese characters" do
      it_behaves_like "parses and renders correctly", "JIS　B　0001",
                      "JIS B 0001"
      it_behaves_like "parses and renders correctly", "JIS C 61000ｰ3ｰ2",
                      "JIS C 61000-3-2"
      it_behaves_like "parses and renders correctly", "JIS C 61000-3-2：2011",
                      "JIS C 61000-3-2:2011"
      it_behaves_like "parses and renders correctly", "JISX0902-1:2019",
                      "JIS X 0902-1:2019"
      it_behaves_like "parses and renders correctly", "JISX0836:2005",
                      "JIS X 0836:2005"
    end

    context "without publisher prefix" do
      it_behaves_like "parses and renders correctly", "B 0001", "JIS B 0001"
      it_behaves_like "parses and renders correctly", "A 0001:1999",
                      "JIS A 0001:1999"
    end
  end

  describe "all_parts comparison" do
    it "matches identifiers with same series and number regardless of year/part" do
      all_parts_id = Pubid::Jis.parse("JIS C 0617（規格群）")
      specific_id = Pubid::Jis.parse("JIS C 0617-2:2017")

      expect(all_parts_id).to eq(specific_id)
      expect(specific_id).to eq(all_parts_id)
    end

    it "does not match identifiers with different series" do
      all_parts_id = Pubid::Jis.parse("JIS C 0617（規格群）")
      different_id = Pubid::Jis.parse("JIS C 0618-1")

      expect(all_parts_id).not_to eq(different_id)
    end
  end
end
