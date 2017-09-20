# Recreating objects from stored hash

class Foo
  attr_accessor(:a, :b, :c, :bar)
  def initialize(a,b)
    @a = a
    @b = b
    @c = 0
    @bar = nil
  end
  def to_s
    "#{@a} #{@b} #{@c} #{@bar}"  
  end
end

class Bar
  attr_accessor(:width, :height)
  def initialize(width, height)
    @width = width
    @height = height
  end
  def to_s
    "#{width} by #{height}"
  end
end

def create_from_hash(init_parms, obj_data, &proc)
  reqd = []
  init_parms.each do |meth|
    reqd << obj_data.delete(meth)
  end

  obj = proc.call(reqd)

  obj_data.each_pair do |methstr, value|
    obj.send((methstr + '=').to_sym, obj_data[methstr])
  end

  obj
end

data = {'b'=>20, 'a'=>10, 'c'=>30, 'bar'=>{'width'=>70, 'height'=>90}}

# To recreate this object use:
# bar : Bar : ['width', 'height']
# * : Foo : ['a', 'b']

inclobj = create_from_hash(['width', 'height'], data['bar']) {|init_args| Bar.new(*init_args)}

puts inclobj.to_s

data['bar'] = inclobj

myfirstobj = create_from_hash(['a', 'b'], data) {|init_args| Foo.new(*init_args)}

puts myfirstobj.to_s
  