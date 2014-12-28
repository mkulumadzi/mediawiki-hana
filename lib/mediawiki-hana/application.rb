require 'optparse'
require 'json'

class Application

	attr_reader :wiki_query, :search_string, :params

	include MediaWiki

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

		opts.on_tail("-h", "--help", "Show this message") do
			puts opts
			exit
		end

		@search_string = opts.parse(argv)[0]

		if @params[:input_file]
			process_input_file
		end

	end

	def process_input_file
		input_file = File.open(@params[:input_file], 'r')
		file_terms = convert_contents_to_search_string(input_file.read)
		add_terms(file_terms)
	end

	def add_terms(terms)
		if @search_string == nil
			@search_string = terms
		else
			@search_string << "|" + terms
		end
	end

	def convert_contents_to_search_string(contents)
		contents = substitute_new_lines_and_commas(contents)
		contents = remove_extra_bars(contents)
		contents
	end

	def substitute_new_lines_and_commas(contents)
		contents.gsub(/[,+\n+]+/, "|")
	end

	def remove_extra_bars(contents)
		contents = contents.gsub(/\A\|/, "")
		contents = contents.gsub(/\|\Z/, "")
		contents
	end

	def enforce_mutually_exclusive_rendering_modes(argv)
		render_opts = ["--text", "--json", "--csv"]
		num_rendering_options = 0

		argv.each { |a| num_rendering_options += 1 if render_opts.index(a) }

		raise ArgumentError, "Please specify a single rendering mode" unless num_rendering_options <= 1
	end

	def initialize(argv)
		parse_options(argv)
		@wiki_query = MediaWiki::Query.new(@search_string)
	end

	def render
		output(render_content)
	end

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

	def output(content)

		if params[:output_file]
			create_output_file(content)
		else
			puts content
		end

	end

	def create_output_file(content)
		f = File.new(@params[:output_file], 'w')
		f << content
		f.close
	end

	def render_to_text

		render_content = ""

		@wiki_query.pages.each do |key, page|
			render_content << "Search string: #{key}\n"
			render_content << "Page title returned: #{page.title}\n" 
			render_content << "Summary: #{page.summary}\n\n"
		end

		render_content

	end

	def render_to_json
		@wiki_query.query_result.to_json
	end

	def render_to_csv

		render_content = ""
		render_content << "'Search string', 'Page title returned', 'Summary'\n"

		@wiki_query.pages.each do |key, page|
			render_content << "'#{key}', '#{page.title}', '#{page.summary}'\n"
		end
		
		render_content

	end

end