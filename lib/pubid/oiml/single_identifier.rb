# frozen_string_literal: true

module Pubid
  module Oiml
    class SingleIdentifier < Identifier
      # Base class for OIML single identifiers (non-supplements)
      attribute :publisher, :string
      attribute :date, Pubid::Components::Date
      attribute :edition, :string
      attribute :stage, :string
      attribute :iteration, :string
      attribute :language, :string
      attribute :parsed_format, :string, default: -> {
        "short"
      } # Track parsed format

      # Serialization delta on top of Oiml::Identifier's shared block. The
      # `date` (year) component is flattened to a top-level key rather than a
      # nested hash, mirroring ISO (lib/pubid/iso/identifier.rb). `type` is
      # intentionally omitted (recomputed from the class on load).
      #
      # The code columns (number/part/subpart/suffix/space_suffix) are NOT
      # here: they are declared, and mapped, by Identifiers::CodeNumber on each
      # concrete leaf, because redefining the inherited `number` on this class
      # — which every leaf inherits — is the multi-flavor determinism landmine.
      # Keeping the mapping with the attribute is also what lets Bulletin, the
      # one leaf with no code, omit both.
      key_value do
        map "publisher", to: :publisher
        map "year", with: { to: :year_to_kv, from: :year_from_kv }
        map "edition", to: :edition
        map "stage", to: :stage
        map "iteration", to: :iteration
      end

      # --- date flattened to a top-level year ---
      def year_to_kv(model, doc) = emit_kv(doc, "year", model.date&.year)

      def year_from_kv(model, value)
        (model.date ||= Pubid::Components::Date.new).year = value.to_s
      end

      def emit_kv(doc, key, value)
        return if value.nil? || value.to_s.empty?

        doc.add_child(Lutaml::KeyValue::DataModel::Element.new(key, value.to_s))
      end

      attr_reader :requested_format

      # Type is determined by the subclass
      def type
        type_string
      end

      def to_s(format: nil, **opts)
        # Store requested format so the renderer can access it
        @requested_format = format
        render(format: :human, **opts)
      end

      def edition_portion
        # Deprecated - kept for compatibility
        # Use to_s(format: :long) instead
        if edition && date
          "#{edition} Edition #{date.year}"
        elsif date
          "Edition #{date.year}"
        else
          edition
        end
      end

      # Subclasses override this
      def type_string
        raise NotImplementedError, "Subclasses must implement type_string"
      end

      # OIML keeps identity in the code columns and `type_string` (e.g. "R",
      # "V", "D"), not in the inherited `typed_stage` — the generic MrString
      # renderer would otherwise drop both and produce `OIML.<year>`.
      # Losslessness for issue #142 requires the type letter and document
      # number to appear in MR.
      #
      # Reads through `code`, which every code-bearing leaf composes from its
      # split columns (Identifiers::CodeNumber); Bulletin has no code and
      # returns nil here, keeping its (year, issue, sequence) slug.
      def mr_number_with_part
        segments = []
        segments << code&.number&.to_s if code&.number
        segments << code&.part&.to_s if code&.part
        segments << code&.subpart&.to_s if code&.subpart
        segments << code&.suffix&.to_s if code&.suffix
        return nil if segments.empty?

        segments.join("-")
      end

      # Bulletin overrides `code`; every other leaf gets it from
      # Identifiers::CodeNumber. Returning nil here keeps #== , the renderer
      # and the URN generator total for the abstract class itself.
      def code
        nil
      end

      def mr_type
        type_string&.downcase
      end

      # Subclasses override this
    end
  end
end
