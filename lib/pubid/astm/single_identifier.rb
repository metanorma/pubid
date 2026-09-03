# frozen_string_literal: true

module Pubid
  module Astm
    # Descends from Pubid::Astm::Identifier (the flavor base) so every concrete
    # ASTM identifier is `is_a?(Pubid::Astm::Identifier)`.
    class SingleIdentifier < Identifier
      # Generate URN for this identifier
      #
      # @return [String] URN representation
      attribute :publisher, :string, default: -> { "ASTM" }
      # The document code lives on every concrete class as flat index columns
      # (Identifiers::CodeNumber) — `number` is what relaton-index keys on. It
      # cannot be declared here: SingleIdentifier is inherited by every ASTM
      # type, and retyping the inherited `number` on an inherited-from class
      # resolves nondeterministically under multi-flavor load.
      attribute :year, :string
      attribute :format_suffix, :string # -EB for eBook

      # --- MR slug hooks -------------------------------------------------
      #
      # ASTM defined none, so the base hooks looked for an inherited
      # `typed_stage`, `date` and `Components::Edition` that ASTM does not use.
      # Two consequences, both measured on the corpus before this change:
      # 201 of 248 ids shared the single slug "astm", and 40 of them RAISED —
      # `mr_edition` calls `edition.number`, but ASTM's `edition` is a plain
      # String. That is the same crash BIPM had, recorded in CLAUDE.md.
      # `to_slug` is what consumers use as an output filename.
      def mr_edition
        edition&.to_s&.downcase
      end

      # ASTM keeps its edition year in a plain `year` string, not the
      # inherited `date`.
      def mr_year
        year&.to_s
      end

      # The document type is the class, not a typed_stage: without it a
      # Manual, a DataSeries and a Standard numbered alike share a filename.
      def mr_type
        self.class.name.split("::").last
          .gsub(/([a-z])([A-Z])/, '\1-\2').downcase
      end
    end
  end
end
