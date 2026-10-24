# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Supplement with nil typed_stage" do
  # metanorma-iso's draft-biblio flow assigns typed_stage = nil through the
  # public setter before re-rendering; the renderer must honor nil as
  # "no stage" instead of crashing on nil.render.
  it "renders without the stage segment" do
    id = Pubid::Iso::Identifier.parse("ISO 32000-2:2020/DAM 1")
    id.typed_stage = nil if id.respond_to?(:typed_stage=)
    expect { id.to_s }.not_to raise_error
    expect(id.to_s).to include("32000-2")
    expect(id.to_s).not_to match(/DIS/i)
  end
end
