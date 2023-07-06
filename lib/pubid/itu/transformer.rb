module Pubid::Itu
  class Transformer < Pubid::Core::Transformer
    rule(series: "Operational Bulletin") do
      { series: "OB" }
    end

    rule(amendment: subtree(:amendment)) do |context|
      { amendment: Identifier::Amendment.new(**context[:amendment]) }
    end
  end
end
