module Pubid::Itu
  class Transformer < Pubid::Core::Transformer
    rule(series: "Operational Bulletin") do
      { series: "OB" }
    end
  end
end
