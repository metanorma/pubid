module NistPubid
  module Series
    class NistTn < NistPubid::Serie
      EDITION_REGEXP = /(?<!Upd)\d+(?<prepend>-)(?<year>\d+)/.freeze
    end
  end
end
