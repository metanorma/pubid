# frozen_string_literal: true

module Pubid
  module Bsi
    # BSI base class. Canonical name Pubid::Bsi::Identifier; SingleIdentifier is a
    # back-compat alias (BSI's common ancestor — there is no Identifiers::Base).
    # Every concrete BSI identifier descends from it, so they are all
    # `is_a?(Pubid::Bsi::Identifier)` natively and get the shared polymorphic
    # `from_hash` (no facade needed).
    class Identifier < ::Pubid::Identifier
      def self.parse(string)
        if string.length > Pubid::MAX_INPUT_LENGTH
          raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        # Delegate to IEC for bare IEC identifiers. This handles IEC-specific
        # features like VAP suffixes (CSV, RLV, etc.) and consolidated
        # supplements (+AMD1:2001).
        if string.match?(/\bIEC\b/) &&
            (string.match?(/\s+(CSV|CMV|RLV|SER|EXV|PAC|PRV)\b/) ||
             string.match?(/\+AMD\d+:/) ||
             string.match?(/\+COR\d+:/))
          return Pubid::Iec.parse(string)
        end

        parser = Parser.new

        parsed = parser.parse(string)
        Builder.build(parsed)
      rescue Parslet::ParseFailed => e
        raise StandardError, "Failed to parse '#{string}': #{e.message}"
      end

      attribute :publisher, Bsi::Components::Publisher, default: -> {
        Bsi::Components::Publisher.new(body: "BS")
      }
      attribute :prefix, :string # Specialized prefix (A, AU, C, M, 2A, etc.)
      attribute :flex_prefix, :string # Flex type prefix (CECC, E9111, M, etc.)
      # `number`/`part`/`subpart` are plain strings, not Bsi::Components::Code:
      # BSI never populates a field of that component beyond `value`. This class
      # body is the sole home of Pubid::Bsi::Identifier (bsi/identifier.rb is a
      # comment-only load stub), so declaring here is safe - every subclass body
      # opens after it has run. `second_number` keeps the component type: it is
      # not one of the three attributes the shared base declares.
      attribute :number, :string
      attribute :iteration, :string # For bracket notation like 1000[9]
      attribute :part, :string
      attribute :subpart, :string
      attribute :second_number, Bsi::Components::Code # For collections like PAS 2035/2030
      attribute :date, Bsi::Components::Date
      attribute :stage, Pubid::Components::Stage
      attribute :type, Bsi::Components::Type
      attribute :typed_stage, Pubid::Components::TypedStage
      attribute :edition, :string
      attribute :month, :integer
      attribute :translation_lang, :string
      attribute :translation_upper, :string
      attribute :explicit_prefix, :boolean, default: -> { false }
      attribute :explicit_publisher, :boolean, default: -> { false }
      attribute :space_separated_part, :boolean, default: -> { false }

      def <=>(other)
        return nil unless other.is_a?(Pubid::Bsi::Identifier)

        # Compare by number first
        num_cmp = number.to_s <=> other.number.to_s
        return num_cmp unless num_cmp.zero?

        # Then by part
        part_cmp = (part || "0").to_s <=> (other.part || "0").to_s
        return part_cmp unless part_cmp.zero?

        # Then by date
        if date && other.date
          date.to_s <=> other.date.to_s
        elsif date
          1
        elsif other.date
          -1
        else
          0
        end
      end

      # Annex F series groupings per "Rules for the structure and drafting
      # of UK standards" (BSI, 2017), F.1.3-F.1.5. Each maps a `prefix`
      # token to the broader series category.
      SERIES_CATEGORIES = {
        # F.1.3 Automobile
        "AU" => :automotive,
        # F.1.4 Aerospace
        "A" => :aerospace, "B" => :aerospace, "C" => :aerospace,
        "F" => :aerospace, "G" => :aerospace, "HC" => :aerospace,
        "L" => :aerospace, "S" => :aerospace, "SP" => :aerospace,
        "X" => :aerospace, "M" => :aerospace, "TA" => :aerospace,
        "2A" => :aerospace, "2B" => :aerospace, "2C" => :aerospace,
        "2F" => :aerospace, "2G" => :aerospace, "2HC" => :aerospace,
        "2HR" => :aerospace, "2L" => :aerospace, "2M" => :aerospace,
        "2S" => :aerospace, "2SP" => :aerospace, "2TA" => :aerospace,
        "2X" => :aerospace, "3A" => :aerospace, "3B" => :aerospace,
        "3F" => :aerospace, "3G" => :aerospace, "3HR" => :aerospace,
        "3J" => :aerospace, "3L" => :aerospace, "3S" => :aerospace,
        "3TA" => :aerospace, "4F" => :aerospace, "4L" => :aerospace,
        "4S" => :aerospace, "5S" => :aerospace, "7S" => :aerospace,
        # F.1.5 Marine
        "MA" => :marine, "PL" => :marine, "QC" => :marine,
      }.freeze

      # Series accessor — semantically named alias for `prefix` per
      # issue #252. Returns the prefix token (e.g., "AU", "MA", "2A").
      def series
        prefix
      end

      # Series category — one of :automotive, :aerospace, :marine, or nil
      # when the identifier doesn't carry a recognized Annex F prefix.
      def series_category
        SERIES_CATEGORIES[prefix.to_s] if prefix
      end

      def automotive?
        series_category == :automotive
      end

      def aerospace?
        series_category == :aerospace
      end

      def marine?
        series_category == :marine
      end
    end

    # Backward-compatible alias: BSI's base class is Pubid::Bsi::Identifier.
    # Concrete types declared as `< SingleIdentifier` continue to work.
    SingleIdentifier = Identifier
  end
end
