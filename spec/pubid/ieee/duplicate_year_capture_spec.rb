# frozen_string_literal: true

require "spec_helper"

# Several IEEE grammar rules carried a base "-YYYY" clause AND a separate
# trailing "Month YYYY" clause, both of which captured :year. When an input
# satisfied both (e.g. "IEEE Std 802.11-2007 September 2009"), Parslet merged
# the sequence hash, found two :year keys, warned "Duplicate subtrees … keys:
# [:year]", and kept only the LATTER — silently dropping the base identity year.
#
# Per IEEE practice the base "-YYYY" is the IEEE-SA Standards Board approval
# year (the document identity), so it must win; a trailing "Month YYYY" is a
# reaffirm/reprint/crawl artifact pubid has no model for and is dropped when a
# base year is present, and promoted to the identity only when there is none.
# The trailing captures now use distinct keys (:trailing_month/:trailing_year),
# so the collision — and the warning — are gone.
# (hand-off: ieee-identifier-duplicate-year-capture.)
# Any month name that must NOT survive on a base-year render.
DUP_YEAR_MONTHS = %w[September May February June].freeze

# One representative per affected rule (generic Std branch, IEEE P, ANSI P,
# Draft P); each pairs a base "-YYYY" with a trailing month/year.
DUP_YEAR_BASE_CASES = {
  "IEEE Std 802.11-2007 September 2009" => "2007",
  "IEEE Std 519-1992, May 1993" => "1992",
  "IEEE P90003-2014, February 2015" => "2014",
  "ANSI P1234-2015, June 2016" => "2015",
  "IEEE Draft P802.11-2010 September 2011" => "2010",
}.freeze

RSpec.describe "IEEE duplicate :year capture" do
  subject(:klass) { Pubid::Ieee::Identifier }

  describe "base year wins, trailing date dropped (no warning)" do
    DUP_YEAR_BASE_CASES.each do |ref, expected_year|
      context ref.inspect do
        it "parses without the Parslet duplicate-subtree warning" do
          expect { klass.parse(ref) }
            .not_to output(/Duplicate subtrees/).to_stderr
        end

        it "keeps the base year #{expected_year}, drops the trailing date" do
          id = klass.parse(ref)
          expect(id.year).to eq(expected_year)
          expect(id.to_s).to include("-#{expected_year}")
          # No fabricated trailing month survives on the rendered form.
          DUP_YEAR_MONTHS.each { |m| expect(id.to_s).not_to include(m) }
        end
      end
    end
  end

  describe "no base year: trailing month/year is promoted to the identity" do
    {
      "IEEE Std 519, May 1993" => %w[1993 May],
      "IEEE 802.16, September 2011" => %w[2011 September],
    }.each do |ref, (year, month)|
      context ref.inspect do
        it "promotes the trailing date and still emits no warning" do
          expect { klass.parse(ref) }
            .not_to output(/Duplicate subtrees/).to_stderr
          id = klass.parse(ref)
          expect(id.year).to eq(year)
          expect(id.month).to eq(month)
        end
      end
    end
  end

  it "leaves a plain base-year id unchanged" do
    id = klass.parse("IEEE Std 528-2019")
    expect(id.year).to eq("2019")
    expect(id.month).to be_nil
    expect(id.to_s).to eq("IEEE Std 528-2019")
  end
end
