extends Node
## Global signal hub. Systems talk to each other through these signals instead
## of holding references to each other. Add a signal here when a system needs one.

# The signals are emitted by other scripts, so they are never "used" in here.
@warning_ignore_start("unused_signal")

## Emitted by Settings after a setting changed and was written to disk.
signal settings_changed
