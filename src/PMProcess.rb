# The process class from which all models can be built
require "ObserverPattern"
module Perimeta

class PMProcess
  include ObserverPattern
  
  attr_reader(:uri, :instance_name)

  #Expect instance name to be string.
  def initialize(instance_name)
    @instance_name = instance_name
    
    #full name is class name and instance name. Need to strip off any module prefixes from classname.
    md = /[\w_]+$/.match(self.class.to_s)
    @uri = md[0] + '/' + @instance_name
    
    #Create mechanism to notify interested observers of changes to attributes ('bottom up' control)
    create_observer_methods(self.class, "attr_set")
    self.on_attr_set {|name| run_behaviour(name)}
    
    init_attr
  end

  #Overridden by specialised process class
  def init_attr
  end
  
  #If the value supports it listen to any changes
  def listen_to_value(attr_name, value)
    if value.respond_to?(:on_attr_set)
      value.on_attr_set do |local_name|
        run_behaviour( (attr_name.to_s + '/' + local_name.to_s).to_sym )
      end
    end
  end

  #Overridden by specialised process class to return list of attributes
  def attr_list()
    []
  end

  #May be overriden to run process specific initialisation
  def init_behaviour()
    #Run init_behaviour on any attribute values which have it
    self.attr_list().each do |attr_sym|
      if (value=self.send(attr_sym)).respond_to?(:init_behaviour)
        value.send(:init_behaviour)
      end
    end
  end

  #Will be overriden by specialised process class, run either explicitly or when
  #triggered by a change to an attribute
  def run_behaviour(attr_name=nil)
  end

  #May be overriden to run process specific finalisation
  def final_behaviour()
    #Run final_behaviour on any attribute values which have it
    self.attr_list().each do |attr_sym|
      if (value=self.send(attr_sym)).respond_to?(:final_behaviour)
        value.send(:final_behaviour)
      end
    end
  end

  def to_s 
    @uri
  end

  def inspect 
    to_s
  end

  def ==(other)
   (self.uri == other.uri)
  end

end


module ProcessFactory

  #Define a specialised process class.
  #klass is the class name (eg. Genericlink)
  #attrs is a list of [symbol name, intial value] for each attribute
  #behaviour_triggers is a list of symbol names for attributes which will trigger behaviour eg:
  # [:description, :'children/evidence']
  #behaviour is a string containing the behaviour code
  #init_behaviour and final_behavior are optional strings containing initialisation and
  #finalisation code 
  def ProcessFactory.define_process(klass, attrs, behaviour_triggers, behaviour,
                                    init_behaviour=nil, final_behaviour=nil)
  
    theklass = Class.new(PMProcess) do
      def initialize(instance_name)
        super      
      end      
    end

    init_method = "def init_attr() \n"
      attrs.each do |arg|
        init_method += '@' + arg[0].to_s + '=' +  arg[1] + "\n"
        init_method += 'listen_to_value(:' + arg[0].to_s + ', @' + arg[0].to_s + ") \n"
      end
    init_method += "end"

    theklass.class_eval init_method

    theklass.class_eval <<-END_OF_STRING      
      def attr_list()
        #{attrs.collect{|item| item[0]}.inspect}
      end
      def run_behaviour(attr_name=nil)
        if attr_name.nil? ||
           #{behaviour_triggers.inspect}.include?(attr_name)
          #{behaviour}
        end
      end
    END_OF_STRING
    
    if init_behaviour
      theklass.class_eval <<-END_OF_STRING      
        def init_behaviour()
          #{init_behaviour}
          super
        end
      END_OF_STRING
    end

    if final_behaviour
      theklass.class_eval <<-END_OF_STRING      
        def final_behaviour()
          #{final_behaviour}
          super
        end
      END_OF_STRING
    end

    attrs.each do |arg|
      attr_name = arg[0]
      #Look for initial values surrounded by [] ie. an array
      array = arg[1] =~ /^\[.*\]$/
      if array.nil? #not an array
        theklass.class_eval <<-END_OF_STRING
          def #{attr_name}=(value)
              @#{attr_name} = value
              listen_to_value(:#{attr_name}, value)
              attr_set(:#{attr_name})                          
          end
          def #{attr_name}
              @#{attr_name}
          end
        END_OF_STRING
      else
        theklass.class_eval <<-END_OF_STRING
          def #{attr_name}_add(value)
              @#{attr_name}.push(value)
              listen_to_value(:#{attr_name}, value)
              attr_set(:#{attr_name})                          
          end
          def #{attr_name}_delete(value)
              @#{attr_name}.delete(value)
              attr_set(:#{attr_name})                                        
          end
          def #{attr_name}
              @#{attr_name}
          end
        END_OF_STRING
      end
    end

    const_set(klass, theklass)
  end

  def ProcessFactory.create_process(klass, instance_name='not defined')

    raise(ArgumentError, "Process type #{klass} has not been defined") if not const_defined?(klass)
    
    const_get(klass).new(instance_name)
  end

end

end