module Tunnels
	class Config
		CONFIG_FILE = File.expand_path( '~/.tunnels' )

		def initialize
			@valid = nil
			@targets = {}
			if File.file? CONFIG_FILE
				config_data = YAML.load_file( CONFIG_FILE )
				parse config_data if config_data.is_a? Hash
			else
				puts "File exists? #{File.exists? CONFIG_FILE} Is a file? #{File.file? CONFIG_FILE}"
				puts "Configure your tunnels in ~/.tunnels in YAML form."
			end
		end

		def parse( targets )
			targets.each_key { |name| parse_target name, targets[name] }
			@valid = true if @valid.nil? && !@targets.empty?
		end

		def parse_target( name, config )
			if config.is_a? Hash
				@targets[ name ] = get_tunnels( Hash.new, config )
			else
				puts "Cannot parse target '#{name}' (#{config.class})"
				@valid = false
			end
		end

		def get_tunnels( context, config )
			tunnels = [];
			host = config[ 'host' ]
			port = config[ 'port' ]
			if host.nil? || port.nil? || port.to_i <= 0 then
				puts "Invalid tunnel: #{host}:#{port}"
				@valid = false
				return []
			else
				return [ [host, port.to_i ] ]
			end	
		end

		def valid?
			@valid
		end

		def each_target(&block)
			@targets.each_key { |x| yield x }
		end

		def has_target?( name )
			@targets.has_key? name
		end
	end


end