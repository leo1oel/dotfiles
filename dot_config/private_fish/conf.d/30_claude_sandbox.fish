# Claude Code refuses --dangerously-skip-permissions / bypass-permissions mode when
# running as root/sudo, unless IS_SANDBOX=1 asserts the environment is a throwaway
# sandbox. The nemo/firstmate flow runs claude as root inside disposable containers -
# both the captain agent and every crewmate herdr spawns - so set it when we are root.
# A herdr server started from such a shell inherits this, so its agent panes (captain
# and crewmates alike) get it too.
#
# Gated on uid 0: a normal non-root machine (e.g. the laptop) never sets it and keeps
# claude's usual root-safety refusal. This assumes root here only ever means a
# disposable sandbox container; do not run root claude on a real host without
# revisiting this.
if test (id -u) -eq 0
    set -gx IS_SANDBOX 1
end
