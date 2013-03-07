---
layout: default
---
# Release History

[Release 0.3.0 (2013-Mar-07)](https://github.com/geoffreywiseman/tunnel-boring-machine/issues?milestone=6&state=closed)

This was mostly a stablization and infrastructure release. It included:
- A shorter syntax for adding aliases to a target
- Setting TBM (and badging the README) in Travis, Gemnasium and Code Climate
- Refactoring on the codebase to reduce complexity
- Updating the Net::SSH dependency
- Documenting the Configuration file format

[Release 0.2.0 (2013-Jan-22)](https://github.com/geoffreywiseman/tunnel-boring-machine/issues?milestone=5&state=closed)

The major push in this release was a significant refactoring of the configuration file format based on my experiences in using the first release's configuration file format. It included:

- New configuration file format
- Initial travis setup
- Improved error handling (catching more runtime exceptions)
- Improved the way gateway host tunnels were displayed
- Code structure improvements
- Different ports client/server
- Rake
- Gem packaging
- More comprehensive tests/specs (RSpec)
- Target aliases

[Release 0.1.0 (2012-Nov-23)](https://github.com/geoffreywiseman/tunnel-boring-machine/issues?milestone=4&state=closed)

The first release. The goal here was minimal viability -- getting the app to the point where it was useful to me. It included the basics:

- Read Configuration File
- List Tunnels
- Open Tunnel
- Display Version
- Remote Host (tunnels not to the gateway host itself)

# Roadmap

I'm not committing to scope or time, but if you're curious about the future plans for TBM, the next stage is about figuring out the feasibility of an interactive mode for TBM, either like a mini shell, or a multi-process setup where you run TBM commands that spawn and close processes.

If that's viable, it'll be a lot of work to go from where I am now to there, and that will result in a revolutionary major release. If it's not viable, then there may be a series of smaller evolutionary releases.

