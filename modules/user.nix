{ pkgs, ... }:
{
  users.users.fixeq = {
    isNormalUser = true;
    description  = "fixeq";
    shell        = pkgs.fish;
    extraGroups  = [
      "wheel"
      "seat"
      "storage"
      "power"
      "audio"
      "video"
      "optical"
      "network"
      "input"
      "docker"
      "libvirtd"
      "kvm"
      "adbusers"
    ];
  };

  security.sudo = {
    enable             = true;
    wheelNeedsPassword = true;
    extraConfig        = "Defaults timestamp_timeout=15";
  };

  programs.adb.enable = true;
}
