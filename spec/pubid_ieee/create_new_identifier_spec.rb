RSpec.describe Pubid::Ieee::Identifier do
  describe "creating new identifier" do
    subject { described_class.new(**{ number: number }.merge(params)) }
    let(:number) { 123 }
    let(:params) { {} }

    it "renders default publisher" do
      expect(subject.to_s).to eq("IEEE #{number}")
    end

    context "using multiple organizations" do
      let(:params) { { organizations: { publisher: "IEC", copublisher: "IEEE" } } }

      it "renders publisher with copublisher" do
        expect(subject.to_s).to eq("IEC/IEEE #{number}")
      end

    end

    context "ISO identifier" do
      subject { described_class.new(**params) }
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
        let(:params) { { parameters: { edition: { year: 2011 } } } }

        it { expect(subject.to_s).to eq("IEEE #{number} 2011 Edition") }
      end

      context "year and version" do
        let(:params) { { parameters: { edition: { version: "1.0", year: 2011 } } } }

        it { expect(subject.to_s).to eq("IEEE #{number} Edition 1.0 2011") }
      end

      context "with month" do
        let(:params) { { parameters: { edition: { version: "1.0", year: 2011, month: 1 } } } }

        it { expect(subject.to_s).to eq("IEEE #{number} Edition 1.0 2011-01") }
      end
    end

    context "revision" do
      let(:params) { { parameters: { revision: [described_class.new(number: 1)] } } }

      it { expect(subject.to_s).to eq("IEEE #{number} (Revision of IEEE 1)") }
    end

    context "draft" do
      let(:params) { { parameters: { draft: { version: 1, revision: 2, month: "January", day: 1, year: 1999 } } } }

      it { expect(subject.to_s).to eq("IEEE #{number}/D1.2, January 1, 1999") }
    end

    context "part" do
      let(:params) { { parameters: { part: "-1" } } }

      it { expect(subject.to_s).to eq("IEEE #{number}-1") }
    end

    context "subpart" do
      let(:params) { { parameters: { part: "-1", subpart: "-1" } } }

      it { expect(subject.to_s).to eq("IEEE #{number}-1-1") }
    end

    context "year" do
      let(:params) { { parameters: { year: 1999 } } }

      it { expect(subject.to_s).to eq("IEEE #{number}-1999") }
    end

    context "dual pubid" do
      let(:params) { { parameters: { alternative: { number: 1 } } } }

      it { expect(subject.to_s).to eq("IEEE #{number} (IEEE 1)") }
    end

    context "amendment" do
      context "with comment" do
        let(:params) { { parameters: { amendment: described_class.new(number: 1) } } }

        it { expect(subject.to_s).to eq("IEEE #{number} (Amendment to IEEE 1)") }
      end

      context "iso amendment" do
        let(:params) do
          { parameters: { iso_amendment: { version: 1, year: 1999 } } }
        end

        it { expect(subject.to_s).to eq("IEEE #{number}/Amd1-1999") }
      end

      context "several amendments" do
        let(:params) { { parameters: { amendment: [described_class.new(number: 1), described_class.new(number: 2)] } } }

        it { expect(subject.to_s).to eq("IEEE #{number} (Amendment to IEEE 1 as amended by IEEE 2)") }
      end
    end

    context "corrigendum" do
      context "with comment" do
        let(:params) { { parameters: { year: 2000, corrigendum_comment: described_class.new(number: 1, parameters: { year: 1999 } ) } } }

        it { expect(subject.to_s).to eq("IEEE #{number}-1999/Cor 1-2000") }
      end

      context "corrigendum" do
        let(:params) { { parameters: { corrigendum: { version: 1, year: 1999 } } } }

        it { expect(subject.to_s).to eq("IEEE #{number}/Cor 1-1999") }
      end
    end

    context "supplement" do
      let(:params) { { parameters: { supplement: described_class.new(number: 2) } } }

      it { expect(subject.to_s).to eq("IEEE #{number} (Supplement to IEEE 2)") }
    end

    context "redline" do
      let(:params) { { parameters: { redline: true } } }

      it { expect(subject.to_s).to eq("IEEE #{number} - Redline") }
    end

    context "publication date" do
      let(:params) { { parameters: { month: "January", year: 1999 } } }

      it { expect(subject.to_s).to eq("IEEE #{number}, January 1999") }
    end

    context "incorporates" do
      let(:params) { { parameters: { incorporates: [described_class.new(number: 2)] } } }

      it { expect(subject.to_s).to eq("IEEE #{number} (Incorporates IEEE 2)") }
    end

    context "reaffirmed" do
      context "year" do
        let(:params) { { parameters: { reaffirmed: { year: 1999 } } } }

        it { expect(subject.to_s).to eq("IEEE #{number} (Reaffirmed 1999)") }
      end

      context "Reaffirmation of" do
        let(:params) { { parameters: { year: 1998, reaffirmed: { reaffirmation_of: described_class.new(number: 2, parameters: { year: 1999 }) } } } }

        it { expect(subject.to_s).to eq("IEEE #{number}-1999 (Reaffirmed 1998)") }
      end
    end
  end
end
