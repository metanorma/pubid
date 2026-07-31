# frozen_string_literal: true

require "spec_helper"

# Historical ISO-led stage designations from relaton-data-ieee that pubid could
# not parse: `<publishers> <ISO-stage> [P]<number>[.part][-YYYY[-MM]]`. These
# are the dominant unparseable bucket (~164 rows). The relaton index gate is the
# HASH round-trip (from_hash(to_hash) == to_hash) plus a non-empty root.number;
# `to_s` may canonicalize (P/dash-date -> the colon ISO form).
# (hand-off: ieee-numberless-standard-parse roadmap items 2/3, phase 1.)
RSpec.describe "IEEE historical ISO-led stage designations" do
  subject(:klass) { Pubid::Ieee::Identifier }

  # ref => bare root.number
  {
    "ISO/IEC/IEEE FDIS P26515-2018-05" => "26515",
    "IEEE FDIS P24748.1-2018-05" => "24748",
    "ISO/IEC/IEEE CD2 P15026.4-2018-02" => "15026",
    "ISO/IEC/IEEE DIS P42030-2019" => "42030",
    "ISO/IEC/IEEE CD1 P12207-2016" => "12207",
    "ISO/IEC/IEEE FDIS 26511:2018" => "26511", # colon form (regression guard)
    # ISO-led stage + /D draft tail (bucket 5)
    "ISO/IEC/IEEE FDIS P15289/D-3-2017" => "15289",
    "ISO/IEC/IEEE DIS P42030/D-1-2017" => "42030",
    "ISO/IEC/IEEE CD P26513/D-1-2015" => "26513",
    "ISO/IEC/IEEE FDIS P21840/D-4-2019-07" => "21840",
    # bucket 7 iso-stage variants: slash-join, DIS2/FCD, "Std" word, /D-<n>
    "ISO/IEC/IEEE/ FDIS P21841-2019-04" => "21841",
    "ISO/IEC/IEEE/FDIS P24748.2/D-3-2018-06" => "24748",
    "IEEE DIS2 P29119.4-2014" => "29119",
    "IEEE FCD P15026.3-2010-12" => "15026",
    "IEEE FCD Std P15026.2-2010-02" => "15026",
    "IEEE FDIS P82079.1/D-4" => "82079",
    "ISO/IEC/IEEE FDIS Std P15288/D-3-2007" => "15288",
  }.each do |ref, number|
    context ref.inspect do
      let(:id) { klass.parse(ref) }

      it "parses to a JointDevelopment" do
        expect(id).to be_a(Pubid::Ieee::Identifiers::JointDevelopment)
      end

      it "exposes a non-empty root.number" do
        expect(id.root.number).to eq(number)
      end

      it "round-trips through to_hash/from_hash (the relaton index gate)" do
        h = id.to_hash
        expect(klass.from_hash(h).to_hash).to eq(h)
      end
    end
  end
end
