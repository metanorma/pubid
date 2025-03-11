module Pubid::Iso
  module Identifier
    class << self
      include Pubid::Core::Identifier

      def parse(*args)
        Base.parse(*args)
      end

      def parse_from_title(title)
        title.split.reverse.inject(title) do |acc, part|
          return Base.parse(acc)
        rescue Pubid::Core::Errors::ParseError
          # delete parts from the title until it's parseable
          acc.reverse.sub(part.reverse, "").reverse.strip
        end

        raise Errors::ParseError, "cannot parse #{title}"
      end
    end
  end
end
