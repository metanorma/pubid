RSpec.describe Pubid::Ieee::Identifier do
  describe "creating new identifier" do
    subject { described_class.create(**{ number: number }.merge(params)) }
    let(:number) { 123 }
    let(:params) { {} }

    it "renders default publisher" do
      expect(subject.to_s).to eq("IEEE Std #{number}")
    end

    context "using multiple organizations" do
      let(:params) { { publisher: "IEC", copublisher: "IEEE" } }

      it "renders publisher with copublisher" do
        expect(subject.to_s).to eq("IEC/IEEE Std #{number}")
      end

    end

    context "ISO identifier" do
      subject { described_class.create(**params) }
      let(:params) do
        { iso_identifier:
            [{ publisher: "IEC" },
             { copublisher: "IEEE" },
             { number: number },
             { part: 1 },
             { year: 2019 }],
        }
      end

      it "renders ISO identifier" do
        expect(subject.to_s).to eq("IEC/IEEE #{number}-1:2019")
      end
    end

    context "edition" do
      context "only year" do
        let(:params) { { year: 2011 } }

        it { expect(subject.to_s).to eq("IEEE Std #{number}-2011") }
      end

      context "year and version" do
        let(:params) { { edition: "1.0", year: 2011 } }

        it { expect(subject.to_s).to eq("IEEE Std #{number}-2011 Edition 1.0") }
      end

      context "with month" do
        let(:params) { { edition: "1.0", year: 2011, month: 1 } }

        it { expect(subject.to_s).to eq("IEEE Std #{number} Edition 1.0, January 2011") }
      end
    end

    context "revision" do
      let(:params) { { revision: [described_class.create(number: 1)] } }

      it { expect(subject.to_s).to eq("IEEE Std #{number} (Revision of IEEE Std 1)") }
    end

    context "draft" do
      let(:params) { { draft: { version: 1, revision: 2 }, month: 1, day: 1, year: 1999 } }

      it { expect(subject.to_s).to eq("IEEE Draft Std #{number}/D1.2, January 1, 1999") }
    end

    context "part" do
      let(:params) { { part: "-1" } }

      it { expect(subject.to_s).to eq("IEEE Std #{number}-1") }
    end

    context "subpart" do
      let(:params) { { part: "-1", subpart: "-1" } }

      it { expect(subject.to_s).to eq("IEEE Std #{number}-1-1") }
    end

    context "year" do
      let(:params) { { year: 1999 } }

      it { expect(subject.to_s).to eq("IEEE Std #{number}-1999") }
    end

    context "dual pubid" do
      let(:params) { { alternative: { number: 1 } } }

      it { expect(subject.to_s).to eq("IEEE Std #{number} (IEEE Std 1)") }
    end

    context "amendment" do
      context "with comment" do
        let(:params) { { amendment: described_class.create(number: 1) } }

        it { expect(subject.to_s).to eq("IEEE Std #{number} (Amendment to IEEE Std 1)") }
      end

      context "iso amendment" do
        let(:params) do
          { iso_amendment: { version: 1, year: 1999 } }
        end

        it { expect(subject.to_s).to eq("IEEE Std #{number}/Amd1-1999") }
      end

      context "several amendments" do
        let(:params) { { amendment: [described_class.create(number: 1), described_class.create(number: 2)] } }

        it { expect(subject.to_s).to eq("IEEE Std #{number} (Amendment to IEEE Std 1 as amended by IEEE Std 2)") }
      end
    end

    context "corrigendum" do
      context "with comment" do
        let(:params) { { year: 2000, corrigendum_comment: described_class.create(number: 1, year: 1999 ) } }

        it { expect(subject.to_s).to eq("IEEE Std #{number}-1999/Cor 1-2000") }
      end

      context "corrigendum" do
        let(:params) { { corrigendum: { version: 1, year: 1999 } } }

        it { expect(subject.to_s).to eq("IEEE Std #{number}/Cor 1-1999") }
      end
    end

    context "supplement" do
      let(:params) { { supplement: described_class.create(number: 2) } }

      it { expect(subject.to_s).to eq("IEEE Std #{number} (Supplement to IEEE Std 2)") }
    end

    context "redline" do
      let(:params) { { redline: true } }

      it { expect(subject.to_s).to eq("IEEE Std #{number} - Redline") }
    end

    context "publication date" do
      let(:params) { { month: 1, year: 1999 } }

      it { expect(subject.to_s).to eq("IEEE Std #{number}, January 1999") }
    end

    context "incorporates" do
      let(:params) { { incorporates: [described_class.create(number: 2)] } }

      it { expect(subject.to_s).to eq("IEEE Std #{number} (Incorporates IEEE Std 2)") }
    end

    context "reaffirmed" do
      context "year" do
        let(:params) { { reaffirmed: { year: 1999 } } }

        it { expect(subject.to_s).to eq("IEEE Std #{number} (Reaffirmed 1999)") }
      end

      context "Reaffirmation of" do
        let(:params) { { year: 1998, reaffirmed: { reaffirmation_of: described_class.create(number: 2, year: 1999) } } }

        it { expect(subject.to_s).to eq("IEEE Std #{number}-1999 (Reaffirmed 1998)") }
      end
    end
  end
end
