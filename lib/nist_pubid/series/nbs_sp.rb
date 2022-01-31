module NistPubid
  module Series
    class NbsSp < NistPubid::Serie
      PART_REGEXP = /(?<=\.)?(?<![a-z])+(?:pt|Pt|p|P)([A-Z\d]+)/.freeze
    end
  end
end
