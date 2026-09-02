# frozen_string_literal: true

module Pubid
  module Schema
    # One identifier type declaration (e.g. iso "amendment", iec "vap").
    class IdentifierType
      attr_reader :key, :title, :short, :abbr, :typed_stages

      def initialize(key:, title:, short: nil, abbr: [], typed_stages: [])
        @key = key
        @title = title
        @short = short
        @abbr = abbr.freeze
        @typed_stages = typed_stages.map(&:freeze).freeze
        freeze
      end

      def typed_stage_for_abbr(candidate)
        typed_stages.find { |stage| stage.matches_abbr?(candidate) }
      end
    end
  end
end
