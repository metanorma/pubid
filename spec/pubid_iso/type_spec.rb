module Pubid::Iso
  RSpec.describe Type do
    context "when don't have type" do
      subject { described_class.new }

      it "assigns IS type by default" do
        expect(subject.type).to eq(:is)
      end
    end

    context "when using symbol" do
      subject { described_class.new(type) }
      let(:type) { :tr }

      it "returns corresponding string" do
        expect(subject.to_s).to eq("TR")
      end

      it "returns long name" do
        expect(subject.to_s(:long)).to eq("Technical Report")
      end

      context "when using wrong type" do
        let(:type) { :wrong_type }

        it { expect { subject }.to raise_exception(Errors::WrongTypeError) }
      end
    end

    context "when using string" do
      subject { described_class.parse(type_string) }
      let(:type_string) { "TR" }

      it "returns corresponding symbol" do
        expect(subject.type).to eq(:tr)
      end

      context "when cannot parse type string" do
        let(:type_string) { "WRONG_TYPE" }

        it { expect { subject }.to raise_exception(Errors::ParseTypeError) }
      end
    end

    describe "#==" do
      subject { described_class.new(type) == another }
      let(:type) { :tr }

      context "when compare with same type" do
        let(:another) { described_class.new(type) }

        it { is_expected.to be_truthy }
      end

      context "when compare with same type symbol" do
        let(:another) { type }

        it { is_expected.to be_truthy }
      end

      context "when another type" do
        let(:another) { described_class.new(:ts) }

        it { is_expected.to be_falsey }
      end

      context "when another type is symbol" do
        let(:another) { :ts }

        it { is_expected.to be_falsey }
      end
    end
  end
end
