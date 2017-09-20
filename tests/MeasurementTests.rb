$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "src")

require 'test/unit'
require 'Model'

module Perimeta
  
  class TestMeasurement < Test::Unit::TestCase
    def setup
      @mymodel = Model.new(1, "rubylicious")  
    end
    
    def teardown
      Model.delete(@mymodel)
    end
    
    # Test that callbacks are created for the measurement
    def test_perfind_callbacks
      nodelist = @mymodel.node_list
      
      node1 = nodelist.add_node(1, 'measure node', MEASUREMENT);

      assert(node1.callbacks.size == 1)      
      assert(node1.callbacks.include?('measurement_changed'))
    end

    # Test flatten of measurement node data with defaults
    def test_flatten_measure1
      @measure = @mymodel.node_list.add_node(5, 'measure5', MEASUREMENT)      
            
      assert_equal( { "name"=>"measure5", "ident"=>5, "type"=>"measurement",
                      "measurement"=>nil },
                    @measure.flatten_data)
    end

    # Test flatten of measurement with data set
    def test_flatten_measure2
      @measure = @mymodel.node_list.add_node(5, 'measure5', MEASUREMENT)          
      @measure.measurement=23.46
      
      assert_equal( { "name"=>"measure5", "ident"=>5, "type"=>"measurement",
                      "measurement"=>23.46 },
                    @measure.flatten_data)
    end

   # Test unflattening data for measurement with all data set
    def test_unflatten_measure
      measure = @mymodel.node_list.add_node(6, 'measure6', MEASUREMENT)
      measure.measurement=4.5
      
      data = measure.flatten_data
      
      @mymodel.node_list.delete_node(measure)
      
      livenode = @mymodel.node_list.node_from_data(data)
      
      assert_equal(measure.ident, livenode.ident) 
      assert_equal(measure.name, livenode.name) 
      assert_equal(measure.node_type, livenode.node_type)       
      assert_equal(measure.measurement, livenode.measurement)
    end

  end
  
end