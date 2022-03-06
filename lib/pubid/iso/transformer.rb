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
  end
end
