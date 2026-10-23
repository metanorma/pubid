# frozen_string_literal: true

module Pubid
  # Per-flavor string formats (renderer/parser pairs), parent-chained
  # along the identifier class hierarchy.
  #
  # When lutaml-model is loaded, every registration is mirrored into
  # Lutaml::Model::FormatRegistry (the single format registry the
  # grammar-backed format machinery consumes), so pubid's string
  # formats and LML-declared formats live in one registry. pubid
  # itself does not depend on lutaml-model — the mirror is inert
  # without it.
  class FormatRegistry
    attr_reader :formats

    def initialize(parent: nil)
      @formats = {}
      @parent = parent
    end

    def register(format, renderer: nil, parser: nil)
      @formats[format.to_sym] = { renderer:, parser: }
      mirror_to_model_registry(format.to_sym, renderer, parser)
    end

    def renderer_for(format)
      entry = @formats[format.to_sym]
      return entry[:renderer] if entry && entry[:renderer]
      return @parent.renderer_for(format) if @parent

      nil
    end

    def parser_for(format)
      entry = @formats[format.to_sym]
      return entry[:parser] if entry && entry[:parser]
      return @parent.parser_for(format) if @parent

      nil
    end

    def registered_formats
      formats = @formats.keys
      formats |= @parent.registered_formats if @parent
      formats
    end

    def has?(format)
      @formats.key?(format.to_sym) || (@parent&.has?(format) || false)
    end

    private

    def mirror_to_model_registry(format, renderer, parser)
      return unless defined?(::Lutaml::Model::FormatRegistry)
      return if ::Lutaml::Model::FormatRegistry.registered?(format)

      adapter = Class.new
      adapter.define_singleton_method(:pubid_renderer) { renderer }
      if parser
        adapter.define_singleton_method(:parse) { |data, _options = {}| parser.call(data) }
      end
      transformer = Class.new do
        define_singleton_method(:name) { "Pubid#{format.to_s.capitalize}Transform" }

        # Lutaml calls the transformer on the class (transformer_for
        # returns the registered object as-is), so the hook is a
        # singleton method.
        define_singleton_method(:data_to_model) do |_model, data, _format, _options = {}|
          data
        end
      end
      ::Lutaml::Model::FormatRegistry.register(
        format,
        mapping_class: ::Lutaml::Model::Mapping,
        adapter_class: adapter,
        transformer: transformer,
        error_types: [Pubid::Errors::ParseError],
      )
    end
  end
end
