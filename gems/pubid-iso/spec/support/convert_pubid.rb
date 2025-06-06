shared_examples "converts pubid to urn" do
  it "converts pubid to urn" do
    expect(subject.urn).to eq(urn)
  end
end

shared_examples "converts pubid to pubid" do
  it "converts pubid to pubid" do
    expect(subject.to_s(format: :ref_num_long)).to eq(pubid)
  end

  it "creates same identifier from #to_h output" do
    expect(subject.to_s).to eq(Pubid::Iso::Identifier.create(**subject.to_h).to_s)
  end
end

shared_examples "converts to pubid with edition" do
  it "converts to pubid with edition" do
    expect(subject.to_s(format: :ref_num_long, with_edition: true)).to eq(pubid_with_edition)
  end
end

shared_examples "converts pubid to french pubid" do
  it "converts pubid to french pubid" do
    expect(subject.to_s(format: :ref_num_long, lang: :french)).to eq(french_pubid)
  end
end

shared_examples "converts pubid to russian pubid" do
  it "converts pubid to russian pubid" do
    expect(subject.to_s(format: :ref_num_long, lang: :russian)).to eq(russian_pubid)
  end
end

shared_examples "converts pubid to pubid with prf" do
  it "converts pubid to pubid with prf" do
    expect(subject.to_s(format: :ref_num_long, with_prf: true)).to eq(pubid)
  end
end

shared_examples "creates same identifier from #to_h output" do
  it "creates same identifier from #to_h output" do
    expect(subject.to_s).to eq(Pubid::Iso::Identifier.create(**subject.to_h).to_s)
  end
end

shared_examples "converts urn to pubid" do |result = nil|
  it "converts urn to pubid" do
    result ||= original || pubid
    expect(described_class.parse(urn).to_s(with_edition: true, format: :ref_num_long)).to eq result
  end
end

shared_examples "converts urn to urn" do |result = nil|
  it "converts urn to urn" do
    result ||= urn
    expect(described_class.parse(urn).urn).to eq result
  end
end
