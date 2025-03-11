require 'forwardable'
require_relative "../renderer/urn"
require_relative "../renderer/urn-tc"

module Pubid::Iso
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      extend Forwardable

      attr_accessor :stage,
                    :iteration, :joint_document,
                    :tctype, :sctype, :wgtype, :tcnumber, :scnumber, :wgnumber,
                    :dirtype,
                    :base,
                    :supplements,
                    :addendum,
                    :jtc_dir,
                    :month

      # Creates new identifier from options provided, includes options from
      # Pubid::Core::Identifier#initialize
      #
      # @param stage [Stage, Symbol, String] stage or typed stage, e.g. "PWI", "NP", "50.00", Stage.new(abbr: :WD), "DTR"
      # @param iteration [Integer] document iteration, eg. "1", "2", "3"
      # @param joint_document [Identifier, Hash] joint document
      # @param supplements [Array<Supplement>] supplements
      # @param tctype [String] Technical Committee type, eg. "TC", "JTC"
      # @param sctype [String] TC subsommittee, eg. "SC"
      # @param wgtype [String] TC working group type, eg. "AG", "AHG"
      # @param tcnumber [Integer] Technical Committee number, eg. "1", "2"
      # @param scnumber [Integer] Subsommittee number, eg. "1", "2"
      # @param wgnumber [Integer] Working group number, eg. "1", "2"
      # @param dirtype [String] Directives document type, eg. "JTC"
      # @param base [Identifier, Hash] base document for supplement's identifier
      # @param type [nil, :tr, :ts, :amd, :cor, :guide, :dir, :tc, Type] document's type, eg. :tr, :ts, :amd, :cor, Type.new(:tr)
      # @param jtc_dir [String] String to indicate "JTC 1 Directives" identifier
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
      def initialize(publisher: "ISO", number: nil, stage: nil, iteration: nil,
                     joint_document: nil, tctype: nil, sctype: nil, wgtype: nil, tcnumber: nil,
                     scnumber: nil, wgnumber:nil,
                     dir: nil, dirtype: nil, year: nil, amendments: nil,
                     corrigendums: nil, type: nil, base: nil, supplements: nil,
                     part: nil, addendum: nil, edition: nil, jtc_dir: nil, month: nil, **opts)
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
          @stage = resolve_stage(stage)
        elsif iteration && !is_a?(Supplement)
          raise Errors::IterationWithoutStageError, "Document without stage cannot have iteration"
        end

        @iteration = iteration.to_i if iteration
        if joint_document
          if joint_document.is_a?(Hash)
            @joint_document = Identifier.create(**joint_document)
          else
            @joint_document = joint_document
          end
        end
        if tctype
          @tctype = tctype.is_a?(Array) ? tctype.map(&:to_s) : tctype.to_s
        end
        @sctype = sctype.to_s if sctype
        @wgtype = wgtype.to_s if wgtype
        @tcnumber = tcnumber.to_s if tcnumber
        @scnumber = scnumber.to_s if scnumber
        @wgnumber = wgnumber.to_s if wgnumber
        @dir = dir.to_s if dir
        @dirtype = dirtype.to_s if dirtype
        if jtc_dir
          @jtc_dir = jtc_dir
        end
        if base
          if base.is_a?(Hash)
            @base = Identifier.create(**base)
          else
            @base = base
          end
        end
        @part = part.to_s if part
        @addendum = addendum if addendum
        @edition = edition
        @month = month
      end

      class << self
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
            Identifier.create(number: supplement[:number], year: supplement[:year],
                month: supplement[:month],
                stage: supplement[:typed_stage], edition: supplement[:edition],
                iteration: supplement[:iteration], type: (supplement[:type] || !supplement[:typed_stage] && :sup),
                publisher: supplement[:publisher], base: Identifier.create(**base_params))
          end

          return supplements.first if supplements.count == 1

          # update corrigendum base to amendment
          if supplements_has_type?(supplements, :cor) &&
              (supplements_has_type?(supplements, :amd) ||
                supplements_has_type?(supplements, :sup)) && supplements.count == 2

            supplement = supplement_by_type(supplements, :cor)
            supplement.base = supplement_by_type(supplements, :amd) ||
              supplement_by_type(supplements, :sup)
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
          if identifier_params[:supplements] && identifier_params[:supplements].is_a?(Array)
            return transform_supplements(
              identifier_params[:supplements],
              identifier_params.dup.tap { |h| h.delete(:supplements) }
            )
          end

          if identifier_params[:extract]
            base_parameters = params.reject { |k, _| k == :extract }

            return Identifier.create(base: Identifier.create(**base_parameters),
                                     type: :ext, **identifier_params[:extract])
          end

          Identifier.create(**identifier_params)
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

        def get_update_codes
          UPDATE_CODES
        end

        def get_identifier
          Identifier
        end

        def type_match?(parameters)
          parameters[:type] ? has_type?(parameters[:type]) : has_typed_stage?(parameters[:stage])
        end
      end

      # Render URN identifier
      # @return [String] URN identifier
      def urn
        ((@tctype && Renderer::UrnTc) || Pubid::Iso::Renderer::Urn).new(
          to_h(deep: false).merge({ type: type[:key] }),
        ).render + (language ? ":#{language}" : "")
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

        self.class.get_renderer_class.new(to_h(deep: false)).render(**options) +
          if @joint_document
            render_joint_document(@joint_document)
          end.to_s
      end

      def render_joint_document(joint_document)
        "|#{@joint_document}"
      end

      # Return typed stage abbreviation, eg. "FDTR", "DIS", "TR"
      # returns root identifier
      def root
        return base.base if base&.base

        base || self
      end
    end
  end
end
