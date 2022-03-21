module Pubid::Ieee
  class Transformer < Parslet::Transform
    rule(draft: subtree(:draft)) do
      result = draft
      if draft[:month]

        if draft[:year].length == 2
          result[:year] = case draft[:year].to_i
            when 0..25 then "20#{draft[:year]}"
            when 26..99 then "19#{draft[:year]}"
          end
        end

        result[:month] = Date.parse(draft[:month]).strftime("%B")
      end
      { draft: result }
    end
  end
end
