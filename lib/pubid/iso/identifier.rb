module Pubid::Iso
  class Identifier < Pubid::Core::Identifier
    attr_accessor :stage,
                  :iteration, :joint_document,
                  :tctype, :sctype, :wgtype, :tcnumber, :scnumber, :wgnumber,
                  :dirtype,
                  # supplement for DIR type identifiers
                  :supplement,
                  :base,
                  :typed_stage,
                  :supplements

    # Creates new identifier from options provided, includes options from
    # Pubid::Core::Identifier#initialize
    #
    # @param stage [Stage, TypedStage, Symbol, String] stage or typed stage, e.g. "PWI", "NP", "50.00", Stage.new(abbr: :WD), "DTR"
    # @param iteration [Integer] document iteration, eg. "1", "2", "3"
    # @param joint_document [Identifier] joint document
    # @param supplement [Supplement] supplement
    # @param tctype [String] Technical Committee type, eg. "TC", "JTC"
    # @param sctype [String] TC subsommittee, eg. "SC"
    # @param wgtype [String] TC working group type, eg. "AG", "AHG"
    # @param tcnumber [Integer] Technical Committee number, eg. "1", "2"
    # @param scnumber [Integer] Subsommittee number, eg. "1", "2"
    # @param wgnumber [Integer] Working group number, eg. "1", "2"
    # @param dirtype [String] Directives document type, eg. "JTC"
    # @param base [Identifier] base document for supplement's identifier
    # @param type [nil, :tr, :ts, :amd, :cor, :guide, :dir, :tc, Type] document's type, eg. :tr, :ts, :amd, :cor, Type.new(:tr)
    # @raise [Errors::SupplementWithoutYearOrStageError] when trying to apply
    #   supplement to the document without edition year or stage
    # @raise [Errors::IsStageIterationError] when trying to apply iteration
    #   to document with IS stage
    # @raise [Errors::IterationWithoutStageError] when trying to applu iteration
    #   to document without stage
    # @see Supplement
    # @see Identifier
    # @see Pubid::Core::Identifier
    # @see Parser
    #
    def initialize(publisher: "ISO", number: nil, stage: nil, iteration: nil, supplement: nil,
                   joint_document: nil, tctype: nil, sctype: nil, wgtype: nil, tcnumber: nil,
                   scnumber: nil, wgnumber:nil,
                   dir: nil, dirtype: nil, year: nil, amendments: nil,
                   corrigendums: nil, type: nil, base: nil, supplements: nil, **opts)
      super(**opts.merge(number: number, publisher: publisher, year: year,
                         amendments: amendments, corrigendums: corrigendums))

      if supplements
        @supplements = supplements.map do |supplement|
          if supplement.is_a?(Hash)
            self.class.get_transformer_class.new.apply(:supplements => [supplement])[:supplements].first
          else
            supplement
          end
        end
      end

      if %i(amd cor).include?(type) && (base.year.nil? && base.stage.nil?)
        raise Errors::SupplementWithoutYearOrStageError,
              "Cannot apply supplement to document without base identifieredition year or stage"
      end

      if stage.is_a?(TypedStage)
        @typed_stage = stage
        # add type to typed stage when missing (case for amendment with stage, eg. "CD Amd")
        @typed_stage.type = Type.new(type) if @typed_stage.type.nil? && type
      elsif stage || type
        @typed_stage = if type
                         TypedStage.new(type: type.is_a?(Type) ? type : Type.new(type))
                       else
                         TypedStage.new
                       end

        if @typed_stage.type == :is && iteration
          raise Errors::IsStageIterationError, "IS stage document cannot have iteration"
        end

        if stage
          provided_type = @typed_stage.type

          @typed_stage.parse_stage(stage.is_a?(Parslet::Slice) ? stage.to_s : stage)
          if !provided_type.nil? && @typed_stage.type != provided_type
            raise Errors::StageInvalidError,
                  "cannot assign typed stage for document with different type (#{provided_type} vs #{@typed_stage.type})"
          end
        end
      elsif iteration
        raise Errors::IterationWithoutStageError, "Document without stage cannot have iteration"
      end

      @iteration = iteration.to_i if iteration
      @supplement = supplement if supplement
      @joint_document = joint_document if joint_document
      @tctype = tctype if tctype
      @sctype = sctype.to_s if sctype
      @wgtype = wgtype.to_s if wgtype
      @tcnumber = tcnumber.to_s if tcnumber
      @scnumber = scnumber.to_s if scnumber
      @wgnumber = wgnumber.to_s if wgnumber
      @dir = dir.to_s if dir
      @dirtype = dirtype.to_s if dirtype
      @base = base if base
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
      def supplements_has_type?(supplements, type)
        supplements.any? do |supplement|
          supplement.typed_stage.type == type
        end
      end

      def supplement_by_type(supplements, type)
        supplements.select { |supplement| supplement.type == type }.first
      end

      def transform_supplements(supplements_params, base_params)
        supplements = supplements_params.map do |supplement|
          new(number: supplement[:number], year: supplement[:year],
              stage: supplement[:typed_stage], edition: supplement[:edition],
              iteration: supplement[:iteration],
              base: new(**base_params))
        end

        return supplements.first if supplements.count == 1

        # update corrigendum base to amendment
        if supplements_has_type?(supplements, :cor) &&
            supplements_has_type?(supplements, :amd) && supplements.count == 2

          supplement = supplement_by_type(supplements, :cor)
          supplement.base = supplement_by_type(supplements, :amd)
          supplement
        else
          raise Errors::SupplementRenderingError, "don't know how to render provided supplements"
        end
      end

      def transform(params)
        identifier_params = params.map do |k, v|
          get_transformer_class.new.apply(k => v).to_a.first
        end.to_h

        # return supplement if supplements applied
        if identifier_params[:supplements]
          return transform_supplements(
            identifier_params[:supplements],
            identifier_params.dup.tap { |h| h.delete(:supplements) })
        end

        new(**identifier_params)
      end

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

    # Render URN identifier
    # @return [String] URN identifier
    def urn
      if %i(amd cor).include?(type&.type) && (@base.base.nil? && !@base.edition || (!@base.base.nil? && !@base.base.edition))
        raise Errors::NoEditionError, "Base document must have edition"
      end
      (@tctype && Renderer::UrnTc || type == :dir && Renderer::UrnDir || Pubid::Iso::Renderer::Urn).new(get_params).render
    end

    # Renders pubid identifier
    #
    # @param lang [:french,:russian] use language specific renderer
    # @param with_date [Boolean] render identifier with date
    # @param with_edition [Boolean] render identifier with edition
    # @param stage_format_long [Boolean] render with long or short stage format
    # @param format [:ref_num_short,:ref_num_long,:ref_dated,:ref_dated_long,:ref_undated,:ref_undated_long] create reference with specified format
    # @param with_prf [Boolean] include PRF stage in output
    # Format options are:
    #   :ref_num_short -- instance reference number: 1 letter language code + short form (DAM) + dated
    #   :ref_num_long -- instance reference number long: 2 letter language code + long form (DAmd) + dated
    #   :ref_dated -- reference dated: no language code + short form (DAM) + dated
    #   :ref_dated_long -- reference dated long: no language code + short form (DAM) + dated
    #   :ref_undated -- reference undated: no language code + short form (DAM) + undated
    #   :ref_undated_long -- reference undated long: 1 letter language code + long form (DAmd) + undated
    # @return [String] pubid identifier
    def to_s(lang: nil, with_date: true,
             with_edition: false, with_prf: false,
             format: :ref_dated_long)
      with_language_code = nil
      stage_format_long = nil
      if format
        case format
        when :ref_num_short
          with_language_code = :single
          stage_format_long = false
        when :ref_num_long
          with_language_code = :iso
          stage_format_long = true
        when :ref_dated
          with_language_code = :none
          stage_format_long = false
        when :ref_dated_long
          with_language_code = :none
          stage_format_long = true
        when :ref_undated
          with_language_code = :none
          stage_format_long = false
          with_date = false
        when :ref_undated_long
          with_language_code = :none
          stage_format_long = true
          with_date = false
        else
          raise Errors::WrongFormat, "#{format} is not available"
        end
      end
      case lang
      when :french
        Renderer::French.new(get_params)
      when :russian
        Renderer::Russian.new(get_params)
      else
        if @tctype
          Renderer::Tc.new(get_params)
        elsif @typed_stage&.type == :dir
          Renderer::Dir.new(get_params)
        else
          self.class.get_renderer_class.new(get_params)
        end
      end.render(with_date: with_date, with_language_code: with_language_code, with_edition: with_edition,
                 stage_format_long: stage_format_long, with_prf: with_prf) +
        if @joint_document && @typed_stage&.type != :dir
          "|#{@joint_document}"
        end.to_s
    end

    def stage
      typed_stage&.stage
    end

    def type
      typed_stage&.type
    end

    # Return typed stage abbreviation, eg. "FDTR", "DIS", "TR"
    def typed_stage_abbrev
      typed_stage.to_s
    end

    # Return typed stage name, eg. "Final Draft Technical Report" for "FDTR"
    def typed_stage_name
      typed_stage.name
    end

    def ==(other)
      get_params == other.get_params
    end
  end
end
