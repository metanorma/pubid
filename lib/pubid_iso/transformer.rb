module PubidIso
  class Transformer < Parslet::Transform
    rule(edition: "Ed") do
      { edition: "1" }
    end
  end
end
