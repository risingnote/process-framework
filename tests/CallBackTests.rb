$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "src")

require 'test/unit'
require 'Model'

module Perimeta
  
  class CallBackTests < Test::Unit::TestCase
    def setup
      @mymodel = Model.new(1, "rubylicious")  
    end
    
    def teardown
      Model.delete(@mymodel)
    end
    
    # Test adding callback to local method
    def test_callbacks    
      nodelist = @mymodel.node_list
      
      counter = 0
      
      #setup callbacks
      nodelist.on_node_added {|node| counter += 1}
      nodelist.on_node_removed {|node| counter -= 1}
      
      #add and remove nodes, expecting callbacks to run
      node1 = nodelist.add_node(1, 'process one')
      node2 = nodelist.add_node(2, 'process two')    
      node3 = nodelist.add_node(3, 'process three')          
      assert(counter == 3)
      
      nodelist.delete_node(node1)
      assert(counter == 2)
    end

    # Test removing local callback
    def test_callbacks2
      nodelist = @mymodel.node_list
      
      counter = 0

      #setup callbacks      
      add_callback = nodelist.on_node_added {|node| counter += 1}
      nodelist.on_node_removed {|node| counter -= 1}
      
      #add nodes, expect callbacks to run
      node1 = nodelist.add_node(1, 'process one')
      node2 = nodelist.add_node(2, 'process two')    
      assert(counter == 2)
      
      #delete the callback, add node will have no effect
      nodelist.del_node_added(add_callback)
      node3 = nodelist.add_node(3, 'process three')    
      assert(counter == 2)
            
      #remove node callback should still be working            
      nodelist.delete_node(node3)
      assert(counter == 1)
    end

    # Test auto setup of callbacks - no callbacks 
    def test_auto_callback_setup
      linklist = @mymodel.link_list
      nodelist = @mymodel.node_list      
      
      node1 = nodelist.add_node(1, 'node one')
      node2 = nodelist.add_node(2, 'node two')      
      
      link = linklist.add_link(node1, node2, true)
      linklist.remove_link(link)      
     
      assert(true) #made it to the end, hooray
    end

    # Test auto setup of callbacks - measurement to perfind
    def test_auto_callback_setup2
      linklist = @mymodel.link_list
      nodelist = @mymodel.node_list      
      
      measure = nodelist.add_node(1, 'node one', MEASUREMENT)
      perfind = nodelist.add_node(2, 'node two', PERFIND)      

      linklist.add_link(measure, perfind, true)
      assert_equal(1, measure.del_callbacks.size)
    end

    # Test auto setup of callbacks - perfind to process
    def test_auto_callback_setup3
      linklist = @mymodel.link_list
      nodelist = @mymodel.node_list      
      
      perfind = nodelist.add_node(1, 'node two', PERFIND)      
      process = nodelist.add_node(2, 'node one', PROCESS)

      linklist.add_link(perfind, process, true)
      
      assert_equal(1, perfind.del_callbacks.size)      
    end

    # Test auto setup of callbacks - process to process
    def test_auto_callback_setup4
      linklist = @mymodel.link_list
      nodelist = @mymodel.node_list      
      
      process1 = nodelist.add_node(1, 'node one', PROCESS)      
      process2 = nodelist.add_node(2, 'node two', PROCESS)

      linklist.add_link(process1, process2, true)
      
      assert_equal(1, process1.del_callbacks.size)      
    end
  
    # Test notifying 2 processes of evidence change and removing one of the callbacks
    def test_multiple_process
      linklist = @mymodel.link_list
      nodelist = @mymodel.node_list      
      
      process1 = nodelist.add_node(1, 'process one', PROCESS)      
      process2 = nodelist.add_node(2, 'process two', PROCESS)
      process3 = nodelist.add_node(3, 'process three', PROCESS)      
      
      link1 = linklist.add_link(process1, process2, true)
      link2 = linklist.add_link(process1, process3, true)

      process1.evidence = [0.63, 0.64]
      
      assert_equal([0.63, 0.64], process2.evidence)
      assert_equal([0.63, 0.64], process3.evidence)      
      
      #remove the callbacks for process 2 as a side affect of deleting the link
      linklist.remove_link(link1)
      
      process1.evidence = [0.44, 0.50]

      assert_equal("undefined", process2.evidence)
      assert_equal([0.44, 0.50], process3.evidence)      
    end

    # Test no auto setup of callbacks - process to process
    def test_no_auto_callback_setup
      linklist = @mymodel.link_list
      nodelist = @mymodel.node_list      
      
      process1 = nodelist.add_node(1, 'node one', PROCESS)      
      process2 = nodelist.add_node(2, 'node two', PROCESS)
      
      linklist.add_link(process1, process2, false)

      process1.evidence = 1.0
      
      assert(process2.evidence == Evidence.undefined)
    end
    
  end
  
end