module TBM

  # Represents a particular tunnel, possibly one of many for a given target.
  class Tunnel
    attr_reader :port

    def initialize( port, options = {} )
      @port = port
      @options = options
    end

    def remote_port
      @options[:remote_port] || port
    end

    def remote_host_addr
      @options[:remote_host] || 'localhost'
    end

    def remote_host
      @options[:remote_host]
    end

  end

end