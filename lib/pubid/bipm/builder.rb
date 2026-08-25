# frozen_string_literal: true

module Pubid
  module Bipm
    # Turns the parse tree into the matching concrete identifier. Each root
    # branch tags its subtree with a distinct key, so dispatch is a lookup on
    # which key the parser produced.
    class Builder
      def self.build(parsed_data)
        new.build(parsed_data)
      end

      def build(data)
        if data[:committee_short]
          build_committee(data[:committee_short], form: "short")
        elsif data[:committee_long_en]
          build_committee(data[:committee_long_en], form: "long", language: "E")
        elsif data[:committee_bare]
          # Bare MRA form: no type word, so build_committee yields nil type.
          build_committee(data[:committee_bare], form: "short")
        elsif data[:committee_long_fr]
          build_committee(data[:committee_long_fr], form: "long", language: "F")
        elsif data[:meeting_en]
          build_meeting(data[:meeting_en])
        elsif data[:meeting_fr]
          build_meeting(data[:meeting_fr], language: "F")
        elsif data.key?(:metrologia)
          build_metrologia(data[:metrologia])
        elsif data[:si_brochure]
          build_si_brochure(data[:si_brochure])
        elsif data[:si_brochure_variant]
          build_si_brochure_variant(data[:si_brochure_variant])
        elsif data.key?(:si_brochure_section)
          build_si_brochure_section(data[:si_brochure_section])
        elsif data[:mep]
          build_mep(data[:mep])
        elsif data[:guide]
          build_guide(data[:guide])
        else
          raise "Unrecognized BIPM parse tree: #{data.inspect}"
        end
      end

      private

      # `group` and `language` are normalized here, so a historic committee
      # name (CCDS) and a two-letter language code (EN/FR) never reach an
      # attribute — the index stores only the current name and the one-letter
      # code BIPM prints.
      def build_committee(node, form:, language: nil)
        Identifiers::CommitteeDocument.new(
          group: Identifier.normalize_group(node[:group]),
          type_code: Identifier::TYPE_WORD_TO_CODE[node[:type_word].to_s],
          number: node[:number]&.to_s,
          year: node[:year]&.to_s&.to_i,
          language: Identifier.normalize_language(language || node[:language]),
          form: form,
        )
      end

      def build_meeting(node, language: nil)
        Identifiers::Meeting.new(
          group: Identifier.normalize_group(node[:group]),
          number: node[:number].to_s,
          year: node[:year]&.to_s&.to_i,
          language: Identifier.normalize_language(language || node[:language]),
        )
      end

      # `number` is the volume, so every article of a volume clusters into one
      # relaton-index bucket (the IETF draft-slug / IANA registry-slug
      # convention). It is nil only for the journal-level record, which carries
      # no volume at all.
      #
      # It is deliberately redundant with `volume`, which stays because the
      # renderer and the URN generator read it. Two limits of that redundancy,
      # both accepted rather than engineered around (see the note above
      # NUMBER_SOURCE_ATTRIBUTES in identifier.rb for the half that IS
      # handled):
      #
      #   * THE BUILDER IS THE CONSTRUCTOR OF RECORD. A caller that bypasses it
      #     — `MetrologiaArticle.new(volume: 51, …)` — gets a nil `number` and
      #     so an empty index key. Deriving it in `initialize` instead would
      #     cover that, but `#exclude` rebuilds through `self.class.new`, so it
      #     would also silently re-fill a `number` the caller just excluded.
      #   * NO SELF-HEALING ACROSS from_hash. lutaml assigns attributes AFTER
      #     `initialize`, so a legacy pre-`number` index row (one carrying only
      #     `volume`) deserializes with `number` nil and no error at all —
      #     lutaml ignores unknown keys and relaton's `id_supported?` skips its
      #     round-trip check for concrete subclasses, which every BIPM id is.
      #     relaton-data-bipm must regenerate index-v2 to gain the key. This is
      #     weaker than the IEEE `CodeNumber` mixin, which rebuilds `code_obj`
      #     from its split columns after `from_hash`.
      def build_metrologia(node)
        node = {} unless node.is_a?(Hash)
        Identifiers::MetrologiaArticle.new(
          number: node[:volume]&.to_s,
          issue: node[:issue]&.to_s,
          article: node[:article]&.to_s,
        )
      end

      # The SI Brochure has no document number of its own, so the edition is
      # the index key — it clusters the English and French records of one
      # edition. The grammar makes `edition` mandatory here, so it is never nil.
      def build_si_brochure(node)
        Identifiers::SiBrochure.new(
          number: node[:edition].to_s,
          edition: node[:edition].to_s,
          version: node[:version].to_s,
          years: node[:years].to_s,
          language: Identifier.normalize_language(node[:language]),
        )
      end

      # The derived products (Appendix N, Concise, FAQ) carry no edition, so
      # the variant name is their key. The grammar makes it mandatory here.
      def build_si_brochure_variant(node)
        variant = node[:variant].to_s
        Identifiers::SiBrochure.new(number: variant, variant: variant)
      end

      # A bare or sectioned reference names no edition, so it gets no key: it is
      # a partial reference that wildcards every edition. The bare form captures
      # nothing, so the parser hands back a slice rather than a hash.
      def build_si_brochure_section(node)
        node = {} unless node.is_a?(Hash)
        Identifiers::SiBrochure.new(part: node[:part]&.to_s)
      end

      # The Appendix/Annex/Part tail is the full-content spelling of the SAME
      # document, so it stays out of the key.
      def build_mep(node)
        Identifiers::Mep.new(
          **mep_codes(node),
          appendix: node[:appendix]&.to_s,
          annex: node[:annex]&.to_s,
          part: node[:part]&.to_s,
        )
      end

      # A MEP is identified by its unit code, or by the report code for the
      # `Rapport BIPM-YYYY/NN` variant; exactly one of the two is set, and
      # whichever it is becomes the relaton index key.
      def mep_codes(node)
        mep_code = node[:mep_code]&.to_s
        report_code = node[:report_code]&.to_s
        { number: mep_code || report_code, mep_code: mep_code,
          report_code: report_code }
      end

      def build_guide(node)
        Identifiers::Guide.new(
          group: Identifier.normalize_group(node[:group]),
          guide_kind: node[:guide_kind].to_s,
          number: node[:number].to_s,
          appendix: node[:appendix]&.to_s,
          part: node[:part]&.to_s,
        )
      end
    end
  end
end
