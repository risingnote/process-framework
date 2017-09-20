$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "src")

require 'test/unit'
require 'Model'
require 'NodeFactory'

module Perimeta
  
  class TestEvidence < Test::Unit::TestCase
    def setup
      @mymodel = Model.new(1, "rubylicious")
      @proc = @mymodel.node_list.add_node(1, 'proc1', PROCESS)
    end
    
    def teardown
      Model.delete(@mymodel)    
    end
    
    # Test assigning valid evidence value
    def test_valid_evidence
      @proc.evidence = Evidence.undefined
      assert_equal(Evidence.undefined, @proc.evidence)

      @proc.evidence = 0.4
      assert_equal([0.4,0.4], @proc.evidence)

      @proc.evidence = [0.23, 0.56]
      assert_equal([0.23, 0.56], @proc.evidence)
    end

    # Test assigning invalid evidence value
    def test_invalid_evidence
      begin
        @proc.evidence = nil
        assert(false)
      rescue ArgumentError => problem
        assert(true)
      end

      begin
        @proc.evidence = [0.1, 0.2, 0.3]
        assert(false)
      rescue ArgumentError => problem
        assert(true)
      end

      begin
        @proc.evidence = [-0.2, 1.2]
        assert(false)
      rescue ArgumentError => problem
        assert(true)
      end

      begin
        @proc.evidence = 12
        assert(false)
      rescue ArgumentError => problem
        assert(true)
      end
      
    end
    
  end
  
end