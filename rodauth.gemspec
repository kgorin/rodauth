require File.expand_path("../lib/rodauth/version", __FILE__)

Gem::Specification.new do |s|
  s.name = 'rodauth'
  s.version = Rodauth.version
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ["README.rdoc", "CHANGELOG", "MIT-LICENSE"] + Dir["doc/*.rdoc"] + Dir['doc/release_notes/*.txt']
  s.rdoc_options += ["--quiet", "--line-numbers", "--inline-source", '--title', 'Rodauth: Authentication and Account Management Framework for Rack Applications', '--main', 'README.rdoc']
  s.license = "MIT"
  s.summary = "Authentication and Account Management Framework for Rack Applications"
  s.author = "Jeremy Evans"
  s.email = "code@jeremyevans.net"
  s.homepage = "https://github.com/jeremyevans/rodauth"
  s.required_ruby_version = ">= 1.8.7"
  s.files = %w(MIT-LICENSE CHANGELOG README.rdoc Rakefile) + Dir["doc/*.rdoc"] + Dir['doc/release_notes/*.txt'] + Dir["{spec,lib}/**/*.rb"] + Dir["{templates,spec/views}/*.str"]
  s.description = <<END
Rodauth is an authentication and account management framework for
rack applications.  It's built using Roda and Sequel, but it can
be used as middleware in front of web applications that use
other web frameworks and database libraries.

Rodauth aims to provide strong security for password storage by
utilizing separate database accounts if possible on PostgreSQL,
MySQL, and Microsoft SQL Server.  Configuration is done via
a DSL that makes it easy to override any part of the authentication
process.
END
  s.add_dependency('sequel', [">= 4"])
  s.add_dependency('roda', [">= 2.6.0"])
  s.add_development_dependency('tilt')
  s.add_development_dependency('rack_csrf')
  s.add_development_dependency('bcrypt')
  s.add_development_dependency('mail')
  s.add_development_dependency('rotp')
  s.add_development_dependency('rqrcode')
  s.add_development_dependency('jwt')
  s.add_development_dependency("minitest", '>=5.0.0')
  s.add_development_dependency("minitest-hooks", '>=1.1.0')
  s.add_development_dependency("capybara", '>=2.1.0')
end
