# Example of performance indicators propagating evidence into local evidence as in Perimeta
require "PMProcess"
require "PMBehaviour"

module Perimeta
  
  #----------------------------- Define the process nodes ---------------------------------------
  pf1 = PMProcess.new('performancefunction', 'pf1',
                       [:minbound, :maxbound, :x, :evidence],
                       [:minbound, :maxbound, :x])
  pf1.set_attr(:minbound, 0.0)
  pf1.set_attr(:maxbound, 200.0)
  pf1.set_attr(:x, 0.0)
  pf1.behaviour = PropagateEvidence.linear_pf()
  
  pi1 = PMProcess.new('performanceindicator', 'pi1',
                       [:measurement, :perfunction, :evidence],
                       [:measurement, :perfunction, :'perfunction/maxbound'])
  pi1.set_attr(:perfunction, pf1)                       
  pi1.behaviour = PropagateEvidence.pi_calc()                       
  pi1.set_attr(:measurement, 90)
  
  p 'Perf ind evidence shd be 0.45'  
  p pi1.attr_list  

  linka = PMProcess.new('genericlink', 'linka',
                         [:childproc, :weight],
                         [:'childproc/evidence'])
  linka.set_attr(:childproc, pi1)
  linka.set_attr(:weight, 0.5)
  linka.behaviour = PropagateEvidence.pass_on_change()

  local1 = PMProcess.new('localevidence', 'local1',
                          [:childlinks, :evidence],
                          [:childlinks, :'childlinks/weight', :'childlinks/childproc'])
  local1.behaviour = PropagateEvidence.simple_average()                          
  local1.set_attr(:childlinks, linka, list_action='add')  

  p 'Inital case expect evidence of 0.225'  
  p local1.attr_list  

  
end
