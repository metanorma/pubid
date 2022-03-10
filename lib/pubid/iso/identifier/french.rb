module Pubid::Iso
  class French < Identifier
    def identifier
      if @type == "Guide"
        "Guide #{originator}#{stage} #{number}#{part}#{iteration}#{year}#{edition}#{supplements}#{language}"
      else
        super
      end
    end

    def copublisher
      super.map { |copublisher| copublisher.sub("IEC", "CEI") }
    end

    def amendment
      if @amendment_number
        "Amd.#{@amendment_version}:#{@amendment_number}"
      else
        "Amd.#{@amendment_version}"
      end
    end

    def corrigendum
      if @corrigendum_number
        "Cor.#{@corrigendum_version}:#{@corrigendum_number}"
      else
        "Cor.#{@corrigendum_version}"
      end
    end
  end
end
