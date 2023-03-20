module Pubid::Core
  class Configuration
    attr_accessor :stages, :default_type, :type_class, :types, :type_names, :stage_class

    def initialize
      @type_class = Pubid::Core::Type
      @stage_class = Pubid::Core::Stage
    end
  end
end
