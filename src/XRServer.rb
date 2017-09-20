# Provide an xmlrpc server to receive requests for evidence graph information
#
# Can multiple values be returned ???? ie. node id and a list of recent changes ?

require "xmlrpc/server"
require "Model"
require "NodeFactory"

module Perimeta

  server = XMLRPC::Server.new(8020, "localhost", 4, stdlog=$stdout, false, false)
  
  class EvidenceHandler

    def all_models
      tidy(Model.id_names)
    end
  
    def model(model_id)
      tidy(Model[model_id].flatten_data)
    end

    def add_model(model_name)
      tidy(Model.new('autonum', model_name).flatten_data)
    end

    def delete_model(model_id)
      Model.delete(Model[model_id])
      {'ok'=>"model #{model_id} deleted"}
    end

    def update_model(model_id, methods)
      model = Model[model_id]

      # Security considerations, validate method against list of possible methods?
      methods.each_pair do |method, value|
        model.send((method+'=').to_sym, value)
      end
      
      {'ok'=>"model #{model_id} updated"}
    end 

    def nodelist(model_id) 
      model = Model[model_id]
      tidy(model.node_list.flatten_data)
    end

    def node(model_id, node_id)
      model = Model[model_id]
      node = model.node_list.node_for_id(node_id)
      tidy(node.flatten_data)
    end

    def add_node(model_id, name, node_type)
      model = Model[model_id]
      node = model.node_list.add_node('autonum', name, node_type);
      tidy(node.flatten_data)
    end
 
    def delete_node(model_id, node_id) 
      model = Model[model_id]
      model.node_list.delete_node(model.node_list.node_for_id(node_id));
      {'ok'=>"node #{node_id} deleted"}    
    end 

    def update_node(model_id, node_id, method, value)
      model = Model[model_id]
      node_list = model.node_list
      node = node_list.node_for_id(node_id)

      # Security considerations, validate method against list of possible methods?
      if method == 'value_function'
        value = ValueFunction.new(value['min_bound'], value['max_bound'], value['units'])
      end
      node.send((method+'=').to_sym, value)
      
      #If there are any outstanding node evidence changes to be notified then return them
      # as hash with key of node id (passed as string) and value of evidence
      idEvidence = build_change_list(model, :evidence)      
      idEvidence.empty? ? {'ok'=>"node #{node_id} updated"} : idEvidence
    end 

    def linklist(model_id) 
      model = Model[model_id]
      tidy(model.link_list.flatten_data)
    end
    
    def add_link(model_id, from_id, to_id)
      model = Model[model_id]
      model.link_list.add_link(model.node_list.node_for_id(from_id),
                               model.node_list.node_for_id(to_id));
                               
      #If there are any outstanding node evidence changes to be notified then return them
      # as hash with key of node id (passed as string) and value of evidence
      idEvidence = build_change_list(model, :evidence)
      idEvidence.empty? ? {'ok'=>"link #{from_id} - #{to_id} added"} : idEvidence
    end
    
    def delete_link(model_id, from_id, to_id)
      model = Model[model_id]
      link_list = model.link_list
      link_list.remove_link(link_list.link_for_ids(from_id, to_id))
      
      #If there are any outstanding node evidence changes to be notified then return them
      # as hash with key of node id (passed as string) and value of evidence
      idEvidence = build_change_list(model, :evidence)
      idEvidence.empty? ? {'ok'=>"link #{from_id} - #{to_id} deleted"} : idEvidence
    end
     
    private 
    #Replace nil values with a NIL245 string as nil is not valid in xmlrpc
    def tidy(hash)
      hash.each {|key,value| if value==nil then hash[key]='NIL245' end}
    end

    #From the list of outstanding node changes get a hash of node id and value pairs for 
    # the requested method.
    def build_change_list(model, method)
      idValue = {}
      while (h = model.consume_next_node_change())
        h[1].each do |change_method|
          if change_method == method
            idValue[h[0].ident] = h[0].send(change_method)
          end
        end
      end
      idValue
    end
    
  end
  
  server.add_handler(XMLRPC::iPIMethods("evidence"), EvidenceHandler.new)

  Model.node_changes_to_log([:evidence])

  #Needs webrick server ?
  # trap("INT") { server.shutdown }

  server.serve

end