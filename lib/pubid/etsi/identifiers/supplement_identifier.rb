# frozen_string_literal: true

module Pubid
  module Etsi
    module Identifiers
      # Identifier class for ETSI supplements (Amendment, Corrigendum)
      class SupplementIdentifier < Identifier
        attribute :base, Pubid::Etsi::Identifier
        attribute :number, :integer

        # Compact serialization: a supplement carries only its own ordinal
        # `number` (A1 -> 1) and the nested base standard under the compact key
        # `base`. type/code/version/date are delegated to `base` (methods below)
        # and NOT re-emitted here, so the old redundant duplication is gone.
        # This block is inherited unchanged by Amendment/Corrigendum.
        key_value do
          map "_type",  to: :_type
          map "number", to: :number
          map "base",   with: { to: :base_to_kv, from: :base_from_kv }
        end

        # Serialize the base via its own to_hash so it collapses to the compact
        # EtsiStandard shape.
        def base_to_kv(model, doc)
          return unless model.base

          doc.add_child(
            Lutaml::KeyValue::DataModel::Element.new(
              "base", model.base.to_hash
            ),
          )
        end

        # Re-dispatch through the flavor base so `_type` resolves to the
        # concrete EtsiStandard; a bare polymorphic cast would rebuild a plain
        # Identifier and lose the subclass (and its custom mappings). Mirrors JCGM.
        def base_from_kv(model, value)
          return unless value

          model.base = Pubid::Etsi::Identifier.from_hash(value)
        end

        # Inherit attributes from base
        def type
          base.type
        end

        def code
          base.code
        end

        def version
          base.version
        end

        def date
          base.date
        end

        # Render via renderer

        # Recursively collect supplement notations from the supplement chain
        def collect_supplement_notations(current_supplement, notations)
          if current_supplement.is_a?(SupplementIdentifier)
            # Add this supplement's notation at the beginning (because supplements wrap from outside in)
            notations.unshift("/#{current_supplement.supplement_notation}")
            # Continue collecting from the base if it's also a supplement
            if current_supplement.base.is_a?(SupplementIdentifier)
              collect_supplement_notations(current_supplement.base, notations)
            else
              notations
            end
          else
            notations
          end
        end

        # Find the actual base ETSI standard (not supplements)
        def find_actual_base(current_base)
          if current_base.is_a?(SupplementIdentifier)
            find_actual_base(current_base.base)
          else
            current_base
          end
        end

        def supplement_notation
          raise NotImplementedError
        end

        # Make Renderers::MrString recurse into `base` instead of slugging the
        # supplement flat. Without this the flat path reads the supplement's own
        # `number` — its ordinal, 1 — and the base document is dropped entirely,
        # so every "/C1" corrigendum published in one month shared the slug
        # `etsi.1.<date>`. `to_slug` is an output FILENAME, so that is an
        # overwrite. Same fix as ITU's AnnexOfRecommendation (see CLAUDE.md).
        def mr_supplement_suffix
          [supplement_notation.to_s.downcase, number].compact.join(".")
        end

        def ==(other)
          return false unless other.is_a?(SupplementIdentifier)
          return false unless other.class == self.class

          base == other.base && number == other.number
        end

        # Include supplement notation in serialization
        def base_hash
          hash = super
          # ETSI supplements need the type (e.g., "ETS", "TR") from the base document
          if base.class.attributes.key?(:type) && base.type
            hash[:type] =
              base.type
          end
          hash[:supplement_notation] = supplement_notation
          hash[:supplement_type] = self.class.name.split("::").last.downcase
          hash
        end
      end
    end
  end
end
