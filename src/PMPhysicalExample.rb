# Example of a physical process model - forced mass spring damper
require "PMProcess"

module Perimeta

  #----------------------------- Define the processes ---------------------------------------
  ProcessFactory.define_process('ExternalForce',
                       [[:A, '0.0'], [:freq, '0.0'], [:force, '0.0'], [:currenttime, '0.0']],
                       [:currenttime],
                       "@force = @A * Math::sin(@freq * 2 * Math::PI * @currenttime)")

  mass_behaviour = <<-END_OF_STRING
      @x = @x + @timestep * @v
      @v = @v + ((@timestep * @force) / @mass)
  END_OF_STRING

  ProcessFactory.define_process('Mass',
                       [[:mass, '0.0'], [:x, '0.0'], [:v, '0.0'], [:force, '0.0'], [:timestep, '0']],
                       [:force],
                       mass_behaviour)

  spring_behaviour = <<-END_OF_STRING
      @fa = @k * (@xb - @xa)
      @fb = -1 * @fa
  END_OF_STRING

  ProcessFactory.define_process('Spring',
                       [[:xa, '0.0'], [:xb, '0.0'], [:k, '0.0'], [:fa, '0.0'], [:fb, '0.0']],
                       [:xa, :xb, :k],
                       spring_behaviour)

  ProcessFactory.define_process('Damper',
                       [[:c, '0.0'], [:force, '0.0'], [:v, '0.0']],
                       [:v],
                       "@force = -1 * @c * @v")

  ProcessFactory.define_process('Anchor',
                       [[:x, '0.0']],
                       [],"")

  add_behaviour = <<-END_OF_STRING
      @store ||= []
      if @store.length == @dimension - 1
        @out = @in + @store.inject {|sum, n| sum + n } 
        @store = []
      else
        @store = @store.push(@in)
        @out = nil           
      end
  END_OF_STRING

  ProcessFactory.define_process('Add',
                       [[:in, '0.0'], [:dimension, '2'], [:out, '0.0']],
                       [:in],
                       add_behaviour)

  ProcessFactory.define_process('Timer',
                       [[:currenttime, '0'], [:endtime, '0'], [:timestep, '0']],
                       [],
                       "@currenttime = @currenttime + @timestep if @currenttime < @endtime")

  timestep_behaviour = <<-END_OF_STRING
      #build list of callable code
      updproc = []
      updattr = []
      readproc = []
      readattr = []
      re = %r{/}
      @connections.each do |pair|
        updname = pair.keys[0]
        readname = pair.values[0]
  
        md = re.match(updname)
        updproc.push( @processes.find{|p| p.instance_name == md.pre_match} )
        updattr.push( (md.post_match + '=').to_sym )
  
        md = re.match(readname)
        readproc.push md.pre_match == '..' ? self : @processes.find{|p| p.instance_name == md.pre_match}
        readattr.push md.post_match.to_sym
      end

      # Setup persistance 
      file = nil
      if @persistfilename
        file = File.new(@persistfilename, "w+")
        md = re.match(@persistattr)          
        recordproc = @processes.find{|p| p.instance_name == md.pre_match}                  
        recordattr = md.post_match.to_sym
      end         

      #Run over the time steps calling each method in order.
      #Form is process1.attrname1 = value where value is read as process2.attrname2
      while @timer.currenttime < @timer.endtime
        updproc.length.times do |i|
          updproc[i].send(updattr[i], readproc[i].send(readattr[i]))
        end

        if file
          file.puts recordproc.send(recordattr)            
        end
                  
        @timer.run_behaviour
      end

      file.close if file 
  END_OF_STRING

  ProcessFactory.define_process('TimeStepSystem',
                       [[:timer, 'nil'], [:processes, '[]'], [:connections, 'nil'],
                        [:persistfilename, 'nil'], [:persistattr, 'nil']],
                       [],
                       timestep_behaviour)


  #----------------------------- Build System -----------------------------------------------
  timer = ProcessFactory.create_process('Timer', 'timer')                                              
  timer.endtime = 50.0
  timer.timestep = 0.001

  extforce = ProcessFactory.create_process('ExternalForce', 'extforce')                       
  extforce.A = 2.0
  extforce.freq = 1.2 # resonant 2.2508

  mass1 = ProcessFactory.create_process('Mass', 'mass1')                       
  mass1.mass = 5.0
  mass1.timestep = timer.timestep

  spring1 = ProcessFactory.create_process('Spring', 'spring1')                       
  spring1.k = 1000.0

  damper1 = ProcessFactory.create_process('Damper', 'damper1')                       
  damper1.c = 1.0

  wall1 = ProcessFactory.create_process('Anchor', 'wall1')                       

  add3 = ProcessFactory.create_process('Add', 'add3')                       
  add3.dimension = 3

  model = ProcessFactory.create_process('TimeStepSystem', 'model')                      
  model.timer = timer
  model.processes_add(timer)
  model.processes_add(extforce)    
  model.processes_add(mass1)
  model.processes_add(spring1)
  model.processes_add(damper1)
  model.processes_add(wall1)  
  model.processes_add(add3)    
  model.connections = [{'extforce/currenttime' => 'timer/currenttime'},
                       {'damper1/v' => 'mass1/v'},
                       {'spring1/xa' => 'mass1/x'},
                       {'spring1/xb' => 'wall1/x'},       
                       {'add3/in' => 'spring1/fa'},
                       {'add3/in' => 'extforce/force'},
                       {'add3/in' => 'damper1/force'},
                       {'mass1/force' => 'add3/out'}]
  model.persistfilename = 'testfile.txt'
  model.persistattr = 'mass1/x'
  model.run_behaviour

end
