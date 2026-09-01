# frozen_string_literal: true

module Pubid
  module Oiml
    class SupplementIdentifier < Identifier
      # Base class for OIML supplements (amendments, annexes)
      # These wrap a base identifier like ISO amendments
      attribute :base, Oiml::Identifier, polymorphic: true
      attribute :year, :string
      attribute :language, :string

      # Delegate the document code to the wrapped standard, mirroring
      # Pubid::Etsi::Identifiers::SupplementIdentifier#code.
      #
      # PRE-EXISTING BUG this closes: `UrnGenerator#urn_number` calls
      # `identifier.code` for every non-Bulletin type, but a supplement
      # descends from Oiml::Identifier directly — it is a SIBLING of
      # SingleIdentifier, which is where `code` used to live — so it inherited
      # no `code` at all and `to_urn` raised NoMethodError for every Amendment,
      # Errata and Annex. Verified against a baseline captured on main: all
      # five supplement fixtures already raised there, so this is a fix, not a
      # regression introduced by the move to split index columns.
      #
      # It stayed hidden because spec/pubid/oiml/urn_spec.rb only exercises a
      # bare Recommendation and spec/pubid/oiml/fixtures_spec.rb globs a bad
      # path and runs 0 examples (hand-off: ten-dead-fixture-specs).
      # `iteration` is the same story: declared on SingleIdentifier, read
      # unconditionally by UrnGenerator#urn_iteration, absent from the
      # supplement branch of the hierarchy. (`stage` escapes because
      # ::Pubid::Identifier declares one, so it merely returns nil.)
      def code
        base&.code
      end

      def iteration
        base&.iteration
      end
      # True for the trailing-word shorthand ("OIML R 138:2009 Amendment"),
      # where the supplement word is appended after a dated base instead of the
      # "Amendment (YYYY) to BASE" prose form. The word itself comes from the
      # concrete class (#supplement_type), so only this flag is stored.
      attribute :trailing, :boolean, default: false
      # True for the plus-joined form ("OIML B 10:2011+Amendment:2012") where
      # both the base and the supplement carry their own year, joined by "+".
      attribute :joined, :boolean, default: false
      attribute :parsed_format, :string, default: -> {
        "short"
      } # Track supplement's parsed format

      # Serialization delta on top of Oiml::Identifier's shared block. The
      # nested base is (de)serialized recursively through the
      # polymorphic router so its own `_type` selects the right subclass.
      key_value do
        map "base",
            with: { to: :base_to_kv, from: :base_from_kv }
        map "year", to: :year
        map "trailing", to: :trailing
        map "joined", to: :joined
      end

      def base_to_kv(model, doc)
        base = model.base
        return unless base

        doc.add_child(
          Lutaml::KeyValue::DataModel::Element.new("base",
                                                   base.to_hash),
        )
      end

      def base_from_kv(model, value)
        model.base = ::Pubid::Oiml::Identifier.from_hash(value) if value
      end

      attr_reader :requested_format

      def to_s(format: nil, **opts)
        @requested_format = format
        render(format: :human, **opts)
      end

      # Subclasses override this
      def supplement_type
        raise NotImplementedError, "Subclasses must implement supplement_type"
      end
    end
  end
end
