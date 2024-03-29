module Pubid
  class Registry
    class << self
      def parse(*args)
        modules = [Pubid::Iso,
                   Pubid::Ieee,
                   Pubid::Nist,
                   Pubid::Iec,
                   Pubid::Cen,
                   Pubid::Bsi,
                   Pubid::Ccsds,
                   Pubid::Itu,
                   Pubid::Jis]
        modules.each do |mod|
          module_identifier = Kernel.const_get("#{mod}::Identifier")
          return module_identifier.parse(*args) if module_identifier.parseable?(*args)
        end

        # Go through each module to try to parse unknown prefix
        modules.each do |mod|
          return Kernel.const_get("#{mod}::Identifier").parse(*args)
        rescue Pubid::Core::Errors::ParseError
          next
        end

        raise Pubid::Core::Errors::ParseError, "cannot find module to parse #{args}"
      end
    end
  end
end
