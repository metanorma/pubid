# frozen_string_literal: true

require "spec_helper"

# Tranche 1 of the `number` retype: ansi, api, bsi, cen_cenelec, idf and jcgm
# hold `number`, `part` and `subpart` as plain `:string` attributes instead of
# a `Pubid::Components::Code`.
#
# WHY. ::Pubid::Identifier declares all three as `Components::Code`
# (lib/pubid/identifier.rb:136-138), so a flavor that wants a scalar must
# REDECLARE the attribute — and a redeclaration on a class that other classes
# inherit from resolves nondeterministically under multi-flavor load. That
# landmine is recorded a dozen times in CLAUDE.md and is why twelve flavors
# carry a structural tripwire spec. It exists only because the parent and the
# leaves disagree about the type. These six flavors stored a String in a box:
# measured over the whole fixture corpus, not one of their 2,066 identifiers
# populated `prefix`, `part`, `subpart` or `parts` inside the Code, and
# `number.parts` / `number.prefix` have zero call sites anywhere in lib/.
#
# The base declaration is deliberately NOT changed here — that is the last step
# of the three-tranche sequence, after ISO, NIST and CSA also move. Until then
# the disagreement is real, which is exactly what the first block below pins.
#
# IMPORTANT: the structural block is only meaningful under the FULL suite
# (`bundle exec rake`), never `rspec spec/pubid/<flavor>` alone. lutaml
# deep-dups the parent attribute table into each subclass at class-definition
# time, so a single-flavor run can resolve the attribute differently from a run
# that has loaded every flavor.
module NumberStringRetypeSpec
  STRING = Lutaml::Model::Type::String

  # The three attributes ::Pubid::Identifier declares as a Components::Code.
  ATTRS = %i[number part subpart].freeze

  # flavor fixture dir => [flavor module, minimum ids the sweep must find]
  FLAVORS = {
    "ansi" => [Pubid::Ansi, 170],
    "api" => [Pubid::Api, 190],
    "bsi" => [Pubid::Bsi, 1_400],
    "cen_cenelec" => [Pubid::CenCenelec, 100],
    "idf" => [Pubid::Idf, 60],
    "jcgm" => [Pubid::Jcgm, 25],
  }.freeze

  # Identifiers whose from_hash(to_hash) does not reproduce to_hash. Every one
  # of these already failed before the retype (measured on the parent commit:
  # ansi 0, api 1, bsi 613, cen_cenelec 64, idf 0, jcgm 0) and none of the
  # causes is the number type. BSI improved from 613 to 594 here, because the
  # members of a bundled identifier now resolve to the flavor class instead of
  # the abstract root — see Pubid::Identifier.own_base_class.
  KNOWN_ROUND_TRIP_FAILURES = {
    "ansi" => 0,
    "api" => 1,
    "bsi" => 594,
    "cen_cenelec" => 64,
    "idf" => 0,
    "jcgm" => 0,
  }.freeze

  # One reference per flavor whose serialized hash must carry a BARE scalar
  # number, and the scalar it must carry.
  FLAT_WIRE = {
    "ansi" => ["ANSI C135.14-2000", "C135.14"],
    "api" => ["API RP 500", "500"],
    "bsi" => ["BS 1234:2020", "1234"],
    "cen_cenelec" => ["EN 196-3:2005", "196"],
    "idf" => ["IDF 125:1988", "125"],
    "jcgm" => ["JCGM 100:2008", "100"],
  }.freeze

  # A generated pass fixture writes "!input!rendered" for a NORMALIZING parse
  # (one that succeeds but whose to_s differs from the input); only the input
  # half is parseable. Mirrors FixtureFileHelper#read_pass_fixture_entries.
  NORMALIZING = /\A!(.+)!(.+)\z/

  class << self
    # Every class in a flavor's hierarchy, the shared base included. Reading
    # polymorphic_type_map first forces the concrete Identifiers::* classes to
    # autoload; ObjectSpace then also picks up the intermediates they inherit
    # (SingleIdentifier, SupplementIdentifier, Identifiers::Base ...), which is
    # where the landmine actually lives.
    def hierarchy(mod)
      base = mod.const_get(:Identifier)
      base.polymorphic_type_map
      ([base] + ObjectSpace.each_object(Class).select { |c| c < base })
        .uniq.sort_by(&:name)
    end

    # Attributes of `klass` that do not resolve to a plain String, reported as
    # "Class#attr=Type" so a failure names the offender.
    def offenders(mod)
      hierarchy(mod).flat_map do |klass|
        ATTRS.filter_map do |attr|
          type = klass.attributes[attr]&.type
          "#{klass.name}##{attr}=#{type}" if type != STRING
        end
      end
    end

    # True when `klass` reaches `attr` through a hand-written delegation rather
    # than the lutaml-generated accessor. All six flavors declare the three
    # attributes on their `Identifier` base, so that is where a generated
    # reader is owned; anything else is a wrapper forwarding to a nested
    # identifier, which may belong to a flavor that has not converted yet.
    def delegated?(mod, klass, attr)
      klass.instance_method(attr).owner != mod.const_get(:Identifier)
    end

    # [input, identifier] for every parseable pass-fixture line of a flavor.
    def corpus(flavor)
      @corpus ||= {}
      @corpus[flavor] ||= begin
        klass = FLAVORS.fetch(flavor).first.const_get(:Identifier)
        fixture_inputs(flavor).filter_map do |line|
          id = try_parse(klass, line)
          [line, id] if id
        end
      end
    end

    private

    def fixture_inputs(flavor)
      glob = File.join(__dir__,
                       "../fixtures/#{flavor}/identifiers/pass/*.txt")
      lines = Dir.glob(glob).flat_map { |f| File.readlines(f, chomp: true) }
      lines.filter_map { |line| fixture_input(line) }.uniq
    end

    def fixture_input(line)
      stripped = line.strip
      return nil if stripped.empty? || stripped.start_with?("#")

      (m = stripped.match(NORMALIZING)) ? m[1] : stripped
    end

    def try_parse(klass, line)
      klass.parse(line)
    rescue StandardError, Parslet::ParseFailed
      nil
    end
  end
