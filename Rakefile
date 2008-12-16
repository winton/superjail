require 'rake'

task :default => 'superjail.gemspec'

file 'superjail.gemspec' => FileList['{bin,lib}/**','Rakefile'] do |f|
  # read spec file and split out manifest section
  spec = File.read(f.name)
  parts = spec.split("  # = MANIFEST =\n")
  fail 'bad spec' if parts.length != 3
  # determine file list from git ls-files
  files = `git ls-files`.
    split("\n").
    sort.
    reject{ |file| file =~ /^\./ }.
    reject { |file| file =~ /^doc/ }.
    map{ |file| "    #{file}" }.
    join("\n")
  # piece file back together and write...
  parts[1] = "  s.files = %w[\n#{files}\n  ]\n"
  spec = parts.join("  # = MANIFEST =\n")
  File.open(f.name, 'w') { |io| io.write(spec) }
  puts "Updated #{f.name}"
end

# sudo rake install
task :install do
  `gem uninstall superjail -q`
  `gem build superjail.gemspec -q`
  `gem install superjail*.gem -q`
  `rm superjail*.gem`
end