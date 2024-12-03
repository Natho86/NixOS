{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd = "hyprlock";
      };

      listener = [
        {
          timeout = 60; 
          on-timeout = "brightnessctl -s; brightnessctl s 10%";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 300;  # 5 minutes
          on-timeout = "brightnessctl -s; brightnessctl s 10%";   # set brightness to 10%
          #on-timeout = "hyprlock";   # set brightness to 10%
          on-resume = "brightnessctl -r";       # restore brightness
        }
        {
          timeout = 600;    # 10 mins
          on-timeout = "hyprlock";
        }
        {
          timeout = 900;
          on-timeout = "hyprctl dispatch dpms off"; # screen off
          on-resume = "hyprctl dispatch dpms on";   # screen on
        }
      ];
    };
  };
}
