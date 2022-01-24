module NistPubid
  module Series
    class FipsPub < NistPubid::Serie
      EDITION_REGEXP = /[0-9]+[A-Za-z]*(?<prepend>-)(?:\d+-(?<date_with_month>\w{3}\d{2})|(?<sequence>\d+))/.freeze
    end
  end
end
