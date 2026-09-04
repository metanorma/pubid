# frozen_string_literal: true

module Pubid
  module Api
    module Identifiers
      class Mpms < Base
        # The MPMS chapter IS the document number — "API MPMS CH 12.2" is
        # chapter 12, section 2 — so it lives in the `number` inherited from
        # ::Pubid::Identifier, which every other API type already sets. It used
        # to sit in a separate `chapter` :string, leaving `number` nil, so all
        # 30 MPMS ids keyed "" for relaton-index.
        #
        # `section`/`subsection` stay as sibling part columns, which is what
        # gives the bucket semantics a part-less reference needs: every section
        # of chapter 12 shares the key "12". `CH` is a literal marker in the
        # renderer and was never part of the value.
        attribute :section, :string
        attribute :subsection, :string

        def type_string
          "MPMS"
        end

        private

        def code_portion
          # Override - MPMS doesn't use code_portion
          nil
        end
      end
    end
  end
end
