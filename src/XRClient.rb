# Test the xmlrpc server with a ruby client
require "xmlrpc/client"

module Perimeta
  
  # Make an object to represent the XML-RPC server.
  server = XMLRPC::Client.new('localhost', '/RPC2', '8044')
  
  begin
    result = server.call('evidence.model', 'rpctest')
    puts result.inspect
  
   (1..6).each do |i| 
      # Call the remote server and get our result
      result = server.call('evidence.node', 'rpctest', i)
      puts result.inspect
    end
    
    #tend = Process.times
    
  rescue XMLRPC::FaultException => e
    puts "Error: "
    puts e.faultCode
    puts e.faultString
  end
  
end