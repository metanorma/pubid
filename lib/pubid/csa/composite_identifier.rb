# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Csa
    # CompositeIdentifier is the base class for identifiers that contain
    # collections of other identifiers or package materials.
    #
    # Examples:
    #   - Package: base + package materials
    #
    # This follows the Composite pattern where an identifier can contain
    # other identifiers or additional metadata as a collection.
    class CompositeIdentifier < Identifier
      # The primary/base identifier. A real lutaml attribute under the uniform
      # `base` name, so `#root` walks it and it survives serialization — see
      # WrapperIdentifier#base for why the type is the cross-flavor
      # ::Pubid::Identifier.
      attribute :base, ::Pubid::Identifier, polymorphic: true

      # Subclasses MUST implement to_s to define how they render
      def to_s
        raise NotImplementedError, "Subclasses must implement to_s method"
      end

      # A package peels to the standard it packages — see
      # WrapperIdentifier#base_document.
      def base_document
        base ? base.base_document : self
      end

      def drop_supplements
        base || self
      end
    end
  end
end
