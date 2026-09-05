# frozen_string_literal: true

module Pubid
  module Oasis
    # Turns the parse tree into an `Identifiers::Standard`: stores the slug
    # verbatim in `original`, then performs a best-effort, ORDER-INDEPENDENT
    # decomposition into number / version / stage / part / label.
    #
    # Decomposition splits `original` on "-" and classifies each *whole*
    # fragment (so a stage-like substring inside a spec name — e.g. "CSDL" — is
    # never mistaken for a stage). `number` is the specification name: the run
    # of leading name fragments before the first recognized fragment, and the
    # key relaton-index sorts and binary-searches on. `version`/`stage`/`part`
    # are the first fragment of each recognized kind; `label` is any name
    # fragment appearing after the first recognized one. Anything the
    # classifier cannot place stays only in `original`, so the printed form
    # always round-trips.
    class Builder
      # A fragment is a version when it is `v?N(.N)+` (e.g. "3.0", "v1.2.1",
      # "V1.0"). Bare integers are deliberately NOT versions (too ambiguous
      # with spec-name tokens).
      VERSION_RE = /\Av?\d+(?:\.\d+)+\z/i
      # OASIS approval-stage tokens (+ optional revision digits). Longest-first
      # so shared prefixes classify correctly (CSPRD/CSD before CS, COS before
      # CS/OS).
      STAGE_RE = /\A(?:CSPRD|CSD|COS|CS|WD|OS|PS|PRD|CD|Errata)\d*\z/
      # Part tokens across the three observed spellings, plus bare "Pt"/"P".
      PART_RE = /\A(?:Part|Pt|part|P)\d*\z/

      def self.build(parsed_data)
        new.build(parsed_data)
      end

      def build(data)
        original = data[:original].to_s
        Identifiers::Standard.new(original: original, **decompose(original))
      end

      private

      # @return [Hash] best-effort { number:, version:, stage:, part:, label: }.
      # Each fragment is classified once into a [fragment, kind] pair. `number`
      # is the leading run of name fragments; `label` is any name fragment after
      # the first recognized one; version/stage/part are the first of each kind.
      def decompose(original)
        pairs = original.split("-").map { |f| [f, classify(f)] }
        lead = pairs.take_while { |_, kind| kind.nil? }
        rest = pairs.drop(lead.length)
        {
          number: names(lead),
          version: first_of(rest, :version),
          stage: first_of(rest, :stage),
          part: first_of(rest, :part),
          label: names(rest),
        }
      end

      # @return [Symbol, nil] :version / :stage / :part, or nil for a name token
      def classify(fragment)
        return :version if fragment.match?(VERSION_RE)
        return :stage if fragment.match?(STAGE_RE)
        return :part if fragment.match?(PART_RE)

        nil
      end

      # First fragment of the given kind among [fragment, kind] pairs, or nil.
      def first_of(pairs, kind)
        pairs.find { |_, k| k == kind }&.first
      end

      # Name (unclassified) fragments among the pairs, re-joined, or nil.
      def names(pairs)
        fragments = pairs.select { |_, kind| kind.nil? }.map(&:first)
        fragments.empty? ? nil : fragments.join("-")
      end
    end
  end
end
