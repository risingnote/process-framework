$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "src")

require 'test/unit'
require 'Model'

module Perimeta
  
  class TestPerfInd < Test::Unit::TestCase
    def setup
      @mymodel = Model.new(1, "rubylicious")  
    end
    
    def teardown
      Model.delete(@mymodel)
    end
    
    # Test that callbacks are created for the performance indicator
    def test_perfind_callbacks
      nodelist = @mymodel.node_list
      
      node1 = nodelist.add_node(1, 'node one', PERFIND);
      
      assert(node1.callbacks.size == 1)
      assert(node1.callbacks.include?('evidence_changed'))
    end

    # Test creation of value function and calculation of evidence
    def test_perfind_evidence
      nodelist = @mymodel.node_list
      
      node1 = nodelist.add_node(1, 'node one', PERFIND);
      
      assert_equal(Evidence.undefined, node1.measure_to_evidence(nil))

      node1.value_function = ValueFunction.new(0, 100, 'degrees')

      assert_equal(Evidence.undefined, node1.measure_to_evidence(nil))      
      assert_in_delta(node1.measure_to_evidence(45.4), 0.454, 0.0001)
    end  

    # Test calculation of evidence when changing value function
    def test_changing_valuefunction
      nodelist = @mymodel.node_list
      linklist = @mymodel.link_list      
      
      pi_node = nodelist.add_node(1, 'node one', PERFIND);
      m_node  = nodelist.add_node(2, 'node two', MEASUREMENT);
      m_node.measurement = 73
      assert_equal(Evidence.undefined, pi_node.evidence)

      pi_node.value_function = ValueFunction.new(0, 100, 'degrees')
      assert_equal(Evidence.undefined, pi_node.evidence)      
      
      linklist.add_link(m_node, pi_node, true)

      (0..1).each { |i| assert_in_delta(pi_node.evidence[i], 0.73, 0.0001) }            

      pi_node.value_function = ValueFunction.new(0, 73, 'degrees')
      
      (0..1).each { |i| assert_in_delta(pi_node.evidence[i], 1.0, 0.0001) }            
    end  

    # Test flattening of perfind with default data
    def test_perfind_flatten1
      pi   = @mymodel.node_list.add_node(3, 'perfind3', PERFIND)   

      assert_equal( { "name"=>"perfind3", "ident"=>3, "type"=>"perfind",
                      "commentary"=>"", "description"=>"", "evidence"=>"undefined",
                      "value_function"=>nil },
                    pi.flatten_data)
    end

    # Test flattening of perfind with data set
    def test_perfind_flatten2
      pi   = @mymodel.node_list.add_node(3, 'perfind3', PERFIND)            
          
      pi.commentary='com'
      pi.description='dsc'
      pi.value_function=ValueFunction.new(10, 80, 'grams')
      pi.measure_to_evidence(80)
      
      assert_equal( { "name"=>"perfind3", "ident"=>3, "type"=>"perfind",
                      "commentary"=>"com", "description"=>"dsc", "evidence"=>[1.0, 1.0],
                      "value_function"=>{"units"=>"grams", "min_bound"=>10, "max_bound"=>80} },
                    pi.flatten_data)
    end
    
   # Test unflattening data for perfind with all data set
    def test_unflatten_perfind1
      pi = @mymodel.node_list.add_node(4, 'perfind4', PERFIND)
      pi.commentary='com'
      pi.description='dsc'
      pi.value_function=ValueFunction.new(10, 80, 'grams')            
      pi.measure_to_evidence(80)
      
      data = pi.flatten_data
      
      @mymodel.node_list.delete_node(pi)
      
      livenode = @mymodel.node_list.node_from_data(data)
      
      assert_equal(pi.ident, livenode.ident) 
      assert_equal(pi.name, livenode.name) 
      assert_equal(pi.node_type, livenode.node_type)       
      assert_equal(pi.commentary, livenode.commentary)       
      assert_equal(pi.description, livenode.description)       
      assert_equal(pi.evidence, livenode.evidence)             
      assert_equal(pi.value_function, livenode.value_function)                   
    end

   # Test unflattening data for perfind with no value func
    def test_unflatten_perfind2
      pi = @mymodel.node_list.add_node(4, 'perfind4', PERFIND)
      
      data = pi.flatten_data
      
      @mymodel.node_list.delete_node(pi)
      
      livenode = @mymodel.node_list.node_from_data(data)
      
      assert_equal(pi.ident, livenode.ident) 
      assert_equal(pi.value_function, livenode.value_function)                   
    end

    
  end
  
end