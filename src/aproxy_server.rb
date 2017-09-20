#why oh why am I trying to write my own http proxy server??????

require 'gserver'
require 'socket'
include Socket::Constants

class ProxyServer < GServer

  def initialize(listen_port=10080, listen_host='localhost', forward_port=80, forward_host=nil, *args)
  #args can contain maxConnections = 4, stdlog = $stderr, audit = false, debug = false
    super(listen_port, *args)
    @listen_port = listen_port
    @forward_host = forward_host
    @forward_port = forward_port
  end
  
  def serve(io) #io is a TCPSocket
    begin
      inrequest = ''
      while (line=io.gets)
        p line

        #If http extract the host and port to forward the connection to        
        if @listen_port==10080 and line =~ /^Host: /
          line =~ /(Host: )([\w\.]+)((:)(\d+))?/
          @forward_host = $2
          @forward_port = $5.nil? ? 80 : $5.to_i
        end
        
        inrequest += line
        break if line =~ /^(\n|\r)/
      end

      puts "create new socket for #{@forward_host} at port #{@forward_port}"
        fsocket = TCPSocket.new(@forward_host, @forward_port)    
      p "write to socket"
      p inrequest
        fsocket.write( inrequest )
        
      p "about to read from socket"
      outrequest = ''
      while (result=fsocket.gets)
        p result
        outrequest += result
        break if result =~ /^(\n|\r)/ 
      end

      io.write outrequest      
    rescue 
      puts "excpeption found #{$!}"
    end
    
  end
end

# Run the server with logging enabled (it's a separate thread).
server = ProxyServer.new(10080, 'localhost')
server.audit = false                  # Turn logging on.
server.start
server.join
