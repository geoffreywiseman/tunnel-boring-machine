require 'etc'
require 'yaml'

module Tunnel
	class Config
		CONFIG_FILE = File.expand_path( '~/.tunnels' )
		attr_reader :errors

		def initialize
			@errors = []
			@targets = []
			if File.file? CONFIG_FILE
				config_data = YAML.load_file( CONFIG_FILE )
				case config_data
				when Hash
					parse config_data if config_data.is_a? Hash
				else
					@errors << "Cannot parse tunnel configuration of type: #{config_data.class}"
				end
			else
				@errors << "No configuration file found. Specify your tunnels in YAML form in: ~/.tunnels"
			end
		end

		def valid?
			@errors.empty?
		end

		def get_target( name )
			@targets.find { |target| target.has_name?(name) }
		end

		def each_target( &block )
			@targets.each { |target| yield target }
		end

		private

		def parse( targets )
			targets.each_key { |name| parse_target name, targets[name] }
			@errors << "No targets specified." if @targets.empty?
		end

		def parse_target( name, config )
			if config.is_a? Hash
				target = create_target( name, config )
				unless target.nil? 
					@targets << target
					parse_forward( target, config['forward'] )
					parse_alias( target, config['alias'] )
				end
			else
				@errors << "Cannot parse target '#{name}' (#{config.class})"
			end
		end

		def create_target( name, config )
			if config.has_key? 'host' then
				if config.has_key? 'username' then
					username = config['username']
				else
					username = Etc.getlogin
				end
				Target.new name, config['host'], username
			else
				@errors << "Cannot parse target '#{name}': no host found."
				return nil
			end
		end

		def parse_forward( target, config )
			case config
			when nil
				@errors << "Target #{target.name} has no forwards defined."
			when Fixnum
				target.forward_port( config )
			when Array
				config.each { |port| target.forward_port(port) }
			when Hash
				config.each_key do |server|
					server_config = config[ server ]
					case server_config
					when Fixnum
						target.forward_port( server_config, server )
					when Array
						server_config.each { |port| target.forward_port( port, server ) }
					else
 						@errors << "Not sure how to handle forward from #{target.host} to #{server}: #{server_config.class}"
 					end
				end
			else
				@errors << "Not sure how to handle forward for '#{target.host}': #{config.class}"
			end
		end

		def parse_alias( target, config )
			case config
			when nil
				# No alias.
			when Array
				config.each { |name| target.alias( name ) }
			when String
				target.alias( config )
			else
				@errors << "Cannot handle alias of type: #{config.class}"
			end
		end

	end

end