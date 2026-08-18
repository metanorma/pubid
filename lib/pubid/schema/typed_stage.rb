# frozen_string_literal: true

module Pubid
  module Schema
    # One typed stage entry of an identifier type declaration.
    class TypedStage
      attr_reader :stage_code, :type_code, :abbr, :name, :harmonized_stages

      def initialize(stage_code:, type_code: nil, abbr: [], name: nil,
                     harmonized_stages: [])
        @stage_code = stage_code
        @type_code = type_code
        @abbr = abbr.freeze
        @name = name
        @harmonized_stages = harmonized_stages.freeze
        freeze
      end

      def matches_abbr?(candidate)
        abbr.include?(candidate)
      end
    end
  end
end
