# frozen_string_literal: true

module Pubid
  module Csa
    class SingleIdentifier < Identifier
      # The document code — "B149.1", "Z240", "C22.2" — and the relaton index
      # key: Relaton::Index sorts and bsearches every row on
      # `id.root.number.to_s`, so it must never be empty.
      #
      # It is the `number` INHERITED from ::Pubid::Identifier, not a
      # redeclaration: Pubid::Csa::Components::Code is a bare alias of
      # Pubid::Components::Code, which is exactly the parent's declared type.
      # That matters. CSA's base is split across two files (csa/identifier.rb +
      # csa/single_identifier.rb) — the IEEE shape in which a leaf can snapshot
      # a half-built parent attribute table (CLAUDE.md, the `number`
      # determinism landmine). Declaring nothing here keeps CSA clear of it.
      # The attribute was named `code` before; there is no alias.
      attribute :no_number, :string
      attribute :year, :string
      attribute :year_format, :string  # "colon" or "dash"
      attribute :year_prefix, :string  # "F" or "M"
      attribute :original_year_4digit, :boolean, default: -> {
        false
      } # Track if original input was 4-digit (e.g., "M1981" vs "M83")
      attribute :french, :boolean
      attribute :reaffirmation, :string
      attribute :original_reaffirmation_4digit, :boolean, default: -> {
        false
      } # Track if original reaffirmation was 4-digit (e.g., "R2004" vs "R04")
      attribute :has_publisher, :boolean  # Track if CSA prefix present
      attribute :series_prefix, :string   # MH, RV, etc.
      attribute :series, :boolean         # Track if SERIES keyword present
      attribute :package, :string         # Package portion (Code, Handbook, etc.)
      attribute :publisher_prefix, :string # Original prefix: "CAN/CSA-", "CSA", "CAN3-"

      # True when the reference printed no publisher at all ("C22.1-15"), so
      # rendering must not supply the default "CSA".
      #
      # This used to be an empty-string `publisher_prefix` sentinel, which the
      # canonical `to_hash` drops (it strips empty and default-valued
      # attributes by design) — so a code-only identifier came back
      # from `from_hash` with a nil prefix and re-rendered as
      # "CSA C22.1-15". Named for the RARE case with a `false` default,
      # per CLAUDE.md, so it is dropped from every ordinary row.
      attribute :code_only, :boolean, default: -> { false }

      # A flat, index-friendly serialized shape: the `Components::Code`
      # attributes collapse to bare scalars (`number: C22.2-286`, not
      # `number: {value: C22.2-286}`), the ISO/ETSI/ITU `key_value` pattern.
      #
      # This is deliberately a serialization mapping rather than an
      # `attribute :number, :string` redeclaration. CSA's base is split across
      # two files (csa/identifier.rb + csa/single_identifier.rb) — the IEEE
      # shape in which a leaf can snapshot a half-built parent attribute table
      # — so a retype here would reintroduce the `number` determinism landmine
      # recorded in CLAUDE.md. The runtime attribute stays a Components::Code;
      # only the hash is flat.
      #
      # A lutaml key_value block is EXHAUSTIVE — an unmapped attribute is
      # dropped, `_type` included — so every attribute above appears here. It
      # lives on SingleIdentifier, which only the single-document types
      # inherit; the container types descend from Csa::Identifier directly and
      # keep the default shape for their nested `base`/`identifiers`.
      key_value do
        map "_type", to: :_type
        map "number", with: { to: :number_to_kv, from: :number_from_kv }
        map "no_number",
            with: { to: :no_number_to_kv, from: :no_number_from_kv }
        map "year", to: :year
        map "year_format", to: :year_format
        map "year_prefix", to: :year_prefix
        map "original_year_4digit", to: :original_year_4digit
        map "french", to: :french
        map "reaffirmation", to: :reaffirmation
        map "original_reaffirmation_4digit", to: :original_reaffirmation_4digit
        map "has_publisher", to: :has_publisher
        map "series_prefix", to: :series_prefix
        map "series", to: :series
        map "package", to: :package
        map "publisher_prefix", to: :publisher_prefix
        map "code_only", to: :code_only
      end

      def number_to_kv(model, doc)
        emit_kv(doc, "number", model.number)
      end

      def number_from_kv(model, value)
        model.number = Components::Code.new(value: value.to_s)
      end

      # `no_number` is a plain :string here but a Components::Code on Cec, so
      # the converter reads through whichever it is given.
      def no_number_to_kv(model, doc)
        emit_kv(doc, "no_number", model.no_number)
      end

      def no_number_from_kv(model, value)
        model.no_number =
          if model.class.attributes[:no_number].type == Components::Code
            Components::Code.new(value: value.to_s)
          else
            value.to_s
          end
      end

      # Emit a scalar, skipping a nil or empty value so the canonical
      # no-defaults hash never gains an empty key.
      def emit_kv(doc, key, value)
        text = value.respond_to?(:value) ? value.value : value
        return if text.nil? || text.to_s.empty?

        doc.add_child(
          Lutaml::KeyValue::DataModel::Element.new(key, text.to_s),
        )
      end
    end
  end
end
