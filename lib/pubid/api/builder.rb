# frozen_string_literal: true

module Pubid
  module Api
    class Builder < Pubid::Builder::Base
      TYPE_CLASS_MAP = {
        "BULL" => Identifiers::Bulletin,
        "MPMS" => Identifiers::Mpms,
        "RP" => Identifiers::RecommendedPractice,
        "SPEC" => Identifiers::Specification,
        "STD" => Identifiers::Standard,
        "TR" => Identifiers::TechnicalReport,
        "COS" => Identifiers::ContinuousOperationsStandard,
        "PUBL" => Identifiers::Publication,
      }.freeze

      private

      def default_identifier_class
        Identifiers::TypelessStandard
      end

      def select_class(data)
        TYPE_CLASS_MAP[data[:type]&.to_s] || default_identifier_class
      end

      def cast(key, value)
        case key
        # `:type` is consumed only by select_class for dispatch; it is not an
        # identifier attribute (the concrete class is pinned by `_type`). Drop it
        # so the raw Parslet::Slice never lands in the inherited :type attribute.
        when :type then nil
        # `:chapter` is a PARSE-TREE key and keeps its name in the grammar; the
        # ATTRIBUTE it feeds is `number` (see handle_key below), so it casts
        # like a number rather than like a plain string.
        when :number, :chapter then Components::Code.new(value: value.to_s)
        when :reaffirmation
          value.is_a?(Hash) ? (value[:year] || value).to_s : value.to_s
        when :part, :section, :subsection, :year
          value.to_s
        else
          super
        end
      end

      # Route the MPMS chapter into the `number` attribute. The shared
      # assign_attributes loop uses the parse-tree key as the setter name and
      # silently skips a key that is not an attribute, so without this the
      # chapter would simply vanish once `attribute :chapter` was removed.
      def handle_key(identifier, key, value)
        return super unless key.to_sym == :chapter

        identifier.number = value
        true
      end
    end
  end
end
