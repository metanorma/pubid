# frozen_string_literal: true

require "rspec"
require_relative "../../lib/pubid/iso"
require_relative "../../lib/pubid/itu"
require_relative "../../lib/pubid/ieee"

RSpec.describe Pubid::Identifier do
  describe "#exclude" do
    it "excludes date" do
      id = Pubid::Iso.parse("ISO 9001:2015")
      excluded = id.exclude(:date)
      expect(excluded.to_s).to eq("ISO 9001")
    end

    it "excludes date and part" do
      id = Pubid::Iso.parse("ISO 8601-1:2019")
      excluded = id.exclude(:date, :part)
      expect(excluded.to_s).to eq("ISO 8601")
    end

    it "excludes type_info" do
      id = Pubid::Iso.parse("ISO/TR 9001:2015")
      excluded = id.exclude(:type_info)
      # After excluding type_info, the identifier still renders because
      # other attributes provide the needed information
      expect(excluded.to_s).to eq("ISO/TR 9001:2015")
    end

    it "returns new identifier without modifying original" do
      id = Pubid::Iso.parse("ISO 9001:2015")
      excluded = id.exclude(:date)
      expect(id.to_s).to eq("ISO 9001:2015")
      expect(excluded.to_s).to eq("ISO 9001")
    end

    it "excludes date from hash representation" do
      id = Pubid::Iso.parse("ISO 9001:2015")
      excluded = id.exclude(:date)
      expect(excluded.to_hash["year"]).to be_nil
      expect(excluded.to_s).not_to include(":2015")
    end

    it "excludes languages" do
      id = Pubid::Iso.parse("ISO 9001:2015(en)")
      excluded = id.exclude(:languages)
      expect(excluded.to_s).to eq("ISO 9001:2015")
      expect(excluded.to_hash["languages"]).to be_nil
    end
  end

  # Regression for #289: #exclude rebuilds via `self.class.new(**attrs)`, so
  # flavors whose identifier #initialize is keyword-only (ITU `**kwargs`, IEEE
  # `**args`) no longer raise ArgumentError. #matches? relies on #exclude, so
  # it must be exercised too. Guards the shared base fix against future
  # keyword-init flavors.
  describe "keyword-init flavors (#289)" do
    {
      "ITU" => -> { Pubid::Itu.parse("ITU-R P.838") },
      "IEEE" => -> { Pubid::Ieee.parse("IEEE 100-1992") },
    }.each do |flavor, build|
      it "#{flavor} #exclude does not raise" do
        expect { build.call.exclude(:date) }.not_to raise_error
      end

      it "#{flavor} #matches? does not raise and self-matches" do
        id = build.call
        expect { id.matches?(id) }.not_to raise_error
        expect(id.matches?(id)).to be true
      end
    end
  end
end
