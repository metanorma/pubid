module NistPubid
  module Series
    class NbsCrpl < NistPubid::Serie
      # NBS CRPL 1-2_3-1A
      SUPPLEMENT_REGEXP = /(?<=_)\d+-\d+([A-Z]+)/.freeze
      # _3-1
      PART_REGEXP = /(?<=_)(\d+-\d+)/.freeze
    end
  end
end
