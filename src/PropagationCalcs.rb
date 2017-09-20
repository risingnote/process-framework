#The propagation calculations to calculate evidence from children to parent

module Perimeta
  module PropagateEvidence
    
    def PropagateEvidence.simple_average()
      Proc.new {|links|
        if links.size == 0
          Evidence.undefined
        else
          # run calculation (average for now)
          (links.inject([0.0,0.0]) do |sum, link|
              (0..1).collect{|i|
                 sum[i] + (link.from.evidence == Evidence.undefined ? 
                                    [0.0, 1.0] : link.from.evidence)[i]}
           end).collect{|x| x/links.size}
        end}
    end
    
    def PropagateEvidence.weighted_average()
      Proc.new {|links|
        if links.size == 0
          Evidence.undefined
        else
          ev_sum = [0.0, 0.0]
          weight_sum = 0.0
          for link in links
            weight = link.weight == nil ? 0.0 : link.weight
            weight_sum += weight 
            evidence = link.from.evidence == Evidence.undefined ? [0.0,1.0] : link.from.evidence
            ev_sum[0] += weight * evidence[0]
            ev_sum[1] += weight * evidence[1]            
          end
          if weight_sum == 0.0
            Evidence.undefined
          else
            ev_result = [ev_sum[0]/weight_sum, ev_sum[1]/weight_sum]
          end
        end}
    end
    
  end
end
