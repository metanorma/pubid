module Pubid::Ieee
  module Identifier
    RSpec.describe Base do
      describe "#to_s" do
        context "with trademark" do
          subject { described_class.new(number: number).to_s(with_trademark: true) }

          context "when 802" do
            let(:number) { 802 }

            it { expect(subject).to eq("IEEE Std 802®") }
          end

          context "when 2030" do
            let(:number) { 2030 }

            it { expect(subject).to eq("IEEE Std 2030®") }
          end

          context "when other from 2030 or 802" do
            let(:number) { 1 }

            it { expect(subject).to eq("IEEE Std 1™") }
          end
        end

        # IEEE attaches the mark to the standard number, before the year and
        # every suffix: "IEEE Std 1619(TM)-2007", "IEEE Std 802.3(R)-2018".
        # See metanorma/pubid#322.
        context "trademark position" do
          {
            # reference                            => trademarked rendering
            "IEEE Std 1619-2007" => "IEEE Std 1619™-2007",
            "IEEE Std 1017.2-2021" => "IEEE Std 1017.2™-2021",
            "IEEE Std C37.09-2018" => "IEEE Std C37.09™-2018",
            "IEEE Std 802.3-2018" => "IEEE Std 802.3®-2018",
            "IEEE Std 2030.5-2018" => "IEEE Std 2030.5®-2018",
            "IEEE Std 802.15.22.3-2020" => "IEEE Std 802.15.22.3®-2020",
            # mark precedes the corrigendum suffix
            "IEEE Std 802.16-2004/Cor 1-2005" =>
              "IEEE Std 802.16®-2004/Cor 1-2005",
            "IEEE Std 1003.1-2002/Cor 1-2002" =>
              "IEEE Std 1003.1™-2002/Cor 1-2002",
            # mark precedes the draft suffix and the trailing date
            "IEEE P802.1AE/D1.0" => "IEEE Draft Std P802.1AE®/D1.0",
            "IEEE P802.1Q/D1.1, September 2015" =>
              "IEEE Draft Std P802.1Q®/D1.1, September 2015",
            # mark precedes the redline suffix
            "IEEE Std 1012-1998 - Redline" =>
              "IEEE Std 1012™-1998 - Redline",
            "IEEE Std 802.3-2018 - Redline" =>
              "IEEE Std 802.3®-2018 - Redline",
          }.each do |reference, trademarked|
            context reference do
              subject(:identifier) { Pubid::Ieee::Identifier.parse(reference) }

              it "renders the mark after the number, before every suffix" do
                expect(identifier.to_s(with_trademark: true)).to eq(trademarked)
              end

              it "leaves the plain rendering unchanged" do
                expect(identifier.to_s)
                  .to eq(trademarked.delete("™®"))
              end
            end
          end
        end

        # The registered mark belongs to the IEEE-published 802 / 8802 / 2030
        # series, whatever the publisher *prefix* or the project "P" — see
        # metanorma/pubid#322.
        context "registered trademark series" do
          {
            "IEEE Std 802.3-2018" => "®",
            "ANSI/IEEE 802.9a-1995" => "®",
            "IEEE Std 8802-3-2021" => "®",
            "IEEE P802.1AE/D1.0" => "®",
            "IEEE Std 2030.5-2018" => "®",
            "IEEE Std 1619-2007" => "™",
            "IEEE Std C37.09-2018" => "™",
            # The registered mark is IEEE's: another body that merely numbered
            # a document 802 does not get it (AIEE dissolved in 1963, two
            # decades before the IEEE 802 series).
            "AIEE Std No. 802" => "™",
            "ANSI 802.1-1985" => "™",
          }.each do |reference, symbol|
            it "renders #{symbol} for #{reference}" do
              rendered = Pubid::Ieee::Identifier.parse(reference)
                .to_s(with_trademark: true)
              expect(rendered).to include(symbol)
            end
          end
        end

        # A purely ISO-routed form has no IEEE number of its own, so the mark
        # falls back to the end of the string — but its symbol must still come
        # from the document series, which for a supplement lives on the base
        # (the supplement's own number is the ordinal "1").
        context "ISO-routed form with no IEEE designation" do
          {
            "ISO/IEC/IEEE 8802-11:2012/Amd.1:2013(E)" => "®",
            "IEC 61588:2009(E)" => "™",
          }.each do |reference, symbol|
            it "ends with #{symbol} for #{reference}" do
              expect(Pubid::Ieee::Identifier.parse(reference)
                .to_s(with_trademark: true)).to end_with(symbol)
            end
          end
        end

        # The IEEE designation of an ISO-led co-publication lives in the
        # parenthesised alternative, so the mark belongs on that number.
        context "ISO-led co-publication" do
          subject(:identifier) do
            Pubid::Ieee::Identifier.parse(
              "ISO/IEC 8802-3:2021 (IEEE Std 802.3-2021)",
            )
          end

          it "marks the IEEE designation, not the ISO one" do
            expect(identifier.to_s(with_trademark: true))
              .to eq("ISO/IEC 8802-3:2021 (IEEE Std 802.3®-2021)")
          end
        end

        # The mark must be purely additive: removing it from the trademarked
        # rendering must give back the plain rendering, for every fixture.
        context "over the whole fixture corpus" do
          let(:references) do
            File.read(
              File.join(__dir__, "..", "..", "fixtures", "pubid-parsed.txt"),
            ).split("\n").map(&:strip).reject(&:empty?)
          end

          it "only ever adds a mark to the plain rendering" do
            checked = 0

            offenders = references.filter_map do |reference|
              identifier = begin
                Pubid::Ieee::Identifier.parse(reference)
              rescue StandardError
                next
              end

              plain = identifier.to_s
              marked = identifier.to_s(with_trademark: true)
              checked += 1
              # ">= 1", not "== 1": an ISO-led form listing several IEEE
              # designations marks each of them, as IEEE prints co-equal
              # designations.
              next if marked.delete("™®") == plain &&
                marked.count("™®") >= 1

              [reference, plain, marked]
            end

            expect(offenders).to eq([])
            # Floor guard — without it this example passes vacuously if the
            # fixture file moves or every reference stops parsing.
            expect(checked).to be > 8_000
          end
        end
      end
    end
  end
end
