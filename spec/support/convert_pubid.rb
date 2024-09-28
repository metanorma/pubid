shared_examples "converts pubid to pubid" do
  it "converts pubid to pubid" do
    expect(subject.to_s).to eq(pubid)
  end
end

shared_examples "converts pubid to french pubid" do
  it "converts pubid to french pubid" do
    expect(subject.to_s(language: :fr)).to eq(pubid_fr)
  end
end

shared_examples "converts pubid to spanish pubid" do
  it "converts pubid to spanish pubid" do
    expect(subject.to_s(language: :es)).to eq(pubid_es)
  end
end

shared_examples "converts pubid to chinese pubid" do
  it "converts pubid to chinese pubid" do
    expect(subject.to_s(language: :cn)).to eq(pubid_cn)
  end
end

shared_examples "converts pubid to russian pubid" do
  it "converts pubid to russian pubid" do
    expect(subject.to_s(language: :ru)).to eq(pubid_ru)
  end
end

shared_examples "converts pubid to arabic pubid" do
  it "converts pubid to arabic pubid" do
    expect(subject.to_s(language: :ar)).to eq(pubid_ar)
  end
end

shared_examples "converts pubid to pubid with type" do
  it "converts pubid to pubid" do
    expect(subject.to_s(with_type: true)).to eq(pubid_with_type)
  end
end

shared_examples "parse identifiers from file" do
  it "parse identifiers from file" do
    f = open("spec/fixtures/#{examples_file}")
    f.readlines.each do |pub_id|
      next if pub_id.match?("^#")

      pub_id = pub_id.split("#").first.strip.chomp
      expect do
        described_class.parse(pub_id)
      rescue Exception => failure
        raise Pubid::Core::Errors::ParseError,
              "couldn't parse #{pub_id}\n#{failure.message}"
      end.not_to raise_error

      expect(described_class.parse(pub_id).to_s.upcase).to eq(pub_id.upcase)
    end
  end
end
