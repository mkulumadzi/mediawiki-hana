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
		opts.on("--json", "Render to json") { @params[:render_mode] = :json }
		opts.on("--csv", "Render to csv") {@params[:render_mode] = :csv }

		opts.on("-o", "--output [FILENAME]", "Output to a file") { |f| @params[:output_file] = f }

		opts.on_tail("-h", "--help", "Show this message") do
			puts opts
			exit
		end

		@search_string = opts.parse(argv)[0]

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
		else
			raise ArgumentError, "Invalid render mode"
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
		@wiki_query.query_result
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