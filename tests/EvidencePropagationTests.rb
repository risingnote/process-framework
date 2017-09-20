$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "src")

require 'test/unit'
require 'Model'

module Perimeta
  
  class TestEvidencePropagation < Test::Unit::TestCase
    def setup
      @mymodel = Model.new(1, "rubylicious")  
    end
    
    def teardown
      Model.delete(@mymodel)
    end
    
    # Test that measure change is propagated to a process evidence value (not using links)
    def test_evidence_prop
      nodelist = @mymodel.node_list
      
      measure  = nodelist.add_node(1, 'my measure', MEASUREMENT);
      perf_ind = nodelist.add_node(2, 'my pi', PERFIND);
      perf_ind.value_function = ValueFunction.new(0, 100, 'degrees')
      process = nodelist.add_node(3, 'my process', PROCESS);      
      
      measure.on_measurement_changed {|measure| perf_ind.measure_to_evidence(measure)}

      perf_ind.on_evidence_changed {|evidence| process.evidence = evidence}
      
      measure.measurement =  78.9

      (0..1).each { |i| assert_in_delta(process.evidence[i], 0.789, 0.0001) }
    end

    # Test that measure change is propagated to 2 process evidence values using links 
    # simple average.
    def test_evidence_prop2
      nodelist = @mymodel.node_list
      linklist = @mymodel.link_list
      @mymodel.node_propagation_calc(PROCESS, 'simple_average')
      
      measure  = nodelist.add_node(1, 'my measure', MEASUREMENT);
      perf_ind = nodelist.add_node(2, 'my pi', PERFIND);
      perf_ind.value_function = ValueFunction.new(0, 100, 'degrees')
      process1 = nodelist.add_node(3, 'my process', PROCESS);
      process2 = nodelist.add_node(4, 'my process', PROCESS);            

      linklist.add_link(measure, perf_ind)
      linklist.add_link(perf_ind, process1)
      linklist.add_link(perf_ind, process2)      
            
      measure.measurement =  78.9
      
      (0..1).each { |i| assert_in_delta(perf_ind.evidence[i], 0.789, 0.0001) }
      (0..1).each { |i| assert_in_delta(process1.evidence[i], 0.789, 0.0001) }      
      (0..1).each { |i| assert_in_delta(process2.evidence[i], 0.789, 0.0001) }      
    end


   # Test multiple evidence propagation (using simple average)    
    def test_evidence_prop3
      nodelist = @mymodel.node_list
      linklist = @mymodel.link_list
      @mymodel.node_propagation_calc(PROCESS, 'simple_average')      
      
      process1 = nodelist.add_node(1, 'process 1', PROCESS);      
      process2 = nodelist.add_node(2, 'process 2', PROCESS);      
      process3 = nodelist.add_node(3, 'process 3', PROCESS);      
      process4 = nodelist.add_node(4, 'process 4', PROCESS);      
      process5 = nodelist.add_node(5, 'process 5', PROCESS);      
      process6 = nodelist.add_node(6, 'process 6', PROCESS);                                    

      linklist.add_link(process2, process1)
      linklist.add_link(process3, process1)
      linklist.add_link(process4, process3)
      linklist.add_link(process5, process3)
      linklist.add_link(process6, process3)      
            
      process2.evidence = 0.3
      process4.evidence = 0.7
      process6.evidence = [0.8, 1.0]

      (0..1).each { |i| assert_in_delta(process1.evidence[i], [0.4, 0.6][i], 0.0001) }            
    end

   # Test evidence propagation (using weighted average - the default)    
    def test_evidence_prop_weighted_average
      nodelist = @mymodel.node_list
      linklist = @mymodel.link_list
      
      process1 = nodelist.add_node(1, 'process 1', PROCESS);      
      process2 = nodelist.add_node(2, 'process 2', PROCESS);      
      process3 = nodelist.add_node(3, 'process 3', PROCESS);      
      process4 = nodelist.add_node(4, 'process 4', PROCESS);      
      process5 = nodelist.add_node(5, 'process 5', PROCESS);

      link1 = linklist.add_link(process2, process1)
      link2 = linklist.add_link(process3, process1)
      link3 = linklist.add_link(process4, process1)
      link4 = linklist.add_link(process5, process1)
      
      link2.weight = 2
      link3.weight = 4      
      link4.weight = 2.0
            
      process2.evidence = 0.3
      process3.evidence = [0.4, 0.6]
      process4.evidence = 0.8      

      (0..1).each { |i| assert_in_delta(process1.evidence[i], [0.5, 0.8][i], 0.0001) }            
    end

   # Test evidence propagation pi contributing to local evidence, procs to propagated evidence
   # (using weighted average - the default method)
   def test_evidence_prop_local_and_prop
      nodelist = @mymodel.node_list
      linklist = @mymodel.link_list
      
      process1 = nodelist.add_node('autonum', 'process 1', PROCESS);      
      proc1_local = nodelist.add_node('autonum', 'proc1 local', LOCALEVIDENCE);      
      proc1_prop = nodelist.add_node('autonum', 'proc1 prop', PROPEVIDENCE);            
      pi1 = nodelist.add_node('autonum', 'perfind 1', PERFIND);      
      pi2 = nodelist.add_node('autonum', 'perfind 2', PERFIND);            
      process2 = nodelist.add_node('autonum', 'process 2', PROCESS);      
      process3 = nodelist.add_node('autonum', 'process 3', PROCESS);

      link1 = linklist.add_link(proc1_local, process1)
      link2 = linklist.add_link(proc1_prop, process1)
      link3 = linklist.add_link(pi1, proc1_local)
      link4 = linklist.add_link(pi2, proc1_local)      
      link5 = linklist.add_link(process2, proc1_prop)
      link6 = linklist.add_link(process3, proc1_prop)      
      
      link1.weight = 1
      link2.weight = 2      
      link3.weight = 0.5
      link4.weight = 0.5
      link5.weight = 1
      link6.weight = 3
            
      pi1.evidence = [0.2, 0.4]
      pi2.evidence = [0.5, 0.8]
      process2.evidence = [0.4, 0.6]
      process3.evidence = 0.8      

      (0..1).each { |i| assert_in_delta(process1.evidence[i], [0.5833, 0.7][i], 0.0001) }            
    end

  end
  
end
