# Milestone 3: night light. Config format and profile behaviour verified
# against upstream hyprsunset wiki doc (content/hypr-ecosystem/user/hyprsunset.md).
{ config, pkgs, ... }:

{
  services.hyprsunset = {
    enable = true;
    settings = {
      profile = [
        {
          time = "7:30";
          identity = true; # daytime: no filter
        }
        {
          time = "21:00";
          temperature = 4500;
        }
      ];
    };
  };
}
