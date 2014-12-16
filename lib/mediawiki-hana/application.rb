require 'optparse'

class Application

	attr_reader :wiki_query, :search_string, :params

	include MediaWiki

	def parse_options(argv)
		@params = {}
		opts = OptionParser.new
		opts.banner = "Usage: QUERY [options]"
		opts.separator ""
		opts.separator "Specific options:"

		opts.on("--text", "Render to a text file") { @params[:render_mode] = :text }
		opts.on("--terminal", "Render to the terminal") { @params[:render_mode] = :terminal }
		opts.on("--json", "Render to a json file") { @params[:render_mode] = :json }

		opts.on("-o", "--output [FILENAME]", "Output to a file") { |f| @params[:output_file] = f }

		opts.on_tail("-h", "--help", "Show this message") do
			puts opts
			exit
		end
		# parser.on('-o') do
		# 	parser.on('data/output.txt') { @params[:output_file] = 'data/output.txt' }
		# end

		@search_string = opts.parse(argv)[0]

	end

	def initialize(argv)
		parse_options(argv)
		@wiki_query = MediaWiki::Query.new(@search_string)
	end

	# For each page, print the search string, title andshort summary
	def render

		case @params[:render_mode]
		when :terminal
			render_to_terminal
		when :text
			render_to_text
		when :json
			render_to_json
		else
			raise ArgumentError, "Invalid render mode"
		end	

	end

	def render_to_terminal

		@wiki_query.pages.each do |key, page|
			puts "Search string: #{key}"
			puts "Page title returned: #{page.title}" 
			puts "Summary: #{page.summary}\n\n"
		end

		return nil

	end

	def render_to_text

		f = File.new(@params[:output_file], 'w')

		@wiki_query.pages.each do |key, page|
			f << "Search string: #{key}\n"
			f << "Page title returned: #{page.title}\n" 
			f << "Summary: #{page.summary}\n\n"
		end

		f.close

	end

	def render_to_json
		f = File.new(@params[:output_file], 'w')
		f << @wiki_query.query_result
		f.close
	end

end

# Placeholder pseudo code

## Enter one more more search strings
## Get the pages back, store them

## Render the pages in a few different ways
## Save a .csv file with the search string, title and summary
## Print the search string, title and summary to the command line
## Save a .json file with the full query content
## Save a .txt file with the full text content, one page at a time
