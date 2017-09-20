# Example of hierarchical process model as in Perimeta, with points of view
require "PMProcess"

module Perimeta
  
  #----------------------------- Define the processes ---------------------------------------
  weighted_average = <<-END_OF_STRING
    if @local_evidence.evidence == 'undefined' &&
       @propagate_evidence.evidence == 'undefined'
      self.evidence = 'undefined'
    elsif @local_evidence.evidence == 'undefined'
      self.evidence = @propagate_evidence.evidence
    elsif @propagate_evidence.evidence == 'undefined'
      self.evidence = @local_evidence.evidence    
    else 
      self.evidence = (@local_evidence.evidence * @local_weight + 
                       @propagate_evidence.evidence * @propagate_weight) /
                       (@local_weight + @propagate_weight)
    end
        
  END_OF_STRING
  
  ProcessFactory.define_process('SummaryEvidence',
                       [[:description, %q\''\], [:evidence, %q\'undefined'\],
                          [:local_evidence, 'ProcessFactory.create_process("LocalEvidence")'],
                          [:local_weight, '0.5'], 
                          [:propagate_evidence, 'ProcessFactory.create_process("PropagateEvidence")'],
                          [:propagate_weight, '0.5'],
                          [:propagate_status, 'ProcessFactory.create_process("PropagateStatus")']],
                       [:'local_evidence/evidence', :'propagate_evidence/evidence',
                          :'propagate_status/on'],
                       weighted_average)


  prop_average = <<-END_OF_STRING 
        sum, cnt = 0, 0 
        @childlinks.each do |link|
          #Only propagate evidence if child procs are switched on
          if link.childproc.propagate_status.on
            if not link.childproc.evidence == 'undefined'   
              sum += link.childproc.evidence * link.weight
              cnt += 1
            end
          end
        end
        self.evidence = cnt == 0 ? 'undefined' : sum/cnt
   END_OF_STRING
  
  ProcessFactory.define_process('PropagateEvidence',
                       [[:childlinks, '[]'], [:evidence, %q\'undefined'\]],
                       [:childlinks, :'childlinks/weight', :'childlinks/childproc'],
                       prop_average)

  ProcessFactory.define_process('LocalEvidence',
                       [[:childlinks, '[]'], [:evidence, %q\'undefined'\]],
                       [:childlinks, :'childlinks/weight', :'childlinks/childproc'],
                       prop_average)

  ProcessFactory.define_process('PerformanceIndicatorLinear',
                       [[:description, %q\''\], [:measure, 'nil'], [:evidence, %q\'undefined'\], 
                        [:min_bound, '0.0'], [:max_bound, '100.0'],
                        [:propagate_status, 'ProcessFactory.create_process("PropagateStatus")']],
                       [:measure, :min_bound, :max_bound, :'propagate_status/on'],
    "self.evidence = @measure.nil? ? 'undefined' : (@measure - @min_bound) / (@max_bound - @min_bound)")

  ProcessFactory.define_process('GenericLink',
                       [[:childproc, 'nil'], [:weight, '0.0']],
                       [:'childproc/evidence'],
                       "attr_set(:childproc)")

  prop_status = <<-END_OF_STRING
      if not @manual
        self.on = false
      elsif @points_of_view.size == 0
        self.on = true
      elsif @points_of_view.find {|pov| pov.include == true }
        self.on = true
      else 
        self.on = false
      end
  END_OF_STRING
  
  ProcessFactory.define_process('PropagateStatus',
                       [[:on, 'true'], [:manual, 'true'], [:points_of_view, '[]']],
                       [:manual, :points_of_view, :'points_of_view/include'],
                       prop_status)
                       
  ProcessFactory.define_process('PointOfView',
                       [[:description, %q\''\], [:include, 'true']],
                       [],
                       "")

  #----------------------------- Build the model -----------------------------------------------    
  p1 = ProcessFactory.create_process('SummaryEvidence', 'proc1')                       
  p1.description = 'Top level process'

puts "evidence p1 on own (expect undefined) #{p1.evidence}"

  p2 = ProcessFactory.create_process('SummaryEvidence', 'proc2')                       
  p2.description = 'Some child process 2'    
  p2.local_evidence.evidence = 0.8

puts "evidence p2 on own (expect 0.8) #{p2.evidence}"

  p3 = ProcessFactory.create_process('SummaryEvidence', 'proc3')                       
  p3.description = 'Some child process 3'  
  p3.local_evidence.evidence = 0.6
  
puts "evidence p3 on own (expect 0.6) #{p3.evidence}"  

  link2 = ProcessFactory.create_process('GenericLink', 'link2')                         
  link2.childproc = p2
  link2.weight = 0.3

  link3 = ProcessFactory.create_process('GenericLink', 'link3')                         
  link3.childproc = p3
  link3.weight = 0.5

  p1.propagate_evidence.childlinks_add(link2)
  p1.propagate_evidence.childlinks_add(link3)

puts "Add links #{p1.propagate_evidence.childlinks.inspect} evidence (should be 0.27) #{p1.evidence}"  
  
  pi1 = ProcessFactory.create_process('PerformanceIndicatorLinear', 'pi1')
  pi1.description = 'my first perf ind'
  pi1.measure = 45
  
puts "evidence pi1 on own (expect 0.45) #{pi1.evidence}"  

  pi2 = ProcessFactory.create_process('PerformanceIndicatorLinear', 'pi2')
  pi2.description = 'my second perf ind'
  pi2.measure = 50
  pi2.max_bound = 200

puts "evidence pi2 on own (expect 0.25) #{pi2.evidence}"  

  link4 = ProcessFactory.create_process('GenericLink', 'link4')                         
  link4.childproc = pi1
  link4.weight = 0.6
  link5 = ProcessFactory.create_process('GenericLink', 'link5')                         
  link5.childproc = pi2
  link5.weight = 0.9

  p1.local_evidence.childlinks_add(link4)
  p1.local_evidence.childlinks_add(link5)
  
puts "Add perfinds local evidence (should be 0.2475) #{p1.local_evidence.evidence}"    
puts "Add perfinds p1 evidence (should be 0.25875) #{p1.evidence}"    
  
  asthetic = ProcessFactory.create_process('PointOfView', 'asthetic')                         
  asthetic.description = "Used to classify objects which contribute to the asthetic performance"
  asthetic.include = false

  pi2.propagate_status.points_of_view_add(asthetic)
  
  puts "Ignore asthetic point of view, switch off pi2, evidence (should be 0.27) #{p1.evidence}"      
  
  asthetic.include = true
  
  puts "Include asthetic point of view evidence (should be 0.25875) #{p1.evidence}"      

end
