# frozen_string_literal: true

module Pubid
  module Amca
    module Identifiers
      # Standard identifier for ACMA standards
      # Examples:
      # - ANSI/AMCA 210-16
      # - ANSI/AMCA Standard 99-25
      # - AMCA Standard 803-02 (R2008)
      class Standard < Identifier
        attribute :number, :string

        def self.type
          { key: :standard, title: "Standard", short: nil }
        end
      end
    end
  end
end
