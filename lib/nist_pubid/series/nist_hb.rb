module NistPubid
  module Series
    class NistHb < NistPubid::Serie
      EDITION_REGEXP = /(?:\d+-)?\d+(?<prepend>-)(?<year>\d{4})/.freeze
    end
  end
end
