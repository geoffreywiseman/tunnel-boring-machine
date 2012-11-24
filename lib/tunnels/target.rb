module Tunnels
	class Target
		attr_reader :name, :host, :username

		def initialize( name, host, username )
			@name = name
			@host = host
			@username = username
			@forwards = []
		end

		def forward_port( port, server='localhost' ) 
			@forwards << [ server, port ]
		end

		def has_name?( name )
			@name==name
		end

		def each_forward( &block )
			@forwards.each { |fwd| yield fwd }
		end
	end
end