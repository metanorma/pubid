# frozen_string_literal: true

module Pubid
  module Nist
    module Series
      # IR (Interagency Report) series carries the most series-specific logic:
      #
      # - "R" or "Ur" letter suffix becomes revision "r1" (e.g., "79-1786R").
      # - part_num alongside second_num becomes a Part component (type "pt").
      # - Preprocessing converts "84-2946" → "84e2946"; this class reverses
      #   that side effect so IR keeps the compound number form.
      class Ir < LetterPreserving
        def self.cast_letter_number(value, _parsed_hash)
          full = combine_letter_suffix(value)
          return nil if full.nil? || full.empty?

          if ["R", "Ur"].include?(full)
            value[:letter_suffix] = full
            value
          else
            super
          end
        end

        def self.part_num_as_component?
          true
        end

        def self.handle_letter_num_compound?(identifier,
                                             first_num:, letter_base:,
                                             letter_suffix:)
          return false unless letter_suffix == "R"

          identifier.number = Components::Code.new(
            value: "#{first_num.value}-#{letter_base}",
          )
          edition_obj = Components::Edition.new(type: "r", id: "1")
          identifier.edition = edition_obj
          true
        end

        def self.finalize_identifier(identifier, _parsed_hash)
          return unless identifier.number

          value = identifier.number.value.to_s
          match = value.match(/^(\d+)e(\d{4})$/)
          return unless match

          identifier.number = Components::Code.new(
            value: "#{match[1]}-#{match[2]}",
          )
          identifier.edition = nil
        end
      end
    end
  end
end
