# Tunnel Boring Machine

Tunnel Boring Machine is a ruby application to manage SSH tunnels, which you can use to achieve something a little like a VPN, wherein SSH access to a server can give you access to the network beyond that server.

I use SSH tunnels on a regular basis to access resources at client sites that are not exposed directly to the internet as a whole. Managing those tunnels as a series of bash scripts or aliases became cumbersome. I wanted / needed something better, and the tunnel boring machine has evolved from that need.

## Invocation ##
For the time being, TBM is a simple command you invoke to open the tunnels you need, then you cancel with `^C` to close the tunnels that you had opened. Something like this:

    $ tbm dev-ngnix

Eventually, I expect that TBM will become a little more interactive, allowing you to open additional tunnels without closing the ones you already opened, close a tunnel without closing all of them, and so forth. Whether it does this as an interactive program, a shell command that interacts with a running process is all TBD.

## Configuration ##
You configure the tunnel boring machine by creating a configuration file in YAML form at `~/.tunnels`. At the moment, you can't have multiple configuration files, change the location of the configuration file or anything of that nature.

An example configuration file follows:

    jira:
        host: ssh.example.com
        forward: 8080
    teamcity:
        host: ssh.example.com
        forward: 8111
        alias: tc
    jdbc-as400:
        host: ssh.example.com
        forward:
          greenmachine: [ 449, 8470, 8471, 8476 ]
        alias: [ ja, j400 ] 

This configuration file is still evolving -- I expect the format to continue to change, the above simply represents the current state.

## Contact ##
If you're using TBM and you want to talk about it or make suggestions, get in touch with me on [Twitter](http://twitter.com/geoffreywiseman)
