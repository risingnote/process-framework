#Export a model to file

require "pstore"
require "Model"

module Perimeta
  module Persist  
    def Persist.export_to_pstore(model, location)
      store = PStore.new(location)
      
      store.transaction do
        store['model'] = model.flatten_data
        model.node_list.all_nodes.each do |node|
          store["node#{node.ident}"] = node.flatten_data
        end
        store['links'] = model.link_list.flatten_data
      end  
      
    end
    
    def Persist.import_from_pstore(location)
      store = PStore.new(location)
      model = nil
      
      store.transaction(true) do
        model = Model.model_from_data(store['model'])
        
        nodekeys = store.roots.select {|item| item[0..3]=='node' }
        
        nodekeys.each do |nodekey|
          model.node_list.node_from_data(store[nodekey])
        end

        store['links']['link_list'].each do |linkdata|
          model.link_list.link_from_data(linkdata)
        end
      end
    
      model
    end
  end
  
end