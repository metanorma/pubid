# frozen_string_literal: true

module Pubid
  module Amca
    # Base identifier class for AMCA identifiers. Canonical name
    # Pubid::Amca::Identifier; common
    # functionality for all AMCA identifier types.
    class Identifier < ::Pubid::Identifier
      # @raise [Parslet::ParseFailed] If parsing fails
      def self.parse(identifier)
        parsed = Parser.parse(identifier)
        Builder.build(parsed)
      rescue Parslet::ParseFailed => e
        raise "Failed to parse ACMA identifier '#{identifier}': #{e.message}"
      end

      # Stored as a plain string (always "AMCA") so it round-trips through
      # to_hash/from_hash. Was a `def publisher` method, which made lutaml
      # serialize a String against the Components::Publisher attribute and raise.
      attribute :publisher, :string, default: -> { "AMCA" }
      attribute :copublisher, :string
      # The document number used to live in AMCA's own `code` attribute, leaving
      # the `number` inherited from ::Pubid::Identifier nil — so relaton-index,
      # which sorts and bsearches on `id.root.number.to_s`, keyed every AMCA row
      # on "". `code` is gone; each LEAF now declares `attribute :number,
      # :string` (see standard.rb / publication.rb / interpretation.rb).
      #
      # It is declared on the leaves, never here: this class is inherited by all
      # three of them, and redefining the parent's Components::Code-typed
      # `number` on an inherited-from class resolves nondeterministically under
      # multi-flavor load. Do not reintroduce `code`, and do not move `number`
      # up here.
      #
      # A bare 2-digit edition year ("21", "02"). Declared :string, not
      # Components::Date: the builder assigns a String and lutaml does not cast
      # it, so a Date declaration left the PARSE path holding a String while
      # from_hash produced a Components::Date — making
      # `parse(x) == from_hash(parse(x).to_hash)` false for every AMCA id and
      # breaking #matches?, which is built on ==. to_hash and to_s agreed, so
      # the relaton index gate never caught it.
      attribute :year, :string
      attribute :suffix, :string
      attribute :reaffirmed, :string

      # Explicit key_value mapping: only these keys serialize (the inherited
      # Pubid::Identifier attributes — including :type, which subclasses expose
      # as a class-metadata Hash via `self.type` — are intentionally dropped).
      # Every mapped attribute is a plain scalar, so no custom converters are
      # needed; the canonical to_hash already drops empty and default values.
      key_value do
        map "_type", to: :_type
        map "publisher", to: :publisher
        map "copublisher", to: :copublisher
        map "number", to: :number
        map "year", to: :year
        map "suffix", to: :suffix
        map "reaffirmed", to: :reaffirmed
      end

      def to_urn
        UrnGenerator.new(self).generate
      end

      # AMCA models its document type as class metadata (`self.type`), not as a
      # `typed_stage`, so the base `mr_type` hook found nothing. Without it an
      # interpretation and the standard it interprets share a slug — and
      # `to_slug` is an output FILENAME. Before the index columns landed the
      # whole flavor collapsed onto two slugs ("amca" and "").
      def mr_type
        return nil unless self.class.respond_to?(:type)

        self.class.type[:key]&.to_s
      end

      # AMCA keeps the edition in its own `year` string, not in the inherited
      # `date`, so the base `mr_year` hook read nil and two editions of one
      # standard — "ANSI/AMCA 300-14" and "ANSI/AMCA Standard 300-24" —
      # produced the same slug. Same shape as the BIPM year recorded in
      # CLAUDE.md.
      def mr_year
        year&.to_s
      end
    end
  end
end
