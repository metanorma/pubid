# frozen_string_literal: true

namespace :docs do
  desc "Generate identifier pattern reference docs"
  task :patterns do
    require "pubid"

    output_dir = File.join(__dir__, "..", "..", "docs", "identifier-patterns")
    FileUtils.mkdir_p(output_dir)

    flavors = Dir[File.join(__dir__, "..", "..", "lib", "pubid",
                            "*")].select do |d|
      File.directory?(d)
    end
      .map do |d|
      File.basename(d)
    end
      .reject do |f|
      %w[core components rendering
         parser serializable utils].include?(f)
    end

    flavors.each do |flavor|
      puts "Generating docs for #{flavor}..."
      generator = Pubid::Core::PatternDocGenerator.new(flavor)
      content = generator.generate
      File.write(File.join(output_dir, "#{flavor}.md"), content)
    end

    # Generate cross-flavor comparison table
    puts "Generating cross-flavor comparison..."
    table = Pubid::Core::PatternDocGenerator.generate_cross_flavor_table(flavors)
    File.write(File.join(output_dir, "README.md"), table)

    puts "Done. Generated docs for #{flavors.length} flavors in #{output_dir}/"
  end
end
