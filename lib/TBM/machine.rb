require 'net/ssh'

module TBM

  # The "Machine" class does all the actual interaction with SSH to perform the tunneling.
  class Machine

    # Initialize the Machine with a set of tunnels to bore
    #
    # @param [Array<Target>] tunnels the tunnels to be bored
    def initialize( targets )
      @targets = targets
    end

    # Open a connection to the gateway server, and then set up (bore) any
    # tunnels specified in the initialize method.
    def bore
      puts "Starting #{APP_NAME} v#{VERSION}"
      puts

      trap("INT") { @cancelled = true }
      host = @targets.first.host
      username = @targets.first.username
      Net::SSH.start( host, username ) do |session|
        puts "Opened connection to #{username}@#{host}:"
        forward_ports( session )
      end

      puts "Shutting down the machine."
    rescue Errno::ECONNRESET
      puts "\nConnection lost (reset). Shutting down the machine."
    rescue Errno::ETIMEDOUT
      puts "\nConnection lost (timed out). Shutting down the machine."
    rescue Errno::EADDRINUSE
      puts "\tPorts already in use, cannot forward.\n\nShutting down the machine."
    rescue Errno::EACCES
      puts "\tCould not open all ports; you may need to sudo if port < 1000."
    end

    private

    def forward_ports( session )
      @targets.each do |target|
        target.each_tunnel do |tunnel|
          port = tunnel.port
          remote_host = tunnel.remote_host || 'localhost'
          remote_host_name = tunnel.remote_host || target.host
          remote_port = tunnel.remote_port
          session.forward.local( port, remote_host, remote_port )
          puts "\ttunneled port #{port} to #{remote_host_name}:#{remote_port}"
        end
      end
      puts "\twaiting for Ctrl-C..."
      session.loop(0.1) { not @cancelled }
      puts "\n\tCtrl-C pressed. Exiting."
    end

  end
end