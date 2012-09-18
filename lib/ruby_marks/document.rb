#encoding: utf-8
module RubyMarks
	

	# Represents a scanned document
	class Document

		attr_writer :file

		def initialize(file)
			@file = Magick::Image.read(file).first
		end

		def filename
			@file.filename
		end
	end

end