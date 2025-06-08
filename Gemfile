source "https://rubygems.org"

version = IO.read("VERSION").strip
puts "Using version: #{version}"

# Include all gems for development
Dir["gems/*/"].each do |gem_dir|
  puts "Adding gem #{File.basename(gem_dir)} from directory: #{gem_dir}"
  gem File.basename(gem_dir), "=#{version}", path: gem_dir
end

# Shared development dependencies
gem "rake"
gem "rspec"
gem "rubocop-performance"
gem "rubocop-rake"
gem "rubocop-rspec"
