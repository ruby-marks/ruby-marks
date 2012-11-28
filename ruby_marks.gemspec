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
  s.add_dependency('rmagick') 
  s.add_dependency('sane_timeout')
   
  magick_version = `convert -version`

  if magick_version =~ /Q16/ 
    s.post_install_message = %{
      *** NOTE: You are running the ImageMagick under 16bits quantum depth. This configuration is used
          in very specific cases and can cause RMagick work a bit slow. See more details in this forum post
          http://rubyforge.org/forum/forum.php?thread_id=10975&forum_id=1618 ***

      We changed the way it recognizes the marks. It's not based on clocks anymore. If you are updating the gem 
      from 0.1.4 version, you should refactor your code to eliminate the clocks parameters and adjust 
      some new configurations. More information can be obtained on README file.
    }
  end

end


