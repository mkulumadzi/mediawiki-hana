require_relative '../../spec_helper'

describe Hana::TextOutput do

	before do
		VCR.insert_cassette 'wiki_query', :record => :new_episodes
	end

	after do
		VCR.eject_cassette
	end

	describe "create a TextOutput object" do

		let(:wiki_query) { MediaWiki::Query.new('foo')}
		let(:text_output) { Hana::TextOutput.new(wiki_query, [:search_term])}

		it "must store the wiki query" do
			text_output.wiki_query.must_be_instance_of MediaWiki::Query
		end

		it "must store the data to render" do
			text_output.data_to_render.must_equal [:search_term]
		end

	end

	describe "get content to render" do

		let(:wiki_query) { MediaWiki::Query.new('foo|bar|c')}
		let(:text_output) { Hana::TextOutput.new(wiki_query, [:search_term, :title])}

		before do
			@foo_page = wiki_query.pages["foo"]
			@foo_content = {
				"Search term:" => "foo",
				"Title:" => "Foobar"
			}
			@content_to_render = [
				{"Search term:" => "bar", "Title:" => "Bar"},
				{"Search term:" => "c", "Title:" => "C"},
				{"Search term:" => "foo", "Title:" => "Foobar"}
			]
		end

		it "must convert data symbols to headers" do
			text_output.convert_symbol_to_header(:search_term).must_equal "Search term:"
		end

		it "must send the symbols for data to render to the page object as a method call" do
			text_output.get_content_for_page_and_symbol('foo', @foo_page, :title).must_equal @foo_page.title
		end

		it "must return the original search term" do
			text_output.get_content_for_page_and_symbol('foo', @foo_page, :search_term).must_equal 'foo'
		end

		it "must get all content needed for a page" do
			text_output.get_content_needed('foo', @foo_page).must_equal @foo_content
		end

		it "must create a hash with the content to render for each page" do
			text_output.content_to_render.must_equal @content_to_render
		end

	end

	describe "handle missing pages" do

		let(:wiki_query) { MediaWiki::Query.new('xfg|Talk:|foo')}
		let(:text_output) { Hana::TextOutput.new(wiki_query, [:search_string, :title])}

		before do
			@missing_page = wiki_query.pages["xfg"]
		end

		it "must indicate that the 'xfg' page is missing" do
			missing_page = wiki_query.pages["xfg"]
			text_output.page_has_method(missing_page, :missing).must_equal true
		end

		it "must indicate that the 'Talk:' page is invalid" do
			invalid_page = wiki_query.pages["Talk:"]
			text_output.page_has_method(invalid_page, :invalid).must_equal true
		end

		it "must not indicate that the 'foo' page is missing" do
			valid_page = wiki_query.pages["foo"]
			text_output.page_has_method(valid_page, :missing).must_equal false
		end

		it "must not indicate that the 'foo' page is invalid" do
			valid_page = wiki_query.pages["foo"]
			text_output.page_has_method(valid_page, :invalid).must_equal false
		end

		it "must return an indication that the page is missing" do
			missing_page = wiki_query.pages["xfg"]
			text_output.get_content_for_page_and_symbol('xfg', missing_page, :title).must_equal "Page not found"
		end

		it "must return an indication that the page is invalid" do
			invalid_page = wiki_query.pages["Talk:"]
			text_output.get_content_for_page_and_symbol('Talk:', invalid_page, :title).must_equal "Invalid search string"
		end

	end

end