$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "src")

require 'test/unit'
require 'Model'

module Perimeta
  
  class TestXRServer < Test::Unit::TestCase
    def setup
    end
    
    def teardown
    end
    
    # Run the xmlrpc server
    def test_xmlrpc_server
      require "XRserver"
    end

  end
end