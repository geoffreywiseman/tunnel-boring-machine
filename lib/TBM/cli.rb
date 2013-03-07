module TBM

	# The command-line interface for TBM, this parses the supplied arguments and orchestrates the 
	# rest of the classes based on those supplied arguments.
	class CommandLineInterface
		attr_reader :targets

		# Initialize the CLI with a parsed config.
		#
		# @param [Config] config the parsed configuration
		def initialize( config )
			@config = config
			@targets = nil
			@cancelled = false
		end

		# Parses the command-line arguments by seeking targets, and print errors/usage if necessary.
		def parse
			if ARGV.empty? then 
				print_targets "SYNTAX: tbm <targets>\n\nWhere <targets> is a comma-separated list of:" 
			else
				parse_targets( ARGV )
			end
		end

		# The CLI is valid if no errors were found during parsing, and that are known target tunnels to bore.
		#
		# @return true if there are targets defined, which will only happen if there were no parsing errors
		def valid?
			!@targets.nil?
		end

		# Parse the configuration and command-line arguments and run the tunnel boring machine if both are valid.
		def self.parse_and_run
			config = ConfigParser.parse
			if config.valid?
				cli = CommandLineInterface.new( config )
				cli.parse
				if cli.valid?
					machine = Machine.new( cli.targets )
					machine.bore
				end
			else
				formatted_errors = config.errors.join( "\n\t" )
				puts "Cannot parse configuration. Errors:\n\t#{formatted_errors}\n"
			end
		end

		private

		def parse_targets( targets )
			found_targets = []
			missing_targets = []
			targets.each do |target_name|
				target = @config.get_target( target_name )
				if target.nil? then
					missing_targets << target_name
				else
					found_targets << target
				end
			end

			if missing_targets.any?
				print_targets( "Cannot find target(s): #{missing_targets.join(', ')}\n\nThese are the targets currently defined:")
			elsif invalid_combination?( found_targets )
				puts "Can't combine targets: #{targets.join(', ')}."
			else
				@targets = found_targets
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

	end
end