# frozen_string_literal: true

module Pubid
  module Bsi
    module Identifiers
      # BSI Practice Guide (PP - Published Practice)
      # Examples: "PP 888:1982", "PP 7307:1986", "PP 7722:2006"
      class PracticeGuide < SingleIdentifier
        attribute :date, Bsi::Components::Date

        def self.type
          {
            short: "PP",
            full: "Published Practice",
          }
        end

      end
    end
  end
end
