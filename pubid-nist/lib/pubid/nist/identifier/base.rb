# frozen_string_literal: true

require "json"
require "forwardable"

UPDATE_CODES = YAML.load_file(File.join(File.dirname(__FILE__), "../../../../update_codes.yaml"))

module Pubid::Nist
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      extend Forwardable
      attr_accessor :series, :code, :revision, :publisher, :version, :volume,
                    :part, :addendum, :stage, :translation,
                    :edition, :supplement, :update,
                    :section, :appendix, :errata, :index, :insert

      def initialize(publisher: "NIST", series:, number: nil, stage: nil, supplement: nil,
                     edition_month: nil, edition_year: nil, edition_day: nil, update: nil,
                     edition: nil, **opts)
        @publisher = publisher.is_a?(Publisher) ? publisher : Publisher.new(publisher: publisher.to_s)
        @series = series.is_a?(Series) ? series : Series.new(series: series)
        @code = number
        @stage = Stage.new(**stage) if stage
        @supplement = (supplement.is_a?(Array) && "") || supplement
        if edition_month || edition_year
          @edition = parse_edition(edition_month, edition_year, edition_day)
        elsif edition
          @edition = Edition.new(number: edition)
        end
        @update = update
        opts.each { |key, value| send("#{key}=", value.to_s) }
      end

      def parse_edition(edition_month, edition_year, edition_day)
        if edition_month
          date = Date.parse("#{edition_day || '01'}/#{edition_month}/#{edition_year}")
          if edition_day
            Edition.new(month: date.month, year: date.year, day: date.day)
          else
            Edition.new(month: date.month, year: date.year)
          end
        else
          Edition.new(year: edition_year.to_i)
        end
      end

      # returns weight based on amount of defined attributes
      def weight
        instance_variables.inject(0) do |sum, var|
          sum + (instance_variable_get(var).nil? ? 0 : 1)
        end
      end

      def ==(other)
        other.instance_variables.each do |var|
          return false if instance_variable_get(var) != other.instance_variable_get(var)
        end
        true
      end

      def merge(document)
        document.instance_variables.each do |var|
          val = document.instance_variable_get(var)
          current_val = instance_variable_get(var)
          if [:@series, :@publisher].include?(var) ||
              (val && current_val.nil?) ||
              (val && current_val.to_s.length < val.to_s.length)
            instance_variable_set(var, val)
          end
        end

        self
      end

      def self.update_old_code(code)
        UPDATE_CODES.map {|k ,v| k.match?(/^\/.*\/$/) ? [[k, v], [k.gsub(" ", "\."), v]] : [[k, v], [k.gsub(" ", "."), v]] }
                    .inject([]) { |a, v| a + v}.each do |from, to|
          code = code.gsub(from.match?(/^\/.*\/$/) ? Regexp.new(from[1..-2]) : from, to)
        end
        code
      end

      # @param without_edition [Boolean] render pubid without rendering edition
      def to_s(format = :short, without_edition: false)
        self.class.get_renderer_class.new(to_h(deep: false)).render(format: format, without_edition: without_edition)
      end

      def to_json(*args)
        result = {
          styles: {
            short: to_s(:short),
            abbrev: to_s(:abbrev),
            long: to_s(:long),
            mr: to_s(:mr),
          }
        }

        instance_variables.each do |var|
          val = instance_variable_get(var)
          result[var.to_s.gsub('@', '')] = val unless val.nil?
        end
        result.to_json(*args)
      end

      class << self
        def create(**opts)
          new(**opts)
        end

        def transform(params)
          # run transform through each element,
          # like running transformer.apply(number: 1) and transformer.apply(year: 1999)
          # instead of running transformer on whole hash, like running transformer.apply({ number: 1, year: 1999 })
          # where rule for number or year only will be not applied
          # transformation only applied to rules matching the whole hash

          identifier_params = params.map do |k, v|
            get_transformer_class.new.apply({ k => v }, params)
          end.inject({}, :merge)

          if identifier_params[:addendum]
            return Addendum.new(base: new(
              **identifier_params.dup.tap { |h| h.delete(:addendum) }
            ), **identifier_params[:addendum])
          end

          new(**identifier_params)
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
    end
  end
end
