module Pubid::Iso
  class French < Identifier
    def initialize(**opts)
      opts.each { |key, value| send("#{key}=", value) }
    end

    def identifier(with_date, with_language_code)
      if @type == "Guide"
        "Guide #{originator}#{stage} #{number}#{part}#{iteration}"\
          "#{with_date && rendered_year || ''}#{edition}#{supplements}#{language(with_language_code)}"
      else
        super
      end
    end

    def copublisher
      super.map { |copublisher| copublisher.sub("IEC", "CEI") }
    end

    def supplements
      super.gsub(" ", ".")
    end
  end
end
