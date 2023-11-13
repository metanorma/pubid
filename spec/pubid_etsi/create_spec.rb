module Pubid::Etsi
  RSpec.describe Identifier do
    describe "creating new identifier" do
      # type: "EN", number: 1234, part: 4, version: "1.2.3", date: "1999-01"
      let(:base) { described_class.create(**{ type: type, number: number, part: part, published: published }.merge(params)) }
      subject { base }
      let(:type) { "EN" }
      let(:number) { 1234 }
      let(:part) { 4 }
      let(:published) { "1999-01" }
      let(:params) { { version: "1.2.3" } }

      it "renders default publisher" do
        expect(subject.to_s).to eq("ETSI EN 1234-4 V1.2.3 (1999-01)")
      end

      context "with edition" do
        let(:params) { { edition: 1 } }

        it "renders identifier with edition" do
          expect(subject.to_s).to eq("ETSI EN 1234-4 ed.1 (1999-01)")
        end
      end

      context "with corrigendum" do
        subject { described_class.create(type: :corrigendum, number: 1, base: base) }

        it "renders corrigendum" do
          expect(subject.to_s).to eq("ETSI EN 1234-4/C1 V1.2.3 (1999-01)")
        end
      end

      context "when another type" do
        let(:type) { "GS" }

        it "renders default publisher" do
          expect(subject.to_s).to eq("ETSI GS 1234-4 V1.2.3 (1999-01)")
        end
      end

      context "when incorrect type" do
        let(:type) { "WRONG_TYPE" }

        it "raises an error" do
          expect { subject }.to raise_exception(Pubid::Core::Errors::WrongTypeError)
        end
      end
    end
  end
end
