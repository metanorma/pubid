module Pubid::Iso
  class Supplement < Pubid::Core::Supplement
    attr_accessor :stage, :publisher

    def initialize(stage: nil, version: nil, publisher: nil, **args)
      super(version: version, **args)
      @stage = stage
      @publisher = publisher
    end

    def render_pubid_stage
      ((@stage && @stage) || "")
    end

    def render_urn_stage
      ((@stage && ":stage-#{sprintf('%05.2f', Pubid::Core::Renderer::Urn::STAGES[@stage.to_sym])}") || "")
    end

    def <=>(other)
      (super == 0) && ((stage.nil? || stage == other.stage) && 0 || -1) || super
    end
  end
end
