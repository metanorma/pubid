# frozen_string_literal: true

require "spec_helper"

# relaton's index-v2 keys on `id.root.number.to_s` and narrows a part-less
# reference to a whole bucket of parts. So IEEE splits its document code into
# separate, index-friendly scalars: a bare-digit `number` (the narrowing key),
# a `prefix` (letter series, e.g. "C"), a `parts` array (dotted/dashed parts,
# arbitrary depth), and a `separator`. The full `code` string is NOT serialized
# — `code_obj` is rebuilt losslessly from the split fields for rendering.
#
# The split lives on concrete leaf types (Standard/ProjectDraft/SI, and
# IecIeeeCopublished), NOT the directly-instantiated base Ieee::Identifier: a
# `number` :string redefinition on the base resolves against the parent's
# Components::Code nondeterministically under multi-flavor load. This spec must
# run as part of the FULL suite to guard that determinism.
RSpec.describe "IEEE split document number (relaton index key)" do
  # Standard-family leaves (Standard/ProjectDraft/SI) use a single `separator`.
  # ref => [number, prefix, parts, separator]
  {
    "IEEE Std 528-2019"          => ["528", nil, [], nil],
    "IEEE Std C37.09-2018"       => ["37", "C", ["09"], "."],
    "IEEE Std 802.16.1-2012"     => ["802", nil, %w[16 1], "."],
    "IEEE P802.16/D-3-2017-07"   => ["802", nil, %w[16], "."],   # ProjectDraft, P stripped
    "IEEE Std S-135"             => ["S-135", nil, [], nil],      # IPCEA cable
  }.each do |ref, (number, prefix, parts, separator)|
    context ref do
      let(:root) { Pubid::Ieee::Identifier.parse(ref).root }

      it "root.number is the bare narrowing key #{number.inspect}" do
        expect(root.number.to_s).to eq(number)
      end

      it "splits prefix/parts/separator" do
        expect(root.prefix).to eq(prefix)
        expect(root.parts || []).to eq(parts)
        expect(root.separator).to eq(separator)
      end

      it "does not serialize a `code` string" do
        expect(Pubid::Ieee::Identifier.parse(ref).root.to_hash).not_to have_key("code")
      end

      it "round-trips through to_hash/from_hash" do
        id = Pubid::Ieee::Identifier.parse(ref)
        h = id.to_hash
        expect(Pubid::Ieee::Identifier.from_hash(h).to_hash).to eq(h)
      end

      it "renders identically after a from_hash round-trip" do
        id = Pubid::Ieee::Identifier.parse(ref)
        expect(Pubid::Ieee::Identifier.from_hash(id.to_hash).to_s).to eq(id.to_s)
      end
    end
  end

  # IecIeeeCopublished uses a per-part `separators` array (its codes mix `.` and
  # `-`), pulls the trailing year into `year`, and drops the verbatim
  # `copublished_number` (reconstructed for rendering).
  # ref => [number, parts, separators, year]
  {
    "IEC/IEEE 60076-2016"      => ["60076", [], [], "2016"],       # trailing year
    "IEC/IEEE 62209-1528:2020" => ["62209", %w[1528], %w[-], "2020"], # 1528 a part, :year
    "IEC/IEEE 60076.57-1202"   => ["60076", %w[57 1202], %w[. -], nil], # 1202 a part
  }.each do |ref, (number, parts, separators, year)|
    context ref do
      let(:root) { Pubid::Ieee::Identifier.parse(ref).root }

      it "root.number is the bare narrowing key #{number.inspect}" do
        expect(root.number.to_s).to eq(number)
      end

      it "splits parts/separators/year" do
        expect(root.parts || []).to eq(parts)
        expect(root.separators || []).to eq(separators)
        expect(root.year).to eq(year)
      end

      it "does not serialize `copublished_number`" do
        expect(Pubid::Ieee::Identifier.parse(ref).to_hash).not_to have_key("copublished_number")
      end

      it "round-trips and renders identically" do
        id = Pubid::Ieee::Identifier.parse(ref)
        h = id.to_hash
        expect(Pubid::Ieee::Identifier.from_hash(h).to_hash).to eq(h)
        expect(Pubid::Ieee::Identifier.from_hash(h).to_s).to eq(id.to_s)
      end
    end
  end

  # A prefix-only, numberless token ("IEEE S", "IEEE WHITE", …) is not a valid
  # IEEE identifier — the `number` rule requires at least one digit. Previously
  # these parsed to a Standard with a nil/letter-only number and leaked into the
  # relaton index as numberless rows (hand-off: ieee-numberless-standard-parse).
  describe "rejects a numberless (letter-only) standard" do
    ["IEEE S", "IEEE Std S", "IEEE WHITE", "IEEE NESC", "IEEE SA"].each do |ref|
      it "#{ref.inspect} raises rather than yielding a numberless Standard" do
        expect { Pubid::Ieee::Identifier.parse(ref) }
          .to raise_error(Parslet::ParseFailed)
      end
    end
  end

  # Same class of junk on the IEC/IEEE copublished number: an all-letter
  # placeholder ("IEC/IEEE TR") has no real document number, so the copublished
  # number grammar requires a digit too (hand-off: ieee-numberless-standard-parse
  # roadmap item 4).
  describe "rejects a numberless IEC/IEEE copublished number" do
    ["IEC/IEEE TR", "IEC/IEEE PAS"].each do |ref|
      it "#{ref.inspect} raises rather than yielding a numberless row" do
        expect { Pubid::Ieee::Identifier.parse(ref) }
          .to raise_error(Parslet::ParseFailed)
      end
    end
  end

  it "a corrigendum's root.number is the base standard's bare number" do
    id = Pubid::Ieee::Identifier.parse("IEEE Std 1003.1-2001/Cor 2-2004")
    expect(id.root.number.to_s).to eq("1003")
    expect(id.root.parts).to eq(%w[1])
  end

  # The split columns exist so relaton can match a date-less reference against
  # every dated hit in the bucket. This needs #exclude/#matches? to work — the
  # base rebuilds via a positional `self.class.new(attrs)` that IEEE's keyword
  # initialize used to reject, and IEEE's date lives in plain year/month/day
  # strings the base `:year`->`:date` remap can't nil. Both are handled now.
  describe "date-less reference matches every date (matches? ignore: :year)" do
    {
      "IEEE Std 802.16" => "IEEE Std 802.16-2012",           # Standard
      "IEC/IEEE 60076"  => "IEC/IEEE 60076-2016",            # IecIeee, year moved out
    }.each do |bare, dated|
      it "#{bare.inspect} matches #{dated.inspect}" do
        b = Pubid::Ieee::Identifier.parse(bare)
        d = Pubid::Ieee::Identifier.parse(dated)
        expect(b.matches?(d, ignore: [:year])).to be true
      end
    end
  end
end
