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
        when :number then value.to_s
        when :reaffirmation
          value.is_a?(Hash) ? (value[:year] || value).to_s : value.to_s
        when :part, :chapter, :section, :subsection, :year
          value.to_s
        else
          super
        end
      end
    end
  end
end
