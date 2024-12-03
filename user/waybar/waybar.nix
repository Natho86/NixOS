{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        margin-left = 10;
        margin-right = 10;
        margin-top = 10;
        spacing = 1;

        modules-left = ["custom/power" "hyprland/workspaces"];
        modules-center = ["clock"];
        modules-right = ["cpu" "temperature" "memory" "disk" "battery" "pulseaudio" "network" "tray"];

        "hyprland/workspaces" = {
          on-click = "activate";
          persistent-workspaces = {
            "*" = 5;
          };
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
          };
        };

        tray = {
          icon-size = 18;
          spacing = 5;
          show-passive-items = true;
        };

        clock = {
          interval = 60;
          format = "  {:%a %d %b  %I:%M %p}";  # %b %d %Y  --Date formatting
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };

        battery = {
          interval = 60;
          full-at = 100;
          states = {
            good = 90;
            warning = 25;
            critical = 15;
          };
          format-full = "  {capacity}%";
          format-good = "  {capacity}%";
          format-warning = "  {capacity}%";
          format-critical = "  {capacity}%";
          format-charging = "󰂉 {capacity}%";
        };

        temperature = {
          critical-threshold = 80;
          interval = 2;
          format = " {temperatureC}°C";
          format-icons = ["" "" ""];
        };

        cpu = {
          interval = 2;
          format = "  {usage}%";
          tooltip = false;
        };

        memory = {
          interval = 2;
          format = "  {}%";
        };

        disk = {
          interval = 15;
          format = "󰋊 {percentage_used}%";
        };

        network = {
          format-wifi = "  {ipaddr}";
          format-ethernet = "  {ipaddr}/{cidr}";
          tooltip-format-wifi = "{essid} ({signalStrength}%) ";
          tooltip-format = "{ifname} via {gwaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "󰌙  Disconnected ⚠";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
        };

        pulseaudio = {
          format = " {icon} {volume}%";
          format-bluetooth = "{icon} {volume}% 󰂯";
          format-bluetooth-muted = "󰖁 {icon} 󰂯";
          format-muted = "󰖁 {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
            headphone = "󰋋";
            hands-free = "󱡒";
            headset = "󰋎";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
        };

        "custom/power" = {
          format = "{icon}";
          format-icons = "⏻";
          exec-on-event = true;
          on-click = "~/.dotfiles/user/rofi/powermenu/powermenu.sh";
        };

        "custom/sepp" = {
          format = "|";
        };
      };
    };
    style = ''
      /*
      * Catppuccin Mocha palette
      * Maintainer: rubyowo
      */

      @define-color base   #1e1e2e;
      @define-color mantle #181825;
      @define-color crust  #11111b;

      @define-color text     #cdd6f4;
      @define-color subtext0 #a6adc8;
      @define-color subtext1 #bac2de;

      @define-color surface0 #313244;
      @define-color surface1 #45475a;
      @define-color surface2 #585b70;

      @define-color overlay0 #6c7086;
      @define-color overlay1 #7f849c;
      @define-color overlay2 #9399b2;

      @define-color blue      #89b4fa;
      @define-color lavender  #b4befe;
      @define-color sapphire  #74c7ec;
      @define-color sky       #89dceb;
      @define-color teal      #94e2d5;
      @define-color green     #a6e3a1;
      @define-color yellow    #f9e2af;
      @define-color peach     #fab387;
      @define-color maroon    #eba0ac;
      @define-color red       #f38ba8;
      @define-color mauve     #cba6f7;
      @define-color pink      #f5c2e7;
      @define-color flamingo  #f2cdcd;
      @define-color rosewater #f5e0dc;

      * {
        min-height: 0;
        font-family: "JetBrainsMono Nerd Font", "Hack Nerd Font", FontAwesome, Roboto,
        Helvetica, Arial, sans-serif;
        font-size: 14px;
      }

      window#waybar {
        color: @text;
        background: @base00;
        transition-property: background-color;
        transition-duration: 0.5s;
      }

      window#waybar.empty {
        opacity: 0.3;
      }

      .modules-left {
        border: none;
      }

      .modules-right {
        border: none;
      }

      .modules-center {
        border: none;
      }

      button {
        border: none;
        border-radius: 0;
      }

      button:hover {
        background: @base;
        border-radius: 90px;
      }

      #custom-power {
        color: @blue;
        font-weight: 600;
        margin-right: 10px;
        padding-left: 15px;
        padding-right: 19px;
        border-radius: 90px;
        background: @crust;
      }

      #workspaces {
        font-weight: 600;
        margin-right: 10px;
        padding: 5px 10px;
        border-radius: 90px;
        background: @crust;
      }

      #workspaces button {
        color: @text;
        font-weight: 600;
        margin: 0px;
        padding: 0px 5px;
      }

      #workspaces button.urgent {
        color: @red;
      }

      #workspaces button.empty {
        color: @surface2;
      }

      #workspaces button.active {
        color: @blue;
      }

      #workspaces button.focused {
        color: @green;
      }

      #cpu,
      #temperature,
      #memory,
      #battery,
      #disk {
        color: @blue;
        font-weight: 600;
        margin-right: 10px;
        padding: 6px 15px;
        border-radius: 90px;
        background: @crust;
      }

      #pulseaudio {
        color: @crust;
        font-weight: 600;
        margin-right: 10px;
        padding: 6px 15px;
        border-radius: 90px;
        background: @blue;
      }

      #network {
        color: @crust;
        font-weight: 600;
        margin-right: 10px;
        padding: 6px 15px;
        border-radius: 90px;
        background: @green;
      }

      #tray {
        color: @text;
        font-weight: 600;
        padding: 6px 15px;
        border-radius: 90px;
        background: @crust;
      }

      #clock {
        color: @blue;
        font-weight: 600;
        margin-right: 10px;
        padding: 6px 15px;
        border-radius: 90px;
        background: @crust;
      }

      #custom-sepp {
        color: @surface2;
        font-size: 20px;
        padding-left: 4px;
        padding-right: 10px;
      }

      #network.disconnected {
        background-color: @red;
      }
    '';
  };
}
