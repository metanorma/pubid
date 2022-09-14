module Pubid::Iso
  class Supplement < Pubid::Core::Supplement
    attr_accessor :stage, :publisher, :edition, :iteration

    # @param stage [Stage] stage, e.g. "PWI", "NP"
    # @param publisher [String] publisher, e.g. "ISO", "IEC"
    # @param edition [Integer] edition, e.g. 1, 2, 3
    # @param iteration [Integer] iteration, e.g. 1, 2, 3
    # @see Pubid::Core::Supplement for other options
    def initialize(stage: nil, publisher: nil, edition: nil, iteration: nil, **args)
      super(**args)
      @stage = stage
      @publisher = publisher.to_s
      @edition = edition&.to_i
      @iteration = iteration&.to_i

      if @iteration && @stage.nil?
        raise Errors::PublishedIterationError.new("cannot assign iteration to published supplement")
      end
    end

    def render_pubid_stage
      ((@stage && @stage.abbr != "IS" && @stage.abbr) || "")
    end

    def render_urn_stage
      ((@stage && ":stage-#{@stage.harmonized_code}") || "")
    end

    def <=>(other)
      (super == 0) && ((stage.nil? || stage == other.stage) && 0 || -1) || super
    end

    def render_iteration
      @iteration && ".#{@iteration}"
    end

    def render_pubid_number(with_date: true)
      if @year && with_date
        "#{@number}#{render_iteration}:#{@year}"
      else
        "#{@number}#{render_iteration}"
      end
    end

    def render_urn_number
      if @year
        ":#{@year}:v#{@number}#{render_iteration}"
      else
        ":#{@number}#{render_iteration}:v1"
      end
    end
  end
end
