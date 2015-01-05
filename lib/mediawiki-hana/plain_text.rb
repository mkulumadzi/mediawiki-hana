require_relative 'text_output'

module Hana

	class PlainText < Hana::TextOutput

		# Render content to text
		def render

			render_content = ""

			content_to_render.each do |page_content|
				page_content.each do |key, value|
					render_content << "#{key} #{value}\n"
				end
				render_content << "\n"
			end

			render_content

		end

	end

end