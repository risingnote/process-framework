$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "src")

require 'test/unit'
require 'Model'
require 'PersistModel'

module Perimeta
  
  class TestPersistance < Test::Unit::TestCase
    def setup
    end
    
    def teardown
      Model.id_names.each_key do |id|
        Model.delete(Model[id])
      end
    end
    
    # Test exporting a model to a pstore
    def test_export_to_pstore
      model=Model.new(2, 'pstore persistance')
      model.description = 'will be deleted between tests'
      model.commentary = 'and they are off'
      
      proc1 = model.node_list.add_node(1, 'process one', PROCESS)
      proc2 = model.node_list.add_node(2, 'process two', PROCESS)
      proc1.evidence = [0.2, 0.3]
      model.link_list.add_link(proc1, proc2)
      
      Persist.export_to_pstore(model, 'models/unittest1')
    end

    # Test importing a model from a pstore
    def test_import_from_pstore
      model = Persist.import_from_pstore('models/unittest1')

      assert_equal(2, model.ident)      
      assert_equal('pstore persistance', model.name)
      assert_equal('will be deleted between tests', model.description)      
      assert_equal('and they are off', model.commentary)
      
      assert_equal(2, model.node_list.size)      
      assert_equal(1, model.link_list.size)
      
      assert_equal([0.2, 0.3], model.node_list.node_for_id(1).evidence)            
    end

  end
  
end