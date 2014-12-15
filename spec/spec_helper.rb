# Load the main file
require_relative '../lib/mediawiki-hana'

# Dependencies
require 'minitest/autorun'
require 'pry'
require 'minitest/reporters'

#Minitest reporter
reporter_options = { color: true}
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]