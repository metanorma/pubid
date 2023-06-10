module Pubid::Ieee
  module Identifier
    class << self
      include Pubid::Core::Identifier

      def parse(*args)
        Base.parse(*args)
      end

      def convert_parser_parameters(type_status: nil, parameters: nil,
                                         organizations: { publisher: "IEEE" }, **args)
        res = [organizations, type_status, parameters].inject({}) do |result, data|
          result.merge(
            case data
            when Hash
              data.transform_values do |v|
                (v.is_a?(Array) && v.first.is_a?(Hash) && merge_parameters(v)) || v
              end
            when Array
              merge_parameters(data)
            else
              {}
            end
          )
        end
        res.merge(args)
      end

      def merge_parameters(params)
        return params unless params.is_a?(Array)

        result = {}
        params.each do |item|
          item.each do |key, value|
            if result.key?(key)
              result[key] = result[key].is_a?(Array) ? result[key] << value : [result[key], value]
            else
              result[key] = value
            end
          end
        end
        result
      end

      def has_stage?(stage)
        Pubid::Iso::Identifier.has_stage?(stage)
      end
    end
  end
end
