# frozen_string_literal: true

module Pubid
  module Conformance
    # Typed reading layer for pubid-testsuite payloads. The YAML schema
    # (schema/test.schema.yaml in pubid-testsuite) is the wire contract;
    # these models are the shared typed reader for every implementation -
    # the Ruby gem now, pubid-ts mirroring the same shape later. No
    # consumer pokes payload hashes directly.
    module Corpus
      autoload :Case, "pubid/conformance/corpus/case"

      class << self
        # Cases from one payload file (underscore payloads excluded).
        def load_file(path)
          Array(YAML.safe_load_file(path)).map { |doc| Case.from_hash(doc) }
        end

        def case_files(flavor, corpus_dir)
          Dir[File.join(corpus_dir, flavor, "*.yaml")]
            .reject { |p| File.basename(p).start_with?("_") }.sort
        end

        def cases(flavor, corpus_dir)
          case_files(flavor, corpus_dir).flat_map { |p| load_file(p) }
        end
      end
    end
  end
end
