# Omarchy-inspired Hyprland desktop. See omarchy-inspired-nixos-plan.md.
#
# Milestone 8: turned into a real opt-in profile (desktop.omarchy.enable)
# rather than a module that's simply present-or-absent from a host's
# `modules` list. Motivation: the user wants to eventually install this
# on a VM on another machine, so "add one line to a new host's config"
# needs to be a real, working path, not something that only happens to
# work today because only one host imports this directory. This file is
# still unconditionally imported by every host (see flake.nix), but
# everything it does is gated by the option -- importing it is now always
# safe and inert by default, matching the plan's own §4 illustrative
# `desktop.omarchy.enable` interface, deferred until now because it was
# a bigger change than Milestone 1 called for.
{ config, lib, ... }:

{
  options.desktop.omarchy.enable = lib.mkEnableOption "the Omarchy-inspired Hyprland desktop";

  imports = [ ./system.nix ];
}
