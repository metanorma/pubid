module Pubid::Core
  class Identifier
    attr_accessor :number, :publisher, :copublisher, :part,
                  :type, :year, :edition, :language, :amendments,
                  :corrigendums

    def initialize(amendments: nil, corrigendums: nil, **opts)
      if amendments
        @amendments = if amendments.is_a?(Array)
                        amendments.map do |amendment|
                          self.class.get_amendment_class.new(**amendment)
                        end
                      else
                        [self.class.get_amendment_class.new(**amendments)]
                      end
      end
      if corrigendums
        @corrigendums = if corrigendums.is_a?(Array)
                          corrigendums.map do |corrigendum|
                            self.class.get_corrigendum_class.new(**corrigendum)
                          end
                        else
                          [self.class.get_corrigendum_class.new(**corrigendums)]
                        end
      end

      opts.each { |key, value| send("#{key}=", value.is_a?(Parslet::Slice) && value.to_s || value) }
    end

    def urn
      Renderer::Urn.new(get_params).render
    end

    def get_params
      instance_variables.map { |var| [var.to_s.gsub("@", "").to_sym, instance_variable_get(var)] }.to_h
    end

    def to_s
      self.class.get_renderer_class.new(get_params).render
    end

    class << self
      def get_amendment_class
        Amendment
      end

      def get_corrigendum_class
        Corrigendum
      end

      def get_renderer_class
        Renderer::Base
      end

      def get_transformer_class
        Transformer
      end

      def parse(code_or_params)
        params = code_or_params.is_a?(String) ? get_parser_class.new.parse(code_or_params) : code_or_params
        # Parslet returns an array when match any copublisher
        # otherwise it's hash
        if params.is_a?(Array)
          new(
            **(
              params.inject({}) do |r, i|
                result = r
                i.map {|k, v| get_transformer_class.new.apply(k => v).to_a.first }.each do |k, v|
                  result = result.merge(k => r.key?(k) ? [v, r[k]] : v)
                end
                result
              end
            )
          )
        else
          new(**params.map do |k, v|
            get_transformer_class.new.apply(k => v).to_a.first
          end.to_h)
        end
        # merge values repeating keys into array (for copublishers)

      rescue Parslet::ParseFailed => failure
        raise Errors::ParseError, "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
      end
    end
  end
end
