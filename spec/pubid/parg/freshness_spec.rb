# frozen_string_literal: true

require "parsanol"

# TODO.SOTA/04: the artifacts are the parser of record, so each one must
# carry the freshness envelope parsanol#210 introduced (source_hash +
# compiler_version) and its embedded .parg source must hash to that
# source_hash. An artifact baked before the envelope existed, or one whose
# source was hand-edited afterwards, fails here instead of parsing
# silently in production.
RSpec.describe "PARG artifact freshness" do
  paths = Dir[File.join(Pubid::Parg::Artifact::DATA_DIR, "*.json")].sort

  it "ships artifacts for the grammar-backed flavors" do
    expect(paths).not_to be_empty
  end

  it "carries the freshness envelope and matches the embedded source" do
    failures = paths.filter_map do |path|
      artifact = Parsanol::PARG::Artifact.load(path)
      flavor = File.basename(path, ".json")

      if artifact.source_hash.nil? || artifact.compiler_version.nil?
        "#{flavor}: missing source_hash/compiler_version"
      elsif !artifact.fresh_against?(artifact.envelope["source"])
        "#{flavor}: embedded source does not hash to source_hash"
      end
    end

    expect(failures).to eq([])
  end
end
