# frozen_string_literal: true

module Pubid
  module Ietf
    # Turns the Parser's parse tree into a concrete identifier object, choosing
    # the class from which fields are present.
    class Builder
      SUBSERIES_CLASSES = {
        "BCP" => "Bcp",
        "STD" => "Std",
        "FYI" => "Fyi",
      }.freeze

      def self.build(parsed_data)
        new.build(parsed_data)
      end

      def build(data)
        if data.key?(:draft_rest)
          build_draft(data)
        elsif data[:series]
          build_subseries(data)
        else
          build_rfc(data)
        end
      end

      private

      def build_rfc(data)
        Identifiers::Rfc.new(number: unpad(data[:number]))
      end

      # The series token only selects the class: it is derived back from the
      # class (Identifiers::Std::SERIES) rather than stored, since `_type`
      # already carries it.
      def build_subseries(data)
        klass = Identifiers.const_get(
          SUBSERIES_CLASSES.fetch(data[:series].to_s),
        )
        klass.new(number: unpad(data[:number]))
      end

      # Strip the zero-padding the RFC editor's rfc-index.xml writes ("STD0066",
      # "RFC0001") so the canonical printed form is the unpadded one. The
      # look-ahead keeps the last digit, so an all-zero number stays "0" rather
      # than becoming empty.
      def unpad(number)
        number.to_s.sub(/\A0+(?=\d)/, "")
      end

      def build_draft(data)
        full = "draft-#{data[:draft_rest]}"
        slug, version = split_draft_version(full)
        Identifiers::InternetDraft.new(number: slug, version: version)
      end

      # An Internet-Draft version is a trailing "-NN" of *exactly* two digits at
      # the very end of the slug. A three-digit topic tail (e.g. "...-256") is
      # NOT a version: there the char before the last two digits is itself a
      # digit, not "-", so the guard below leaves it in the slug. This also
      # means a (non-existent in practice) revision >= 100 would be read as part
      # of the slug — IETF drafts are always two-digit-versioned, so that case
      # never arises. Either way the printed string round-trips exactly.
      #
      # Dotted slugs need no special handling here: only the final three
      # characters are inspected, so "draft-ietf-pilc-2.5g3g-12" splits into
      # ("draft-ietf-pilc-2.5g3g", "12").
      def split_draft_version(full)
        if full.length > 3 && full[-3] == "-" && full[-2..].match?(/\A\d\d\z/)
          [full[0...-3], full[-2..]]
        else
          [full, nil]
        end
      end
    end
  end
end
