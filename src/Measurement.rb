# A mixin class that adds measurement data and behaviour to a node

module Perimeta

  module Measurement
    def initialize(*a, &b)
      super
      create_observer_methods(self.class, "measurement_changed")
      @measure = nil
    end
 
    #Called when this node to linked to another (this node is child)
    # create_default_callbacks of true indicates callbacks should be setup
    def linked_to(to_node, create_default_callbacks)
      if create_default_callbacks && to_node.respond_to?(:measure_to_evidence)
        cbid = on_measurement_changed {|measure| to_node.measure_to_evidence(measure)}
        to_node.measure_to_evidence(@measure)
        del_callbacks[to_node] = del_callbacks[to_node] <<         
                                        proc {self.del_measurement_changed(cbid)}
      end      
      super if defined?(super)
    end

    #Called when this node is unlinked from another (this node is child)
    def unlinked_to(to_node)
      if to_node.respond_to?(:measure_to_evidence)
        to_node.measure_to_evidence(nil)
      end
      super if defined?(super)
    end
       
    def measurement=(measure)
      @measure = measure.to_f
      measurement_changed measure
    end

    def measurement
      @measure
    end
    
    def flatten_data(data={})
      data['measurement'] = @measure
      data = super(data) if defined?(super)
      data
    end        

    #Given hash of state, set instance variables
    def unflatten_data(data)
      @measure = data['measurement']
      super(data) if defined?(super)
    end       
    
  end  
  
end

