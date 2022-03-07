module Pubid::Iso
  class URN
    attr_accessor :identifier

    def initialize(identifier)
      @identifier = identifier
    end

    def to_s
      # docidentifier = originator [":" type] ":" docnumber [":" partnumber]
      # [[":" status] ":" edition]
      # [":" docversion] [":" language]

      "urn:iso:std:#{originator}#{type}:#{identifier.number}#{part}#{stage}#{edition}#{supplement}#{language}"
    end

    def part
      ":-#{identifier.part}" if identifier.part
    end

    def stage
      ":stage-#{identifier.stage}.#{sprintf('%02d', identifier.substage)}#{iteration}" if identifier.stage
    end

    def originator
      # originator    = "iso" / "iso-iec" / "iso-cie" / "iso-astm" /
      #   "iso-ieee" / "iec"

      if identifier.copublisher
        "#{identifier.publisher.downcase}-#{identifier.copublisher.downcase.gsub('/', '-')}"
      else
        identifier.publisher.downcase
      end
    end

    def edition
      ":ed-#{identifier.edition}" if identifier.edition
    end

    def iteration
      ".v#{identifier.iteration}" if identifier.iteration
    end

    def type
      # type          = "data" / "guide" / "isp" / "iwa" /
      #   "pas" / "r" / "tr" / "ts" / "tta"

      if identifier.type
        ":#{identifier.type.downcase}"
      end
    end

    def supplement
      result = ""
      if identifier.amendment
        result +=  if identifier.amendment_number
                     ":amd:#{identifier.amendment_number}:v#{identifier.amendment_version}"
                   else
                     ":amd:v#{identifier.amendment_version}"
                   end
      end
      if identifier.corrigendum
        result += if identifier.corrigendum_number
                    ":cor:#{identifier.corrigendum_number}:v#{identifier.corrigendum_version}"
                  else
                    ":cor:v#{identifier.corrigendum_version}"
                  end
      end

      result
    end

    def language
      if identifier.language
        ":#{identifier.language}"
      end
    end
  end
end
