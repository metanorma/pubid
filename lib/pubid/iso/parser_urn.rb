module Pubid
  module Iso
    module ParserUrn
      LANGUAGES = %w[en fr ru other].freeze
      SUPPLEMENTS = %w[amd cor sup].freeze

      def self.included(base) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        base.class_eval do # rubocop:disable Metrics/BlockLength
          rule(:colon) { str(":") }

          rule(:urn_organization) do
            array_to_str(Parser::ORGANIZATIONS.map(&:downcase))
          end

          rule(:urn_publisher_copublisher) do
            urn_organization.as(:publisher) >> (dash >> urn_organization.as(:copublisher)).repeat >> colon
          end

          rule(:urn_type) do
            (array_to_str(Parser::TYPES.map(&:downcase)).as(:type) >> colon).maybe
          end

          rule(:urn_part) { (colon >> part).maybe }

          rule(:urn_iteration) do
            (str(".v") >> digits.as(:iteration)).maybe
          end

          rule(:urn_stage) do
            (colon >> str("stage-draft").as(:stage) >> urn_iteration).maybe
          end

          rule(:urn_edition) do
            (colon >> (str("ed-") >> digits.as(:edition))).maybe
          end

          rule(:urn_typed_stage) do
            (colon >> str("stage-draft").as(:typed_stage)).maybe
          end

          rule(:urn_supplement) do
            (urn_typed_stage >>
              colon >> (array_to_str(SUPPLEMENTS).as(:type) >>
              (colon >> year_digits.as(:year)).maybe >>
              (colon >> ((digits.as(:number) >> str(":v1")) | str("v") >> digits.as(:number))).maybe)
            ).repeat(1).as(:supplements).maybe
          end

          rule(:urn_extract) do
            (colon >> str("ext") >> colon >> year_digits.as(:year) >>
              (colon >> str("v") >> digits.as(:number))).as(:extract).maybe
          end

          rule(:languages) do
            array_to_str(LANGUAGES)
          end

          rule(:urn_language) do
            (colon >> (languages >> (str(",") >> languages).repeat).as(:language)).maybe
          end

          rule(:urn_identifier) do
            str("urn:iso:std:") >> urn_publisher_copublisher >> urn_type >>
              digits.as(:number) >> urn_part >> urn_stage >> urn_edition >>
              urn_supplement >> urn_extract >> urn_language
          end
        end
      end
    end
  end
end
