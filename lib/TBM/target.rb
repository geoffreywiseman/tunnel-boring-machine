module TBM

	# A target defines a tunnel or set of tunnels that can be created by invoking one or more names assigned to the target.
	#
	# It has a name, a host, a user, and one or more tunnels well as an optional list of aliases.
	class Target

		attr_reader :name, :host, :username, :tunnels

		def initialize( name, host, username )
			@name = name
			@host = host
			@username = username
			@tunnels = []
			@aliases = []
		end

		# Adds a tunnel to the target.
		#
		# @param [Tunnel] tunnel the tunnel to add
		def add_tunnel( tunnel )
			@tunnels << tunnel
		end

		# Adds an alias to the list of recognized aliases supported by the target.
		#
		# @param [String] name the alias to add
		def add_alias( name )
			@aliases << name
		end

		def has_name?( name )
			( @name == name ) || ( @aliases.include? name )
		end

		def each_tunnel( &block )
			@tunnels.each { |tunnel| yield tunnel }
		end

		def to_s
			if @aliases.empty?
				@name
			else
				"#{@name} (#{@aliases.join(', ')})"
			end
		end

		def has_tunnels?
			!@tunnels.empty?
		end

	end

end