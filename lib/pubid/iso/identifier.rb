module Pubid::Iso
  class Identifier

    attr_accessor :number, :publisher, :copublisher, :stage, :substage, :part,
                  :type, :year, :edition, :iteration, :supplements, :language,
                  :amendment, :amendment_version, :amendment_number,
                  :corrigendum, :corrigendum_version, :corrigendum_number,
                  :amendment_stage, :corrigendum_stage

    def initialize(**opts)
      opts.each { |key, value| send("#{key}=", value.is_a?(Array) && value || value.to_s) }
    end

    def urn
      URN.new(self)
    end

    def pubid
      params = instance_variables.map { |var| [var.to_s.gsub("@", "").to_sym, instance_variable_get(var)] }.to_h
      PubID.new(**params)
    end

    def self.parse(code)
      new(**Parser.new.parse(code).map do |k, v|
        Transformer.new.apply(k => v).to_a.first
      end.to_h)
    rescue Parslet::ParseFailed => failure
      raise Pubid::Iso::Errors::ParseError, "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
    end
  end
end
