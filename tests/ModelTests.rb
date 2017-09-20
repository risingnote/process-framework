$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "src")

require 'test/unit'
require 'Model'

module Perimeta
  
  class TestModel < Test::Unit::TestCase
    def setup
      @mymodel = Model.new(1, "rubylicious") 
    end
    
    def teardown
      Model.id_names.each_key do |id|
        Model.delete(Model[id])
      end
    end
    
    # Test Model class methods for storing a list of models
    def test_model_stored
      model=Model[1]
      assert_equal(@mymodel, model)
      
      newmodel = Model.new(2, 'short term')  
      assert_equal(Model[2], newmodel)
      Model.delete(newmodel)

      begin
        Model[newmodel.ident]
        assert(false)
      rescue EvidenceError
        assert(true)
      end
    end

    # Test retrieving a list of model id and names
    def test_id_names
      Model.new('autonum', 'model x')  
      Model.new('autonum', 'model y')
      
      assert_equal(Model.id_names.size, 3)
      assert_equal(Model.id_names, {1=>'rubylicious', 2=>'model x', 3=>'model y'})
    end
    
    
    # Test that node and linklists are created
    def test_lists
      nodelist = @mymodel.node_list
      linklist = @mymodel.link_list
      
      assert(nodelist.size == 0)
      assert(linklist.size == 0)
    end
    
    def test_information_attributes
      assert_equal(@mymodel.description,"")
      assert_equal(@mymodel.commentary, "")     
      
      @mymodel.description = 'About this model'
      @mymodel.commentary = 'Talk about me' 
      
      assert_equal(@mymodel.description, 'About this model')
      assert_equal(@mymodel.commentary, 'Talk about me')     
    end
    
    def test_no_name
      begin 
        name = nil
        Model.new(2, name)
        assert(false)
      rescue ArgumentError
        assert_equal(1, Model.id_names.size)
      end
      begin 
        Model.new("")
        assert(false)
      rescue ArgumentError
        assert_equal(1, Model.id_names.size)
      end
    end
    
    def test_add_duplicate
      begin 
        Model.new(1, "rubylicious")
        assert(false)
      rescue EvidenceError
        assert_equal(1, Model.id_names.size)
      end
    end

    def test_delete_nomodel
      begin 
        Model.delete(Model[44])
        assert(false)
      rescue EvidenceError
        assert_equal(1, Model.id_names.size)
      end
    end
 
    # Test flattening data for model with defaults
    def test_flatten_model
      assert_equal( { "ident"=>1, "name"=>"rubylicious", "commentary"=>"", "description"=>""},
                    @mymodel.flatten_data)
    end

    # Test recovering model from flattened data
    def test_unflatten_model
      comm = @mymodel.commentary = 'should be able to recover'
      desc = @mymodel.description
      name = @mymodel.name
      ident = @mymodel.ident
      
      data = @mymodel.flatten_data
      Model.delete(@mymodel)

      seco = Model.model_from_data(data)

      assert_equal(ident, seco.ident)      
      assert_equal(name, seco.name)
      assert_equal(desc, seco.description)
      assert_equal(comm, seco.commentary)      
      
    end
    
  end
  
end