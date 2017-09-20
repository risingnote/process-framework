# A Perimeta model whose main job is to store lists of objects
require "ObserverPattern"
require "NodeFactory"
require "InformationAttributes"
require "PropagationCalcs"

module Perimeta
  
  class Model
    include InformationAttributes
    
    @@models = {}
    @@log_node_changes = []
    @@high_id = 0
    
    attr_reader(:ident, :node_list, :link_list)
    attr_accessor(:name)    
    
    def initialize(id, name)
      if id.kind_of? Integer
        raise EvidenceError, "Cannot add model with duplicate id #{id}" if id_exists(id)
        @@high_id = id if id > @@high_id
      else
        id = @@high_id += 1
      end
    
      raise ArgumentError, "Model name must be non blank" if name.nil? || name.size == 0        
      
      @ident = id
      @name = name
      @node_list = NodeList.new(self)
      @link_list = LinkList.new(self)
      #Setup the default propagation methods for each node type
      node_propagation_calc(NODE, 'simple_average')      
      node_propagation_calc(PROCESS, 'weighted_average')
      node_propagation_calc(PERFIND, 'measurement')
      node_propagation_calc(MEASUREMENT, nil)
      node_propagation_calc(LOCALEVIDENCE, 'weighted_average')
      node_propagation_calc(PROPEVIDENCE, 'weighted_average')      
      #Add this model to the list of all models
      Model.add(self)
      setup_node_change_log
      super()
    end
    
    def inspect 
      to_s
    end
    
    def to_s 
    "Model #{@ident} #{@name}"
    end
 
    def ==(other)
     self.ident == other.ident
    end
 
    #Run a calculation for all nodes connected to 'node_to' where the nodes support 'method'.
    #There are 3 ways to specify the calculation (each must accept a list of links) :
    #    Pass a block
    #    Pass the name of a propagation calculation specified in PropagationCalcs
    #    Pass neither and use the default for the node type of 'node_to'
    def model_calculation(node_to, method, calc_type=nil)
      links = @link_list.connected_nodes_with_method(node_to, method)
      if block_given?
        yield(links)
      elsif calc_type
        PropagateEvidence.send(calc_type).call(links)
      else
        calc_type = @default_propagation_calcs[node_to.node_type]
        PropagateEvidence.send(calc_type).call(links)        
      end
    end
 
    #Get the next entry as an array [node, [method1, method2, ..]] from the change log.
    #The entry will be removed by this call, returns nil if none found.      
    def consume_next_node_change
      if @node_change_log.size == 0
        nil
      else      
        @node_change_log.shift
      end
    end

    def flatten_data(data={})
      data['ident'] = @ident    
      data['name'] = @name
      data = super(data) if defined?(super)
      data
    end
    
    def unflatten_data(data)
      #No extra attributes to set from data, pass up chain
      super(data) if defined?(super)
    end       

    #Change default propagation calc for a particular node type
    def node_propagation_calc(node_type, calc_type)
      @default_propagation_calcs ||= {}
      @default_propagation_calcs[node_type] = calc_type
    end
     
    #Create and return a model from model data created by flatten_data
    def Model.model_from_data(data)
      modnew = Model.new(data['ident'], data['name'])
      modnew.unflatten_data(data)
      modnew
    end
    
    def Model.add(model)
      @@models[model.ident] = model
    end
    
    def Model.[](ident)
      model = @@models[ident]
      raise EvidenceError, "Model #{name} not found" if model.nil?
      model
    end
    
    def Model.delete(model)
      raise EvidenceError, "The model does not exist" if model.nil? || (not Model[model.ident])
      @@models.delete(model.ident)
    end
    
    def Model.id_names
      idn = {} 
      @@models.each_pair {|id, model| idn[id]=model.name}    
      idn
    end

    #Pass a list of node method symbols to log these changes. Must have a callback 
    #method of form <method>_changed.
    def Model.node_changes_to_log(change_list)
      @@log_node_changes = change_list   
    end

    private
    #Setup the node change log
    def setup_node_change_log
      @node_change_log = Hash.new {|hash, key| Array.new }
      @@log_node_changes.each do |method|
        @node_list.on_node_added do |node|
          callback_method = ('on_' + method.to_s + '_changed').to_sym
          if node.respond_to? callback_method
            node.send(callback_method) do            
              @node_change_log[node] = @node_change_log[node] << 
                  method unless @node_change_log[node].include?(method)
            end
          end                                      
        end
      end
    end

    #Does id already exist in a model - convenience method  
    def id_exists(id)   
      begin
        Model[id]
        true
      rescue EvidenceError
        false
      end
    end
    
  end
  
  # A list of all nodes. Uses has_a pattern holding array of nodes 
  class NodeList
    include ObserverPattern
    
    def initialize(model)
      @model = model
      @node_list = Array.new
      create_observer_methods(self.class, "node_added", "node_removed")
      @high_id = 0
    end
    
    #If id is not number then generate id as next highest id
    def add_node(id, name, node_type=NODE)
      if id.kind_of? Integer
        raise EvidenceError, "Cannot add node with duplicate id #{id}" if id_exists(id)
        @high_id = id if id > @high_id
      else
        id = @high_id += 1
      end
      anode = NodeFactory.create_node(id, name, @model, node_type)
      @node_list.push(anode)
      node_added(anode)
      anode
    end
    
    def delete_node(node)
      raise ArgumentError, "Node must be non blank" if node.nil?
      #Delete any links to this node
      @model.link_list.with_node(node).each do |link|
        @model.link_list.remove_link(link)
      end
      
      @node_list.delete(node)
      node_removed(node)
      node = nil
    end
    
    def size
      @node_list.size
    end
    
    def all_nodes
      @node_list.clone
    end
    
    def node_for_id(ident)
      node = @node_list.find {|node| node.ident == ident }
      raise EvidenceError, "Node #{ident} not found" if node.nil?
      node
    end
    
    def flatten_data(data={})
      data['node_list'] = @node_list.map {|node| [node.ident, node.node_type]}
      data = super(data) if defined?(super)
      data
    end        

    #Create and return a node from node data created by Node.flatten_data
    def node_from_data(data)
      nodenew = add_node(data['ident'], data['name'], data['type'])
      nodenew.unflatten_data(data)
      nodenew
    end
       
    private
    #Does id already exist in a node - convenience method  
    def id_exists(id)   
      begin
        self.node_for_id(id)
        true
      rescue EvidenceError
        false
      end
    end
    
  end
  
  # A list of all links (node -> node) with implied direction. 
  # Uses has_a pattern holding array of Links.
  class LinkList
    include ObserverPattern
    
    def initialize(model)
      @model = model
      @link_list = Array.new
      @del_callbacks = Hash.new {|hash, key| Array.new}
      create_observer_methods(self.class, "link_added", "link_removed")
    end

    # Get a link with these ids
    def link_for_ids(from_id, to_id)
      link = @link_list.find {|link| link.from.ident == from_id && link.to.ident == to_id }
      raise EvidenceError, "Link #{from_id} - #{to_id} not found" if link.nil?
      link
    end
    
    def add_link(from, to, create_default_callbacks=true)
      raise ArgumentError, "From node must be non blank" if from.nil?
      raise ArgumentError, "To node must be non blank" if to.nil?
      raise EvidenceError, "Link #{from.ident} - #{to.ident} already exists" if link_exists(from, to)            
      link = Link.new(from, to)
      @link_list.push(link)
      link.added(create_default_callbacks)
      link_added(link) #callback for anything interested in link being added
      link
    end
    
    def remove_link(link)
      raise ArgumentError, "Link must be non blank" if link.nil?    
      @link_list.delete(link)
      link.removed() #tell the link it is history
      link_removed(link) #callback for anything interested in link being removed
      link = nil
    end
    
    def size
      @link_list.size
    end
    
    def all_links
      @link_list.clone
    end
    
    # Return a list of any links which reference this node
    def with_node(node)
     (@link_list.collect do |link|
        link if link.contains(node)
        end).compact
    end
      
    #Look for any 'from' nodes linked to this node which have the passed method
    #Return the list of links   
    def connected_nodes_with_method(node_to, amethod)
     (@link_list.collect do |link|
        link if (link.to == node_to) && (link.from.respond_to?(amethod)) 
        end).compact
    end
      
    def flatten_data(data={})
      data['link_list'] = @link_list.map {|link| link.flatten_data}
      data = super(data) if defined?(super)
      data
    end        

    #Create and return a link from link data created by Link.flatten_data
    def link_from_data(data)
      node_from = @model.node_list.node_for_id(data['from_id'])
      node_to = @model.node_list.node_for_id(data['to_id'])      
      linknew = add_link(node_from, node_to)
      linknew.unflatten_data(data)
      linknew
    end

    private
    #Does link already exist - convenience method  
    def link_exists(from, to)   
      begin
        self.link_for_ids(from.ident, to.ident)
        true
      rescue EvidenceError
        false
      end
    end
      
  end
  
  #A directed link from one node to another.    
  class Link

    attr_reader(:from, :to)
    attr_accessor(:weight)        
    
    def initialize(from, to)
      @from = from
      @to = to
      @weight = nil
    end
    
    #Run setup tasks if link has been added to list
    def added(create_default_callbacks)  
      from.linked_to(to, create_default_callbacks)
    end
    
    #Run tidy up tasks if link has been removed from list
    def removed  
      from.unlinked_to(to)    
    end
    
    def inspect 
      to_s
    end
    
    def to_s 
      "Link #{@from} -> #{@to}"
    end
    
    def ==(other)
     (self.from == other.from) && (self.to == other.to)
    end
    
    def contains(node)
      from == node || to == node
    end
    
    def flatten_data(data={})
      data['from_id'] = @from.ident
      data['to_id'] = @to.ident    
      data = super(data) if defined?(super)
      data
    end  
    
    def unflatten_data(data)
      #Nothing to do here (links are created in LinkList)
      super(data) if defined?(super)
    end       
    
  end
      
  class EvidenceError < RuntimeError
    def initialize(msg)
      super(msg)
    end
  end

end
    
    

    