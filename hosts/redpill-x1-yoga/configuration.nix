# Host-specific configuration for redpill-x1-yoga
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Import hardware configuration
  imports = [ ./hardware-configuration.nix ];

  # Hostname
  networking.hostName = "redpill-x1-yoga";

  # Keep all three desktop sessions available from ReGreet while trying GNOME.
  # GNOME follows nixpkgs-unstable because this flake tracks that channel.
  services.desktopManager.gnome.enable = true;
  services.desktopManager.plasma6.enable = true;

  # ReGreet provides the session chooser for GNOME, Plasma, and Hyprland.
  # Use GNOME's dark Adwaita styling so the chooser feels at home with the
  # desktop being tested, with a little extra spacing and softer controls.
  services.displayManager.regreet = {
    theme.name = "Adwaita-dark";
    iconTheme.name = "Adwaita";
    extraCss = ''
      window {
        background: linear-gradient(135deg, #171a21 0%, #242938 100%);
      }

      # Keep the login card readable without making the background feel heavy.
      box#login {
        background: alpha(#111318, 0.82);
        border: 1px solid alpha(#ffffff, 0.10);
        border-radius: 18px;
        padding: 28px;
      }

      button, entry, dropdown {
        border-radius: 10px;
      }

      button.suggested-action {
        min-height: 42px;
      }
    '';
  };

  # Keep WireGuard available but disabled by default; toggle to true when needed.
  my.wireguard.enable = lib.mkDefault false;

  # sops-nix age key location for this host. Overrides shared/configuration.nix's
  # default of /home/nath/.config/sops/age/keys.txt: sops-nix's activation script
  # (system.activationScripts.setupSecrets) runs during early boot, before /home
  # is mounted, so a key under /home can never be read there and secrets silently
  # fail to render (see: /run/secrets/rendered/* never created, breaking the
  # Documents CIFS mount). /etc is on the root filesystem and available at that
  # point in boot.
  #
  # ACTION REQUIRED before rebuilding: copy the existing key to the new path,
  # e.g. `sudo install -D -m 0400 /home/nath/.config/sops/age/keys.txt /etc/sops/age/keys.txt`
  sops.age.keyFile = lib.mkForce "/etc/sops/age/keys.txt";

  # LUKS encryption setup for this machine
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/1fe239ed-81f2-4c97-80cc-30c24ffe8e2f"; # Laptop LUKS UUID
    allowDiscards = true; # Improves SSD performance
  };

  # ReGreet is configured above and appears after disk unlock and whenever a
  # desktop session exits, so all installed sessions remain selectable.

  # Power management for laptop (TLP)
  services.power-profiles-daemon.enable = false; # Conflicts with TLP
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };
  # Passwordless sudo for nixos-rebuild only (not blanket sudo). Scoped to
  # the stable /run/current-system/sw/bin symlink, not a content-addressed
  # /nix/store path, so it keeps working across rebuilds. Anything run as
  # user nath can now switch/rollback the system without a password prompt
  # to notice or stop it -- accepted trade-off for rebuild convenience on
  # this personal laptop.
  security.sudo.extraRules = [
    {
      users = [ "nath" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # SSH server configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true; # Set to false after setting up SSH keys
      X11Forwarding = false;
    };
  };

}
