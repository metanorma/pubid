# frozen_string_literal: true

module Pubid
  module Bipm
    module Identifiers
      # A committee meeting (proceedings). Printed with a naive ordinal derived
      # from the first number component's last digit (as the source data
      # generates it: "11st", "12nd", "13rd"), and ranges keep that first
      # component's ordinal ("100-1th").
      #
      # Printed forms (all round-trip):
      #   "CGPM 17th Meeting (1983)"             English      (language nil)
      #   "CCAUV 11st Meeting (2017)"            naive ordinal
      #   "CIPM 100-1th Meeting (2011)"          range
      #   "CCAUV 10<sup>e</sup> réunion (2015)"  French       (language "F")
      class Meeting < Identifier
        def self.type
          { key: :meeting, web: :meeting, title: "Meeting", short: "meeting" }
        end

        # English ordinal suffix from the first number component's last digit.
        # Naive (matches the source data): 1→st, 2→nd, 3→rd, else→th — no
        # 11/12/13 exception, so "11" → "11st", and a range "22-23" → "22-23nd".
        def self.ordinal_suffix(number)
          first = number.to_s.split("-").first.to_s
          case first[-1]
          when "1" then "st"
          when "2" then "nd"
          when "3" then "rd"
          else "th"
          end
        end

        # "15" → "15th", "100-1" → "100-1th".
        def ordinal_en
          "#{number}#{self.class.ordinal_suffix(number)}"
        end

        # MR: `bipm.meeting.<group>-<number>.<year>`. The English and French
        # spellings of one meeting collapse onto the same slug on purpose.
        def mr_type
          "meeting"
        end

        # The group has to be in the number segment or the 17th CGPM and the
        # 17th CIPM meeting would share a slug.
        def mr_number_with_part
          mr_slug(group, number)
        end
      end
    end
  end
end
