require_relative '../../spec_helper'

describe Hana::Application do

	describe "default attributes" do

		it "must include the Mediawiki methods" do
			Hana::Application.must_include MediaWiki
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
			application = Hana::Application.new(['Main Page', '--text'])
			application.params.must_be_instance_of Hash
		end

		describe "render mode" do

			it "must set the mode to :text if the --text option is given" do
				application = Hana::Application.new(['Main Page', '--text'])
				application.params[:render_mode].must_equal :text
			end

			it "must set the mode to :json if the --json option is given" do
				application = Hana::Application.new(['Main Page', '--json'])
				application.params[:render_mode].must_equal :json
			end

			it "must set the mode to :csv if the --csv option is given" do
				application = Hana::Application.new(['Main Page', '--csv'])
				application.params[:render_mode].must_equal :csv
			end

			it "must raise an exception if multiple rendering modes are given" do
				assert_raises ArgumentError do
					Hana::Application.new(['Main Page', '--text', '--csv'])
				end
			end

		end

		describe "input file" do

			before do

				File.new('data/input.csv', 'w')

				File.open('data/input.csv', 'w') do |f|
					f << 'Main Page'
				end

				@application = Hana::Application.new(['-i', 'data/input.csv', '--text'])
			end

			after do
				File.delete('data/input.csv')
			end

			it "must set the input file if the -i option is given" do
				@application.params[:input_file].must_equal 'data/input.csv'
			end

			it "must get the query terms from the input file" do
				@application.search_string.must_equal "Main Page"
			end

		end

		describe "process csv as input file" do

			before do

				File.new('data/input.csv', 'w')

				File.open('data/input.csv', 'w') do |f|

					f << ",foo,\n"
					f << "bar,\n,\n"
					f << "c,"

				end

				@contents = ",foo,\nbar,\n,\nc,"

				@substituted_contents = "|foo|bar|c|"

				@application = Hana::Application.new(['-i', 'data/input.csv', '--text'])
			end

			it "must substitute new lines and commas with bars" do
				@application.substitute_new_lines_and_commas(@contents).must_equal "|foo|bar|c|"
			end

			it "must remove leading and trailing bars" do
				@application.remove_extra_bars(@substituted_contents).must_equal "foo|bar|c"
			end

			it "must replace commas and carriage returns in the input file with bars" do
				@application.convert_contents_to_search_string(@contents).must_equal 'foo|bar|c'
			end

			it "must store the contents of the processed file as the search string" do
				@application.search_string.must_equal 'foo|bar|c'
			end

		end

		describe "get search terms from input file and command line" do

			before do

				File.new('data/input.csv', 'w')

				File.open('data/input.csv', 'w') do |f|

					f << "foo,\n"
					f << "bar,\n"

				end

				@application = Hana::Application.new(['c', '-i', 'data/input.csv', '--text'])
			end

			it "must add terms from the file to the terms from the command line" do
				@application.search_string.must_equal 'c|foo|bar'
			end

		end

		describe "output file" do

			it "must set the output file if the -o option is given" do
				application = Hana::Application.new(['Main Page', '--text', '-o', 'data/output.txt'])
				application.params[:output_file].must_equal 'data/output.txt'
			end

			it "must set the output file if the --output option is given" do
				application = Hana::Application.new(['Main Page', '--text', '--output', 'data/output.txt'])
				application.params[:output_file].must_equal 'data/output.txt'
			end

		end

		describe "render the search term for each page" do

			let(:application) { Hana::Application.new(['foo|bar|c', '--text', '-s'])}

			before do
				@data_to_render = [:search_term]
			end

			it "must record which data to render" do
				application.params[:data_to_render].must_equal @data_to_render
			end

		end

		describe "render multiple values" do

			let(:application) { Hana::Application.new(['foo|bar|c', '--text', '-stdf'])}

			before do
				@data_to_render = [:search_term, :title, :summary, :full_text]
			end

			it "must get all of the items to render" do
				application.params[:data_to_render].must_equal @data_to_render
			end

		end

		describe "use default rendering values" do

			let(:application) { Hana::Application.new(['foo|bar|c', '--text'])}

			before do
				@data_to_render = [:search_term, :title, :summary]
			end

			it "must render the search term, title and summary by default" do
				application.params[:data_to_render].must_equal @data_to_render
			end

		end

		describe "show help text" do

			before do
				$stdout = StringIO.new
			end

			it "must show the help text if the --help option is given" do
				begin
					Hana::Application.new(['--help'])
				rescue SystemExit
				end
				$stdout.string.split("\n")[0].must_equal "Usage: QUERY [options]"
			end

			it "must show the help text if the --h option is given" do
				begin
					Hana::Application.new(['--h'])
				rescue SystemExit
				end
				$stdout.string.split("\n")[0].must_equal "Usage: QUERY [options]"
			end

		end

		it "must store the remaining parameters as the search string" do
			application = Hana::Application.new(['Main Page', '--text'])
			application.search_string.must_equal "Main Page"
		end

	end

	describe "get MediaWiki Query" do

		let(:application) { Hana::Application.new(['Main Page', '--text'])}

		it "must get a valid MediaWiki query object" do
			application.wiki_query.must_be_instance_of MediaWiki::Query
		end

		it "must get the right search string do" do
			application.wiki_query.query.must_equal "Main Page"
		end

	end

	describe "rendering" do

		describe "render a plain text result" do

			let(:application) { Hana::Application.new(['Main Page', '--text'])}

			it "must create a new plain text object to render" do
				application.render_object.must_be_instance_of Hana::PlainText
			end

		end

		describe "render a csv result" do

			let(:application) { Hana::Application.new(['Main Page', '--csv'])}

			it "must create a new csv object to render" do
				application.render_object.must_be_instance_of Hana::CSV
			end

		end

		describe "render a json result" do

			let(:application) { Hana::Application.new(['Main Page', '--json'])}

			it "must create a new json object to render" do
				application.render_object.must_be_instance_of Hana::JsonOutput
			end

		end

		describe "output rendered content" do

			let(:wiki_query) { MediaWiki::Query.new('Main Page')}
			let(:plain_text) { Hana::PlainText.new(wiki_query, [:search_term, :title, :summary])}

			describe "output to the termianl" do

				let(:application) { Hana::Application.new(['Main Page', '--text'])}

				it "must print the rendered content to the terminal" do
					$stdout = StringIO.new
					application.render

					$stdout.string.must_equal plain_text.render
				end

			end

			describe "output to a file" do

				let(:application) { Hana::Application.new(['Main Page', '--text', '-o', 'data/output.txt'])}

				before do
					@render_object = application.render_object
				end

				it "must create an output file with the rendered content" do
					application.create_output_file(@render_object.render)

					File.open('data/output.txt', 'r') do |f|
						@result = f.read
					end

					@result.must_equal plain_text.render
				end

				it "must create this file when the render function is called" do
					application.render

					File.open('data/output.txt', 'r') do |f|
						@result = f.read
					end

					@result.must_equal plain_text.render

				end

			end

		end

	end

end