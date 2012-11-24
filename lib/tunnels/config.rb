require 'etc'

module Tunnels
	class Config
		CONFIG_FILE = File.expand_path( '~/.tunnels' )

		def initialize
			@valid = nil
			@targets = []
			if File.file? CONFIG_FILE
				config_data = YAML.load_file( CONFIG_FILE )
				parse config_data if config_data.is_a? Hash
			else
				puts "File exists? #{File.exists? CONFIG_FILE} Is a file? #{File.file? CONFIG_FILE}"
				puts "Configure your tunnels in ~/.tunnels in YAML form."
			end
		end

		def valid?
			@valid
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
			@valid = true if @valid.nil? && !@targets.empty?
		end

		def parse_target( name, config )
			if config.is_a? Hash
				target = create_target( name, config )
				unless target.nil? 
					@targets << target
					parse_forward( target, config['forward'] )
				end
			else
				puts "Cannot parse target '#{name}' (#{config.class})"
				@valid = false
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
				puts "Cannot parse target '#{name}': no host found."
				@valid = false
			end
		end

		def parse_forward( target, config )
			case config
			when nil
				puts "Target #{target.name} has no forwards defined."
				@valid = false
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
 						puts "Not sure how to handle forward from #{target.host} to #{server}: #{server_config.class}"
 					end
				end
			else
				puts "Not sure how to handle forward for '#{target.host}': #{config.class}"
				@valid = false
			end
		end

	end

end