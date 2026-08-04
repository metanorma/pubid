# frozen_string_literal: true

require "spec_helper"

# The descriptive relationship/amendment narrative ("(Amendment to … as
# amended by …)", "(Revision of …)", "(Adoption of …)", note) must NOT be
# embedded in Identifier#to_s. A document's identifier is the bare code (e.g.
# "IEEE Std 802.3bs-2017"), not 300+ chars of prose — relaton uses to_s as a
# document number AND output filename, and a 300-char filename blows past the
# OS 255-byte limit (Errno::ENAMETOOLONG). The narrative is preserved on the
# runtime `relationships` accessor, so nothing is lost.
RSpec.describe "IEEE Identifier#to_s drops the amendment narrative" do
  let(:klass) { Pubid::Ieee::Identifier }

  # The exact 313-char amendment normtitle from the hand-off.
  let(:amendment_nt) do
    "IEEE Std 802.3bs-2017 (Amendment to IEEE Std 802.3-2015 as amended by " \
      "IEEE Std 802.3bw-2015, IEEE Std 802.3by-2016, IEEE Std 802.3bq-2016, " \
      "IEEE Std 802.3bp-2016, IEEE Std 802.3br-2016, IEEE Std 802.3bn-2016, " \
      "IEEE Std 802.3bz-2016, IEEE Std 802.3bu-2016, IEEE Std 802.3bv-2017, " \
      "and IEEE Std 802.3-2015/Cor 1-2017)"
  end

  it "renders the bare identifier for the 313-char amendment normtitle" do
    pid = klass.parse(amendment_nt)
    expect(pid.to_s).to eq("IEEE Std 802.3bs-2017")
    expect(pid.to_s.length).to be <= 80
  end

  it "preserves the amendment detail on the relationships accessor" do
    pid = klass.parse(amendment_nt)
    expect(pid.relationships).not_to be_empty
    expect(pid.relationships.first.relationship_type).to eq("amendment_to")
    # the "as amended by …" list is still reachable on the object
    expect(pid.relationships.first.related_identifiers).not_to be_empty
  end

  context "other descriptive parenthetical forms render bare" do
    {
      "IEEE Std 802.11-2016 (Revision of IEEE Std 802.11-2012)" =>
        "IEEE Std 802.11-2016",
      "IEEE Std 1547-2018 (Revision of IEEE Std 1547-2003 / " \
      "Incorporates IEEE Std 1547-2018/Cor 1-2019)" => "IEEE Std 1547-2018",
      "AIEE No 19-1943 (Supercedes A. I. E. E. Standard No. 19-1938)" =>
        "AIEE No 19-1943",
    }.each do |input, expected|
      it "renders #{input.inspect} as #{expected.inspect}" do
        expect(klass.parse(input).to_s).to eq(expected)
      end
    end
  end

  it "keeps the bounded reaffirmation marker (R…) in to_s" do
    # Only the descriptive narrative is dropped; the bounded (R2010) status
    # marker stays. The revision narrative that follows is dropped.
    ref = "ANSI/IEEE Std 101-1987 (Reaffirmed 2010) " \
          "(Revision of ANSI/IEEE Std 101-1972)"
    pid = klass.parse(ref)
    expect(pid.to_s).to include("(R2010)")
    expect(pid.to_s).not_to include("Revision of")
    expect(pid.to_s.length).to be <= 80
  end
end
