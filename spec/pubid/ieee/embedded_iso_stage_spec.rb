# frozen_string_literal: true

require "spec_helper"

# Embedded (stage-last) ISO-led designations from relaton-data-ieee that pubid
# could not parse: the ISO stage is written AFTER the (dotted or dashed) part —
# `ISO/IEC/IEEE 29119.4.FDIS, April 2015` — rather than before the number
# (`ISO/IEC/IEEE FDIS 29119.4:2015`, already handled). Same meaning:
# `29119.4`/`29119-4` = "29119 part 4" and the trailing `.FDIS`/`.CD3` is the
# ISO stage, NOT a second part. Both spellings unify to a JointDevelopment with a
# proper iso_stage and the numeric part kept separate.
#
# The relaton index gate is the HASH round-trip (from_hash(to_hash) == to_hash)
# plus a non-empty root.number; `to_s` may canonicalize to the stage-first form.
# (hand-off: ieee-iso-stage-dotted-part-embedded.)
RSpec.describe "IEEE embedded/stage-last ISO designations" do
  subject(:klass) { Pubid::Ieee::Identifier }

  describe "embedded (stage-last) form" do
    # ref => [bare root.number, iso_stage, numeric parts]
    {
      # dotted part + embedded stage (the corpus form)
      "ISO/IEC/IEEE 29119.4.FDIS, April 2015" => ["29119", "FDIS", ["4"]],
      "ISO/IEC/IEEE 24748.5.CD3, February 2015" => ["24748", "CD3", ["5"]],
      "IEEE P24748.5.CD3, July 2015" => ["24748", "CD3", ["5"]],
      "ISO/IEC/IEEE 29119.1.FDIS, March 2013" => ["29119", "FDIS", ["1"]],
      "ISO/IEC/IEEE 29119.5.CD1, April 2014" => ["29119", "CD1", ["5"]],
      "ISO/IEC/IEEE P29119.2.DIS, December 2011" => ["29119", "DIS", ["2"]],
      # dashed part + embedded stage (previously parsed as a Standard with the
      # stage mislabeled as a part — now unified to the correct model)
      "ISO/IEC/IEEE 24748-5.CD3, February 2015" => ["24748", "CD3", ["5"]],
      # no part, just embedded stage
      "ISO/IEC/IEEE 29119.FDIS, April 2015" => ["29119", "FDIS", []],
    }.each do |ref, (number, stage, parts)|
      context ref.inspect do
        let(:id) { klass.parse(ref) }

        it "parses to a JointDevelopment" do
          expect(id).to be_a(Pubid::Ieee::Identifiers::JointDevelopment)
        end

        it "exposes a non-empty root.number" do
          expect(id.root.number).to eq(number)
        end

        it "recognizes the trailing token as the ISO stage (not a part)" do
          h = id.to_hash
          expect(h["iso_stage"]).to eq(stage)
          expect(h["parts"] || []).to eq(parts)
        end

        it "round-trips through to_hash/from_hash (the relaton index gate)" do
          h = id.to_hash
          expect(klass.from_hash(h).to_hash).to eq(h)
        end
      end
    end
  end

  # Cause 2: the stage-FIRST rule (joint_development_iso_format) must also take
  # a trailing ", Month Year" text date, not only `:YYYY` / `-YYYY[-MM]`.
  describe "stage-first form with a text date" do
    {
      "ISO/IEC/IEEE FDIS 29119-4, April 2015" => "29119",
      "ISO/IEC/IEEE FDIS 29119.4, April 2015" => "29119",
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
end
