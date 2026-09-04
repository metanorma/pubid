# frozen_string_literal: true

module Pubid
  # Identifier that
  module Idf
    # An IDF identifier has no copublisher
    class Identifier < ::Pubid::Identifier
      attribute :typed_stage, Components::TypedStage

      # `number`/`part`/`subpart` are declared here rather than inherited as a
      # Components::Code: IDF stores a bare string in every one of them.
      # Declaring on this class is safe because its body lives in this one file
      # and is never reopened, so every subclass body opens after it has run
      # (lutaml deep-dups the parent attribute table at class-definition time).
      attribute :number, :string
      attribute :part, :string
      attribute :subpart, :string

      def to_s(**opts)
        render(format: :human, **opts)
      end

      def publisher_portion(lang: :en)
        [
          publisher.body,
          (typed_stage.abbreviation.empty? ? "" : "/#{typed_stage.abbreviation}"),
        ].join
      end

      def number_portion(lang_single: false)
        [
          # Directives may not have a number
          (number ? " #{number}" : ""),

          # Parts and subparts are optional
          (part ? "-#{part}" : ""),
          (subpart ? "-#{subpart}" : ""),

          # Stage iteration is optional
          (stage_iteration ? ".#{stage_iteration.number}" : ""),

          # Date is optional
          (date ? ":#{date.year}" : ""),

          # Languages are optional
          language_portion(lang_single: lang_single),
        ].join
      end

      # Returns a string representation of the languages
      # :single returns single-char language codes
      def language_portion(lang_single: false)
        return "" unless languages&.any?

        [
          "(",
          languages.map do |lang|
            lang.to_s(lang_single: lang_single)
          end.join(lang_single ? "/" : ","),
          ")",
        ].join
      end

      def self.parse(string)
        if string.length > Pubid::MAX_INPUT_LENGTH
          raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        parsed = Pubid::Idf::Parser.new.parse(string)
        if parsed.nil? || parsed.empty?
          raise Pubid::Idf::Parser::ParseError,
                "Invalid identifier format"
        end

        Pubid::Idf::Builder.new.build(parsed)
      end
    end
  end
end
