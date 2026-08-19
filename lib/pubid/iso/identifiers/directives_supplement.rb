# frozen_string_literal: true

module Pubid
  module Iso
    module Identifiers
      class DirectivesSupplement < SupplementIdentifier
        attribute :supplement_publisher, ::Pubid::Components::Publisher

        # supplement_publisher (e.g. "IEC" in "ISO/IEC DIR 1 IEC SUP") is needed
        # by to_s/to_urn; serialize its body under "publisher" (the supplement's
        # own publisher; the base's publisher lives in the nested base). This
        # overrides the inherited publisher map, whose delegated value is nil or
        # the omitted ISO default here.
        key_value do
          map "publisher",
              with: { to: :supplement_publisher_to_kv, from: :supplement_publisher_from_kv }
        end

        def supplement_publisher_to_kv(model, doc)
          body = model.supplement_publisher&.body
          return if body.nil? || body.to_s.empty?

          doc.add_child(
            Lutaml::KeyValue::DataModel::Element.new("publisher", body.to_s),
          )
        end

        def supplement_publisher_from_kv(model, value)
          model.supplement_publisher = ::Pubid::Components::Publisher.new(body: value.to_s)
        end

        # copublishers here is the base's (delegated), redundant with the nested
        # base; don't duplicate it at the supplement level.
        def copublishers_to_kv(_model, _doc); end

        # Delegate base identifier attributes for easier access
        def copublishers
          base&.copublishers
        end

        def publisher
          base&.publisher
        end

        TYPED_STAGES = [
          ::Pubid::Components::TypedStage.new(
            code: :pubdirsup,
            stage_code: :published,
            type_code: :"dir-sup",
            abbr: ["DIR SUP", "SUP", "Supplement"],
            name: "Directives Supplement",
            harmonized_stages: %w[60.00 60.60],
          ),
        ].freeze

        def self.type
          { key: :"dir-sup",
            web: :directives_supplement, title: "Directives Supplement", short: "SUP" }
        end

        # def render_directives_supplement_identifier(identifier)
        #   raise "Not a directives supplement identifier" unless identifier.is_a?(Identifiers::DirectivesSupplement)

        #   render(identifier.base) +
        #     " #{identifier.publisher.body}" +
        #     " #{identifier.stage.abbr}" +
        #     (identifier.date ? ":#{identifier.date.year}" : "")
        # end

        def to_s(lang: :en, lang_single: false, with_edition: false,
format: nil, stage_format_long: nil, with_date: nil)
          if base
            # Full rendering with base identifier
            [
              base.to_s(lang: lang, lang_single: lang_single,
                                   with_edition: with_edition, format: format, stage_format_long: stage_format_long, with_date: with_date),
              " #{supplement_publisher.render}",
              " SUP", # Always render as "SUP" even though typed_stage.abbreviation is "DIR SUP"
              (date ? ":#{date.render}" : ""),
              (edition ? " Edition #{edition.value}" : ""),
            ].join
          else
            # Simplified rendering for bundled identifiers (just the supplement part)
            to_supplement_s(lang: lang, lang_single: lang_single)
          end
        end

        # Render just the supplement part (for use in bundled identifiers)
        def to_supplement_s(lang: :en, lang_single: false, with_edition: false,
format: nil, stage_format_long: nil, with_date: nil)
          date_str = if date
                       ":#{date.render}"
                     else
                       ""
                     end

          [
            supplement_publisher.render,
            " SUP",
            date_str,
          ].join
        end

        # DirectivesSupplement use urn:iso:doc scheme (not urn:iso:std)
        # Format: urn:iso:doc:{base_urn_parts}:jtc:X:sup[:{year}][:{edition}]
        def to_urn
          urn_ctx = Rendering::RenderingContext.urn

          # If this is a standalone supplement (no base), build URN directly
          unless base
            parts = ["urn", "iso", "doc"]
            parts << supplement_publisher.render(context: urn_ctx) if supplement_publisher
            parts << "sup"
            parts << date.render(context: urn_ctx) if date
            parts << edition.render(context: urn_ctx) if edition&.number
            return parts.join(":")
          end

          # Start with base identifier's URN parts (it will use urn:iso:doc scheme)
          base_urn = base.to_urn

          # Handle JTC pattern specially
          if supplement_publisher&.body&.match?(/^JTC\s+(\d+)$/i)
            # Extract JTC number: "JTC 1" -> ["jtc", "1"]
            jtc_parts = supplement_publisher.render(context: urn_ctx).split
            # Insert JTC parts before "sup"
            parts = base_urn.split(":")
            parts.concat(jtc_parts) # Add "jtc" and "1"
            parts << "sup"
          else
            # Normal supplement
            parts = [base_urn, "sup"]
            parts << supplement_publisher.render(context: urn_ctx) if supplement_publisher
          end

          # Year (if present)
          parts << date.render(context: urn_ctx) if date

          # Edition (if present)
          parts << edition.render(context: urn_ctx) if edition&.number

          parts.join(":")
        end
      end
    end
  end
end
