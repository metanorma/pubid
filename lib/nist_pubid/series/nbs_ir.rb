module NistPubid
  module Series
    class NbsIr < NistPubid::Serie
      REVISION_REGEXP = /(?:[\daA-Z](?:rev|r|Rev\.\s)|, Revision )([\da]+|$|\w+\d{4})/.freeze
      VOLUME_REGEXP = /(?:74-577|77-1420)()-(\d+)/.freeze
      PART_REGEXP = /(?:\d+-\d+)(-)(\d+)/.freeze
    end
  end
end
