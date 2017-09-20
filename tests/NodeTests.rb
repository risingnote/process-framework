$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "src")

require 'test/unit'
require 'Model'
require 'NodeFactory'

module Perimeta
  
  class TestNode < Test::Unit::TestCase
    def setup
      @mymodel = Model.new(1, "rubylicious")      
    end
    
    def teardown
      Model.delete(@mymodel)    
    end
    
    # Test ==
    def test_equivalence
      node1 = NodeFactory::create_node(1, 'Plain Node 1', nil, NODE)
      node2 = NodeFactory::create_node(2, 'Plain Node 2', nil, NODE)      
      
      assert(node1 == node1)
      assert(!(node1 == node2))
      assert(!(node1 == 'owl'))      
      assert(!(node1 == nil))            
    end

    # Test flattening data for process with defaults
    def test_flatten_process1
      proc = @mymodel.node_list.add_node(1, 'proc1', PROCESS)
      
      assert_equal( { "name"=>"proc1", "ident"=>1, "type"=>"process",
                      "commentary"=>"", "description"=>"", "evidence"=>"undefined" },
                    proc.flatten_data)
    end

    # Test flattening data for process with all data set
    def test_flatten_process2
      proc = @mymodel.node_list.add_node(1, 'proc1', PROCESS)    
      proc.commentary='com'
      proc.description='dsc'      
      proc.evidence=0.23
      
      assert_equal( { "name"=>"proc1", "ident"=>1, "type"=>"process",
                      "commentary"=>"com", "description"=>"dsc", "evidence"=>[0.23, 0.23] },
                    proc.flatten_data)
    end

    # Test unflattening data for process with all data set
    def test_unflatten_process
      proc = @mymodel.node_list.add_node(1, 'proc1', PROCESS)
      proc.commentary='com'
      proc.description='dsc'      
      proc.evidence=0.23
      
      data = proc.flatten_data
      
      @mymodel.node_list.delete_node(proc)
      
      livenode = @mymodel.node_list.node_from_data(data)
      
      assert_equal(proc.ident, livenode.ident) 
      assert_equal(proc.name, livenode.name) 
      assert_equal(proc.node_type, livenode.node_type)       
      assert_equal(proc.commentary, livenode.commentary)       
      assert_equal(proc.description, livenode.description)       
      assert_equal(proc.evidence, livenode.evidence)             
    end

  end
  
end