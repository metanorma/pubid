shared_examples "converts pubid to different formats" do
  it "converts into long Full PubID" do
    expect(subject.to_s(:long)).to eq(long_pubid) if long_pubid
  end

  it "converts into Abbreviated PubID" do
    expect(subject.to_s(:abbrev)).to eq(abbrev_pubid) if abbrev_pubid
  end

  it "converts into Short PubID" do
    expect(subject.to_s(:short)).to eq(short_pubid)
  end

  it "converts into Machine-readable PubID" do
    expect(subject.to_s(:mr)).to eq(mr_pubid)
  end
end
