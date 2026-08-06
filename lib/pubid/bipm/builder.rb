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
        else
          raise "Unrecognized BIPM parse tree: #{data.inspect}"
        end
      end

      private

      def build_committee(node, form:, language: nil)
        Identifiers::CommitteeDocument.new(
          group: node[:group].to_s,
          type_code: Identifier::TYPE_WORD_TO_CODE[node[:type_word].to_s],
          number: node[:number]&.to_s,
          year: node[:year]&.to_s&.to_i,
          language: language || node[:language]&.to_s,
          form: form,
        )
      end

      def build_meeting(node, language: nil)
        Identifiers::Meeting.new(
          group: node[:group].to_s,
          number: node[:number].to_s,
          year: node[:year]&.to_s&.to_i,
          language: language || node[:language]&.to_s,
        )
      end

      def build_metrologia(node)
        node = {} unless node.is_a?(Hash)
        Identifiers::MetrologiaArticle.new(
          volume: node[:volume]&.to_s&.to_i,
          issue: node[:issue]&.to_s,
          article: node[:article]&.to_s,
        )
      end

      def build_si_brochure(node)
        Identifiers::SiBrochure.new(
          edition: node[:edition].to_s,
          version: node[:version].to_s,
          years: node[:years].to_s,
          language: node[:language]&.to_s,
        )
      end
    end
  end
end
