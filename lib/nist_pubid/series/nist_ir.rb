module NistPubid
  module Series
    class NistIr < NistPubid::Serie
      EDITION_REGEXP = /(?<!Upd)\d+(?<prepend>-)(?<year>\d{4})(?!-)/.freeze
    end
  end
end
