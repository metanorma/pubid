module Pubid::Iso
  class Supplement < Pubid::Core::Supplement
    attr_accessor :stage, :publisher, :edition, :iteration

    def initialize(stage: nil, publisher: nil, edition: nil, iteration: nil, **args)
      super(**args)
      @stage = stage
      @publisher = publisher.to_s
      @edition = edition
      @iteration = iteration
    end

    def render_pubid_stage
      ((@stage && @stage) || "")
    end

    def render_urn_stage
      ((@stage && ":stage-#{sprintf('%05.2f', Pubid::Iso::Renderer::Urn::STAGES[@stage.to_sym])}") || "")
    end

    def <=>(other)
      (super == 0) && ((stage.nil? || stage == other.stage) && 0 || -1) || super
    end

    def render_iteration
      @iteration && ".#{@iteration}"
    end

    def render_pubid_number
      if @year
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
