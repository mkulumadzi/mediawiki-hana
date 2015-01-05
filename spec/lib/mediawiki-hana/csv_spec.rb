require_relative '../../spec_helper'

describe Hana::CSV do

	before do
		VCR.insert_cassette 'wiki_query', :record => :new_episodes
	end

	after do
		VCR.eject_cassette
	end

	describe "render a single page to csv" do

		let(:wiki_query) { MediaWiki::Query.new('Main Page')}
		let(:csv) { Hana::CSV.new(wiki_query, [:search_term, :title, :summary])}

		it "must create an array of the headers" do
			csv.get_array_of_headers.must_equal ["Search term:", "Title:", "Summary:"]
		end

		it "must create an array of values from a hash" do
			example_hash = {"Search term:" => "Main Page", "Title:" => "Main Page"}
			csv.get_array_of_content(example_hash).must_equal ["Main Page", "Main Page"]
		end

		it "must create a csv row from an array" do
			array = csv.get_array_of_headers
			csv.create_csv_row(array).must_equal "'Search term:', 'Title:', 'Summary:'\n"
		end

		describe "render the content" do

			before do
				@result = csv.render.split("\n")
			end

			it "must include the column headers on the first line" do
				@result[0].must_equal "'Search term:', 'Title:', 'Summary:'"
			end

			it "must list the search string, title and the summary for the page" do
				@result[1].match(/Main Page(.*)Main Page/).must_be_instance_of MatchData
			end

		end

	end

	describe "render multiple pages to csv" do

		let(:wiki_query) { MediaWiki::Query.new('foo|bar|camp')}
		let(:csv) { Hana::CSV.new(wiki_query, [:search_term, :title, :summary])}

		before do
			@result = csv.render
		end

		it "must render the first page" do
			@result.index('foo').must_be_instance_of Fixnum
		end

		it "must render the second page" do
			@result.index('bar').must_be_instance_of Fixnum
		end

	end

end