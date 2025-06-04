source "https://rubygems.org"

# Include all gems for development
Dir["gems/*/"].each do |gem_dir|
  gemspec path: gem_dir
end

# Shared development dependencies
gem "parslet"
gem "rake", "~> 13.0"
gem "rspec", "~> 3.0"
gem "rubocop-performance"
gem "rubocop-rake"
gem "rubocop-rspec"
