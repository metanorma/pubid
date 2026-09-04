# frozen_string_literal: true

module Pubid
  module Bsi
    module Identifiers
      # BSI Handbook
      # Examples: "Handbook 17:1963", "HB 10146:1998"
      class Handbook < SingleIdentifier
        attribute :date, Bsi::Components::Date
        attribute :original_abbr, :string # Preserve "Handbook" or "HB"

        def self.type
          {
            short: "HB",
            full: "Handbook",
            names: ["Handbook", "HB"],
          }
        end

      end
    end
  end
end
