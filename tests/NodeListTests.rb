$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "src")

require 'test/unit'
require 'Model'

module Perimeta
  
  class TestNodeList < Test::Unit::TestCase
    def setup
      @mymodel = Model.new(1, "rubylicious")  
      @node1 = @mymodel.node_list.add_node(1, 'node one');
      @node2 = @mymodel.node_list.add_node(2, 'node two');
    end
    
    def teardown
      Model.delete(@mymodel)
    end
    
    # Test that callbacks are created for the nodelist
    def test_nodelist_callbacks
      nodelist = @mymodel.node_list
      assert(nodelist.callbacks.size == 2)
      
      assert(nodelist.callbacks.include?('node_added'))
      assert(nodelist.callbacks.include?('node_removed'))
    end

    # Test adding and removing nodes
    def test_nodelist_adddelete
      nodelist = @mymodel.node_list
      
      assert(nodelist.size == 2)
      
      nodelist.delete_node(@node2)
      assert(nodelist.size == 1)
    end
 
    def test_node_for_id
      nodelist = @mymodel.node_list
      
      node3 = nodelist.add_node(3, 'node three', PROCESS);
      
      assert(nodelist.node_for_id(3) == node3)
      begin
        nodelist.node_for_id(4)
        assert(false)
      rescue
        assert(true)
      end
    end
    
    def test_nodelist_flatten_data
      nodelist = @mymodel.node_list
      
      node3 = nodelist.add_node(3, 'node three', PROCESS);
      
      assert_equal( { "node_list"=>[[1, "node"],[2, "node"],[3, "process"]] }, 
                  nodelist.flatten_data)
    end

    #Test autonumbering of nodes
    def test_node_autonumber
      nodelist = @mymodel.node_list
      
      proc3 = nodelist.add_node('autonum', 'process 3', PROCESS);
      assert(proc3.ident == 3)
      
      node4 = nodelist.add_node('autonum', 'node 4');
      assert(node4.ident == 4)

      node99 = nodelist.add_node(99, 'node 99');
      assert(node99.ident == 99)
    end
 
    def test_add_dupl_id
      begin
        @mymodel.node_list.add_node(1, 'another node one');    
        assert(false)
      rescue
        assert(true)      
      end
    end   
    
    def test_delete_null
      begin
        @mymodel.node_list.delete_node(nil);    
        assert(false)
      rescue
        assert(true)      
      end
    end   
    
  end
  
end