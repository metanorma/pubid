module Pubid::Itu
  class Transformer < Pubid::Core::Transformer
    rule(series: "Operational Bulletin") do
      { series: "OB" }
    end

    rule(language: simple(:language)) do
      { language: LANGUAGES.key(language) }
    end
  end
end
