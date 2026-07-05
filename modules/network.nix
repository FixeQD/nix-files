{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.network; in
{
  options.modules.network.enable = mkEnableOption "iwd and dhcpcd networking";

  config = mkIf cfg.enable {
    services.iwd.enable = true;

    services.dhcpcd.enable = true;
    services.dhcpcd.settings = {
      static = "domain_name_servers=1.1.1.2 1.0.0.2";
    };

    environment.systemPackages = with pkgs; [
      iwd
      dhcpcd
    ];
  };
}
