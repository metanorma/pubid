# frozen_string_literal: true

module Pubid
  module Bsi
    module Identifiers
      # British Industrial Practice (BIP)
      # Examples: "BIP 2225:2022", "BIP 0142:2014", "BIP 0009:2020"
      class BritishIndustrialPractice < SingleIdentifier
        attribute :date, Bsi::Components::Date

        def self.type
          {
            short: "BIP",
            full: "British Industrial Practice",
          }
        end

      end
    end
  end
end
