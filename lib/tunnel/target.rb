module Tunnel
	class Target
		attr_reader :name, :host, :username

		def initialize( name, host, username )
			@name = name
			@host = host
			@username = username
			@forwards = []
			@aliases = []
		end

		def forward_port( port, server ) 
			@forwards << [ server, port ]
		end

		def alias( name )
			@aliases << name
		end

		def has_name?( name )
			( @name == name ) || ( @aliases.include? name )
		end

		def each_forward( &block )
			@forwards.each { |fwd| yield fwd }
		end

		def to_s
			if @aliases.empty?
				@name
			else
				"#{@name} (#{@aliases.join(', ')})"
			end
		end
	end
end