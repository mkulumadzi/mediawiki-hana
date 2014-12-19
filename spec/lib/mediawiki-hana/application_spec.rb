require_relative '../../spec_helper'

describe Application do

	describe "default attributes" do

		it "must include the Mediawiki methods" do
			Application.must_include MediaWiki
		end

	end

	before do
		VCR.insert_cassette 'wiki_query', :record => :new_episodes
	end

	after do
		VCR.eject_cassette
	end

	describe "parse options" do

		it "must store a hash of the parameters" do
			application = Application.new(['Main Page', '--text'])
			application.params.must_be_instance_of Hash
		end

		describe "render mode" do

			it "must set the mode to :text if the --text option is given" do
				application = Application.new(['Main Page', '--text'])
				application.params[:render_mode].must_equal :text
			end

			it "must set the mode to :json if the --json option is given" do
				application = Application.new(['Main Page', '--json'])
				application.params[:render_mode].must_equal :json
			end

			it "must set the mode to :csv if the --csv option is given" do
				application = Application.new(['Main Page', '--csv'])
				application.params[:render_mode].must_equal :csv
			end

			it "must raise an exception if multiple rendering modes are given" do
				assert_raises ArgumentError do
					Application.new(['Main Page', '--text', '--csv'])
				end
			end

		end

		describe "output file" do

			it "must set the output file if the -o option is given" do
				application = Application.new(['Main Page', '--text', '-o', 'data/output.txt'])
				application.params[:output_file].must_equal 'data/output.txt'
			end

			it "must set the output file if the --output option is given" do
				application = Application.new(['Main Page', '--text', '--output', 'data/output.txt'])
				application.params[:output_file].must_equal 'data/output.txt'
			end

		end

		describe "show help text" do

			before do
				$stdout = StringIO.new
			end

			it "must show the help text if the --help option is given" do
				begin
					Application.new(['--help'])
				rescue SystemExit
				end
				$stdout.string.split("\n")[0].must_equal "Usage: QUERY [options]"
			end

			it "must show the help text if the --h option is given" do
				begin
					Application.new(['--h'])
				rescue SystemExit
				end
				$stdout.string.split("\n")[0].must_equal "Usage: QUERY [options]"
			end

		end

		it "must store the remaining parameters as the search string" do
			application = Application.new(['Main Page', '--text'])
			application.search_string.must_equal "Main Page"
		end

	end

	describe "get MediaQuery" do

		let(:application) {Application.new(['Main Page', '--text'])}

		it "must get a valid MediaWiki query object" do
			application.wiki_query.must_be_instance_of MediaWiki::Query
		end

		it "must get the right search string do" do
			application.wiki_query.query.must_equal "Main Page"
		end

	end

	describe "rendering" do

		describe "render a single page to text" do

			let(:application) { Application.new(['Main Page', '--text'])}

			before do
				@rendered_lines = application.render_to_text.split("\n")
			end

			it "must render the search string in the first line" do
				@rendered_lines[0].must_equal "Search string: Main Page"
			end

			it "must render the page title on the second line" do
				@rendered_lines[1].must_equal "Page title returned: Main Page"
			end

			it "must render the page summary" do
				@rendered_lines[4].must_equal "Welcome to Wikipedia,"
			end

		end

		describe "render multiple pages to text" do

			let(:application) { Application.new(['a|b|c', '--text'])}

			before do
				@result = application.render_to_text
			end

			it "must render the first page" do
				@result.index('Search string: a').must_be_instance_of Fixnum
			end

			it "must render the second page" do
				@result.index('Search string: b').must_be_instance_of Fixnum
			end

			it "must render the last page" do
				@result.index('Search string: c').must_be_instance_of Fixnum
			end

		end

		describe "render a single page to json" do

			let(:application) { Application.new(['Main Page', '--json'])}

			before do
				@result = application.render_to_json
			end

			it "must render the content to json" do
				JSON.parse(@result).must_be_instance_of Hash
			end

		end

		describe "render a single page to csv" do

			let(:application) { Application.new(['Main Page', '--csv'])}

			before do
				@result = application.render_to_csv.split("\n")
			end

			it "must include the column headers on the first line" do
				@result[0].must_equal "'Search string', 'Page title returned', 'Summary'"
			end

			it "must list the search string, title and the summary for the page" do
				@result[1].match(/Main Page(.*)Main Page/).must_be_instance_of MatchData
			end

		end

		describe "render multiple pages to csv" do

			let(:application) { Application.new(['foo|bar|camp', '--csv'])}

			before do
				@result = application.render_to_csv
			end

			it "must render the first page" do
				@result.index('foo').must_be_instance_of Fixnum
			end

			it "must render the second page" do
				@result.index('bar').must_be_instance_of Fixnum
			end

		end

		describe "output to the terminal" do

			let(:application) { Application.new(['Main Page', '--text'])}

			before do
				$stdout = StringIO.new
				application.render
				@result = $stdout.string
			end

			it "must print the rendered content to the terminal" do
				@result.must_equal application.render_to_text
			end

		end

		describe "output to a file" do

			let(:application) { Application.new(['Main Page', '--text', '-o', 'data/output.txt'])}

			before do
				application.render

				File.open('data/output.txt', 'r') do |f|
					@result = f.read
				end

			end

			it "must save the rendered content in the file" do
				@result.must_equal application.render_to_text
			end

		end

	end

end