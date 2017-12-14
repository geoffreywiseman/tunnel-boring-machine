require 'etc'
require 'yaml'
require 'tbm'

module TBM
	class ConfigParser
		# The configuration file before expansion
		CONFIG_FILE = '~/.tbm'

		# The configuration file used for parsing config.
		EXPANDED_CONFIG_FILE = File.expand_path( CONFIG_FILE )

		# Pattern for Gateway Server with Optional Username
		GATEWAY_PATTERN = /^([^@]+)(@([^@]+))?$/

		# Pattern for a tunnel with a remote host followed by a port (example.com:3333)
		HOSTPORT_PATTERN = /^([a-zA-Z0-9\.\-]+):(\d{1,5})$/

		# Pattern for a tunnel with a remote host and local and remote ports (1234:example.com:4321)
		PORTHOSTPORT_PATTERN = /^(\d{1,5}):([a-zA-Z0-9\.\-]+):(\d{1,5})$/

		# Pattern for a tunnel with a local port and a gateway port (1234:4321)
		PORTPORT_PATTERN = /^(\d{1,5}):(\d{1,5})$/

		# Pattern for a tunnel with a single port to be used client/server to forward to the gateway (1234)
		PORT_PATTERN = /^\d{1,5}$/

		# Pattern for a target with aliases defined in the target name
		TARGET_NAME_PATTERN = /^
			([A-Za-z0-9\.\-\[\]\#]+)									# name
			(\s*\(\s* 																# optional parenthesized aliases
			([A-Za-z0-9\.\-\[\]\#]+\s*								# first alias
			(,\s*[A-Za-z0-9\.\-\[\]\#]+\s*)*)						# repeating alias pattern with commas
		\))?\s*$/x 																	# end of parenthesized aliases


		# Parses the tunnel boring machine configuration to get a list of targets which can 
		# be invoked to bore tunnels.
		#
		# @return [Config] the parsed configuration for TBM
		def self.parse
			config = Config.new
			if File.file? EXPANDED_CONFIG_FILE
				config_data = YAML.load_file( EXPANDED_CONFIG_FILE )
				case config_data
				when Hash
					parse_gateways( config_data, config ) if config_data.is_a? Hash
				else
					config.errors << "Cannot parse TBM configuration of type: #{config_data.class}"
				end
			else
				config.errors << "No configuration file found. Specify your tunnels in YAML form in: #{CONFIG_FILE}"
			end
			return config
		rescue Psych::SyntaxError => pse
			config.errors << "TBM config is invalid YAML: #{pse}"
			return config
		end

		private

		def self.parse_gateways( gateways, config )
			if gateways.empty?
				config.errors << "No gateways specified."
			else
				gateways.each_key { |key| parse_gateway key, gateways[key], config }
			end
			return config
		end

		private

		def self.parse_gateway( gateway_name, targets, config )
			if String === gateway_name
				(gateway_host, gateway_username) = parse_gateway_name( gateway_name )
				parse_targets( gateway_host, gateway_username, targets, config ) unless gateway_host.nil?
			else
				config.errors << "Cannot parse gateway name: #{gateway_name} (#{gateway_name.class})"
			end
		end

		def self.parse_gateway_name( gateway_name )
			if GATEWAY_PATTERN =~ gateway_name
				if $3.nil?
					[$1,Etc.getlogin]
				else
					[$3,$1]
				end
			else
				config.errors << "Cannot parse gateway name: #{gateway_name}"
				nil
			end
		end

		def self.parse_targets( gateway_host, gateway_username, targets, config )
			if Hash === targets
				targets.each_key do |target_name_string|
					names = parse_target_names( target_name_string.to_s )
					if names.empty?
						config.errors << "Cannot parse target name: #{target_name_string}"
					else
						target = Target.new( names.shift, gateway_host, gateway_username )
						config.targets << target
						names.each { |aka| target.add_alias aka }
						configure_target( target, targets[target_name_string], config )
					end
				end
			else
				config.errors << "Cannot parse targets, expected Hash, received: #{targets.class}"
			end
		end

		def self.parse_target_names( target_name_string )
			names = []
			if TARGET_NAME_PATTERN =~ target_name_string
				names << $1
				unless $3.nil?
					names.concat $3.split(',').map { |x| x.strip }
				end
			end
			return names
		end

		def self.configure_target( target, target_config, config )
			case target_config
			when Fixnum, String
				tunnel( target, target_config, config )
			when Array
				target_config.each { |tunnel_config| tunnel(target, tunnel_config, config) }
				config.errors << "Target #{target} contains no tunnels." if target_config.empty?
			when Hash
				target_config.each { |key,value| configure_target_attribute( target, key, value, config ) }
				config.errors << "Target #{target} contains no tunnels." if target_config.empty?
			when nil
				config.errors << "No target config for #{target}."
			else
				config.errors << "Cannot parse target config: #{target_config} (#{target_config.class})"
			end
		end

		def self.tunnel( target, tunnel_config, config )
			case tunnel_config
			when Fixnum
					config.errors.concat validate_and_add( tunnel_config, tunnel_config, target )
			when String
				case tunnel_config 
				when PORT_PATTERN
					config.errors.concat validate_and_add( tunnel_config.to_i, tunnel_config, target )
				when PORTPORT_PATTERN
					config.errors.concat validate_and_add( $1.to_i, tunnel_config, target, :remote_port => $2.to_i )
				when PORTHOSTPORT_PATTERN
					config.errors.concat validate_and_add( $1.to_i, tunnel_config, target, :remote_host => $2, :remote_port => $3.to_i )
				when HOSTPORT_PATTERN
					config.errors.concat validate_and_add( $2.to_i, tunnel_config, target, :remote_host => $1 )
				else
					config.errors.concat "Cannot parse tunnel: #{tunnel_config} (#{tunnel_config.class})"
				end
			else
				config.errors.concat "Cannot parse tunnel: #{tunnel_config} (#{tunnel_config.class})"
			end
		end

		def self.validate_and_add( port, tunnel_config, target, options={} )
			errors = []
			if options.has_key?( :remote_port ) then
				validate_port( port, 'local', tunnel_config, errors )
				validate_port( options[:remote_port], 'remote', tunnel_config, errors )
			else
				validate_port( port, nil, tunnel_config, errors )
			end
			target.add_tunnel( Tunnel.new( port, options ) ) if errors.empty?
			return errors
		end

		def self.validate_port( port, port_qualifier, tunnel_config, errors )
			if valid_port?( port )
				return true
			else
				qualified_port = ( port_qualifier.nil? ? "port" : "#{port_qualifier} port" )
				port_source = tunnel_config.to_s.match PORT_PATTERN ? '' : " from ${tunnel_config}"
				errors << "Invalid #{qualified_port} number #{port}#{port_source}"
				return false
			end
		end

		def self.valid_port?( port )
			port.between?( 1, 65535 )
		end

		def self.configure_target_attribute( target, attribute_name, attribute_value, config )
			case attribute_name
			when "tunnel"
				tunnel( target, attribute_value, config )
			when "alias"
				case attribute_value
				when Array
					attribute_value.each { |name| target.add_alias( name.to_s ) }
				else
					target.add_alias( attribute_value.to_s )
				end
			else 
				remote_host = attribute_name.to_s
				case attribute_value
				when Fixnum, String
					remote_tunnel( target, remote_host, attribute_value, config )
				when Array
					attribute_value.each { |tunnel_config| remote_tunnel(target, remote_host, tunnel_config, config) }
					config.errors << "Host #{remote_host} on target #{target} contains no tunnels." if attribute_value.empty?
				when nil
					config.errors << "No target config for host #{remote_host} on target #{target}."
				else
					config.errors << "Cannot parse target config: #{attribute_name} = #{attribute_value} (#{attribute_value.class})"
				end
			end
		end

		def self.remote_tunnel( target, remote_host, tunnel_config, config )
			case tunnel_config
			when Fixnum
				config.errors.concat validate_and_add( tunnel_config, tunnel_config, target, :remote_host => remote_host )
			when String
				case tunnel_config 
				when PORT_PATTERN
					config.errors.concat validate_and_add( tunnel_config.to_i, tunnel_config, target, :remote_host => remote_host )
				when PORTPORT_PATTERN
					config.errors.concat validate_and_add( $1.to_i, tunnel_config, target, :remote_host => remote_host, :remote_port => $2.to_i )
				else
					config.errors.concat "Cannot parse tunnel: #{tunnel_config} (#{tunnel_config.class})"
				end
			else
				config.errors.concat "Cannot parse tunnel: #{tunnel_config} (#{tunnel_config.class})"
			end
		end


	end
end
