require_relative '../../spec_helper'

describe Hana::JsonOutput do

	before do
		VCR.insert_cassette 'wiki_query', :record => :new_episodes
	end

	after do
		VCR.eject_cassette
	end

	describe "render a single page to json" do

		let(:wiki_query) { MediaWiki::Query.new('Main Page')}
		let(:json) { Hana::JsonOutput.new(wiki_query)}

		before do
			@result = json.render
		end

		it "must render the content to json" do
			JSON.parse(@result).must_be_instance_of Hash
		end

	end

end