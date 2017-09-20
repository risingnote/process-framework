# A mixin class that adds evidence to a node

module Perimeta
  
  module Evidence

    attr_accessor(:propagation_calc)
    
    def initialize(*a, &b)
      super
      create_observer_methods(self.class, "evidence_changed")
      @evidence = 'undefined'
      @propagation_calc = nil
    end

    #Called when this node to linked to another (this node is child)
    def linked_to(to_node, create_default_callbacks)
      if create_default_callbacks && to_node.respond_to?(:propagate_evidence)
        cbid = on_evidence_changed {to_node.propagate_evidence}
        to_node.propagate_evidence
        del_callbacks[to_node] = del_callbacks[to_node] << 
                                      proc {self.del_evidence_changed(cbid)}
      end      
      super if defined?(super)
    end

    #Called when this node is unlinked from another (this node is child)
    def unlinked_to(to_node)
      if to_node.respond_to?(:propagate_evidence)
        to_node.propagate_evidence
      end
      super if defined?(super)
    end
    
    #Evidence should be array size 2 containing numeric or the undefined value
    def evidence=(evidence)
      evidence, errmsg = validate_evidence(evidence)
      raise ArgumentError, errmsg if errmsg
      
      if evidence != @evidence
        @evidence = evidence    
        evidence_changed evidence
      end
    end
    
    def evidence
      @evidence
    end

    #Calculate evidence by combining evidence from child nodes
    def propagate_evidence
      #Ask the model to look for connected evidence nodes and return the calculated evidence
      # Use the propagation calculation indicated by the @propagation_calc attribute (may be nil)
      self.evidence = model.model_calculation(self, :evidence, @propagation_calc)
    end
    
    def flatten_data(data={})
      data['evidence'] = @evidence
      data = super(data) if defined?(super)
      data
    end

    #Given hash of state, set instance variables
    def unflatten_data(data)
      @evidence = data['evidence']
      super(data) if defined?(super)
    end       

    def Evidence.undefined
      'undefined'
    end

    private
    def validate_evidence(evidence) 
      errmsg = nil
      if evidence.nil?
        errmsg = "An evidence value is required"
      elsif evidence == Evidence.undefined
        #OK
      elsif evidence.kind_of?(Array)
        if evidence.size != 2
          errmsg = "Evidence can only contain 2 values : #{evidence.inspect}"
        elsif not (evidence[0] >= 0.0 && evidence[0] <= 1.0) && 
                  (evidence[1] >= 0.0 && evidence[0] <= 1.0)
          errmsg = "Evidence must be numeric in range 0-1 : #{evidence.inspect}" 
        end
      else
        if not evidence >= 0.0 && evidence <= 1.0
          errmsg = "Evidence must be numeric in range 0-1 : #{evidence.inspect}"
        else
          evidence = [evidence, evidence]
        end
      end
      [evidence, errmsg]
    end
          
  end 

end

