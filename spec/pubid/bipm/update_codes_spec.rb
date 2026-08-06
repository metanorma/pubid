# frozen_string_literal: true

require "spec_helper"

# BIPM applies data/bipm/update_codes.yaml normalization before parsing, so
# legacy/docnumber-style spellings of the CIPM MRA:2005 interpretation document
# normalize onto the canonical, parseable "CIPM 2005-06" form.
RSpec.describe "Pubid::Bipm update_codes normalization" do
  let(:canonical) { Pubid::Bipm.parse("CIPM 2005-06") }

  it "normalizes the slash + (REV) docnumber spelling" do
    id = Pubid::Bipm.parse("CIPM/2005-06(REV)")
    expect(id.to_hash).to eq(canonical.to_hash)
    expect(id.to_s).to eq("CIPM 2005-06")
  end

  it "normalizes the space + (REV) spelling" do
    id = Pubid::Bipm.parse("CIPM 2005-06(REV)")
    expect(id.to_hash).to eq(canonical.to_hash)
  end

  it "leaves a normal typed committee document untouched" do
    id = Pubid::Bipm.parse("CCTF REC 2 (2012)")
    expect(id.to_s).to eq("CCTF REC 2 (2012)")
    expect(id.type_code).to eq("REC")
  end
end
