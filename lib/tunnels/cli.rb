require 'net/ssh'

module Tunnels
	class CommandLineInterface
		def initialize( config )
			@config = config
			@targets = []
		end

		def parse
			if ARGV.empty? 
				puts "SYNTAX: tunnels <name>"
				puts "Where name is one of:"
				@config.each_target { |name| puts "\t#{name}" }
			else
				@targets += ARGV
			end
		end

		def valid?
			missing_targets = @targets.select { |t| !@config.has_target?(t) }
			puts "Cannot find target(s): #{missing_targets}" unless missing_targets.empty?
			!@targets.empty? && missing_targets.empty?
		end

		def open_tunnels
			puts "Tunnels v#{VERSION}"
			puts

			puts "TODO: Open Tunnel"
			# Net::SSH.start( host, username ) do |session|
				# puts "Opened connection to Host."
				# session.forward.local( 8888, 'localhost', 8888 )
				# puts "Tunnel open for 8888"
				# int_pressed = false
				# trap("INT") { int_pressed = true }
				# puts "Waiting for Ctrl-C"
				# session.loop(0.1) { not int_pressed }
				# puts "Ctrl-C pressed. Exiting."
			# end

			puts "Tunnels closed."
		end

		def self.parse_and_run
			config = Config.new
			if config.valid? 
				cli = CommandLineInterface.new( config )
				cli.parse
				cli.open_tunnels if cli.valid?
			end
		end
	end
end