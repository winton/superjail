Gem::Specification.new do |s|
  s.name = "superjail"
  s.version = "0.1.0"

  s.author = "AppTower"
  s.date = "2008-12-15"
  s.email = "apptower@wintoni.us"
  s.executables = ["superjail"]
  s.extra_rdoc_files = ["README.markdown", "changelog.markdown", "LICENSE"]
  s.has_rdoc = true
  s.homepage = "http://www.github.com/AppTower/superjail"
  s.require_paths = ["lib"]
  
  s.description = "A ruby implementation of jailkit"
  s.summary     = "A ruby implementation of jailkit"

  # = MANIFEST =
  s.files = %w[
    MIT-LICENSE
    README.markdown
    Rakefile
    bin/superjail
    changelog.markdown
    lib/superjail.rb
    superjail.gemspec
  ]
  # = MANIFEST =
end
