module NistPubid
  module Series
    class NistTn < NistPubid::Serie
      EDITION_REGEXP = /[0-9]+(?<prepend>-)(?<year>\d+)/.freeze
    end
  end
end
