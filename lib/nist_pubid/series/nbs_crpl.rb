module NistPubid
  module Series
    class NbsCrpl < NistPubid::Serie
      # NBS CRPL 1-2_3-1A
      SUPPLEMENT_REGEXP = /(?<=_)\d+-\d+([A-Z]+)/.freeze
      # _3-1
      PART_REGEXP = /_(\d+-\d+)/.freeze

      def parse_part(code)
        part = PART_REGEXP.match(code)
        return ["", part.captures.join] if part

        [nil, nil]
      end
    end
  end
end
