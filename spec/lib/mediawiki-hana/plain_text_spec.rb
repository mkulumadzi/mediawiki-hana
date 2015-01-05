require_relative '../../spec_helper'

describe Hana::PlainText do

	before do
		VCR.insert_cassette 'wiki_query', :record => :new_episodes
	end

	after do
		VCR.eject_cassette
	end

	describe "render a single page to text" do

		let(:wiki_query) { MediaWiki::Query.new('Main Page')}
		let(:plaintext) { Hana::PlainText.new(wiki_query, [:search_term, :title, :summary])}

		before do
			@rendered_lines = plaintext.render.split("\n")
		end

		it "must render the search string in the first line" do
			@rendered_lines[0].must_equal "Search term: Main Page"
		end

		it "must render the page title on the second line" do
			@rendered_lines[1].must_equal "Title: Main Page"
		end

		it "must render the page summary" do
			@rendered_lines[4].must_equal "Welcome to Wikipedia,"
		end

	end

	describe "render multiple pages to text" do

		let(:wiki_query) { MediaWiki::Query.new('a|b|c')}
		let(:plaintext) { Hana::PlainText.new(wiki_query, [:search_term, :title, :summary])}

		before do
			@result = plaintext.render
		end

		it "must render the first page" do
			@result.index('Search term: a').must_be_instance_of Fixnum
		end

		it "must render the second page" do
			@result.index('Search term: b').must_be_instance_of Fixnum
		end

		it "must render the last page" do
			@result.index('Search term: c').must_be_instance_of Fixnum
		end

	end

end