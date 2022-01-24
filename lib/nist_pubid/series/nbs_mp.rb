module NistPubid
  module Series
    class NbsMp < NistPubid::Serie
      EDITION_REGEXP = /(?<=NBS MP )\d+(?<prefix>\()(?<sequence>\d+)(?<suffix>\))/.freeze
    end
  end
end
