module Pubid::Ieee
  module Identifier
    RSpec.describe Base do
      describe "#to_s" do
        context "with trademark" do
          subject { described_class.new(number: number).to_s(with_trademark: true) }

          context "when 802" do
            let(:number) { 802 }

            it { expect(subject).to eq("IEEE Std 802\u00AE") }
          end

          context "when 2030" do
            let(:number) { 2030 }

            it { expect(subject).to eq("IEEE Std 2030\u00AE") }
          end

          context "when other from 2030 or 802" do
            let(:number) { 1 }

            it { expect(subject).to eq("IEEE Std 1\u2122") }
          end
        end
      end
    end
  end
end
