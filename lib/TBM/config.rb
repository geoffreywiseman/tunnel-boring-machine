module TBM

	# Configuration for the Tunnel Boring Machine. This class is both the parser of the configuration
	# data in YAML form, and the artifact that results from the parsing.
	class Config

		# Any errors discovered while parsing the configuration.
		attr_reader :errors

		# The targets defined in the configuration.
		attr_reader :targets

		def initialize
			@errors = []
			@targets = []
		end

		# The configuration is valid if there are no errors.
		#
		# @return true if the error collection is empty
		def valid?
			@errors.empty?
		end

		# Request a target having the specified name.
		#
		# @param [String] name the name of the target
		def get_target( name )
			@targets.find { |target| target.has_name?(name) }
		end

		# Iterate over each target and yield to the specified block.
		#
		# @yield [target] a block to which each target will be passed
		def each_target( &block )
			@targets.each { |target| yield target }
		end

	end

end