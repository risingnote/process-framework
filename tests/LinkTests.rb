$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "src")

require 'test/unit'
require 'Model'

module Perimeta
  
  class TestLink < Test::Unit::TestCase
    def setup
      @mymodel = Model.new(1, "rubylicious")
      @link_list = @mymodel.link_list
      @measure = @mymodel.node_list.add_node(1, 'measure one', MEASUREMENT)            
      @perfind = @mymodel.node_list.add_node(2, 'perfind two', PERFIND)            
      @proc = @mymodel.node_list.add_node(3, 'process three', PROCESS)
    end
    
    def teardown
      Model.delete(@mymodel)    
    end
    
    # Test ==
    def test_equivalence
      link = @link_list.add_link(@measure, @perfind)
      assert_equal(link, Link.new(@measure, @perfind))
    end

    def test_contains
      link = @link_list.add_link(@measure, @perfind)    
      assert(link.contains(@perfind))
    end

    # Test flattening data for link
    def test_flatten_link
      link = @link_list.add_link(@measure, @perfind)    
      assert_equal( { "from_id"=>1, "to_id"=>2 },
                    link.flatten_data)
    end

    # Test unflattening data for link
    def test_unflatten_link
      link = @link_list.add_link(@perfind, @proc)        
      
      data = link.flatten_data
      
      @link_list.remove_link(link)
      
      livelink = @link_list.link_from_data(data)
      
      assert_equal(link.from, livelink.from) 
      assert_equal(link.to, livelink.to)       
    end

  end
  
end