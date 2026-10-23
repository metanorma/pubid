# frozen_string_literal: true

module Pubid
  module Iso
    class SupplementIdentifier < SingleIdentifier
      attribute :base, Identifier,
                polymorphic: true

      # The RFC 5141 <supplversion> (the corrected version of the
      # supplement; published supplements are version 1). Distinct from
      # the amendment/corrigendum <supplnumber>.
      attribute :supplement_version, :string

      key_value do
        # Serialized key is "base" (matches JIS); the attribute/method stays
        # `base`, which relaton-index's get_id_number depends on.
        map "base", to: :base, polymorphic: {
          attribute: "_type",
          class_map: Identifier::ISO_TYPE_MAP,
        }
        map "supplement_version",
            with: { to: :supplement_version_to_kv, from: :supplement_version_from_kv }
      end

      def supplement_version_to_kv(model, doc)
        return unless model.supplement_version

        doc.add_child(
          Lutaml::KeyValue::DataModel::Element.new(
            "supplement_version", model.supplement_version.to_s,
          ),
        )
      end

      def supplement_version_from_kv(model, value)
        return if value.nil? || value.to_s.empty?

        model.supplement_version = value.to_i
      end

      # A supplement carries the publisher/copublishers of the document it
      # supplements. Delegate to the root rather than the immediate base so a
      # nested supplement (e.g. ".../Amd 1/Cor 1") reads identity from the
      # underlying standard in one hop, regardless of chain depth. This keeps a
      # parsed supplement and a from_hash-deserialized one in agreement (== and
      # index matching compare both). Guard on base: `root` returns
      # self when there is no base, which would otherwise recurse forever.
      def publisher
        root.publisher if base
      end

      def copublishers
        root.copublishers if base
      end

      def to_s(**opts)
        context = build_rendering_context(nil, format: :human, **opts)
        Pubid::Renderers::SupplementRenderer.new(self).render(context:,
                                                              **opts.slice(:with_edition))
      end

      # MR supplement suffix: `/{type}.{number}.{year}` (e.g. "/amd.1.2020").
      # The MrString renderer recurses into `base` and appends this so the
      # full supplement chain round-trips losslessly (issue #142).
      def mr_supplement_suffix
        segments = []
        segments << mr_type if mr_type
        segments << number&.to_s if number
        segments << date&.year&.to_s if date&.year
        return nil if segments.empty?

        segments.join(".")
      end
    end
  end
end
