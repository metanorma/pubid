require_relative "identifier/base"
require_relative "renderer/base"

module Pubid::Bsi
  class Transformer < Parslet::Transform
    rule(amendment: subtree(:amendment)) do |context|
      { amendment: Identifier::Amendment.new(**context[:amendment]) }
    end
  end
end
