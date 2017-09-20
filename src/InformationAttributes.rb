# A mixin class that allows a set of information attributes to be added

module Perimeta
  
  module InformationAttributes
    
    attr_accessor(:description, :commentary)
    
    def initialize(*a, &b)
      @description = ''
      @commentary = ''      
      super
    end

    #Called when this node is linked to another (this node is child)
    # create_default_callbacks of true indicates callbacks should be setup
    def linked_to(to_node, create_default_callbacks)
      super if defined?(super)
    end

    #Called when this node is unlinked from another (this node is child)
    def unlinked_to(to_node)
      super if defined?(super)
    end

    #Return the data needed to persist this class as a hash
    def flatten_data(data={})
      data['description'] = @description
      data['commentary'] = @commentary
      data = super(data) if defined?(super)
      data
    end

    #Given hash of state, set instance variables
    def unflatten_data(data)
      @description = data['description']
      @commentary = data['commentary']
      super(data) if defined?(super)
    end       

  end  
  
end

