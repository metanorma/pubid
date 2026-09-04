# frozen_string_literal: true

module Pubid
  module Jcgm
    module Identifiers
      # A JCGM committee/meeting record, e.g. "JCGM 17th Meeting (2012)".
      #
      # `number` (Components::Code) holds the meeting ordinal as a clean integer
      # value ("17"); `date` (Components::Date, year-only) holds the year.
      class Meeting < SingleIdentifier
        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :pubmeeting,
            stage_code: :published,
            type_code: :jcgm_meeting,
            abbr: ["Meeting"],
            name: "Meeting",
            harmonized_stages: %w[60.00 60.60],
          ),
        ].freeze

        def self.type
          { key: :jcgm_meeting, title: "Meeting" }
        end

        # Ordinal suffix as printed by the JCGM/BIPM data generator: a naive
        # last-digit rule (1->st, 2->nd, 3->rd, else th) with NO 11/12/13 teens
        # exception. The real records print "11st", "12nd", "13rd", so applying
        # the standard-English teens exception would break round-trip.
        def self.ordinal(number)
          n = number.to_i
          suffix = case n % 10
                   when 1 then "st"
                   when 2 then "nd"
                   when 3 then "rd"
                   else "th"
                   end
          "#{n}#{suffix}"
        end

        def ordinal
          self.class.ordinal(number)
        end
      end
    end
  end
end
