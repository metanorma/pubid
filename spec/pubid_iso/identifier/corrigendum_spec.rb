module Pubid::Iso
  module Identifier
    RSpec.describe Amendment do
      context "when create corrigendum identifier" do
        let(:base) { described_class.new(**{ number: number }.merge(params)) }

        subject { described_class.new(type: :cor, number: 1, base: base, **corrigendum_params) }

        let(:params) { { year: 1999 } }

        context "when corrigendum with stage" do
          let(:corrigendum_params) { { stage: stage } }

          context "with DCor stage" do
            let(:stage) { :dcor }
            it "renders long stage and corrigendum" do
              expect(subject.to_s).to eq("ISO #{number}:1999/DCor 1")
            end

            it "renders short stage and corrigendum" do
              expect(subject.to_s(format: :ref_num_short)).to eq("ISO #{number}:1999/DCOR 1")
            end
          end
        end
      end
    end
  end
end
