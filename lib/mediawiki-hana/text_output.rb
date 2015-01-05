module Hana

	class TextOutput

		attr_reader :wiki_query, :data_to_render

		def initialize(wiki_query, data_to_render)
			@wiki_query = wiki_query
			@data_to_render = data_to_render
		end

		# Get content to render from all pages, based on the items specified by the user
		def content_to_render
			content_to_render = []

			@wiki_query.pages.each do |key, page|
				content_to_render << get_content_needed(key, page)
			end

			content_to_render
		end

		# Get content for a single page
		def get_content_needed(key, page)
			content_hash = Hash.new

			@data_to_render.each do |symbol|
				content_hash[convert_symbol_to_header(symbol)] = get_content_for_page_and_symbol(key, page, symbol)
			end

			content_hash
		end

		def convert_symbol_to_header(symbol)
			symbol.to_s.capitalize.gsub("_", " ") + ":"
		end

		# Pages do not have a method for returning the original search term.
		# If the symbol is the search term, return the key.
		# Otherwise, call the page with the method for the symbol
		def get_content_for_page_and_symbol(key, page, symbol)
			if symbol == :search_term
				key
			elsif page_has_method(page, :missing)
				"Page not found"
			elsif page_has_method(page, :invalid)
				"Invalid search string"
			else
				page.send(symbol)
			end
		end

		def page_has_method(page, symbol)

			@has_method = true

			begin
				page.send(symbol)
			rescue NoMethodError
				@has_method = false
			end

			@has_method

		end

	end

end