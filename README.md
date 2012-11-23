# Tunnels

A simple Ruby script to manage named SSH tunnels because I need these regularly and it's a bit of a pain to manage this in some other way.

At the moment, this will be a command that you invoke, and leave running. At some point, it might make sense to make this two processes -- one that stays alive while there are active tunnels, and a command-line that interacts with that process. For now, that's more work than I intend to bite off -- more of a v2 feature.
