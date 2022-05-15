module Pubid::Iso
  class Urn < Identifier

    STAGES = { PWI: 0,
               NP: 10,
               AWI: 20,
               WD: 20.20,
               CD: 30,
               DIS: 40,
               FDIS: 50,
               PRF: 50,
               IS: 60 }.freeze

    def initialize(**opts)
      opts.each { |key, value| send("#{key}=", value) }
    end

    def to_s
      # docidentifier = originator [":" type] ":" docnumber [":" partnumber]
      # [[":" status] ":" edition]
      # [":" docversion] [":" language]

      if tctype
        "urn:iso:doc:#{originator}:#{tctype.downcase}:#{tcnumber}:#{sctype.downcase}#{wgtype}:#{scnumber}:#{number}"
      else
        "urn:iso:std:#{originator}#{type}:#{number}#{part}#{stage}#{edition}#{supplement}#{language}"
      end
    end

    def wgtype
      ":#{@wgtype.downcase}" if @wgtype
    end

    def part
      ":-#{@part}" if @part
    end

    def render_stage(stage)
      ":stage-#{sprintf('%05.2f', STAGES[stage.to_sym])}#{iteration}"
    end

    def stage
      return render_stage(@stage) if @stage

      return render_stage(@amendment_stage) if @amendment_stage

      render_stage(@corrigendum_stage) if @corrigendum_stage
    end

    def originator
      # originator    = "iso" / "iso-iec" / "iso-cie" / "iso-astm" /
      #   "iso-ieee" / "iec"

      if @copublisher
        @copublisher = [@copublisher] unless @copublisher.is_a?(Array)
        @publisher.downcase + @copublisher.map(&:to_s).sort.map do |copublisher|
          "-#{copublisher.downcase.gsub('/', '-')}"
        end.join
      else
        @publisher.downcase
      end
    end

    def edition
      ":ed-#{@edition}" if @edition
    end

    def iteration
      ".v#{@iteration}" if @iteration
    end

    def type
      # type          = "data" / "guide" / "isp" / "iwa" /
      #   "pas" / "r" / "tr" / "ts" / "tta"
      if @type
        ":#{@type.downcase}"
      end
    end

    def supplement
      result = ""
      if @amendment
        result +=  if @amendment_number
                     ":amd:#{@amendment_number}:v#{@amendment_version}"
                   else
                     ":amd:#{@amendment_version}:v1"
                   end
      end
      if @corrigendum
        result += if @corrigendum_number
                    ":cor:#{@corrigendum_number}:v#{@corrigendum_version}"
                  else
                    ":cor:#{@corrigendum_version}:v1"
                  end
      end

      result
    end

    def language
      if @language
        ":#{@language}"
      end
    end
  end
end
