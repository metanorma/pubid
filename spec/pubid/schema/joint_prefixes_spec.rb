# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::JOINT_PREFIXES do
  it "is sourced from schema/core/joint_prefixes.yaml" do
    expect(described_class).to eq(
      iso: %w[ISO/IEC IEC/ISO ISO/IEC/IEEE],
      iec: %w[ISO/IEC IEC/ISO ISO/IEC/IEEE],
      ieee: %w[ISO/IEC/IEEE],
      ansi: %w[ANSI/ASHRAE ANSI/AMCA],
      ashrae: %w[ANSI/ASHRAE],
      amca: %w[ANSI/AMCA],
    )
  end

  it "is frozen" do
    expect(described_class).to be_frozen
  end
end
