module Pubid::Iso
  class Identifier < Pubid::Core::Identifier
    attr_accessor :stage, :substage,
                  :iteration, :supplements,
                  :amendment_stage, :corrigendum_stage, :joint_document,
                  :tctype, :sctype, :wgtype, :tcnumber, :scnumber, :wgnumber,
                  :urn_stage, :dir, :dirtype, :supplement

    def initialize(**opts)
      super
      # if supplement
      #   @supplement = Supplement.new(number: supplement[:year],
      #                                publisher: supplement[:publisher],
      #                                edition: supplement[:edition])
      # end
    end

    def self.parse_from_title(title)
      title.split.reverse.inject(title) do |acc, part|
        return parse(acc)
      rescue Pubid::Core::Errors::ParseError
        # delete parts from the title until it's parseable
        acc.reverse.sub(part.reverse, "").reverse.strip
      end
    end

    class << self
      def get_amendment_class
        Pubid::Iso::Amendment
      end

      def get_corrigendum_class
        Pubid::Iso::Corrigendum
      end

      def get_parser_class
        Parser
      end

      def get_transformer_class
        Transformer
      end
    end

    def urn
      (@tctype && Renderer::UrnTc || @dir && Renderer::UrnDir || Pubid::Core::Renderer::Urn).new(get_params).render
    end

    def to_s(lang: nil, with_date: true, with_language_code: :iso)
      # @pubid_language = lang
      case lang
      when :french
        Renderer::French.new(get_params)
      when :russian
        Renderer::Russian.new(get_params)
      else
        if @tctype
          Renderer::Tc.new(get_params)
        elsif @dir
          Renderer::Dir.new(get_params)
        else
          self.class.get_renderer_class.new(get_params)
        end
      end.render(with_date: with_date, with_language_code: with_language_code) +
        if @joint_document && !@dir
          "|#{@joint_document}"
        end.to_s
    end
  end
end
