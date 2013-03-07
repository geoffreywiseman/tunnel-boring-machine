---
layout: default
---
# Configuration #

Configuring TBM is done by putting a ".tbm" file in your home directory (e.g. "~/.tbm" on a Unix machine).

## File Format ##

Within that configuration file, the structure is as follows:

    <gateway>:
        <target name(s)>:  <target config>
        <target name(s)>:  <target config>
    <gateway>:
        <target name(s)>:  <target config>
        <target name>(s):  <target config>

The gateway takes one of two forms, either `username@address` or simply `address` where:

-   *address* is the ip address (number or name) of the server to which the ssh connection is to be made
-   *username* is the username to be used to connect to the gateway machine; if you don't specify this, then the username will be the current username on the local machine

The target name is the name you would pass to TBM on the command-line to open the tunnel. TBM doesn't really care about the name, but to make parsing aliases a little easier, I've limited the names to characters, numbers, underscores, dashes, the period and the pound sign. If you feel strongly that I should add something to that charater set, let me know.

If you want aliases to your target name, short-forms for instance, you can specify them here in a parenthesized comma-separated list:

    name (alias, alias, alias): <target config>

The target configuration options are varied, from the simple tunnel configurations through detailed multi-line configurations to multi-server configurations.

### Simple Tunnel Configurations ###
The simplest target configurations simply define the tunnel and take place on the same line as the target name, and are in one the following forms:

*&lt;port&gt;*

If you wish to tunnel a single &lt;port&gt; from the gateway machine to your local machine using the same port number on both machines.

*&lt;local port&gt;:&lt;remote port&gt;*

If the port number on your local machine isn't the same as the port number on the gateway machine.

*&lt;remote host&gt;:&lt;port&gt;*

If the tunnel is to a server beyond the SSH gateway, this lets you forward a port from that specified remote host to your local machine using the same port number.

*&lt;local port&gt;:&lt;remote host&gt;:&lt;remote port&gt;*

Combining the previous two configurations, this lets you tunnel a port on your local machine through the ssh gateway machine to a different port on the specified remote host beyond the ssh gateway.

*\[&lt;tunnel&gt;,&lt;tunnel&gt;\]*

You can put several tunnel configurations together on one line by putting them within a YAML array separated by commas and surrounded by square braces.

### Detailed Multi-Line Configurations ###

If you prefer, you can define your target configuration across multiple lines using a YAML hash, by indending and providing keyed configuration values like:

    <target name>:
        <attribute name>:   <attribute value>
        <attribute name>:   <attribute value>

Where attribute name is one of:

*tunnel*

Indicates that the attribute value will be the same kind of tunnel configurations lised above under simple tunnel configurations.

*alias*

Indicates that the attribute value is an additional target name that can be used on the command-line to select the target to open. This is useful if you find yourself using multiple forms of names, or you'd like a long name and one or more short names.

*&lt;remote host&gt;*

If the attribute name isn't "tunnel" or "alias" it is assumed to be a remote host name follwed by one or more tunnels in the `<port>` or `<local port>:<remote port>` forms.

You can have several tunnel or alias attribute for a single target if you prefer that to using a compound tunnel or alias definition.

You can also have several remote host attribute names followed by the tunnel for each host.


## Examples ##

These examples might help someone who is familiar with SSH tunnels figure out how best to set up equivalent tunnels using the tunnel-boring-machine.

### Forwarding a Port from the SSH Server ###

If you want to forward your development server, `8080`, on a remote server, `ssh.example.com`, to your local machine, you might perform this command:

    ssh ssh.example.com -L 8080:localhost:8080

The equivalent ~/.tbm file would be:

    ssh.example.com:
        development: 8080

### Forwarding a Port on Another Server ### 

If you want to forward a single port, `8080`, on your staging server, `staging.example.com` accessible to the ssh server, `ssh.example.com` to your local machine, you might perform this command:

    ssh ssh.example.com -L 8080:staging.example.com:8080

The equivalent ~/.tbm file would be:

    ssh.example.com:
        staging: staging.example.com:8080

### Forward a Port to a Different Port Number ###

If you want to forward a single port, `80`, on your gateway server, `ssh.example.com` to your local machine on port 8080, you might perform this command:

    ssh ssh.example.com -L 8080:localhost:80

The equivalent ~/.tbm file would be:

    ssh.example.com:
        intra: 8080:80

### Forward a Port to Another Server with a Different Port Number ###

If you want to forward a single port, `80`, on your intranet server, `intranet` accessible to the ssh server, `ssh.example.com` to your local machine on port 8123, you might perform this command:

    ssh ssh.example.com -L 8123:intranet:80

The equivalent ~/.tbm file would be:

    ssh.example.com:
        intra: 8123:intranet:80

### Forward with an Alias ###

If you want to forward a single port, 8080, from your gateway server, `ssh.example.com` and you'd like to be able to refer to it as either 'testing' or 'test', you might configure your `~/.tbm` as follows:

    ssh.example.com:
        testing:
            tunnel: 8080
            alias:  test

### Forward with Multiple Aliases ###

If you want to forward a single port, 8111, from your gateway server, `ssh.example.com` and you'd like to be able to refer to it as any of 'continuous-integration', 'ci', 'teamcity' or 'tc', you might configure your `~/.tbm` as follows:

    ssh.example.com:
        continuous-integration:
            tunnel: 8111
            alias:  [ci,teamcity,tc]

### Forwarding Multiple Ports ###

Perhaps you want to forward several ports on the gateway server to your local machine:

    ssh ssh.example.com -L 8080:localhost:8080 -L 8081:localhost:8081 -L 8082:localhost:80

This could be written in your `~/.tbm` as:

    ssh.example.com:
        stuff: [8080,8081,8082:80]

### Forwarding Multiple Ports on Multiple Servers ###

If you want to forward a bunch of ports to multiple servers all under a single alias, you might write:

    ssh ssh.example.com -L 8080:development:8080 -L 8111:development:8111 -L 8000:development:80 -L 3307:database:3306 -L 8081:localhost:8081

The equivalent ~/.tbm file would be:

    ssh.example.com:
        development:
            alias: dev
            development: [8080,8111,8000:80]
            database: [3306:3307]
            tunnel: 8081
