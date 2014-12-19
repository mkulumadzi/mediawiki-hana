# Load the main file
require_relative '../lib/mediawiki-hana'

# Dependencies
require 'minitest/autorun'
require 'pry'
require 'minitest/reporters'
require 'vcr'
require 'webmock/minitest'

#Minitest reporter
reporter_options = { color: true}
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]

#VCR config
VCR.configure do |c|
	c.cassette_library_dir = 'spec/fixtures/mediawiki_hana_cassettes'
	c.hook_into :webmock
end