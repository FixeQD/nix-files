{ lib, config, ... }:
with lib;
let cfg = config.modules.pam; in
{
  options.modules.pam.enable = mkEnableOption "PAM config for quickshell";

  config = mkIf cfg.enable {
    environment.etc."pam.d/quickshell".text = ''
      #%PAM-1.0
      auth       include      system-auth
      account    include      system-auth
      password   include      system-auth
      session    include      system-auth
    '';
  };
}
