$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "src")

require 'test/unit'
require 'NodeFactory'

module Perimeta
  
  class TestNodeFactory < Test::Unit::TestCase
    def setup
    end
    
    def teardown
    end
    
    # Test the method signature of the default node with no additional behaviour
    def test_plain_node
      node = NodeFactory::create_node(1, 'Plain Node', nil, NODE)
      
      %w(to_s == name name= ident node_type inspect).each do
          |method|
          assert(node.public_methods(true).include?(method),
                   "Node does not contain method #{method}")
      end      
    end

    # Test the method signature of the process node
    def test_process_node
      node = NodeFactory::create_node(2, 'Test Process', nil, PROCESS)

      #Additional information methods
      %w(description description= commentary commentary=).each do
          |method|
          assert(node.public_methods(true).include?(method),
                   "Node does not contain method #{method}")
      end      
      
      #Additional evidence methods
      %w(evidence evidence=).each do
          |method|
          assert(node.public_methods(true).include?(method),
                   "Node does not contain method #{method}")
      end      
    end

    # Test the method signature of the performance indicator node
    def test_perfind_node
      node = NodeFactory::create_node(3, 'Test Perf ind', nil, PERFIND)
      
      #Additional information methods
      %w(description description= commentary commentary=).each do
          |method|
          assert(node.public_methods(true).include?(method),
                   "Node does not contain method #{method}")
      end      

      #Additional perf ind methods
      %w(value_function value_function= measure_to_evidence evidence).each do
          |method|
          assert(node.public_methods(true).include?(method),
                   "Node does not contain method #{method}")
      end      
    end

    # Test the method signature of the measurement node
    def test_perfind_node
      node = NodeFactory::create_node(4, 'Test measure', nil, MEASUREMENT)
      
      #Additional measurement methods
      %w(measurement measurement=).each do
          |method|
          assert(node.public_methods(true).include?(method),
                   "Node does not contain method #{method}")
      end      
    end

  end
  
end