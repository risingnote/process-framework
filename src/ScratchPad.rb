class Foo
  attr_accessor :id, :name
  def initialize(id, name)
    self.id = id
    self.name = name
  end
end

foo = Foo.new(1, 'one')

foolist = [Foo.new(1, 'one'), Foo.new(2, 'two'), Foo.new(3, 'three')]

class Symbol
    
    # A generalized conversion of a method name
    # to a proc that runs this method.
    #
    def to_proc
        lambda {|x| x.send(self)}
    end
    
end



proc = lambda {|foo| foo.id}
#p foolist.map {|foo| foo.id}
p foolist.map(&:id)