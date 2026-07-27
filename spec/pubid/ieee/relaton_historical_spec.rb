# frozen_string_literal: true

require "spec_helper"

# relaton's bespoke formatter (`Relaton::Ieee::PubId::Id#to_s`) serialized the
# `relaton-data-ieee` corpus with suffix spellings that differ from pubid's
# canonical grammar: `/D-N` drafts with a trailing `-YYYY[-MM]` numeric date,
# `/E-N` editions, `/R-N` revisions, `/CorN` corrigenda, and a bare ` Redline`
# suffix (no leading dash). To let relaton migrate `relaton-data-ieee` to a
# pubid-structured index-v2, `Pubid::Ieee::Identifier.parse` must accept these
# forms AND round-trip them (`from_hash(id.to_hash).to_hash == id.to_hash`).
RSpec.describe "IEEE — relaton historical serialization" do
  def round_trips?(id)
    h = id.to_hash
    Pubid::Ieee::Identifier.from_hash(h).to_hash == h
  end

  # rubocop:disable Layout/LineLength
  cases = {
    # draft + trailing numeric date (the dominant ~87% of the corpus)
    "IEEE P802.16/D-3-2017-07" => "draft with -YYYY-MM date",
    "ANSI PC63.10/D-14-2020-04" => "ANSI draft with -YYYY-MM date",
    "ANSI PC63.15/D-1.04-2017-06" => "decimal draft with date",
    "IEEE Approved Std P1516.4/D-x.1-2007-06" => "letter/decimal draft with date",
    "IEEE P145/D-D2-2013" => "D-prefixed draft value with year",
    "ANSI PC63.17/D-0.9" => "decimal draft, no date",
    "IEEE/ISO/IEC P29119.2/D-IS-2011" => "IS draft with year",
    # redline (bare " Redline", no leading dash)
    "IEEE Std 802.16-2012 Redline" => "redline suffix",
    "ANSI C63.10-2013 Redline" => "ANSI redline suffix",
    # edition /E-N
    "IEC/IEEE P62209.3/E-2-2023-02" => "edition /E-N with date",
    # revision /R-N
    "IEEE P1512.4/R-44-2006" => "revision /R-N with year",
    # combined draft + corrigendum with a base year (handoff regression case)
    "IEEE Std P802.16-2004/D-5/Cor1-2005" => "draft + corrigendum + base year",
    "IEEE P11073.10419-2015/D-3/Cor1-2016" => "base-year draft + corrigendum",
    # corrigendum attached form
    "ANSI C63.5/Cor1-2019" => "attached corrigendum with year",
  }
  # rubocop:enable Layout/LineLength

  cases.each do |identifier, desc|
    describe "#{identifier} (#{desc})" do
      it "parses without raising" do
        expect { Pubid::Ieee::Identifier.parse(identifier) }.not_to raise_error
      end

      it "round-trips through to_hash/from_hash" do
        parsed = Pubid::Ieee::Identifier.parse(identifier)
        expect(round_trips?(parsed)).to be(true)
      end
    end
  end
end
