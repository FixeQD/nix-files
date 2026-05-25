{ pkgs, ... }:
{
  finit.services.pipewire = {
    description = "PipeWire multimedia daemon";
    runlevels = "2345";
    conditions = [ "service/seatd/ready" ];
    command = "${pkgs.pipewire}/bin/pipewire";
    notify = "systemd";
  };

  finit.services.wireplumber = {
    description = "WirePlumber session manager";
    runlevels = "2345";
    conditions = [ "service/pipewire/ready" ];
    command = "${pkgs.wireplumber}/bin/wireplumber";
    notify = "systemd";
  };

  finit.services.pipewire-pulse = {
    description = "PipeWire PulseAudio replacement";
    runlevels = "2345";
    conditions = [ "service/pipewire/ready" ];
    command = "${pkgs.pipewire}/bin/pipewire-pulse";
  };

  environment.systemPackages = with pkgs; [
    pipewire
    wireplumber
  ];

  hardware.alsa.enable = true;
}
