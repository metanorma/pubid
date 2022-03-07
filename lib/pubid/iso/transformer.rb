module Pubid::Iso
  class Transformer < Parslet::Transform
    rule(edition: "Ed") do
      { edition: "1" }
    end

    rule(stage: simple(:stage)) do
      { stage: case stage
               when "D"
                 "DIS"
               when "FD"
                 "FDIS"
               else
                 stage
               end
      }
    end

    rule(language: simple(:language)) do
      { language: case language
                  when "R"
                    "ru"
                  when "F"
                    "fr"
                  when "E"
                    "en"
                  when "A"
                    "ar"
                  else
                    language
                  end
      }
    end
  end
end
