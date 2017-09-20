$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "src")

require 'test/unit'
require 'Model'

module Perimeta
  
  class TestLinkList < Test::Unit::TestCase
    def setup
      @mymodel = Model.new(1, "rubylicious")  
      @node1 = @mymodel.node_list.add_node(1, 'node1')
      @node2 = @mymodel.node_list.add_node(2, 'node2')
      @node3 = @mymodel.node_list.add_node(3, 'node3', PROCESS)
      @node4 = @mymodel.node_list.add_node(4, 'node4', PERFIND)      
      @node5 = @mymodel.node_list.add_node(5, 'node5', MEASUREMENT)      
      @node6 = @mymodel.node_list.add_node(6, 'node6', MEASUREMENT)                  
      @linklist = @mymodel.link_list
    end
    
    def teardown
      Model.delete(@mymodel)
    end

    def test_add_dupl_link
      begin
        @linklist.add_link(@node1, @node2)    
        @linklist.add_link(@node1, @node2)
        assert(false)
      rescue
        assert(@linklist.size == 1)
      end
    end
    
    # Test that callbacks are assigned to a link
    def test_linklist_callbacks
      assert(@linklist.callbacks.size == 2)
      
      assert(@linklist.callbacks.include?('link_added'))
      assert(@linklist.callbacks.include?('link_removed'))      
    end

    # Test with_node returns all links connected to node (none)
    def test_with_node_none
      link1 = @linklist.add_link(@node1, @node2)
      link2 = @linklist.add_link(@node2, @node3)      
      
      assert(@linklist.with_node(@node4).length == 0)
    end

    # Test with_node returns all links connected to node
    def test_with_node_some
      link1 = @linklist.add_link(@node1, @node3, false)
      link2 = @linklist.add_link(@node2, @node3, false)
      link3 = @linklist.add_link(@node1, @node6, false)
      link4 = @linklist.add_link(@node3, @node4, false)
      link5 = @linklist.add_link(@node4, @node5, false)
      
      assert(@linklist.with_node(@node3).size == 3)
      
      @mymodel.node_list.delete_node(@node1)
      
      assert(@mymodel.link_list.size == 3)
    end

    # Test finding connected nodes with specified method
    def test_connected_nodes_with_method1
       link1 = @linklist.add_link(@node4, @node3, false)
      
      #process node has one child but doesn't have method      
      assert(@linklist.connected_nodes_with_method(@node3, :measurement).size == 0)
      #perfind node has no children
      assert(@linklist.connected_nodes_with_method(@node4, :measurement).size == 0)
    end

    # Test finding connected nodes with specified method
    def test_connected_nodes_with_method2
      link1 = @linklist.add_link(@node4, @node3, false)
      link2 = @linklist.add_link(@node5, @node4, false)
      
      #perfind node has one child with matching method
      assert(@linklist.connected_nodes_with_method(@node4, :measurement).size == 1)
      assert(@linklist.connected_nodes_with_method(@node4, :measurement).include?(link2)) 
      
      link3 = @linklist.add_link(@node6, @node4, false)
      #perfind node has two children with matching methods
      assert(@linklist.connected_nodes_with_method(@node4, :measurement).size == 2)
      assert(@linklist.connected_nodes_with_method(@node4, :measurement).include?(link2)) 
      assert(@linklist.connected_nodes_with_method(@node4, :measurement).include?(link3))       
    end
    
    # Test deleting a link should delete callback but also update parent node
    def test_delete_link
      @node5.measurement = 45.8
      @node4.value_function = ValueFunction.new(0, 100, 'elephants')
      
      link = @linklist.add_link(@node5, @node4, true)

      (0..1).each { |i| assert_in_delta(@node4.evidence[i], 0.458, 0.0001) }            
      
      @linklist.remove_link(link)
      assert_equal(Evidence.undefined, @node4.evidence)      
      
      @node5.measurement = 10
      assert_equal(Evidence.undefined, @node4.evidence)            
    end 
    
    def test_linklist_flatten_data
      @linklist.add_link(@node1, @node2, false)
      @linklist.add_link(@node1, @node3, false)
      @linklist.add_link(@node4, @node2, false)      
      
      assert_equal( { "link_list"=>[{"from_id"=>1, "to_id"=>2},
                         {"from_id"=>1, "to_id"=>3},{"from_id"=>4, "to_id"=>2}] }, 
                  @linklist.flatten_data)
    end
     
  end
end