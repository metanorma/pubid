module PubidIso
  class URN
    attr_accessor :identifier

    def initialize(identifier)
      @identifier = identifier
    end

    def to_s
      result = "urn:iso:std:#{publisher}:#{identifier.number}"

      if identifier.part
        result += ":-#{identifier.part}"
      end

      if identifier.stage
        result += ":stage-#{stage}"
      end
      result
    end

    def stage
      # Stage 10: NP (non-public)
      # Stage 20: WD (non-public)
      # Stage 30: CD
      # Stage 40: DIS
      # Stage 50: FDIS
      # Stage 50.60: PRF ("proof") (non-public)
      # Stage 60: IS

      case identifier.stage
      when "NP"
        "10.00";
      when "WD"
        "20.00";
      when "FDIS"
        "50.00";
      end
    end

    def publisher
      if identifier.copublisher
        "iso-#{identifier.copublisher.downcase}"
      else
        "iso"
      end
    end
  end
end
