# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Csa
    # WrapperIdentifier is the base class for all CSA identifiers that wrap
    # other identifiers.
    # Examples:
    #   - CanadianAdopted: CAN/{base}
    #   - CsaAdopted:      CSA {ISO/IEC/CISPR identifier}
    #
    # The wrapper pattern allows proper MODEL-DRIVEN architecture where
    # adoptions are objects that contain other identifier objects, not string
    # prefixes.
    class WrapperIdentifier < Identifier
      # The wrapped identifier (recursively parsed).
      #
      # A real lutaml attribute, not an attr_accessor: the accessor was
      # invisible to `to_hash`, `from_hash` AND `#exclude` (which iterates
      # `self.class.attributes`), so a wrapper serialized to a hash with no
      # identifier in it at all. It is named `base` — the uniform parent
      # accessor every flavor uses — so the inherited `#root` walks it to the
      # origin document and `exclude_from_nested` reaches inside. There is no
      # `wrapped_identifier` alias.
      #
      # Typed as the cross-flavor `::Pubid::Identifier`, not the CSA one:
      # CsaAdopted wraps ISO/IEC/CISPR ids, and lutaml enforces the declared
      # type — `polymorphic: true` widens it only to SUBCLASSES, so a narrower
      # type raises Lutaml::Model::IncorrectModelError on `to_hash`. The
      # Ieee::Identifiers::AdoptedStandard precedent. The nested child carries
      # its own `_type`, so `from_hash` routes it back via TypeResolver.
      attribute :base, ::Pubid::Identifier, polymorphic: true

      # Reaffirmation year (common across wrappers)
      attribute :reaffirmation, :string

      # Whether the reaffirmation was printed 4-digit ("(R2004)") rather than
      # 2-digit ("(R04)"). CanadianAdopted#to_s reads it to choose the spacing
      # and to render the year back in its original width.
      attribute :original_reaffirmation_4digit, :boolean, default: -> { false }

      # Year format tracking (for compatibility)
      attribute :year_format, :string

      # Subclasses MUST implement to_s
      def to_s
        raise NotImplementedError, "Subclasses must implement to_s method"
      end

      # The matching primitives relaton uses to normalise a reference before
      # comparing it. An adoption wrapper peels to the document it adopts;
      # without these the inherited defaults return the WRAPPER, which is a
      # silently wrong answer rather than a loud one.
      def base_document
        base ? base.base_document : self
      end

      def drop_supplements
        base || self
      end
    end
  end
end
