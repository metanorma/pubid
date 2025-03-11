require 'date'
require "yaml"

module Pubid::Ieee
  UPDATE_CODES = YAML.load_file(File.join(File.dirname(__FILE__), "../../../../update_codes.yaml"))

  module Identifier
    class Base < Pubid::Core::Identifier::Base
      attr_accessor :subpart, :edition, :draft, :redline, :month, :alternative,
                    :draft_status, :revision, :adoption_year, :amendment, :supersedes,
                    :corrigendum, :corrigendum_comment, :reaffirmed, :incorporates,
                    :supplement, :proposal, :iso_identifier, :iso_amendment,
                    :iteration, :includes, :adoption, :day

      def initialize(publisher: "IEEE", number: nil, stage: nil, subpart: nil, edition: nil,
                     draft: nil, redline: nil, month: nil, revision: nil,
                     iso_identifier: nil, type: :std, alternative: nil,
                     draft_status: nil, adoption_year: nil,
                     amendment: nil, supersedes: nil, corrigendum: nil,
                     corrigendum_comment: nil, reaffirmed: nil,
                     incorporates: nil, supplement: nil, proposal: nil,
                     iso_amendment: nil, iteration: nil, includes: nil, adoption: nil,
                     year: nil, day: nil, **opts)

        super(**opts.merge(number: number, publisher: publisher))#.merge(amendments: amendments, corrigendums: corrigendums))

        @edition = edition if edition

        @proposal = @number.to_s[0] == "P"
        @revision = revision
        if iso_identifier
          @iso_identifier = Pubid::Iso::Identifier.parse(iso_identifier)
        elsif draft# && type != :p
          @type = Type.new(:draft)
        elsif type
          if type.is_a?(Symbol)
            @type = Type.new(type)
          else
            @type = Type.parse(type)
          end
        else
          @type = Type.new
        end

        @stage = stage
        @subpart = subpart
        @draft = draft
        @redline = redline
        @month = month
        @revision = revision
        @amendment = amendment
        @corrigendum = corrigendum
        @corrigendum_comment = corrigendum_comment
        @alternative = alternative
        @draft_status = draft_status
        @adoption_year = adoption_year
        @supersedes = supersedes
        @reaffirmed = reaffirmed
        @incorporates = incorporates
        @supplement = supplement
        @proposal = proposal
        @iso_amendment = iso_amendment
        @iteration = iteration
        @includes = includes
        @adoption = adoption
        @year = year.is_a?(Array) ? year.first.to_i : year.to_i if year
        @day = day.to_i if day
      end

      def self.type
        { key: :std, title: "Standard" }
      end

      # convert parameters comes from parser to
      def set_values(hash)
        hash.each { |key, value| send("#{key}=", value.is_a?(Parslet::Slice) && value.to_s || value) }
      end

      def self.add_missing_bracket(code)
        code.count("(") > code.count(")") ? "#{code})" : code
      end

      def self.update_old_code(code)
        UPDATE_CODES.each do |from, to|
          code = code.gsub(from.match?(/^\/.*\/$/) ? Regexp.new(from[1..-2]) : /^#{Regexp.escape(from)}$/, to)
        end
        code
      end


      def self.transform_parameters(params)
        return params if params == ""

        if params[:iso_identifier]
          if params[:iso_identifier].is_a?(Array)
            params[:iso_identifier] = array_to_hash(params[:iso_identifier])
          end

          if params[:iso_identifier][:month]
            params[:month] = params[:iso_identifier][:month]
            params[:year] = params[:iso_identifier][:year]
            params[:iso_identifier].delete(:year)
            params[:iso_identifier].delete(:month)
          end
        end

        params.map do |k, v|
          case k
          when :parameters, :draft, :alternative
            v = Identifier.merge_parameters(v) if k == :draft
            # apply transformer for each separate item when array provided
            if v.is_a?(Array)
              get_transformer_class.new.apply(k => v.map { |vv| transform_parameters(vv) })
            else
              get_transformer_class.new.apply(k => transform_parameters(v))
            end
          when :iso_identifier
            v = Identifier.merge_parameters(v)
            result = get_transformer_class.new.apply(k => v)
            # apply transformation when output was transformed to IEEE
            result.key?(:iso_identifier) ? result : transform_parameters(result)
          else
            get_transformer_class.new.apply(k => v)
          end
        end.inject({}, :merge)
      end

      def self.transform(params)
        # transform inside parameters

        identifier_params = transform_parameters(
          Identifier.convert_parser_parameters(**params),
        )

        if identifier_params.key?(:draft) && identifier_params[:draft].key?(:year)
          identifier_params[:year] = identifier_params[:draft][:year]
          identifier_params[:month] = identifier_params[:draft][:month]
          identifier_params[:day] = identifier_params[:draft][:day]
          identifier_params[:draft].delete(:year)
          identifier_params[:draft].delete(:month)
        end

        Identifier.create(**identifier_params)
      end

      # @param [:short, :full] format
      def to_s(format = :short, with_trademark: false)
        opts = { format: format, with_trademark: with_trademark }
        (@iso_identifier ? @iso_identifier.to_s(format: :ref_num_short, with_edition: true) : "") +
          self.class.get_renderer_class.new(to_h(deep: false)).render(**opts) +
          (with_trademark ? trademark(@number) : "")
      end

      def trademark(number)
        %w(802 2030).include?(number.to_s) ? "\u00AE" : "\u2122"
      end

      class << self
        def get_renderer_class
          Renderer::Base
        end

        def get_transformer_class
          Transformer
        end

        def get_parser_class
          Parser
        end
      end
    end
  end
end
