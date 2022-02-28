module PubidIso
  class Parser < Parslet::Parser
    rule(:digits) do
      match('\d').repeat(1)
    end

    rule(:identifier) do
      str("ISO ") >>  digits
    end

    rule(:root) { identifier }
  end
end
