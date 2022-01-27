module NistPubid
  module Series
    class NbsRpt < NistPubid::Serie
      SERIE_REGEXP = /(NBS report ;|NBS RPT)/.freeze
      DOCNUMBER_REGEXP = /(\w{3}-\w{3}\d{4}|ADHOC|div9)/.freeze
    end
  end
end
