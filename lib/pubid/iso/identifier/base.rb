require 'forwardable'
require_relative "../renderer/urn"
require_relative "../renderer/urn-tc"

module Pubid::Iso
  module Identifier
    class Base < Pubid::Core::Identifier
      extend Forwardable

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
      # @param stage [Stage, Symbol, String] stage or typed stage, e.g. "PWI", "NP", "50.00", Stage.new(abbr: :WD), "DTR"
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

        if stage
          if stage.is_a?(Stage)
            @stage = stage
            @typed_stage = resolve_typed_stage(@stage.harmonized_code) unless @stage.abbr
          elsif self.class.has_typed_stage?(stage)
            @typed_stage, @stage = find_typed_stage(stage)
          else
            @stage = Stage.parse(stage)
            @typed_stage = resolve_typed_stage(@stage.harmonized_code) if @stage.empty_abbr?(with_prf: true)
          end
        elsif iteration && !is_a?(Supplement)
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

      # @param typed_stage [String, Symbol] eg. "DTR" or :dtr
      # @return [[Symbol, Stage]] typed stage and stage with assigned harmonized codes
      def find_typed_stage(typed_stage)
        if typed_stage.is_a?(Symbol)
          return [typed_stage,
           Stage.new(
            harmonized_code: HarmonizedStageCode.new(self.class::TYPED_STAGES[typed_stage][:harmonized_stages])),
          ]
        end

        typed_stage = self.class::TYPED_STAGES.find do |_, v|
          if v[:abbr].is_a?(Hash)
            v[:abbr].value?(typed_stage)
          else
            if v.key?(:legacy_abbr)
              v[:legacy_abbr].include?(typed_stage) || v[:abbr] == typed_stage
            else
              v[:abbr] == typed_stage
            end
            #
            # v[:abbr] == typed_stage
          end
        end

        [typed_stage.first,
         Stage.new(harmonized_code: HarmonizedStageCode.new(typed_stage[1][:harmonized_stages]))]
      end

      # Resolve typed stage using stage harmonized stage code
      # @param harmonized_code [HarmonizedStageCode]
      # @return [Symbol, nil] typed stage or nil
      def resolve_typed_stage(harmonized_code)
        self.class::TYPED_STAGES.each do |k, v|
          if (v[:harmonized_stages] & harmonized_code.stages) == harmonized_code.stages
            return k
          end
        end
        nil
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
        def create(**opts)
          resolve_identifier(opts[:type], opts[:stage],
                             opts.reject { |k, _v| [:type, :stage].include?(k) })
        end

        def supplements_has_type?(supplements, type)
          supplements.any? do |supplement|
            supplement.type[:key] == type
          end
        end

        def supplement_by_type(supplements, type)
          supplements.select { |supplement| supplement.type[:key] == type }.first
        end

        def transform_supplements(supplements_params, base_params)
          supplements = supplements_params.map do |supplement|
            create(number: supplement[:number], year: supplement[:year],
                stage: supplement[:typed_stage], edition: supplement[:edition],
                iteration: supplement[:iteration], type: (supplement[:type] || !supplement[:typed_stage] && :sup),
                publisher: supplement[:publisher], base: create(**base_params))
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
            get_transformer_class.new.apply(k => v)
          end.inject({}, :merge)

          # return supplement if supplements applied
          if identifier_params[:supplements]
            return transform_supplements(
              identifier_params[:supplements],
              identifier_params.dup.tap { |h| h.delete(:supplements) }
            )
          end

          create(**identifier_params)
        end

        def descendants
          ObjectSpace.each_object(Class).select { |klass| klass < self }
        end

        # @param type [Symbol] eg. :tr, :ts
        # @return [Boolean] true if provided type matches with identifier's class type
        def has_type?(type)
          type.to_s.downcase.to_sym == self.type[:key]
        end

        # @param typed_stage [String, Symbol] typed stage, eg. "DTR" or :dtr
        # @return [Boolean] true when identifier has associated typed stage
        def has_typed_stage?(typed_stage)
          return self::TYPED_STAGES.key?(typed_stage) if typed_stage.is_a?(Symbol)

          self::TYPED_STAGES.any? do |_, v|
            if v[:abbr].is_a?(Hash)
              v[:abbr].value?(typed_stage)
            else
              if v.key?(:legacy_abbr)
                v[:legacy_abbr].include?(typed_stage) || v[:abbr] == typed_stage
              else
                v[:abbr] == typed_stage
              end
            end
          end
        end

        # @param typed_stage_or_stage [String] typed stage or stage
        # @return identifier's class
        def resolve_identifier(type, typed_stage_or_stage, parameters = {})
          return Identifier::InternationalStandard.new(**parameters) if type.nil? && typed_stage_or_stage.nil?

          descendants.each do |identifier_type|
            if type
              return identifier_type.new(stage: typed_stage_or_stage, **parameters) if identifier_type.has_type?(type)

              next
            elsif identifier_type.has_typed_stage?(typed_stage_or_stage)
              return identifier_type.new(stage: typed_stage_or_stage, **parameters)
            end
          end

          # When stage is not typed stage and type is not defined
          if type.nil? && Stage.has_stage?(typed_stage_or_stage)
            return Identifier::InternationalStandard.new(stage: typed_stage_or_stage, **parameters)
          end

          raise Errors::TypeStageParseError, "cannot parse typed stage or stage '#{typed_stage_or_stage}'" if type.nil?

          raise Errors::ParseTypeError, "cannot parse type #{type}"
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
        ((@tctype && Renderer::UrnTc) || Pubid::Iso::Renderer::Urn).new(
          get_params.merge({ type: type[:key] }),
        ).render + (language ? ":#{language}" : "")
      end

      def get_params
        instance_variables.map do |var|
          if var.to_s == "@typed_stage" && @typed_stage
            [:typed_stage, self.class::TYPED_STAGES[@typed_stage][:abbr]]
          else
            [var.to_s.gsub("@", "").to_sym, instance_variable_get(var)]
          end
        end.to_h
      end

      # @param format [:ref_num_short,:ref_num_long,:ref_dated,:ref_dated_long,:ref_undated,:ref_undated_long] create reference with specified format
      # Format options are:
      #   :ref_num_short -- instance reference number: 1 letter language code + short form (DAM) + dated
      #   :ref_num_long -- instance reference number long: 2 letter language code + long form (DAmd) + dated
      #   :ref_dated -- reference dated: no language code + short form (DAM) + dated
      #   :ref_dated_long -- reference dated long: no language code + short form (DAM) + dated
      #   :ref_undated -- reference undated: no language code + short form (DAM) + undated
      #   :ref_undated_long -- reference undated long: 1 letter language code + long form (DAmd) + undated
      def resolve_format(format = :ref_dated_long)
        options = { with_date: true }
        case format
        when :ref_num_short
          options[:with_language_code] = :single
          options[:stage_format_long] = false
        when :ref_num_long
          options[:with_language_code] = :iso
          options[:stage_format_long] = true
        when :ref_dated
          options[:with_language_code] = :none
          options[:stage_format_long] = false
        when :ref_dated_long
          options[:with_language_code] = :none
          options[:stage_format_long] = true
        when :ref_undated
          options[:with_language_code] = :none
          options[:stage_format_long] = false
          options[:with_date] = false
        when :ref_undated_long
          options[:with_language_code] = :none
          options[:stage_format_long] = true
          options[:with_date] = false
        else
          raise Errors::WrongFormat, "#{format} is not available"
        end
        options
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
      def to_s(lang: nil, with_edition: false, with_prf: false,
               format: :ref_dated_long)

        options = resolve_format(format)
        options[:with_edition] = with_edition
        options[:with_prf] = with_prf
        options[:language] = lang

        self.class.get_renderer_class.new(get_params).render(**options) +
          if @joint_document
            render_joint_document(@joint_document)
          end.to_s
      end

      def render_joint_document(joint_document)
        "|#{@joint_document}"
      end

      # Return typed stage abbreviation, eg. "FDTR", "DIS", "TR"
      def typed_stage_abbrev
        if self.class::TYPED_STAGES.key?(typed_stage)
          self.class::TYPED_STAGES[typed_stage][:abbr]
        else
          "#{stage.abbr} #{type[:key].to_s.upcase}"
        end
      end

      # Return typed stage name, eg. "Final Draft Technical Report" for "FDTR"
      def typed_stage_name
        if self.class::TYPED_STAGES.key?(typed_stage)
          self.class::TYPED_STAGES[typed_stage][:name]
        else
          "#{stage.name} #{type[:title]}"
        end
      end

      def ==(other)
        get_params == other.get_params
      end
    end
  end
end
