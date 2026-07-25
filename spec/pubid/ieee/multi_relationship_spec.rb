# frozen_string_literal: true

require "spec_helper"

RSpec.describe "IEEE multi-relationship parsing — issue #222" do
  # Each parenthetical may carry more than one relationship (e.g. a revision
  # that also incorporates a corrigendum). Separators observed in the wild
  # include " / ", "/", "; ", and even " - ". The parser must split on any of
  # these only when another relationship keyword follows — otherwise the
  # slash inside "IEEE Std 525-2007/Cor 1-2015" would be mistaken for a break.
  {
    "IEEE Std 605-2008 (Revision of IEEE Std 605-1998 / Incorporates IEEE Std 605a-2010)" =>
      %w[revision_of incorporates],
    "IEEE Std 80-2013 (Revision of IEEE Std 80-2000/ Incorporates IEEE Std 80-2013/Cor 1-2015)" =>
      %w[revision_of incorporates],
    "IEEE STD 525-2007 (Revision of IEEE Std 525-1992/Incorporates IEEE Std 525-2007/Cor1:2008)" =>
      %w[revision_of incorporates],
    "ANSI N42.18-2004 (Reaffirmation of ANSI N42.18-1980; Redesignation of ANSI N13.10-1974)" =>
      %w[reaffirmation_of redesignation_of],
    "IEEE Std 738-2012 (Revision of IEEE Std 738-2006 - Incorporates IEEE Std 738-2012 Cor 1-2013)" =>
      %w[revision_of incorporates],
    "IEEE Std C95.1-2019 (Revision of IEEE Std C95.1-2005/ Incorporates IEEE Std C95.1-2019/Cor 1-2019)" =>
      %w[revision_of incorporates],
  }.each do |input, expected_types|
    it "splits #{input.inspect} into #{expected_types.inspect}" do
      parsed = Pubid::Ieee.parse(input)
      expect(parsed.relationships.map(&:relationship_type)).to eq(expected_types)
    end

    it "renders #{input.inspect} without nested 'IEEE Std (IEEE Std ...)'" do
      parsed = Pubid::Ieee.parse(input)
      rendered = parsed.to_s
      expect(rendered).not_to match(/IEEE Std \(IEEE Std/)
      expect(rendered).not_to match(/IEEE Std \(/)
    end
  end

  it "does not split a corrigendum slash as a relationship break" do
    parsed = Pubid::Ieee.parse("IEEE Std 80-2013 (Revision of IEEE Std 80-2000/ Incorporates IEEE Std 80-2013/Cor 1-2015)")
    incorporates = parsed.relationships.find { |r| r.relationship_type == "incorporates" }
    expect(incorporates.related_identifiers.size).to eq(1)
    expect(incorporates.related_identifiers.first.to_s).to include("Cor")
  end
end
