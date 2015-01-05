require 'json'

module Hana

	class JsonOutput

		def initialize(wiki_query)
			@wiki_query = wiki_query
		end

		## RENDERING TO JSON - Could be child class (but not text)
		def render
			@wiki_query.query_result.to_json
		end

	end

end