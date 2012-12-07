require 'net/ssh'

module Tunnel
	class CommandLineInterface
		def initialize( config )
			@config = config
			@targets = nil
			@cancelled = false
		end

		def parse
			if ARGV.empty? then 
				print_targets "SYNTAX: tbm <targets>\n\nWhere <targets> is a comma-separated list of:" 
			else
				targets = []
				missing_targets = []
				ARGV.each do |target_name|
					target =  @config.get_target( target_name )
					if target.nil? 
						missing_targets << target_name
					else
						targets << target
					end
				end

				if missing_targets.any?
					print_targets( "Cannot find target(s): #{missing_targets.join(', ')}\n\nThese are the targets currently defined:")
				elsif invalid_combination?(targets)
					puts "Can't combine targets: #{ARGV.join(', ')}."
				else
					@targets = targets
				end
			end
		end

		def invalid_combination?( targets )
			num_hosts = targets.map { |t| t.host }.uniq.size
			num_usernames = targets.map { |t| t.username }.uniq.size
			num_hosts != 1 || num_usernames != 1
		end

		def print_targets( message )
			puts message
			@config.each_target { |target| puts "\t#{target.to_s}" }
		end


		def valid?
			!@targets.nil?
		end

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
		end

		def forward_ports( session )
			begin
				@targets.each do |target|
					target.each_forward do |fwd|
						port = fwd.last
						remote_host = fwd.first || 'localhost'
						remote_host_name = fwd.first || target.host
						session.forward.local( port, remote_host, port )
						puts "\tforwarded port #{port} to #{remote_host_name}:#{port}"
					end
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