# frozen_string_literal: true

module Pubid
  module W3c
    # Turns the parse tree into a concrete identifier: picks the class from the
    # leading maturity token and splits the captured remainder into slug + date.
    class Builder
      # Maturity token -> concrete identifier class name (resolved lazily so the
      # Identifiers namespace need not be loaded at class-definition time).
      TYPE_CLASSES = {
        "NOTE" => "Note",
        "DNOTE" => "DraftNote",
        "WD" => "WorkingDraft",
        "CR" => "CandidateRecommendation",
        "CRD" => "CandidateRecommendationDraft",
        "REC" => "Recommendation",
        "PR" => "ProposedRecommendation",
        "PER" => "ProposedEditedRecommendation",
        "SPSD" => "SupersededRecommendation",
        "OBSL" => "ObsoleteRecommendation",
      }.freeze

      # A trailing "-<digits>" group is the date only when the digit run is
      # exactly 8 (YYYYMMDD), 6 (legacy YYMMDD) or 4 (legacy MMDD) wide. No real
      # W3C slug ends in such a run, so this never mis-splits a slug that merely
      # ends in a short digit run (e.g. "url-1", "ATAG10").
      DATE_RE = /\A(.+)-(\d{8}|\d{6}|\d{4})\z/

      def self.build(parsed_data)
        new.build(parsed_data)
      end

      def build(data)
        number, date = split_date(data[:rest].to_s)
        klass_for(data[:type]&.to_s).new(number: number, date: date)
      end

      private

      def klass_for(type)
        name = TYPE_CLASSES[type] || "Standard"
        Identifiers.const_get(name)
      end

      # @return [Array(String, String|nil)] the slug and the optional date
      def split_date(rest)
        if (m = DATE_RE.match(rest))
          [m[1], m[2]]
        else
          [rest, nil]
        end
      end
    end
  end
end
