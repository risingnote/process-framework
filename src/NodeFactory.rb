require "ObserverPattern"
require "InformationAttributes"
require "PerformanceIndicator"
require "Measurement"
require "Evidence"

module Perimeta
  NODE    = 'node'
  PROCESS = 'process'
  PERFIND = 'perfind'
  MEASUREMENT = 'measurement'  
  LOCALEVIDENCE = 'localev'    
  PROPEVIDENCE = 'propev'
  
  class NodeFactory
    
    def NodeFactory.create_node(ident, name, model, node_type)
      if node_type == PROCESS
        klass = Class.new(Node) do
                  include InformationAttributes
                  include Evidence
                  def initialize(*a, &b)
                    super
                  end
                end
      elsif node_type == PERFIND
        klass = Class.new(Node) do
                  include InformationAttributes
                  include PerformanceIndicator
                  include Evidence                  
                  def initialize(*a, &b)
                    super
                  end
                end
      elsif node_type == MEASUREMENT
        klass = Class.new(Node) do
                  include Measurement
                  def initialize(*a, &b)
                    super
                  end
                end
      elsif node_type == LOCALEVIDENCE
        klass = Class.new(Node) do
                  include Evidence
                  def initialize(*a, &b)
                    super
                  end
                end
      elsif node_type == PROPEVIDENCE
        klass = Class.new(Node) do
                  include Evidence
                  def initialize(*a, &b)
                    super
                  end
                end
      else
        klass = Class.new(Node) do
                  def initialize(*a, &b)
                    super
                  end
                end
      end
      klass.new(ident, name, model, node_type)
    end
    
  end
  
  # All types of node have this as super class. Knows about which model it belongs to.
  class Node
    include ObserverPattern
    
    attr_accessor(:name)
    attr_reader(:ident, :model, :node_type, :del_callbacks)
    protected :model
    
    def initialize(*a, &b)
      @ident = a[0]
      @name = a[1]
      @model = a[2]
      @node_type = a[3]
      #For each 'linked to node' store a list of procs to execute to remove callbacks
      @del_callbacks = Hash.new {|hash, key| Array.new }
    end
 
    #Called when this node is linked to another (this node is child)
    # create_default_callbacks of true indicates callbacks should be setup
    def linked_to(to_node, create_default_callbacks)
      super if defined?(super)
    end

    #Called when this node is unlinked from another (this node is child)
    def unlinked_to(to_node)
      @del_callbacks[to_node].each do |proc|
        proc.call
      end
      super if defined?(super)
    end
    
    def inspect 
      to_s
    end
    
    def to_s 
      "Node ident #{@ident} name #{@name}"
    end
    
    def ==(other)
      if (other.respond_to?(:ident))
        self.ident == other.ident
      else
        nil
      end        
    end

    def flatten_data(data={})
      data['ident'] = @ident
      data['name'] = @name
      data['type'] = @node_type      
      data = super(data) if defined?(super)
      data
    end

    def unflatten_data(data)
      #Nothing to do here (nodes are created in NodeList)
      super(data) if defined?(super)
    end       

  end

end
