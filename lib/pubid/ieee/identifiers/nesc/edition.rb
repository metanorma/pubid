# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      module Nesc
        # A plain year-first NESC edition — the National Electrical Safety Code
        # itself, referenced by publication year rather than by its C2 code.
        #
        # @example
        #   nesc = Pubid::Ieee.parse(
        #     "2017 National Electrical Safety Code(R) (NESC(R))",
        #   )
        #   nesc.to_s
        #   # => "IEEE Std 2017 National Electrical Safety Code(R) (NESC(R))"
        #
        # Rendering is Nesc::Base's; this class exists so that the builder never
        # instantiates the abstract Base. Only concrete leaves may carry the
        # CodeNumber mixin's `:string` `number` (see the mixin's notes on the
        # multi-flavor attribute-resolution landmine), and every identifier that
        # can be a `#root` needs a non-empty `number` for the relaton index.
        class Edition < Base
          include Pubid::Ieee::Identifiers::CodeNumber

          def self.polymorphic_name
            "pubid:ieee:nesc-edition"
          end
        end
      end
    end
  end
end