end

RSpec.describe "number/part/subpart as :string (tranche 1)" do
  describe "the shared base is NOT retyped" do
    # The whole point of the tranching: this line moves last, once ISO, NIST
    # and CSA have also converted. A failure here means someone jumped ahead.
    NumberStringRetypeSpec::ATTRS.each do |attr|
      it "::Pubid::Identifier still declares #{attr} as Components::Code" do
        expect(Pubid::Identifier.attributes[attr].type)
          .to eq(Pubid::Components::Code)
      end
    end
  end

  NumberStringRetypeSpec::FLAVORS.each do |flavor, (mod, minimum)|
    describe mod.name do
      describe "structural tripwire (full-suite only)" do
        it "resolves number/part/subpart to String on every class" do
          expect(NumberStringRetypeSpec.offenders(mod)).to eq([])
        end
      end

      describe "the fixture corpus" do
        # These six flavors' own fixtures_spec.rb files all report 0 examples
        # (the `../../../fixtures` glob has one `..` too many; api and idf also
        # use an uppercase directory). Until that is fixed separately, this
        # sweep is the only thing exercising the corpus.
        let(:corpus) { NumberStringRetypeSpec.corpus(flavor) }

        it "parses a corpus worth sweeping" do
          expect(corpus.size).to be >= minimum
        end

        it "holds a String, never a Code, in number/part/subpart" do
          bad = corpus.reject do |_, id|
            NumberStringRetypeSpec::ATTRS.all? do |attr|
              # A wrapper that DELEGATES the reader (BSI's adoption types
              # return their nested identifier's number) reports a value it
              # does not own, and that nested id may be an ISO or IEC one,
              # which still holds a Components::Code until tranche 3.
              next true if NumberStringRetypeSpec.delegated?(mod, id.class,
                                                             attr)

              value = id.public_send(attr)
              value.nil? || value.is_a?(String)
            end
          end

          expect(bad.map(&:first).first(10)).to eq([])
        end

        it "round-trips through from_hash(to_hash) no worse than before" do
          # The counts are pinned exactly rather than as an upper bound, so
          # that a REGRESSION and an accidental IMPROVEMENT are both visible —
          # the convention identifier_roundtrip_spec.rb's PENDING_EQUALITY list
          # already uses. A count reaching 0 means: delete the entry.
          klass = mod.const_get(:Identifier)
          bad = corpus.reject do |_, id|
            hash = id.to_hash
            klass.from_hash(hash).to_hash == hash
          rescue StandardError
            false
          end

          expect(bad.size).to eq(
            NumberStringRetypeSpec::KNOWN_ROUND_TRIP_FAILURES.fetch(flavor),
          )
        end
      end

      describe "serialized shape" do
        it "emits a bare scalar number, not a nested {value => ...}" do
          ref, scalar = NumberStringRetypeSpec::FLAT_WIRE.fetch(flavor)

          expect(mod.const_get(:Identifier).parse(ref).to_hash["number"])
            .to eq(scalar)
        end
      end
    end
  end
end
