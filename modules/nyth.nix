{ pkgs, lib, config, nyth, ... }:
with lib;
let
  cfg = config.modules.nyth;
  user = config.modules.user.name;
  nythPkg = nyth.packages.${pkgs.stdenv.hostPlatform.system}.default;
  mountArgsFile = "${config.users.users.${user}.home}/.local/state/nyth/mount-args";
in
{
  options.modules.nyth.enable = mkEnableOption "nyth write-through OverlayFS over ${config.modules.user.name}'s $HOME";

  config = mkIf cfg.enable {
    environment.systemPackages = [ nythPkg ];
    finit.tasks."nyth-mount-${user}" = {
      description = "nyth write-through overlay for ${user}";
      runlevels = "2345";
      conditions = [ "task/hm-activate-${user}/success" ];
      command = pkgs.writeShellScript "nyth-mount-${user}" ''
        set -eu
        exec ${nythPkg}/bin/nyth mount --for-user ${user} $(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg mountArgsFile})
      '';
    };

    finit.services.sddm.conditions = [ "task/nyth-mount-${user}/success" ];
  };
}
