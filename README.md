# Tunnel Boring Machine
[![Build Status](https://travis-ci.org/geoffreywiseman/tunnel-boring-machine.png?branch=master)](https://travis-ci.org/geoffreywiseman/tunnel-boring-machine) [![Dependency Status](https://gemnasium.com/geoffreywiseman/tunnel-boring-machine.png)](https://gemnasium.com/geoffreywiseman/tunnel-boring-machine) [![Code Climate](https://codeclimate.com/github/geoffreywiseman/tunnel-boring-machine.png)](https://codeclimate.com/github/geoffreywiseman/tunnel-boring-machine)

Tunnel Boring Machine is a ruby application to manage SSH tunnels, which you can use to achieve something a little like a VPN, wherein SSH access to a server can give you access to the network beyond that server.

I use SSH tunnels on a regular basis to access resources at client sites that are not exposed directly to the internet as a whole. Managing those tunnels as a series of bash scripts or aliases became cumbersome. I wanted / needed something better, and the tunnel boring machine has evolved from that need.

## Current Status ##
It's pretty early days. I'm using this myself, and I've shared it so other people can use it, but its advantages over a shell script are still fairly thin. There are some enhancements that I have planned that might make the case much stronger, but we'll see.

## Installing ##
It is bundled as a ruby gem, so if you have Ruby and RubyGems installed, simply run:

    gem install tbm

If you prefer, you can certainly download it and build it yourself, or simply invoke the ruby code from the command-line.

## Invocation ##
For the time being, TBM is a simple command you invoke to open the tunnels you need, then you cancel with `^C` to close the tunnels that you had opened. Something like this:

    $ tbm dev-nginx

Eventually, I expect that TBM will become a little more interactive, allowing you to open additional tunnels without closing the ones you already opened, close a tunnel without closing all of them, and so forth. Whether it does this as an interactive program, a shell command that interacts with a running process is all TBD.

## Configuration ##
You configure the tunnel boring machine by creating a configuration file in YAML form at `~/.tbm`. At the moment, you can't have multiple configuration files, change the location of the configuration file or anything of that nature.

An example configuration file follows:

    dev.example.com:
      jira: 2222
      teamcity:
        tunnel: 8888
        alias: tc
      jdbc-as400:
        as400: [ 449, 8470, 8471, 8476 ]
        alias: [ ju, ussi ]
      qa:
        tunnel: 8080
      staging (stage, st): 8080:80
      5250: 8023:as400:23
      webfacing: as400:10905

I have [documented the configuration file format](http://geoffreywiseman.github.com/tunnel-boring-machine/config.html) on the website.

## License ##
I've put it under the UNLICENSE. Basically, I don't care if you use it, bundle it inside commercial software, or otherwise make use of it, and I don't offer any kind of warranty or support guarantees, nor do I guarantee that any of the projects dependencies are suited for whatever purpose you have in mind. That's all up to you. That said, if you want to talk about it, see the next section.

## Contact ##
If you're using TBM and you want to talk about it or make suggestions, get in touch with me on [Twitter](http://twitter.com/geoffreywiseman) or send me an [email](mailto:geoffrey.wiseman@codiform.com). If there's enough interest, I'd be happy to set up a group, but for the time being that seems like overkill.
