require_relative 'text_output'

module Hana

	class CSV < Hana::TextOutput

		# Render content to csv
		def render

			render_content = ""

			render_content << create_csv_row(get_array_of_headers)

			content_to_render.each do |h|
				render_content << create_csv_row(get_array_of_content(h))
			end
			
			render_content

		end

		# Create array of headers from symbols
		def get_array_of_headers
			array = []
			@data_to_render.each do |s|
				array << convert_symbol_to_header(s)
			end
			array
		end

		# Create array of content for a page
		def get_array_of_content(hash)
			array = []
			hash.each do |key, value|
				array << value
			end
			array
		end

		# Create a csv row from an array of strings
		def create_csv_row(array)
			row = ""
			i = 0

			while i < array.length - 1
				row << "'#{array[i]}', "
				i += 1
			end
			row << "'#{array[i]}'\n"

			row
		end

	end

end