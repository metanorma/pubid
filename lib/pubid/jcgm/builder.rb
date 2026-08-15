# frozen_string_literal: true

module Pubid
  module Jcgm
    class Builder < Pubid::Builder::Base
      def locate_identifier_klass(parsed_hash)
        if parsed_hash[:base]
          type_with_stage = parsed_hash[:type_with_stage]
          return Jcgm.locate_type(:amendment) unless type_with_stage

          return Jcgm.locate_type(locate_typed_stage(type_with_stage).type_code)
        end

        if parsed_hash[:gum_number]
          return Jcgm.locate_type(:gum_guide)
        end

        # Standard guide (no type_with_stage, no gum_number).
        # Don't use locate_stage("") — Guide and GumGuide both have
        # abbr: [""], so the result depends on constant iteration order.
        return Jcgm.locate_type(:guide) unless parsed_hash[:type_with_stage]

        typed_stage = locate_typed_stage(parsed_hash[:type_with_stage])
        Jcgm.locate_type(typed_stage.type_code)
      end

      def build(parsed_hash)
        klass = locate_identifier_klass(parsed_hash)

        # GUM guides store their part number in the shared `number` attribute
        # ("JCGM GUM-6" -> number "6"); the parser tags it :gum_number only to
        # pick this class. Fold it back onto :number before assigning.
        if parsed_hash[:gum_number] && klass == Identifiers::GumGuide
          parsed_hash = parsed_hash.merge(number: parsed_hash[:gum_number])
          parsed_hash.delete(:gum_number)
        end

        identifier = klass.new
        assign_attributes(identifier, parsed_hash)

        # Bare guides/gum-guides carry no parsed stage; derive the (single,
        # published) typed_stage from the concrete class so parse and from_hash
        # agree. Avoids the ambiguous locate_stage("") lookup (Guide and
        # GumGuide both register abbr: [""]).
        if identifier.class.attributes.key?(:typed_stage) && identifier.typed_stage.nil?
          identifier.typed_stage = identifier.class.published_typed_stage ||
            raise(ArgumentError, "No published typed_stage for #{identifier.class}")
        end

        identifier
      end

      private

      def default_identifier_class
        Identifiers::Guide
      end

      def locate_typed_stage(typed_stage_string)
        typed_stage_string = "" if typed_stage_string.nil?
        Jcgm.locate_stage(typed_stage_string) ||
          raise(ArgumentError, "Unknown type abbreviation: '#{typed_stage_string}'")
      end

      def cast(type, value)
        case type
        when :base
          build(value)
        when :publisher
          Jcgm::Components::Publisher.new(publisher: value.to_s)
        when :number
          Pubid::Components::Code.new(value: value.to_s)
        when :date
          date_str = value.to_s
          if date_str.include?("-")
            parts = date_str.split("-")
            Pubid::Components::Date.new(
              year: parts[0],
              month: parts[1],
              day: parts[2],
            )
          else
            Pubid::Components::Date.new(year: date_str)
          end
        when :type_with_stage
          typed_stage = locate_typed_stage(value.to_s)
          {
            stage: typed_stage.to_stage,
            type: typed_stage.to_type,
            typed_stage: typed_stage,
          }
        when :languages
          original_value = value.to_s
          langs = original_value.include?("/") ? original_value.split("/") : [original_value]
          langs.map do |lang|
            lang = lang.strip
            original_lang = lang
            lang = LANG_CHAR_MAP[lang] if lang.length == 1
            Pubid::Components::Language.new(code: lang,
                                            original_code: original_lang)
          end
        end
      end
    end
  end
end
