# frozen_string_literal: true

module Pubid
  module Ashrae
    # Base class for all ASHRAE identifiers. Canonical name
    # Pubid::Ashrae::Identifier; every concrete ASHRAE identifier descends from it.
    class Identifier < ::Pubid::Identifier
      # Parse an ASHRAE identifier string into an identifier object
      # @param identifier [String] The ASHRAE identifier string to parse
      # @return [Pubid::Ashrae::Identifier] The appropriate identifier object
      # @raise [Parslet::ParseFailed] If parsing fails
      def self.parse(identifier)
        parsed = Parser.parse(identifier)
        Builder.build(parsed)
      rescue Parslet::ParseFailed => e
        raise "Failed to parse ASHRAE identifier '#{identifier}': #{e.message}"
      end

      attribute :publisher, :string, default: "ASHRAE"
      # The document number used to live here as `attribute :code, :string`,
      # leaving the `number` inherited from ::Pubid::Identifier nil — so
      # relaton-index, which sorts and bsearches on `id.root.number.to_s`,
      # keyed all 3,619 ASHRAE rows on "".
      #
      # It is now `attribute :number, :string` on the two single-document
      # LEAVES (Identifiers::Standard and Identifiers::Guideline), never here:
      # this class is inherited by BOTH SingleIdentifier and
      # SupplementIdentifier, and redefining the parent's Components::Code-typed
      # `number` on an inherited-from class resolves nondeterministically under
      # multi-flavor load. The supplement types carry no number of their own —
      # they reach it through #root, which walks `base`.
      attribute :year, :string
      attribute :type, :string
      attribute :suffix, :string # R (revision), P (proposed), etc.
      attribute :amendment, :string
      attribute :reaffirmed, :string
      attribute :copublisher, :string

      # --- MR slug hooks -------------------------------------------------
      #
      # ASHRAE supplied none, and every base hook looks for something ASHRAE
      # does not use: `mr_type` reads a typed_stage, `mr_year` reads a
      # Components::Date. With `number` nil too, ALL 3,619 ids collapsed onto
      # the single slug "ashrae" — the worst collapse measured in the gem, and
      # `to_slug` is what consumers use as an output FILENAME.
      #
      # `type` distinguishes a Guideline from a Standard of the same number
      # (Guideline 0 and Standard 0 are different documents), so it has to
      # reach the slug and not only `==`.
      def mr_type
        type&.to_s&.downcase
      end

      # ASHRAE keeps its edition in a plain `year` string, not the inherited
      # `date`, so the base hook read nil and every edition of one standard
      # shared a slug.
      def mr_year
        year&.to_s
      end

      # `copublisher` is in `==` and in `to_s`, so by the project rule it has to
      # reach the slug too: "ASHRAE Standard 15-2019 Addendum a" and
      # "ANSI/ASHRAE Addendum a to ANSI/ASHRAE Standard 15-2019" have different
      # hashes and would otherwise share a filename. (Whether those two strings
      # ought to normalise to ONE identifier is a separate question, and not one
      # the slug should paper over.)
      def mr_publisher
        mr_sanitize(copublisher || publisher)
      end

      # Both trailing markers are identity-bearing and must reach the slug, not
      # only `==`: `reaffirmed` ("RA 2017") separates "ANSI/ASHRAE Standard
      # 206-2013 (RA 2017)" from the plain "…206-2013", and `suffix` ("R" for
      # revision, "P" for proposed) separates "ASHRAE Guideline 27-2019" from
      # "…27-2019R". Their hashes differ, so their filenames must too.
      # Uses the shared #mr_join rather than a bare `compact.join("-")`, so it
      # returns nil instead of "" when nothing survives: MrString's own
      # `compact` drops nil but not the empty string, and a blank segment
      # yields a double dot in the joined slug.
      def mr_number_with_part
        mr_join(mr_sanitize(number),
                (reaffirmed ? "ra#{mr_sanitize(reaffirmed)}" : nil),
                mr_sanitize(suffix))
      end

      # An ASHRAE value can carry characters outside the [a-z0-9.-] charset
      # Renderers::MrString documents: a comma in the code "90A,B,C", a slash
      # in the copublisher "ANSI/ASHRAE", spaces in a package description.
      # Filter BY CHARSET (the BIPM `mr_slug` precedent) rather than by an
      # enumerated escape list, so a character introduced later cannot reach a
      # filename.
      #
      # Public alongside the hooks above rather than tucked behind `private`,
      # since the whole MR surface here is public, and the supplement types
      # call it from their own mr_supplement_suffix. The output emptiness check
      # matters: a value made only of out-of-charset characters collapses to
      # "", which is truthy in Ruby and would reach the renderer as a blank
      # segment, producing a double dot in the joined slug.
      def mr_sanitize(value)
        return nil if value.nil? || value.to_s.empty?

        sanitized = value.to_s.downcase
          .gsub(%r{[^a-z0-9.-]+}, "-").gsub(%r{\A-+|-+\z}, "")
        sanitized.empty? ? nil : sanitized
      end

      # ASHRAE stores the publication year in a plain :string scalar, not a
      # Components::Date, so the base #exclude's :year->:date remap cannot nil
      # it. Reset the scalar directly (mirroring CSA/BIPM) so a year-less
      # partial reference is a year wildcard under
      # matches?(other, ignore: [:year]). super still recurses into the nested
      # `base` of wrapper types (Errata/Addendum/…), which carry no year scalar.
      def exclude(*args)
        result = super
        year_keys = args & %i[year date]
        result.year = nil if !year_keys.empty? && result.respond_to?(:year=)
        result
      end
    end
  end
end
