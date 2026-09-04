# frozen_string_literal: true

module Pubid
  # Identifier that represents a combined bundle of documents using the + operator.
  # Examples:
  #   EN 10077-1:2006+AC:2009+AC2:2009
  #   ISO/IEC DIR 1 + IEC SUP:2016-05
  #   ISO 8601:2019+Amd 1:2024+Cor 1:2025
  #
  # Semantic: Base document combined with amendments/corrigenda that are applied together
  # This is different from:
  #   / operator (SupplementIdentifier) - supplement of a document
  #   | operator (CombinedIdentifier) - dual-published by multiple organizations
  class BundledIdentifier < Identifier
    attribute :base_document, Identifier, polymorphic: true
    attribute :supplements, Identifier, polymorphic: true, collection: true
    attribute :type, :string, default: -> { "bundled_identifier" }

    # Delegate common attributes to base_document for easier access
    def publisher
      base_document&.publisher
    end

    def copublishers
      base_document&.copublishers
    end

    def number
      base_document&.number
    end

    def date
      base_document&.date
    end

    def type
      base_document&.type
    end

    def stage
      base_document&.stage
    end

    def typed_stage
      base_document&.typed_stage
    end

    def to_s(lang: :en, lang_single: false, with_edition: false, format: nil,
stage_format_long: nil, with_date: nil)
      result = base_document.to_s(lang: lang, lang_single: lang_single,
                                  with_edition: with_edition, format: format, stage_format_long: stage_format_long, with_date: with_date)

      supplements.each do |supplement|
        # ISO DirectivesSupplement always uses " + " (space before)
        # CEN-style supplements (AC, A) without base use "+" (no space before)
        # Other ISO supplements with base use " + " (space before)
        if supplement.class.name&.include?("DirectivesSupplement") ||
            (supplement.class.attributes.key?(:base) && !supplement.base.nil?)
          result += " + #{supplement.to_s(lang: lang, lang_single: lang_single,
                                          with_edition: with_edition, format: format, stage_format_long: stage_format_long, with_date: with_date)}"
        else
          result += "+#{supplement.to_s(lang: lang, lang_single: lang_single,
                                        with_edition: with_edition, format: format, stage_format_long: stage_format_long, with_date: with_date)}"
        end
      end

      result
    end

    # Generate URN for bundled identifier
    # Flattens all components into a single URN
    #
    # Example: "ISO/IEC DIR 1:2022 + IEC SUP:2022"
    #          → "urn:iso:doc:iso-iec:dir:1:2022:iec:sup:2022"
    def to_urn
      # Start with base document URN components
      parts = base_document.to_urn.split(":")

      # Add each supplement's components
      supplements.each do |supplement|
        # For DirectivesSupplement: add organization and "sup" (not "dir-sup")
        if supplement.class.name&.include?("DirectivesSupplement")
          # Add organization (e.g., "IEC")
          if supplement.class.attributes.key?(:supplement_publisher) && supplement.supplement_publisher
            parts << supplement.supplement_publisher.body.downcase
          end

          # Always add "sup" for DirectivesSupplement (not "dir-sup")
          parts << "sup"

          # Add year
          parts << supplement.date.year.to_s if supplement.date
        else
          # For other supplements: use typed_stage type_code
          if supplement.typed_stage
            type_code = supplement.typed_stage.type_code
            parts << type_code.to_s unless type_code == :is
          end

          # Add supplement date
          if supplement.date
            parts << supplement.date.year.to_s
          end

          # Add supplement number if present. `supplement` is polymorphic and
          # `number` is a Components::Code on ::Pubid::Identifier but a plain
          # :string in a growing number of flavors, so read through either.
          if supplement.number
            number = supplement.number
            value = number.respond_to?(:value) ? number.value : number
            parts << "v#{value}"
          end
        end
      end

      parts.join(":")
    end

    # Support comparison for sorting
    def <=>(other)
      return nil unless other.is_a?(BundledIdentifier)

      base_comparison = base_document.to_s <=> other.base_document.to_s
      return base_comparison unless base_comparison.zero?

      supplements.map(&:to_s).sort <=> other.supplements.map(&:to_s).sort
    end
  end
end
