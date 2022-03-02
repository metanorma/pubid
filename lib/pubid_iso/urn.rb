module PubidIso
  class URN
    attr_accessor :identifier

    def initialize(identifier)
      @identifier = identifier
    end

    def to_s
      # docidentifier = originator [":" type] ":" docnumber [":" partnumber]
      # [[":" status] ":" edition]
      # [":" docversion] [":" language]

      result = "urn:iso:std:#{originator}#{type}:#{identifier.number}"

      if identifier.part
        result += ":-#{identifier.part}"
      end

      if identifier.stage
        result += ":stage-#{identifier.stage}.#{sprintf('%02d', identifier.substage)}"
      end
      result
    end

    def originator
      # originator    = "iso" / "iso-iec" / "iso-cie" / "iso-astm" /
      #   "iso-ieee" / "iec"

      if identifier.copublisher
        "iso-#{identifier.copublisher.downcase}"
      else
        "iso"
      end
    end

    def type
      # type          = "data" / "guide" / "isp" / "iwa" /
      #   "pas" / "r" / "tr" / "ts" / "tta"

      if identifier.type
        ":#{identifier.type.downcase}"
      end
    end
  end
end
