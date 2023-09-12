# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "open-uri"
require "zip"
require "json"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

task :fetch_pubs_export do
  result_json = ""
  pub_export_file = URI.open("https://csrc.nist.gov/CSRC/media/feeds/metanorma/pubs-export.zip")
  Zip::File.open_buffer(pub_export_file) do |zip_file|
    zip_file.each { |entry| result_json += entry.get_input_stream.read }
  end
  File.write('spec/fixtures/pubs-export.txt',
             (JSON.parse(result_json).map { |rec| "NIST #{rec['docidentifier']}" }.join("\n")))
end
