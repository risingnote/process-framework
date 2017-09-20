# A mixin class that adds performance indicator behaviour 
#  for example a value function and a method to calculate evidence using
#  a measurement. Needs to be added to a node.
require "Evidence"

module Perimeta
  
  module PerformanceIndicator
  
    def initialize(*a, &b)
      super
      @value_function = nil
    end

    #Called when this node to linked to another (this node is child)
    # create_default_callbacks of true indicates callbacks should be setup
    def linked_to(to_node, create_default_callbacks)
      super if defined?(super)
    end

    #Called when this node is unlinked from another (this node is child)
    def unlinked_to(to_node)
      super if defined?(super)
    end
    
    def value_function=(vf)
      @value_function = vf
      #Ask the model to look for connected measurement nodes and return the first measurement
      meas = model.model_calculation(self, :measurement) do |links|
        if links.size == 0
          nil
        else
          links[0].from.measurement
        end
      end

      measure_to_evidence(meas)
    end
    
    def value_function
      @value_function
    end

    def measure_to_evidence(measurement)
      if (!@value_function || !measurement)
        ev = Evidence.undefined
      else
        ev = @value_function.calc_evidence(measurement)
      end
      self.evidence = ev
      ev
    end
    
    def flatten_data(data={})
      data['value_function'] = if value_function.nil? then nil 
                                else value_function.flatten_data end
      data = super(data) if defined?(super)
      data
    end        
 
     #Given hash of state, set instance variables
    def unflatten_data(data)
      vf_data = data['value_function']
      unless vf_data.nil?
        @value_function = ValueFunction.new(vf_data['min_bound'], 
                                   vf_data['max_bound'], vf_data['units'])
      end
      super(data) if defined?(super)
    end       
    
  end 
  
  class ValueFunction
    attr_reader(:min_bound, :max_bound, :units)
    #Want numbers to be held as floats
    def initialize(min, max, units)
      @min_bound = min.to_f
      @max_bound = max.to_f
      @units = units
    end

    #measure should have a to_f method
    def calc_evidence(measure)
      (measure.to_f - @min_bound) / (@max_bound - @min_bound)
    end
    
    def flatten_data(data={})
      data['min_bound'] = @min_bound
      data['max_bound'] = @max_bound
      data['units'] = @units
      data = super(data) if defined?(super)
      data
    end        

     #Given hash of state, set instance variables
    def unflatten_data(data)
      #Nothing additional to do here
      super(data) if defined?(super)
    end 
    
    def ==(other)
      if (other.respond_to?(:min_bound))
        self.min_bound == other.min_bound &&
        self.max_bound == other.max_bound &&
        self.units == other.units
      else
        nil
      end        
    end
          
                    
  end
  
end
