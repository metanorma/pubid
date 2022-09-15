module Pubid::Iso
  class Identifier < Pubid::Core::Identifier
    attr_accessor :stage,
                  :iteration, :joint_document,
                  :tctype, :sctype, :wgtype, :tcnumber, :scnumber, :wgnumber,
                  :urn_stage, :dir, :dirtype,
                  # supplement for DIR type identifiers
                  :supplement

    # Creates new identifier from options provided, includes options from
    # Pubid::Core::Identifier#initialize
    #
    # @param stage [Stage] stage
    # @param urn_stage [Float] numeric stage for URN rendering
    # @param iteration [Integer] document iteration, eg. "1", "2", "3"
    # @param joint_document [Identifier] joint document
    # @param supplement [Supplement] supplement
    # @param tctype [String] Technical Committee type, eg. "TC", "JTC"
    # @param sctype [String] TC subsommittee, eg. "SC"
    # @param wgtype [String] TC working group type, eg. "AG", "AHG"
    # @param tcnumber [Integer] Technical Committee number, eg. "1", "2"
    # @param scnumber [Integer] Subsommittee number, eg. "1", "2"
    # @param wgnumber [Integer] Working group number, eg. "1", "2"
    # @param dir [Boolean] Directives document
    # @param dirtype [String] Directives document type, eg. "JTC"
    # @see Supplement
    # @see Identifier
    # @see Pubid::Core::Identifier
    # @see Parser
    #
    def initialize(publisher: "ISO", number: nil, stage: nil, iteration: nil, supplement: nil,
                   joint_document: nil, urn_stage: nil,
                   tctype: nil, sctype: nil, wgtype: nil, tcnumber: nil,
                   scnumber: nil, wgnumber:nil,
                   dir: nil, dirtype: nil, **opts)
      super(**opts.merge(number: number, publisher: publisher))
      @stage = stage if stage
      @iteration = iteration.to_i if iteration
      @supplement = supplement if supplement
      @joint_document = joint_document if joint_document
      @urn_stage = urn_stage if urn_stage
      @tctype = tctype if tctype
      @sctype = sctype.to_s if sctype
      @wgtype = wgtype.to_s if wgtype
      @tcnumber = tcnumber.to_s if tcnumber
      @scnumber = scnumber.to_s if scnumber
      @wgnumber = wgnumber.to_s if wgnumber
      @dir = dir.to_s if dir
      @dirtype = dirtype.to_s if dirtype
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

      def get_renderer_class
        Renderer::Base
      end
    end

    def urn
      (@tctype && Renderer::UrnTc || @dir && Renderer::UrnDir || Pubid::Iso::Renderer::Urn).new(get_params).render
    end

    def formatted(format)
      case format
      when :ref_num_short
        to_s(with_language_code: :single, stage_format_long: false)
      when :ref_num_long
        to_s(with_language_code: :iso, stage_format_long: true)
      when :ref_dated
        to_s(with_language_code: :none, stage_format_long: false)
      when :ref_dated_long
        to_s(with_language_code: :none, stage_format_long: true)
      when :ref_undated
        to_s(with_language_code: :none, stage_format_long: false, with_date: false)
      when :ref_undated_long
        to_s(with_language_code: :none, stage_format_long: true, with_date: false)
      else
        raise Errors::WrongFormat, "#{format} is not available"
      end
    end

    # Renders pubid identifier
    #
    # @param lang [:french,:russian] use language specific renderer
    # @param with_date [Boolean] render identifier with date
    # @param with_language_code [:iso,:single] use iso format or single language code for rendering
    # @param with_edition [Boolean] render identifier with edition
    # @param stage_format_long [Boolean] render with long or short stage format
    # @return [String] pubid identifier
    def to_s(lang: nil, with_date: true, with_language_code: :iso,
             with_edition: true, stage_format_long: true)
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
      end.render(with_date: with_date, with_language_code: with_language_code, with_edition: with_edition,
                 stage_format_long: stage_format_long) +
        if @joint_document && !@dir
          "|#{@joint_document}"
        end.to_s
    end
  end
end
