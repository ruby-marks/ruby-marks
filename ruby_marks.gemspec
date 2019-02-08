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
  # s.extra_rdoc_files        = ['README.md']

  # Dependencies
  s.add_development_dependency 'bundler', '~> 2.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'codeclimate-test-reporter'
  s.add_development_dependency 'pry'

  s.add_dependency 'rmagick', '2.13.2'

  magick_version = system('convert -version')

  if magick_version && magick_version =~ /Q16/
    s.post_install_message = %{
      *** NOTE: You are running the ImageMagick under 16bits quantum depth.
          This configuration is used in very specific cases and can cause
          RMagick work a bit slow. See more details in this forum post
          http://rubyforge.org/forum/forum.php?thread_id=10975&forum_id=1618 ***
    }
  end
end


