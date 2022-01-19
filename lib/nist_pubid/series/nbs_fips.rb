module NistPubid
  module Series
    class NbsFips < NistPubid::Serie
      EDITION_REGEXP = /NBS\sFIPS\s[0-9]+[A-Za-z]*-(?:
                        (?:\d+-)?(?<date_with_month>[A-Za-z]{3}\d{4})| # NBS FIPS 107-Mar1985
                        (?:\d+-)?(?<date_with_day>[A-Za-z]{3}\d{2}\/\d{4})| # NBS FIPS PUB 11-1-Sep30\/1977
                        (?:\d+-)(?<year>\d{4})
                      )/x.freeze
    end
  end
end
