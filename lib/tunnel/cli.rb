require 'net/ssh'

module Tunnel
	class CommandLineInterface
		def initialize( config )
			@config = config
			@target = nil
			@cancelled = false
		end

		def parse
			if ARGV.size != 1 
				print_targets "SYNTAX: tbm <target>\n\nWhere target is one of:" 
			else
				target_name = ARGV[0]
				@target = @config.get_target( target_name )
				print_targets( "Cannot find target: #{target_name}\n\nThese are the targets currently defined:" ) if @target.nil?
			end
		end

		def print_targets( message )
			puts message
			@config.each_target { |target| puts "\t#{target.to_s}" }
		end


		def valid?
			!@target.nil?
		end

		def bore
			puts "Starting #{APP_NAME} v#{VERSION}"
			puts

			trap("INT") { @cancelled = true }
			Net::SSH.start( @target.host, @target.username ) do |session|
				forward_ports( session )
			end

			puts "Shutting down the machine."
		rescue Errno::ECONNRESET
			puts "\nConnection lost (reset). Shutting down the machine."
		rescue Errno::ETIMEDOUT
			puts "\nConnection lost (timed out). Shutting down the machine."
		rescue Errno::EADDRINUSE
			puts "\nPorts already in use, cannot forward. Shutting down the machine."
		end

		def forward_ports( session )
			begin
				puts "Opened connection to #{@target.username}@#{@target.host}:"
				@target.each_forward do |fwd|
					port = fwd.last
					remote_host = fwd.first || 'localhost'
					remote_host_name = fwd.first || @target.host
					session.forward.local( port, remote_host, port )
					puts "\tforwarded port #{port} to #{remote_host_name}:#{port}"
				end
				puts "\twaiting for Ctrl-C..."
				session.loop(0.1) { not @cancelled }
				puts "\n\tCtrl-C pressed. Exiting."
			rescue Errno::EACCES
				@cancelled = true
				puts "\tCould not open all ports; you may need to sudo if port < 1000."
			end
		end

		def self.parse_and_run
			config = Config.new
			if config.valid? 
				cli = CommandLineInterface.new( config )
				cli.parse
				cli.bore if cli.valid?
			else
				puts "Cannot parse configuration:\n\t#{config.errors.join('\n\t')}"
			end
		end
	end
end