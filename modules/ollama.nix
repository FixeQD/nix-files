{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.ollama;

  ollamaStart = pkgs.writeShellScript "ollama-start" ''
    set -euo pipefail
    export OLLAMA_HOST="${cfg.host}:${toString cfg.port}"
    export OLLAMA_MODELS="${cfg.modelsDir}"
    ${optionalString (cfg.extraEnv != { }) (concatStringsSep "\n"
      (mapAttrsToList (n: v: "export ${n}=${escapeShellArg v}") cfg.extraEnv))}
    mkdir -p "${cfg.modelsDir}"
    exec ${pkgs.ollama}/bin/ollama serve
  '';
in
{
  options.modules.ollama = {
    enable = mkEnableOption "Ollama LLM server (runs as root)";

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address ollama binds to";
    };

    port = mkOption {
      type = types.port;
      default = 11434;
      description = "Port ollama listens on";
    };

    modelsDir = mkOption {
      type = types.str;
      default = "/var/lib/ollama/models";
      description = "Where pulled models are stored";
    };

    extraEnv = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = { OLLAMA_NUM_PARALLEL = "2"; };
      description = "Extra environment variables passed to ollama serve";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.ollama ];

    finit.services.ollama = {
      description = "Ollama LLM server";
      runlevels = "2345";
      conditions = [ "service/syslogd/ready" ];
      command = "${ollamaStart}";
    };
  };
}
