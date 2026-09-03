# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Ashrae
    module Identifiers
      # AddendaPackage identifier for ASHRAE addenda collection packages
      # Represents packages that contain multiple addendums
      # Examples:
      # - ASHRAE Standard 52.2-1999: Addenda Supplement Package (Contains Addendum a)
      # - ASHRAE Standard 52.2-2007 Addenda Supplement Package (Contains Addendum b)
      # - ASHRAE Standard 62.2-2004: Addenda Supplement Package (Contains Addendum g) (PDF)
      class AddendaPackage < SupplementIdentifier
        attribute :package_description, :string # e.g., "Addenda Supplement Package"

        # See Errata.
        def mr_supplement_suffix
          ["pkg", mr_sanitize(package_description)]
            .compact.reject(&:empty?).join(".")
        end

        TYPED_STAGES = [
          Components::TypedStage.new(
            abbr: ["Addenda Supplement Package", "Addenda Package"],
            type_code: "addenda_package",
            stage_code: "published",
          ),
        ].freeze

        def self.type
          { key: :addenda_package, title: "ASHRAE Addenda Package",
            short: "Addenda Package" }
        end

        def copublisher
          base&.copublisher
        end
      end
    end
  end
end
