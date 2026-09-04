# frozen_string_literal: true

module Pubid
  module Idf
    class Builder < Pubid::Builder::Base
      LANG_CHAR_MAP = {
        "R" => "ru",
        "F" => "fr",
        "E" => "en",
        "A" => "ar",
        "S" => "es",
        "D" => "de",
      }.freeze

      def build(parsed_hash)
        typed_stage = Pubid::Idf.locate_stage(parsed_hash[:type_with_stage])
        identifier = Pubid::Idf.locate_type(typed_stage.type_code).new

        if type_with_stage_fr = parsed_hash.delete(:type_with_stage_fr)
          parsed_hash[:type_with_stage] = type_with_stage_fr
        end

        assign_attributes(identifier, parsed_hash)
        identifier
      end

      private

      def default_identifier_class
        Identifiers::InternationalStandard
      end

      def cast(type, value)
        case type
        when :base
          build(value)
        when :publisher
          Components::Publisher.new(body: value)
        when :number_with_part
          parts = value.to_s.split("-")
          number = parts.shift
          part = parts.shift
          subpart = parts.size.positive? ? parts.join("-") : nil
          code_hash = { number: number }
          code_hash[:part] = part if part
          code_hash[:subpart] = subpart if subpart
          code_hash
        when :type_with_stage
          iteration = value.to_s.match(/(\d+)$/)
          value = value.to_s.sub(iteration.to_s, "")
          typed_stage = Pubid::Idf.locate_stage(value || "")
          {
            stage: typed_stage.to_stage,
            type: typed_stage.to_type,
            typed_stage: typed_stage,
          }
        when :date
          value = value.to_s
          if value.match?(/^\d{4}(-\d{2})?$/)
            year, month = value.split("-")
            Components::Date.new(year: year, month: month || nil)
          elsif value.is_a?(Integer) || (value.is_a?(String) && value.match?(/^\d{4}$/))
            Components::Date.new(year: value)
          else
            raise ArgumentError, "Invalid date format: #{value.inspect}"
          end
        when :languages
          value = value.to_s.gsub("/", ",")
          value.split(",").map do |lang|
            lang = lang.strip
            lang = LANG_CHAR_MAP[lang] if lang.length == 1
            Components::Language.new(code: lang)
          end
        when :all_parts
          Components::Locality.new(all_parts: true)
        else
          raise ArgumentError, "Unknown type: #{type}"
        end
      end
    end
  end
end
