$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "src")

require 'test/unit'
require 'Model'

module Perimeta
  
  class TestNodeChangeLog < Test::Unit::TestCase
    def setup
    end
    
    def teardown
      Model.delete(@mymodel)
    end
    
    #Test that no changes are logged.
    def test_node_change_log1
      @mymodel = Model.new(1, "rubylicious")      
      node_list = @mymodel.node_list

      node1 = node_list.add_node('autonum', 'node one', NODE);
      perfind2 = node_list.add_node('autonum', 'pi two', PERFIND);      
      process3 = node_list.add_node('autonum', 'process three', PROCESS);
      process4 = node_list.add_node('autonum', 'process four', PROCESS);      

      process3.evidence = [0.2, 0.3]
      process4.evidence = [0.54, 0.777]
            
      assert(@mymodel.consume_next_node_change.nil?)
    end

    #Test that changes are logged for the process and perfind nodes.
    def test_node_change_log2
      Model.node_changes_to_log([:evidence])
      @mymodel = Model.new(1, "rubylicious")            
      node_list = @mymodel.node_list      

      node1 = node_list.add_node('autonum', 'node one', NODE);
      perfind2 = node_list.add_node('autonum', 'pi two', PERFIND);      
      process3 = node_list.add_node('autonum', 'process three', PROCESS);
      process4 = node_list.add_node('autonum', 'process four', PROCESS);      
      
      perfind2.evidence = 0.12
      process3.evidence = 0.34      
      process4.evidence = 0.56      
      
      i = 0
      while(ar = @mymodel.consume_next_node_change)
        assert_equal([0.12,0.12], ar[0].send(ar[1][0])) if ar[0] == perfind2
        assert_equal([0.34,0.34], ar[0].send(ar[1][0])) if ar[0] == process3        
        assert_equal([0.56,0.56], ar[0].send(ar[1][0])) if ar[0] == process4
        i += 1
      end
      
      assert_equal(3, i, 'Incorrect number of node changes were logged')
    
    end

    #Test that changes are logged for the process and perfind nodes.
    # Include another method in the log list which doesn't exist. 
    def test_node_change_log3
      Model.node_changes_to_log([:evidence, :doesnotexist])
      @mymodel = Model.new(1, "rubylicious")            
      node_list = @mymodel.node_list      

      node1 = node_list.add_node('autonum', 'node one', NODE);
      perfind2 = node_list.add_node('autonum', 'pi two', PERFIND);      
      process3 = node_list.add_node('autonum', 'process three', PROCESS);
      process4 = node_list.add_node('autonum', 'process four', PROCESS);      
      
      perfind2.evidence = 0.12
      process3.evidence = 0.34      
      process4.evidence = 0.56      
      
      i = 0
      while(ar = @mymodel.consume_next_node_change)
        assert_equal([0.12,0.12], ar[0].send(ar[1][0])) if ar[0] == perfind2
        assert_equal([0.34,0.34], ar[0].send(ar[1][0])) if ar[0] == process3        
        assert_equal([0.56,0.56], ar[0].send(ar[1][0])) if ar[0] == process4
        i += 1
      end
      
      assert_equal(3, i, 'Incorrect number of node changes were logged')
    end  
    
  end
  
end