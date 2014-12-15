require 'mediawiki-keiki'

Dir[File.dirname(__FILE__) + '/mediawiki-hana/*.rb'].each do |file|
	require file
end