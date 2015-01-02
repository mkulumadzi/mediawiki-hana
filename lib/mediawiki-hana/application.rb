require 'optparse'
require 'json'

class Application

	attr_reader :wiki_query, :search_string, :params

	include MediaWiki

	## PARSING OPTIONS

	# Parse arguments from the command line to set up the application
	def parse_options(argv)
		@params = {}
		opts = OptionParser.new
		opts.banner = "Usage: QUERY [options]"
		opts.separator ""
		opts.separator "Specific options:"

		enforce_mutually_exclusive_rendering_modes(argv)

		opts.on("--text", "Render to a text file") { @params[:render_mode] = :text }
		opts.on("--json", "Render to json") { @params[:render_mode] = :json }
		opts.on("--csv", "Render to csv") {@params[:render_mode] = :csv }

		opts.on("-o", "--output [FILENAME]", "Output to a file") { |f| @params[:output_file] = f }

		opts.on("-i", "--input [FILENAME]", "Source file for search queries") { |f| @params[:input_file] = f}

		@params[:data_to_render] = []

		opts.on("-s", "Show search term") { @params[:data_to_render] << :search_term}
		opts.on("-t", "Show title") { @params[:data_to_render] << :title}
		opts.on("-d", "Show short description") { @params[:data_to_render] << :summary}
		opts.on("-f", "Show full text") { @params[:data_to_render] << :full_text}

		opts.on_tail("-h", "--help", "Show this message") do
			puts opts
			exit
		end

		@search_string = opts.parse(argv)[0]

		if @params[:input_file]
			process_input_file
		end

	end

	# Ensure that only one rendering mode has been specified
	def enforce_mutually_exclusive_rendering_modes(argv)
		render_opts = ["--text", "--json", "--csv"]
		num_rendering_options = 0

		argv.each { |a| num_rendering_options += 1 if render_opts.index(a) }

		raise ArgumentError, "Please specify a single rendering mode" unless num_rendering_options <= 1
	end


	## INPUT FILES

	# Get a list of search terms from an input file
	def process_input_file
		input_file = File.open(@params[:input_file], 'r')
		file_terms = convert_contents_to_search_string(input_file.read)
		add_terms(file_terms)
	end

	# Add terms from the input file to any terms that were specified on the command line
	def add_terms(terms)
		if @search_string == nil
			@search_string = terms
		else
			@search_string << "|" + terms
		end
	end

	# Convert contents of a file to a valid search string
	def convert_contents_to_search_string(contents)
		contents = substitute_new_lines_and_commas(contents)
		contents = remove_extra_bars(contents)
		contents
	end

	# Replace new lines and commas with a bar character to produce a valid search string
	def substitute_new_lines_and_commas(contents)
		contents.gsub(/[,+\n+]+/, "|")
	end

	# Leave a single bar between each search term
	def remove_extra_bars(contents)
		contents = contents.gsub(/\A\|/, "")
		contents = contents.gsub(/\|\Z/, "")
		contents
	end

	##Initialization

	# Initialize the application
	def initialize(argv)
		parse_options(argv)
		@wiki_query = MediaWiki::Query.new(@search_string)

		get_default_items_to_render_if_non_specified

	end

	# By default, render the search term, title and summary
	def get_default_items_to_render_if_non_specified
		if @params[:data_to_render].any? == false
			@params[:data_to_render] = [:search_term, :title, :summary]
		end
	end

	## Rendering

	def render
		output(render_content)
	end

	# Print to screen, or to an output file
	def output(content)

		if params[:output_file]
			create_output_file(content)
		else
			puts content
		end

	end

	# Choose the appropriate rendering method based on the render mode
	def render_content

		case @params[:render_mode]
		when :text
			render_to_text
		when :json
			render_to_json
		when :csv
			render_to_csv
		end	

	end

	# Create an output file at the specified location
	def create_output_file(content)
		f = File.new(@params[:output_file], 'w')
		f << content
		f.close
	end

	## GET TEXT CONTENT - COULD BE CLASS DEFINITION

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

		@params[:data_to_render].each do |symbol|
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
		else
			page.send(symbol)
		end
	end

	## RENDERING TO TEXT - Could be child class

	# Render content to text
	def render_to_text

		render_content = ""

		content_to_render.each do |page_content|
			page_content.each do |key, value|
				render_content << "#{key} #{value}\n"
			end
		end

		render_content

	end

	## RENDERING TO JSON - Could be child class (but not text)
	def render_to_json
		@wiki_query.query_result.to_json
	end

	## RENDERING TO CSV

	def render_to_csv

		render_content = ""

		render_content << create_csv_row(get_array_of_headers)

		content_to_render.each do |h|
			render_content << create_csv_row(get_array_of_content(h))
		end
		
		render_content

	end

	def get_array_of_headers
		array = []
		@params[:data_to_render].each do |s|
			array << convert_symbol_to_header(s)
		end
		array
	end

	def get_array_of_content(hash)
		array = []
		hash.each do |key, value|
			array << value
		end
		array
	end

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