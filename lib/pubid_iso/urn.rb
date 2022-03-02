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
        result += ":stage-#{identifier.stage}.#{sprintf('%02d', identifier.substage)}"
      end
      result
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
