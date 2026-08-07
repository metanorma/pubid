# frozen_string_literal: true

require "spec_helper"

# `/D-` corrupted IEEE draft docids — normalized in data/ieee/update_codes.yaml.
#
# These malformed draft designations are emitted by relaton-ieee's
# RawbibIdParser fallback rendering (`/D-`, `_CDV_`, `.pdf`, `201x`, stray
# dots/spaces) and cannot be parsed directly. update_codes maps each corrupted
# string (full-line, plain) to a canonical parseable form before parsing.
#
# Relaton's index-v2 gate is the *hash* round-trip plus a non-empty
# root.number — NOT `to_s == input` — so joint ISO/IEC/IEEE draft forms that
# render a colon `to_s` without the draft are still fine (the hash keeps
# `ieee_draft`).

# Every corrupted raw docid that should now parse + round-trip.
IEEE_DASHD_RECOVERED = [
  # 8 pre-verified (from the hand-off)
  "IEEE Approved Std P1609.3/D-23.pdf-2007-02",
  "IEEE P3004.5/D-6.2.",
  "IEEE P730/D-0.16.-2025",
  "IEEE PC37.107/D-4.-2023-11",
  "IEEE PC37.113/D-8.0.-2015-08",
  "IEEE PC37.98/D-5.1D-2013",
  "IEEE PC57.637/D-6.2.-2014-03",
  "IEEE Std P650/D-9.-2006",
  # 21 derived
  "IEC/IEEE P63198.2775/D-6.1_CDV_March-2022",
  "IEEE 3.Rev.B/D-4.0-2023-01",
  "IEEE 3.Rev.B/D-5.0-2023-03",
  "IEEE P1003.1/D-5/Cor1-201x-2012-04",
  "IEEE P1003.1/D-5/Cor1-201x-2012-08",
  "IEEE P1127/D-4.1_July-2023",
  "IEEE P2660_1/D-2-2020-06",
  "IEEE P802.1AE/D-1.0/R-/Cor1",
  "IEEE P802.1AE_Rev/D-1.2-2018",
  "IEEE P802.1AE_Rev/D-1.3-2018",
  "IEEE Unapproved Std P802.16Rev2/D-9-2009-01",
  "IEEE Unapproved Std P802.1X_REV/D-4.5-2009",
  "IEEE Unapproved Std PC37.91/D-8-2007-20",
  "IEEEE P1243/D-3-2023-02",
  "ISO/IEC/IEEE FDIS P15289./E-3/D-2-2016",
  "ISO/IEC/IEEE P24641/D-2_CD-2020",
  "ISO/IEC/IEEE P24641/D-3_CD2",
  "ISO/IEC/IEEE P24748.3/D-3_FDIS-2020",
  "ISO/IEC/IEEE/ P12207.2/D-3_FDIS-2020",
  "ISO/IEC/IEEE/ P24748.3/D-IS-2019",
  "P1635/D10/ASHARE 21/D-10-2016",
].freeze

# Genuinely broken source data — intentionally NOT mapped (documents the
# boundary): D-- has no draft number; PSI.10 mis-parses and never round-trips.
IEEE_DASHD_STILL_UNPARSEABLE = [
  "IEEE P11073.10415/D--2019",
  "IEEE PSI.10/D-1-2010-05",
].freeze

RSpec.describe "IEEE /D- corrupted draft docids — update_codes normalization" do
  describe "recovered docids" do
    IEEE_DASHD_RECOVERED.each do |raw|
      context raw.inspect do
        it "parses without raising" do
          expect { Pubid::Ieee::Identifier.parse(raw) }.not_to raise_error
        end

        it "round-trips through to_hash / from_hash" do
          hash = Pubid::Ieee::Identifier.parse(raw).to_hash
          expect(Pubid::Ieee::Identifier.from_hash(hash).to_hash).to eq(hash)
        end

        it "has a non-empty root.number (relaton index key)" do
          expect(Pubid::Ieee::Identifier.parse(raw).root.number.to_s)
            .not_to be_empty
        end
      end
    end
  end

  describe "intentionally unmapped (broken source data)" do
    IEEE_DASHD_STILL_UNPARSEABLE.each do |raw|
      it "#{raw.inspect} still raises" do
        expect { Pubid::Ieee::Identifier.parse(raw) }
          .to raise_error(Parslet::ParseFailed)
      end
    end
  end
end
