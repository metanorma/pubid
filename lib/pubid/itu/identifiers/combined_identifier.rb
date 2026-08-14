# frozen_string_literal: true

module Pubid
  module Itu
    module Identifiers
      # Combined (joint) recommendation — a single document published under two
      # or more series/number designations at once.
      # Format: ITU-T G.780/Y.1351         (dual)
      #         ITU-T G.780/Y.1351/Z.1362  (triple)
      #
      # The primary designation lives on the base `series`/`code`; every
      # additional designation is a Components::Designation in `combined`
      # (one for a dual form, two+ for triple).
      class CombinedIdentifier < Identifier
        include StandardSerialization

        attribute :combined, Pubid::Itu::Components::Designation,
                  collection: true, default: -> { [] }

        # Extra map merged on top of StandardSerialization: the additional
        # designations as a flat list of { series, number, subseries?, parts? }.
        key_value do
          map "combined",
              with: { to: :combined_to_kv, from: :combined_from_kv }
        end

        def combined_to_kv(model, doc)
          designations = model.combined
          return if designations.nil? || designations.empty?

          rows = designations.map do |d|
            row = { "series" => d.series&.series.to_s,
                    "number" => d.code&.number.to_s }
            row["subseries"] = d.code.subseries.to_s if d.code&.subseries
            row["parts"] = d.code.parts.map(&:to_s) if d.code&.parts&.any?
            # Each emitted only when set, so an ordinary joint designation's
            # row keeps its existing two-key shape.
            if d.code&.series_suffix
              row["series_suffix"] = d.code.series_suffix.to_s
              row["series_suffix_spaced"] = true if d.code.series_suffix_spaced
            end
            if d.code&.qualifier
              row["qualifier"] = d.code.qualifier.to_s
              row["qualifier_glued"] = true if d.code.qualifier_glued
            end
            row
          end

          doc.add_child(
            Lutaml::KeyValue::DataModel::Element.new("combined", rows),
          )
        end

        def combined_from_kv(model, value)
          model.combined = Array(value).map do |row|
            row = row.transform_keys(&:to_s)
            Components::Designation.new(
              series: Components::Series.new(series: row["series"].to_s),
              code: Components::Code.new(
                number: row["number"].to_s,
                series_suffix: row["series_suffix"]&.to_s,
                series_suffix_spaced: !!row["series_suffix_spaced"],
                subseries: row["subseries"]&.to_s,
                parts: Array(row["parts"]).map(&:to_s),
                qualifier: row["qualifier"]&.to_s,
                qualifier_glued: !!row["qualifier_glued"],
              ),
            )
          end
        end

        # Rendering hooks into `render_base` (not `to_s`) so that any wrapper
        # composing this identifier — AnnexOfRecommendation, which renders
        # "<base.render_base> Annex <label>" — keeps the co-designations.
        # Overriding `to_s` instead silently dropped the "/Y.1351" half.
        # The inherited `to_s` adds the language suffix and common-text twin.
        def render_base(**_opts)
          result = "#{publisher}-#{sector}"

          # Add primary series and code
          result += if series
                      " #{series}#{series_dash ? '-' : '.'}#{code}"
                    else
                      " #{code}"
                    end

          result += "-#{range_end}" if range_end

          # Add additional designations
          if combined&.any?
            result += "/#{combined.join('/')}"
          end

          result += " series" if series_word
          result += " attachment" if attachment

          # Add version marker if present — always between code and date
          result += " (V#{version})" if version

          result + render_date_suffix
        end

        def ==(other)
          return false unless other.is_a?(CombinedIdentifier)

          sector == other.sector &&
            series == other.series &&
            code == other.code &&
            combined == other.combined &&
            date == other.date &&
            version == other.version &&
            series_word == other.series_word &&
            series_dash == other.series_dash &&
            attachment == other.attachment &&
            range_end == other.range_end &&
            language == other.language
        end
      end
    end
  end
end
