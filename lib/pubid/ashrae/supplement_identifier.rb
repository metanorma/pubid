# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Ashrae
    # Base class for supplement identifiers (addendums, errata, interpretations)
    # Supplements modify or add to a base document
    class SupplementIdentifier < Identifier
      attribute :base, Identifier, polymorphic: true

      # Delegate publisher to base
      def publisher
        base&.publisher
      end

      # Delegate the document code to the base standard.
      #
      # The BODY had to move with the `code` -> `number` rename — it was
      # `base&.code`, and `code` no longer exists anywhere in the hierarchy, so
      # it raised NoMethodError on every Errata/Addendum/CombinedAddenda/
      # AddendaPackage/Interpretation. Nothing inside lib/pubid/ashrae calls
      # it, which is exactly why the suite stayed green while a public method
      # on five types was broken.
      #
      # The NAME deliberately stays `code`. Renaming it to `number` looks
      # tidier and is wrong twice over: `number` is an inherited lutaml
      # attribute typed Components::Code, so a String-returning method of that
      # name makes `to_hash` raise IncorrectModelError on every supplement —
      # and even typed correctly it would serialize a duplicate of the base's
      # number onto the wrapper. `code` is not an attribute anywhere, so it is
      # free to be a plain reader. Use `#root.number` for the index key.
      def code
        base&.number
      end
    end
  end
end
