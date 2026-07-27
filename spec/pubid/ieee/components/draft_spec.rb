# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Ieee::Components::Draft do
  # `Draft.parse` must be an exact inverse of `Draft#to_s`: the identifier stores
  # the draft as the rendered string (`draft_obj.to_s`, e.g. "/D3"), and after
  # `from_hash` the object is rebuilt via `Draft.parse(that_string)`. If the two
  # disagree, `to_hash` no longer round-trips (relaton drops such ids from its
  # index). Historically `Draft.parse` used a `^D(\d+)` regex that missed the
  # leading "/D", producing a doubled "/D/D3".
  describe "round-trips its own rendering (parse(to_s).to_s == to_s)" do
    %w[
      /D3
      /D10
      /D3.4
      /D.19
      /D6.0
      /D12e
      /Dx.1
      /DD7.2
      /DIS
      /DIS2
    ].each do |rendered|
      it "reproduces #{rendered}" do
        expect(described_class.parse(rendered).to_s).to eq(rendered)
      end
    end

    # Date-carrying drafts (from the text-date grammar, e.g. PSI drafts) must also
    # round-trip, and must keep `version` clean (the SI/PSI renderer reads
    # `draft_obj.version` directly).
    {
      "/D2, October, 2015" => "2",
      "/D2 October, 2015" => "2",
      "/D7 Jul 2019" => "7",
      "/D7 2019" => "7",
    }.each do |rendered, clean_version|
      it "reproduces #{rendered.inspect} and keeps a clean version" do
        parsed = described_class.parse(rendered)
        expect(parsed.to_s).to eq(rendered)
        expect(parsed.version).to eq(clean_version)
      end
    end
  end
end
