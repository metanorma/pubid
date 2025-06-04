# frozen_string_literal: true

RSpec.describe "Dependency chains" do
  describe "pubid-core dependencies" do
    it "loads pubid-core successfully" do
      require "pubid-core"
      expect(defined?(Pubid::Core)).to be_truthy
    end

    it "loads pubid-iso with pubid-core dependency" do
      require "pubid-iso"
      expect(defined?(Pubid::Iso)).to be_truthy
      expect(defined?(Pubid::Core)).to be_truthy
    end

    it "loads pubid-iec with pubid-core dependency" do
      require "pubid-iec"
      expect(defined?(Pubid::Iec)).to be_truthy
      expect(defined?(Pubid::Core)).to be_truthy
    end

    it "loads pubid-nist with pubid-core dependency" do
      require "pubid-nist"
      expect(defined?(Pubid::Nist)).to be_truthy
      expect(defined?(Pubid::Core)).to be_truthy
    end
  end

  describe "complex dependency chains" do
    it "loads pubid-ieee through pubid-iso" do
      require "pubid-ieee"
      expect(defined?(Pubid::Ieee)).to be_truthy
      expect(defined?(Pubid::Iso)).to be_truthy
    end

    it "loads pubid-cen with multiple dependencies" do
      require "pubid-cen"
      expect(defined?(Pubid::Cen)).to be_truthy
      expect(defined?(Pubid::Core)).to be_truthy
      expect(defined?(Pubid::Iec)).to be_truthy
      expect(defined?(Pubid::Iso)).to be_truthy
    end

    it "loads pubid-bsi with all its dependencies" do
      require "pubid-bsi"
      expect(defined?(Pubid::Bsi)).to be_truthy
      expect(defined?(Pubid::Core)).to be_truthy
      expect(defined?(Pubid::Iec)).to be_truthy
      expect(defined?(Pubid::Iso)).to be_truthy
      expect(defined?(Pubid::Cen)).to be_truthy
      expect(defined?(Pubid::Nist)).to be_truthy
    end
  end

  describe "meta-gem" do
    it "loads pubid meta-gem with multiple dependencies" do
      require "pubid"
      expect(defined?(Pubid)).to be_truthy
      expect(defined?(Pubid::Core)).to be_truthy
      expect(defined?(Pubid::Nist)).to be_truthy
      expect(defined?(Pubid::Iso)).to be_truthy
    end
  end
end
