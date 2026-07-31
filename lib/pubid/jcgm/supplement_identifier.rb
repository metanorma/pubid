# frozen_string_literal: true

module Pubid
  module Jcgm
    # Base class for JCGM supplement identifiers (amendments, corrigenda, etc.)
    #
    # The supplement's OWN number (the "1" in "/Cor 1", the "2" in "/Amd 2")
    # is stored in the inherited `number` attribute — NOT a separate
    # `iteration` attribute. Each supplement is itself a numbered document,
    # just like the base. The base document's number is accessed via
    # `base.number`. This mirrors how pubid-Iso models supplements.
    class SupplementIdentifier < SingleIdentifier
      attribute :base, Identifier, polymorphic: true

      # The base document nests under the compact key "base" (mirrors ISO/JIS),
      # serialized via its own to_hash so it collapses to {_type, number, year}.
      # On load the sub-hash is re-dispatched through Jcgm::Identifier.from_hash,
      # which resolves `_type` to the concrete Guide/GumGuide — a bare
      # polymorphic cast would rebuild it as a plain Identifier and later fail
      # on publisher_portion. This custom mapping replaces the former
      # self.from_hash override.
      #
      # `number` (the supplement's own number) is mapped by SingleIdentifier's
      # key_value block via number_to_kv / number_from_kv — no override needed.
      key_value do
        map "base", with: { to: :base_to_kv, from: :base_from_kv }
      end

      def base_to_kv(model, doc)
        return unless model.base

        doc.add_child(
          Lutaml::KeyValue::DataModel::Element.new(
            "base", model.base.to_hash
          ),
        )
      end

      def base_from_kv(model, value)
        return unless value

        model.base = ::Pubid::Jcgm::Identifier.from_hash(value)
      end

      # Delegate publisher to base
      def publisher
        base&.publisher
      end
    end
  end
end
