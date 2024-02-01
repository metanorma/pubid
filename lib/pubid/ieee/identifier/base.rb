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
                    :iteration, :includes, :adoption

      def initialize(publisher: "IEEE", number: nil, stage: nil, subpart: nil, edition: nil,
                     draft: nil, redline: nil, month: nil, revision: nil,
                     iso_identifier: nil, type: :std, alternative: nil,
                     draft_status: nil, adoption_year: nil,
                     amendment: nil, supersedes: nil, corrigendum: nil,
                     corrigendum_comment: nil, reaffirmed: nil,
                     incorporates: nil, supplement: nil, proposal: nil,
                     iso_amendment: nil, iteration: nil, includes: nil, adoption: nil, **opts)

        super(**opts.merge(number: number, publisher: publisher))#.merge(amendments: amendments, corrigendums: corrigendums))

        if edition
          @edition = edition.update(edition) do |key, value|
            case key
            when :year, :month
              value.to_i
            else
              value
            end
          end
        end

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


      def self.parse(code)
        parsed = Parser.new.parse(update_old_code(code))
        transform(parsed)

      rescue Parslet::ParseFailed => failure
        raise Pubid::Core::Errors::ParseError, "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
      end

      def self.transform(params)
        identifier_params = params.map do |k, v|
          get_transformer_class.new.apply(k => v)
        end.inject({}, :merge)

        Identifier.create(**Identifier.convert_parser_parameters(**identifier_params))
      end

      # @param [:short, :full] format
      def to_s(format = :short, with_trademark: false)
        opts = { format: format, with_trademark: with_trademark }
        (@iso_identifier ? @iso_identifier.to_s(format: :ref_num_short) : "") +
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
      end
    end
  end
end
