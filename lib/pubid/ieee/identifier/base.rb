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
                    :iteration, :includes

      def initialize(publisher: "IEEE", number: nil, stage: nil, subpart: nil, edition: nil,
                     draft: nil, redline: nil, month: nil, revision: nil,
                     iso_identifier: nil, type: :std, alternative: nil,
                     draft_status: nil, adoption_year: nil,
                     amendment: nil, supersedes: nil, corrigendum: nil,
                     corrigendum_comment: nil, reaffirmed: nil,
                     incorporates: nil, supplement: nil, proposal: nil,
                     iso_amendment: nil, iteration: nil, includes: nil, **opts)

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
        raise Pubid::Ieee::Errors::ParseError, "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
      end

      def self.transform(params)
        identifier_params = params.map do |k, v|
          get_transformer_class.new.apply(k => v)
        end.inject({}, :merge)

        Identifier.create(**Identifier.convert_parser_parameters(**identifier_params))
      end

      def self.get_transformer_class
        Transformer
      end

      # @param [:short, :full] format
      def to_s(format = :short, with_trademark: false)
        if @iso_identifier
          "#{@iso_identifier.to_s(format: :ref_num_short)}#{iso_amendment}#{dual_identifier}"
        else
          "#{identifier(format)}#{with_trademark ? trademark(@number) : ''}#{parameters}#{adoption}"
        end
      end

      def trademark(number)
        %w(802 2030).include?(number.to_s) ? "\u00AE" : "\u2122"
      end

      def iso_amendment

      end

      def dual_identifier
        @number ? " (#{identifier})#{parameters}" : "#{identifier}#{parameters}"
      end

      def publisher
        "#{@publisher}#{copublisher}" if @publisher && @number
      end

      def identifier(format = :short)
        "#{publisher}#{stage}#{draft_status(format)}#{type(format)}#{number}#{iteration}#{part}"\
          "#{subpart}#{year}#{revision_date}"
      end

      def number
        return "" unless @number

        " #{@number}"
      end

      def stage
        return "" unless @stage

        (@copublisher ? " ": "/") + @stage
      end

      def iteration
        return "" unless @iteration

        ".#{@iteration}"
      end

      def parameters
        "#{corrigendum}#{draft}#{edition}#{alternative}#{supersedes}"\
        "#{reaffirmed}#{incorporates}#{supplement}#{revision}#{amendment}#{includes}#{redline}"
      end

      def copublisher
        return "" unless @copublisher

        if @copublisher.is_a?(Array)
          @copublisher&.map { |c| "/#{c}" }&.join
        else
          "/#{@copublisher}"
        end
      end

      def part
        "#{@part}" if @part
      end

      def subpart
        @subpart if @subpart && !@subpart.to_s.empty?
      end

      def ieee_format?
        (@publisher == "IEEE")# || @copublisher == "IEEE" || (@copublisher.is_a?(Array) && @copublisher.include?("IEEE")))
      end

      def type(format)
        return unless @type

        result = @type.to_s(ieee_format?  ? format : :alternative)
        result.empty? ? result : " #{result}"
      end

      def year
        return "" if @month
        return "" unless @year

        if @corrigendum_comment
          @corrigendum_comment.year
        elsif @reaffirmed && @reaffirmed.key?(:reaffirmation_of)
          @reaffirmed[:reaffirmation_of].year
        else
          "-#{@year}"
        end
      end

      def alternative
        if @alternative
          if @alternative.is_a?(Array)
            " (#{@alternative.map { |a| self.class.new(**Identifier.convert_parser_parameters(**a)) }.join(', ')})"
          else
            " (#{self.class.new(**Identifier.convert_parser_parameters(**@alternative))})"
          end
        end
      end

      def edition
        return "" unless @edition

        result = ""
        if @edition[:version]
          result += @edition[:version] == "First" ? " Edition 1.0 " : " Edition #{@edition[:version]} "
        end

        if @edition[:year]
          result += if @edition[:version]
                      "#{@edition[:year]}"
                    else
                      " #{@edition[:year]} Edition"
                    end
        end

        if @edition[:month]
          month = @edition[:month]
          month = Date.parse(@edition[:month]).month if month.to_i.zero?
          result += "-#{sprintf('%02d', month)}"
        end
        result += "-#{@edition[:day]}" if @edition[:day]
        result
      end

      def draft
        return "" unless @draft

        @draft = Identifier.merge_parameters(@draft) if @draft.is_a?(Array)

        result = "/D#{@draft[:version].is_a?(Array) ? @draft[:version].join('D') : @draft[:version]}"
        result += ".#{@draft[:revision]}" if @draft[:revision]
        result += ", #{@draft[:month]}" if @draft[:month]
        result += " #{@draft[:day]}," if @draft[:day]
        result += " #{@draft[:year]}" if @draft[:year]
        result
      end

      def draft_status(format)
        " #{@draft_status}" if @draft_status && format == :full
      end

      def revision
        " (Revision of #{@revision.join(' and ')})" if @revision
      end

      def includes
        return "" unless @includes

        if @includes.is_a?(Hash) && @includes[:supplement]
          return " (Includes Supplement #{@includes[:supplement]})"
        end

        " (Includes #{@includes})"
      end

      def revision_date
        return nil unless @month
        ", #{@month} #{@year}"
      end

      def amendment
        return unless @amendment || @iso_amendment

        if @iso_amendment
          if @iso_amendment[:year]
            return "/Amd#{@iso_amendment[:version]}-#{@iso_amendment[:year]}"
          else
            return "/Amd#{@iso_amendment[:version]}"
          end
        end

        return " (Amendment to #{@amendment})" unless @amendment.is_a?(Array)

        result = " (Amendment to #{@amendment.first} as amended by "
        result += if @amendment.length > 2
                    "#{@amendment[1..-2].map(&:to_s).join(', ')}, and #{@amendment[-1]}"
                  else
                    @amendment.last.to_s
                  end

        "#{result})"
      end

      def redline
        " - Redline" if @redline
      end

      def adoption
        if @adoption_year
          adoption_id = dup
          adoption_id.year = @adoption_year
          " (Adoption of #{adoption_id.identifier})"
        end
      end

      def supersedes
        return unless @supersedes

        if @supersedes.length > 2
          " (Supersedes #{@supersedes.join(', ')})"
        else
          " (Supersedes #{@supersedes.join(' and ')})"
        end
      end

      def corrigendum
        if @corrigendum.nil?
          (@year && @corrigendum_comment && "/Cor 1-#{@year}") || ""
        else
          if @corrigendum[:year]
            "/Cor #{@corrigendum[:version]}-#{@corrigendum[:year]}"
          else
            "/Cor #{@corrigendum[:version]}"
          end
        end
      end

      def reaffirmed
        return unless @reaffirmed

        return " (Reaffirmed #{@year})" if @reaffirmed.key?(:reaffirmation_of)

        " (Reaffirmed #{@reaffirmed[:year]})" if @reaffirmed[:year]
      end

      def incorporates
        # " (Supersedes #{@supersedes.join(', ')})"

        " (Incorporates #{@incorporates.join(', and ')})" if @incorporates
      end

      def supplement
        " (Supplement to #{@supplement})" if @supplement
      end
    end
  end
end
