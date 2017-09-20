#Implement a generalised observer pattern
#Usage is:
#
#  if b=B.new (observer) is interested in changes to a=A.new (subject) then
#
#    in the subject class definition A
#       include ObserverPattern
#    in the A.initialize method call:
#      create_observer_methods(self.class, "foo_changed")
#    when foo is changed in A call:
#      foo_changed foo
#
#    setup a callback so that the observer b can receive messages from a:
#      a.on_foo_changed {|foo| b.foo_update(foo)}
#

module ObserverPattern
  def create_observer_methods(aclass, *args)
    #Create a method which returns an array containing the public callback method names
    # .inspect creates a string version of the array suitable as a return type
    #NOTE this will not work if called more than once in a class
    aclass.class_eval "def callbacks
                         #{args.inspect}
                       end"
                       
    #Create the set of callback methods
    args.each { |arg|
        aclass.class_eval <<-CEEND
            def on_#{arg}(&callback)
                @#{arg}_observers ||= {}
                @#{arg}_observers[callback.object_id]=callback
		            return callback.object_id
            end
            def del_#{arg}(id)
		            @#{arg}_observers ||= {}
		            return @#{arg}_observers.delete( id)
		        end
            private
            def #{arg} *the_args
                @#{arg}_observers ||= {}
                @#{arg}_observers.each { |caller, cb|
                  cb.call *the_args
                }
            end
        CEEND
    }
  end
end

