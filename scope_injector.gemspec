# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: scope_injector 0.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "scope_injector"
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Tom Smith"]
  s.date = "2014-03-11"
  s.description = "ActiveRecord default_scope alternative for injecting scopes into database operations. Think of it as named default_scope with enhanced functionality"
  s.email = "tsmith@landfall.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/scope_injector.rb",
    "lib/scope_injector/scope_injector.rb",
    "lib/scope_injector/scope_injector_relation.rb",
    "scope_injector.gemspec",
    "spec/database.yml",
    "spec/scope_injector_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/models.rb",
    "spec/support/schema.rb"
  ]
  s.homepage = "http://github.com/rtomsmith/scope_injector"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.2"
  s.summary = "ActiveRecord scoping mechanism similar to default_scope. Think of it as default_scope with naming and enhanced functionality"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>, ["~> 3.2"])
      s.add_runtime_dependency(%q<activesupport>, ["~> 3.2"])
      s.add_development_dependency(%q<rspec>, ["~> 2.14"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["~> 1"])
      s.add_development_dependency(%q<jeweler>, ["~> 2.0"])
      s.add_development_dependency(%q<simplecov>, ["~> 0"])
      s.add_development_dependency(%q<sqlite3>, ["~> 1"])
    else
      s.add_dependency(%q<activerecord>, ["~> 3.2"])
      s.add_dependency(%q<activesupport>, ["~> 3.2"])
      s.add_dependency(%q<rspec>, ["~> 2.14"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["~> 1"])
      s.add_dependency(%q<jeweler>, ["~> 2.0"])
      s.add_dependency(%q<simplecov>, ["~> 0"])
      s.add_dependency(%q<sqlite3>, ["~> 1"])
    end
  else
    s.add_dependency(%q<activerecord>, ["~> 3.2"])
    s.add_dependency(%q<activesupport>, ["~> 3.2"])
    s.add_dependency(%q<rspec>, ["~> 2.14"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["~> 1"])
    s.add_dependency(%q<jeweler>, ["~> 2.0"])
    s.add_dependency(%q<simplecov>, ["~> 0"])
    s.add_dependency(%q<sqlite3>, ["~> 1"])
  end
end

