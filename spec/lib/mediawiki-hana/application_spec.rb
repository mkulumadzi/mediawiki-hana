require_relative '../../spec_helper'

describe Application do

	describe "default attributes" do

		it "must include the Mediawiki methods" do
			Application.must_include MediaWiki
		end

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

	describe "rendering a single page" do

		describe "render to the terminal" do

			let(:application) { Application.new(['Main Page', '--text'])}

			before do
				$stdout = StringIO.new
				application.render
				@result = $stdout.string.split("\n")
			end

			it "must have a render method" do
				application.must_respond_to :render
			end

			it "must have an output method" do
				application.must_respond_to :output
			end

			it "must print the search string on the first line" do
				@result[0].must_equal "Search string: Main Page"
			end

			it "must print the page title on the second line" do
				@result[1].must_equal "Page title returned: Main Page"
			end

			# Summary has a few extra new lines
			it "must print the page summary" do
				@result[4].must_equal "Welcome to Wikipedia,"
			end

		end

		describe "render to a text file" do

			let(:application) { Application.new(['Main Page', '--text', '-o', 'data/output.txt']) }

			before do
				application.render
				@result = []

				File.open('data/output.txt', 'r') do |f|
					f.each_line do |line|
						@result << line.chomp
					end
				end

			end

			after do
				File.delete('data/output.txt')
			end

			it "must print the search string on the first line" do
				@result[0].must_equal "Search string: Main Page"
			end

			it "must print the page title on the second line" do
				@result[1].must_equal "Page title returned: Main Page"
			end

			# Summary has a few extra new lines
			it "must print the page summary" do
				@result[4].must_equal "Welcome to Wikipedia,"
			end
			
		end

		describe "render to a json file" do

			let(:application) { Application.new(['Main Page', '--json', '-o', 'data/output.json']) }

			before do
				application.render
				File.open('data/output.json', 'r') { |f| @result = f.read }
			end

			after do
				File.delete('data/output.json')
			end

			# To Do: Do a better job of testing for JSON...
			it "must save the query result to the file" do
				@result.index("{").must_be_instance_of Fixnum
			end

		end

		describe "render to a csv file" do

			let(:application) { Application.new(['Main Page', '--csv', '-o', 'data/output.csv']) }

			before do
				application.render
				@result = []

				File.open('data/output.csv', 'r') do |f|
					f.each_line do |line|
						@result << line.chomp
					end
				end

			end

			after do
				File.delete('data/output.csv')
			end

			it "must include the column headers on the first line" do
				@result[0].must_equal "'Search string', 'Page title returned', 'Summary'"
			end

			it "must list the search string, title and the summary for the page" do
				@result[1].match(/Main Page(.*)Main Page/).must_be_instance_of MatchData
			end

		end

	end

end