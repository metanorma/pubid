# frozen_string_literal: true

require "spec_helper"

# API's renderer dropped the document number and the type token from every
# non-MPMS identifier, so 163 of the 193 corpus ids rendered as the bare
# publisher "API". `to_s` is both the document number and the output filename,
# so all 163 collapsed onto each other.
#
# Two independent causes, both dead reads:
#
#   1. `Api::Renderer#code_portion` read an `id.code` attribute that NOTHING
#      ever assigned — the parser emits no `:code` key and Builder#cast never
#      sets one — while the number the builder DOES populate sits in `number`.
#      The attribute is now gone (see Api::SingleIdentifier) and the renderer
#      reads `number`.
#   2. The type token was gated on `id.class.attributes.key?(:type_string)`,
#      but `type_string` is a plain method on each leaf, never a lutaml
#      attribute, so the guard was always false. It now checks `respond_to?`.
#
# Nothing caught this: API's fixtures_spec.rb resolves a glob that matches no
# files and reports 0 examples (hand-off `ten-dead-fixture-specs`), and the
# other API specs are `respond_to?(:parse)` stubs. The generated pass fixtures
# had recorded the CORRECT renderings all along — the code had drifted away
# from them silently.
RSpec.describe "Pubid::Api rendering" do
  describe "renders the type token and the document number" do
    {
      "API RP 500" => "RecommendedPractice",
      "API STD 650-2020" => "Standard",
      "API BULL 11L2" => "Bulletin",
      "API PUBL 4527" => "Publication",
      "API SPEC 5CT-2018" => "Specification",
      "API 5L-2018" => "TypelessStandard",
    }.each do |ref, leaf|
      context ref do
        subject(:id) { Pubid::Api::Identifier.parse(ref) }

        it "is an Identifiers::#{leaf}" do
          expect(id.class.name.split("::").last).to eq(leaf)
        end

        it "round-trips to_s byte-exactly" do
          expect(id.to_s).to eq(ref)
        end
      end
    end
  end

  describe "the `code` attribute is gone" do
    # It was write-never / read-always-nil. Removing it is what forced the
    # renderer onto `number`; re-adding it would silently reopen the defect.
    it "is not declared anywhere in the hierarchy" do
      klasses = [Pubid::Api::Identifier, Pubid::Api::SingleIdentifier,
                 Pubid::Api::Identifiers::Base,
                 Pubid::Api::Identifiers::RecommendedPractice]

      klasses.each { |k| expect(k.attributes).not_to have_key(:code) }
    end

    it "keeps the number in `number`, as a String" do
      id = Pubid::Api::Identifier.parse("API RP 500")

      expect(id.number).to eq("500")
      expect(id.number).to be_a(String)
    end
  end

  describe "MPMS rendering" do
    # The one form that always rendered correctly: render_mpms builds its own
    # string and never consulted code_portion, which is why it escaped the
    # defect above.
    it "renders its chapter designation" do
      expect(Pubid::Api::Identifier.parse("API MPMS CH 4.1").to_s)
        .to eq("API MPMS CH 4.1")
    end
  end

  describe "the Parslet::Slice that used to reach root.number" do
    # On the parent commit this one corpus form put a raw Parslet::Slice
    # ("75"@16) into a model attribute — a parser artifact the retype hand-off
    # documented and warned would look like a migration failure. The retype
    # closes it: Api::Builder#cast now returns `value.to_s` for :number rather
    # than wrapping the Slice in a Components::Code, so the attribute holds a
    # real String. It was the only such id in the whole API corpus.
    subject(:number) do
      Pubid::Api::Identifier.parse("API COS 1-07/RP 75, 4th edition")
        .root.number
    end

    it "is now a String, not a Parslet::Slice" do
      expect(number).to be_a(String)
      expect(number).not_to be_a(Parslet::Slice)
    end

    it "carries the document number" do
      expect(number).to eq("75")
    end
  end

  describe "MPMS MR slugs" do
    # Two changes met here. #354 moved the MPMS chapter out of its own
    # `chapter` attribute into the inherited `number` (it IS the document
    # number), and this branch retyped that `number` to :string. Composed,
    # they close the collapse this spec originally pinned: all 30 MPMS ids
    # used to slug to the bare "api", because the shared Renderers::MrString
    # hooks found no number at all.
    it "no longer collapses every MPMS document onto the bare publisher" do
      a = Pubid::Api::Identifier.parse("API MPMS CH 4.1")
      b = Pubid::Api::Identifier.parse("API MPMS CH 12.2")

      expect(a.to_mr_string).to eq("api.4")
      expect(b.to_mr_string).to eq("api.12")
    end

    it "carries the chapter in `number`, as a String" do
      id = Pubid::Api::Identifier.parse("API MPMS CH 12.2")

      expect(id.number).to eq("12")
      expect(id.number).to be_a(String)
    end

    # KNOWN GAP, narrower than before and NOT this branch's to close: the MR
    # slug is built from `number` alone, so every section of one chapter still
    # shares it — 11 colliding slugs across the corpus, and to_slug is an
    # output FILENAME. Closing it needs an Mpms#mr_number_with_part that
    # appends section/subsection, the shape BIPM and OIML use. Asserted as
    # CURRENT behaviour so a fix trips it.
    it "still shares one slug across the sections of a chapter" do
      a = Pubid::Api::Identifier.parse("API MPMS CH 14.4")
      b = Pubid::Api::Identifier.parse("API MPMS CH 14.6")

      expect(a.to_s).not_to eq(b.to_s)
      expect(a.to_mr_string).to eq(b.to_mr_string)
    end

    it "gives an ordinary numbered identifier a distinct slug" do
      expect(Pubid::Api::Identifier.parse("API RP 500").to_mr_string)
        .to eq("api.500")
    end
  end

  describe "the whole API fixture corpus" do
    # API's own fixtures_spec.rb reports 0 examples, so this is the only thing
    # exercising the corpus. 190 of 193 render byte-exactly; the 3 exceptions
    # are the normalizing parses the generated fixtures already mark with the
    # `!input!rendered` form.
    let(:normalizing) do
      {
        "API MPMP CH 10.10" => "API MPMS CH 10.10",
        "API RP 554, Part 2" => "API RP 554",
        "API COS 1-07/RP 75, 4th edition" => "API 75-07",
      }
    end

    let(:inputs) do
      Dir.glob(File.join(__dir__, "../../fixtures/api/identifiers/pass/*.txt"))
        .flat_map { |f| File.readlines(f, chomp: true) }
        .map(&:strip).reject(&:empty?).reject { |l| l.start_with?("#") }
        .map { |l| (m = l.match(/\A!(.+)!(.+)\z/)) ? m[1] : l }
        .uniq
    end

    it "finds the corpus" do
      expect(inputs.size).to be >= 190
    end

    it "renders every identifier back to itself, bar the normalizing forms" do
      bad = inputs.reject do |line|
        rendered = Pubid::Api::Identifier.parse(line).to_s
        rendered == (normalizing[line] || line)
      end

      expect(bad).to eq([])
    end

    it "gives every identifier a non-empty root.number" do
      # No exclusions: since #354 moved the MPMS chapter into `number`, every
      # API identifier has one.
      bad = inputs.select do |line|
        Pubid::Api::Identifier.parse(line).root.number.to_s.empty?
      end

      expect(bad).to eq([])
    end
  end
end
