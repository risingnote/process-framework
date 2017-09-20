#The propagation calculations to calculate evidence from children to parent

module Perimeta

  module PropagateEvidence

    def PropagateEvidence.pass_on_change()
      Proc.new do |process|
        #use send method to invoke method, ignores access control!
        process.send(:attr_set, :childproc)
      end
    end
    
    def PropagateEvidence.simple_average()
      Proc.new do |process|
        sum, cnt = 0, 0 
        childlinks = process.get_attr(:childlinks) || []        
        childlinks.each do |link|
          sum += link.get_attr(:childproc).get_attr(:evidence) * link.get_attr(:weight)
          cnt += 1
        end
        if cnt == 0
          process.set_attr(:evidence, 'undefined')
        else
          process.set_attr(:evidence, sum/cnt)
        end
      end
    end

    def PropagateEvidence.linear_pf()
      Proc.new do |process|
        ev = (process.get_attr(:x) - process.get_attr(:minbound)) /
             (process.get_attr(:maxbound) - process.get_attr(:minbound))
        process.set_attr(:evidence, ev)
      end
    end

    def PropagateEvidence.pi_calc()
      Proc.new do |process|
        pf = process.get_attr(:perfunction)
        pf.set_attr(:x, process.get_attr(:measurement))
        process.set_attr(:evidence, pf.get_attr(:evidence))
      end
    end

  end
  
  module MassSpring
    
    def MassSpring.run_system()
      Proc.new do |process|
        processes = process.get_attr(:processes)

        #build list of callable code
        updproc = []
        updattr = []
        readproc = []
        readattr = []
        re = /\//        
        process.get_attr(:connections).each do |pair|
          key = pair.keys[0]
          value = pair.values[0]
  
          md = re.match(key)
          updproc.push processes.find{|p| p.instance_name == md.pre_match}
          updattr.push md.post_match.to_sym
  
          md = re.match(value)
          readproc.push md.pre_match == '..' ? process : processes.find{|p| p.instance_name == md.pre_match}
          readattr.push md.post_match.to_sym
        end

        # Setup persistance 
        file = nil
        if process.get_attr(:persistfilename)
          file = File.new(process.get_attr(:persistfilename), "w+")
          md = re.match(process.get_attr(:persistattr))          
          recordproc = processes.find{|p| p.instance_name == md.pre_match}                  
          recordattr = md.post_match.to_sym
        end         

        #Run over the time steps calling each method in order.
        #Form is process1.set_attr(:attrname1, value) where value is 
        # read as process2.get_attr(:attrname2)
        while process.get_attr(:currenttime) < process.get_attr(:endtime)
          updproc.length.times do |i|
            updproc[i].send(:set_attr, updattr[i],
                               readproc[i].send(:get_attr, readattr[i]))
          end

          if file
            file.puts recordproc.send(:get_attr, recordattr)            
          end
                  
          process.set_attr(:currenttime, process.get_attr(:currenttime) + process.get_attr(:timestep))
        end

        file.close if file 
      end
    end

    def MassSpring.force_input()
      Proc.new do |process| 
        #force=A*sin(f*2*pi*t);
        force = process.get_attr(:A) * 
                 Math::sin(process.get_attr(:f)*2*Math::PI*process.get_attr(:currenttime))              
        process.set_attr(:force, force)
      end     
    end

    def MassSpring.mass()
      Proc.new do |process|
        #Uses Euler implicit scheme
        #Assumes setting of force has triggered this behaviour

        #Rember current x and vel
        x = process.get_attr(:x)
        v = process.get_attr(:v)   
      
        #Calc next x and vel
        x_next = x + (process.get_attr(:timestep) * v)
        v_next = v + (process.get_attr(:timestep) * process.get_attr(:force)) / process.get_attr(:mass)
        process.set_attr(:x, x_next)                                        
        process.set_attr(:v, v_next)
      end
    end

    def MassSpring.spring()
      Proc.new do |process|
        # doesn't know about time stepping, up to controller to interpret the force
        forcea = process.get_attr(:k) * (process.get_attr(:xb) - process.get_attr(:xa))
        process.set_attr(:fa, forcea)
        process.set_attr(:fb, -1 * forcea)        
      end
    end

    def MassSpring.damper()
      Proc.new do |process|
        force = -1 * process.get_attr(:c) * process.get_attr(:v)
        process.set_attr(:force, force)
      end
    end

  end

  module General
    
    def General.add()
      Proc.new do |process|
        store = process.get_attr(:store)
        if store.length == process.get_attr(:dimension) - 1
          process.set_attr(:out, process.get_attr(:in) + store.inject {|sum, n| sum + n }) 
          process.set_attr(:store, [])
        else
          process.set_attr(:store, store.push(process.get_attr(:in)))
          process.set_attr(:out, nil)           
        end
      end
    end
    
  end
  
end
