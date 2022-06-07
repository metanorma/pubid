module Pubid::Iso
  class Identifier < Pubid::Core::Identifier
    attr_accessor :stage, :substage,
                  :iteration, :supplements,
                  :amendment_stage, :corrigendum_stage, :joint_document,
                  :tctype, :sctype, :wgtype, :tcnumber, :scnumber, :wgnumber,
                  :urn_stage

    LANGUAGES = {
      "ru" => "R",
      "fr" => "F",
      "en" => "E",
      "ar" => "A",
    }.freeze

    def urn
      Urn.new(**get_params)
    end

    def self.parse_from_title(title)
      title.split.reverse.inject(title) do |acc, part|
        return parse(acc)
      rescue Pubid::Iso::Errors::ParseError
        # delete parts from the title until it's parseable
        acc.reverse.sub(part.reverse, "").reverse.strip
      end
    end

    def self.parse(code_or_params)
      params = code_or_params.is_a?(String) ? Parser.new.parse(code_or_params) : code_or_params
      # Parslet returns an array when match any copublisher
      # otherwise it's hash
      if params.is_a?(Array)
        new(
          **(
            params.inject({}) do |r, i|
              result = r
              i.map {|k, v| Transformer.new.apply(k => v).to_a.first }.each do |k, v|
                result = result.merge(k => r.key?(k) ? [v, r[k]] : v)
              end
              result
            end
          )
        )
      else
        new(**params.map do |k, v|
          Transformer.new.apply(k => v).to_a.first
        end.to_h)
      end
      # merge values repeating keys into array (for copublishers)


      # params.to_h)
    rescue Parslet::ParseFailed => failure
      raise Pubid::Iso::Errors::ParseError, "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
    end

    class << self
      def get_amendment_class
        Pubid::Iso::Amendment
      end

      def get_corrigendum_class
        Pubid::Iso::Corrigendum
      end
    end

    def to_s(lang: nil, with_date: true, with_language_code: :iso)
      # @pubid_language = lang
      case lang
      when :french
        French.new(**get_params)
      when :russian
        Russian.new(**get_params)
      else
        self
      end.identifier(with_date, with_language_code) + (@joint_document && "|#{@joint_document}").to_s
    end

    def identifier(with_date, with_language_code)
      if @tctype
        "#{originator} #{tctype} #{tcnumber}#{sctype}#{wgtype} N#{number}"
      else
        "#{originator}#{type}#{stage} #{number}#{part}#{iteration}"\
        "#{with_date && rendered_year || ''}#{edition}#{supplements}#{language(with_language_code)}"
      end
    end

    def tctype
      return @tctype.join("/") if @tctype.is_a?(Array)

      @tctype
    end

    # TC 184/SC/WG 4 - no wg number
    # TC 184/SC 4/WG 12 - separate sc and wg number
    def sctype
      return unless @sctype

      if @wgnumber || !@wgtype
        "/#{@sctype} #{@scnumber}"
      else
        "/#{@sctype}"
      end
    end

    def wgtype
      return unless @wgtype

      if @wgnumber
        "/#{@wgtype} #{@wgnumber}"
        else
        "/#{@wgtype} #{@scnumber}"
      end
    end

    def copublisher
      return nil unless @copublisher

      (!@copublisher.is_a?(Array) && [@copublisher]) || @copublisher
    end

    def originator
      if copublisher
        # @copublisher = [@copublisher] unless @copublisher.is_a?(Array)
        # @copublisher.map! { |copublisher| copublisher.sub("IEC", "CEI") } if @french
        publisher + copublisher.map(&:to_s).sort.map do |copublisher|
          "/#{copublisher.gsub('-', '/')}"
        end.join
      else
        publisher
      end
    end

    def stage
      "#{(@copublisher && ' ') || '/'}#{@stage}" if @stage
    end

    def part
      "-#{@part}" if @part
    end

    def rendered_year
      @year && ":#{@year}"
    end

    def type
      "#{(@copublisher && ' ') || '/'}#{@type}" if @type
    end

    def edition
      " ED#{@edition}" if @edition
    end

    def iteration
      ".#{@iteration}" if @iteration
    end

    def supplements
      result = @amendments && @amendments.map(&:render_pubid).join("+") || ""

      result + (@corrigendums && @corrigendums.map(&:render_pubid).join("+") || "")
    end

    def language(with_language_code = :iso)
      if @language
        if with_language_code == :single
          "(#{LANGUAGES[@language]})"
        else
          "(#{@language})"
        end
      end
    end

  end
end
