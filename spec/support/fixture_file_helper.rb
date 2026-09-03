# frozen_string_literal: true

# Shared helper module for reading fixture files in tests
# Handles blank lines and comments consistently across all fixture tests
module FixtureFileHelper
  # Read identifiers from a fixture file, filtering blank lines and comments
  # @param file_path [String] Path to the fixture file
  # @return [Array<String>] Array of identifier strings
  def read_fixture_file(file_path)
    File.readlines(file_path).map(&:strip).reject do |line|
      line.empty? || line.start_with?("#")
    end
  end

  # Find all fixture files in a directory
  # @param dir_path [String] Path to the fixtures directory
  # @return [Array<String>] Array of file paths
  def find_fixture_files(dir_path)
    Dir.glob(File.join(dir_path, "*.txt"))
  end

  # Read a pass-fixture file into [input, expected_rendering] pairs.
  #
  # `classify_fixtures.rb` writes two line shapes into `pass/`: a plain
  # identifier that renders back byte-identically, and a `!input!rendered`
  # marker that records a *normalizing* parse — one that succeeds but whose
  # `to_s` differs from the input. A reader that does not know the marker
  # feeds `!input!rendered` to the parser verbatim and counts a spurious
  # failure, so the marker must be split here.
  #
  # The regex mirrors the writer in `spec/fixtures/classify_fixtures.rb`
  # exactly (greedy `.+`, non-empty right side), so reader and writer cannot
  # drift apart.
  #
  # @param file_path [String] Path to a `pass/*.txt` fixture file
  # @return [Array<Array(String, String)>] input and its expected rendering
  def read_pass_fixture_entries(file_path)
    read_fixture_file(file_path).map do |line|
      match = line.match(/\A!(.+)!(.+)\z/)
      match ? [match[1], match[2]] : [line, line]
    end
  end

  # Read the inputs out of a fail-fixture file.
  #
  # Every line in `fail/` has the shape `#input# ErrorClass: "message"`, which
  # `read_fixture_file` drops as a comment. The two generated header comments
  # carry no second `#`, so they do not match and need no special case.
  #
  # @param file_path [String] Path to a `fail/*.txt` fixture file
  # @return [Array<String>] the identifiers recorded as unparseable
  def read_fail_fixture_inputs(file_path)
    File.readlines(file_path).filter_map do |line|
      match = line.strip.match(/\A#(.+)# .+\z/)
      match && match[1]
    end
  end

  # Test round-trip parsing for a list of identifiers
  # @param identifiers [Array<String>] List of identifier strings
  # @param parser [Object] Parser object with .parse method
  # @return [Hash] Results with :successes, :failures, :total, :pass_rate
  def test_round_trip(identifiers, parser)
    failures = []
    successes = 0

    identifiers.each do |id_str|
      parsed = parser.parse(id_str)
      rendered = parsed.to_s

      if rendered == id_str
        successes += 1
      else
        failures << { original: id_str, rendered: rendered,
                      type: "mismatch" }
      end
    rescue StandardError => e
      failures << { original: id_str, error: "#{e.class}: #{e.message}",
                    type: "parse_error" }
    end

    total = identifiers.count
    pass_rate = total.positive? ? (successes.to_f / total * 100).round(2) : 0

    { successes: successes, failures: failures, total: total,
      pass_rate: pass_rate }
  end
end
