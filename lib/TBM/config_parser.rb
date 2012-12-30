require 'etc'
require 'yaml'
require 'tbm'

module TBM
	class ConfigParser

		# The configuration file used for parsing config.
		CONFIG_FILE = File.expand_path( '~/.tbm' )
		GATEWAY_PATTERN = /^([^@]+)(@([^@]+))?$/

		# Parses the tunnel boring machine configuration to get a list of targets which can 
		# be invoked to bore tunnels.
		#
		# @return [Config] the parsed configuration for TBM
		def self.parse
			config = Config.new
			if File.file? CONFIG_FILE
				config_data = YAML.load_file( CONFIG_FILE )
				case config_data
				when Hash
					parse_gateways( config_data, config ) if config_data.is_a? Hash
				else
					config.errors << "Cannot parse TBM configuration of type: #{config_data.class}"
				end
			else
				config.errors << "No configuration file found. Specify your tunnels in YAML form in: ~/.tunnels"
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
				targets.each_key do |target_name|
					target = Target.new( target_name.to_s, gateway_host, gateway_username )
					config.targets << target
					configure_target( target, targets[target_name], config )
				end
			else
				config.errors << "Cannot parse targets, expected Hash, received: #{targets.class}"
			end
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
				if valid_port?( tunnel_config )
					target.add_tunnel( Tunnel.new( tunnel_config ) )
				else
					config.errors << "Invalid port number: #{tunnel_config}"
				end
			when String
				case tunnel_config 
				when /^\d{1,5}$/
					port = tunnel_config.to_i
					if valid_port?( port )
						target.add_tunnel( Tunnel.new( port ) )
					else
						config.errors << "Invalid port number: #{tunnel_config}"
					end
				when /^(\d{1,5}):(\d{1,5})$/
					port = $1.to_i
					remote_port = $2.to_i
					if !valid_port?( port )
						config.errors << "Invalid local port number #{port} from #{tunnel_config}"
					elsif !valid_port?( remote_port )
						config.errors << "Invalid remote port number #{remote_port} from #{tunnel_config}"
					else
						target.add_tunnel( Tunnel.new( port, :remote_port => remote_port ) )
					end
				when /^(\d{1,5}):([a-zA-Z0-9\.\-]+):(\d{1,5})$/
					port = $1.to_i
					remote_host = $2
					remote_port = $3.to_i
					if !valid_port?( port )
						config.errors << "Invalid local port number #{port} from #{tunnel_config}"
					elsif !valid_port?( remote_port )
						config.errors << "Invalid remote port number #{remote_port} from #{tunnel_config}"
					else
						target.add_tunnel( Tunnel.new( port, :remote_host => remote_host, :remote_port => remote_port ) )
					end
				when /^([a-zA-Z0-9\.\-]+):(\d{1,5})$/
					port = $2.to_i
					remote_host = $1
					if !valid_port?( port )
						config.errors << "Invalid port number #{port} from #{tunnel_config}"
					else
						target.add_tunnel( Tunnel.new( port, :remote_host => remote_host ) )
					end
				else
					config.errors << "Cannot parse tunnel: #{tunnel_config} (#{tunnel_config.class})"
				end
			else
				config.errors << "Cannot parse tunnel: #{tunnel_config} (#{tunnel_config.class})"
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
				if valid_port?( tunnel_config )
					target.add_tunnel( Tunnel.new( tunnel_config, :remote_host => remote_host ) )
				else
					config.errors << "Invalid port number: #{tunnel_config}"
				end
			when String
				case tunnel_config 
				when /^\d{1,5}$/
					port = tunnel_config.to_i
					if valid_port?( port )
						target.add_tunnel( Tunnel.new( port, :remote_host => remote_host ) )
					else
						config.errors << "Invalid port number: #{tunnel_config}"
					end
				when /^(\d{1,5}):(\d{1,5})$/
					port = $1.to_i
					remote_port = $2.to_i
					if !valid_port?( port )
						config.errors << "Invalid local port number #{port} from #{tunnel_config}"
					elsif !valid_port?( remote_port )
						config.errors << "Invalid remote port number #{remote_port} from #{tunnel_config}"
					else
						target.add_tunnel( Tunnel.new( port, :remote_port => remote_port, :remote_host => remote_host ) )
					end
				else
					config.errors << "Cannot parse tunnel: #{tunnel_config} (#{tunnel_config.class})"
				end
			else
				config.errors << "Cannot parse tunnel: #{tunnel_config} (#{tunnel_config.class})"
			end
		end


	end
end