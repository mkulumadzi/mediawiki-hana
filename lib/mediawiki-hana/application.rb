require 'optparse'
# require 'json'

module Hana

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

		# Print to screen, or to an output file
		def render

			content = render_object.render

			if params[:output_file]
				create_output_file(content)
			else
				puts content
			end

		end

		# Get the appropriate object to render based on the render mode
		def render_object

			case @params[:render_mode]
			when :text
				Hana::PlainText.new(@wiki_query, @params[:data_to_render])
			when :csv
				Hana::CSV.new(@wiki_query, @params[:data_to_render])
			when :json
				Hana::JsonOutput.new(@wiki_query)
			end

		end

		# Create an output file at the specified location
		def create_output_file(content)
			f = File.new(@params[:output_file], 'w')
			f << content
			f.close
		end

	end

end