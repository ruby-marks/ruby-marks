#encoding: utf-8 
$:.push File.expand_path("../lib", __FILE__)
require "ruby_marks/version"

Gem::Specification.new do |s|
  s.name                    = 'ruby_marks'
  s.version                 = RubyMarks::VERSION.dup
  s.platform                = Gem::Platform::RUBY
  s.date                    = '2012-09-17'
  s.summary                 = "A simple OMR tool"
  s.description             = "A simple OMR tool"
  s.authors                 = ["André Rodrigues", "Ronaldo Araujo"]
  s.email                   = ['andrerpbts@gmail.com', 'ronaldoaraujo1980@gmail.com']
  s.homepage                = 'https://github.com/andrerpbts/ruby_marks.git'
  s.files                   = Dir["README.md", "lib/**/*"]
  s.test_files              = Dir["test/**/*"]
  s.require_paths           = ["lib"]
  s.licenses                = ["MIT"]
  s.rubyforge_project       = "ruby_marks"
  s.extra_rdoc_files        = ['README.rdoc']
  
  # Dependencies
  s.add_dependency('rmagick')  
end