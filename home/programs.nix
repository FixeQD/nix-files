{ config, ... }:
{
  programs.fish = {
    enable    = true;
    functions.fish_greeting = "fastfetch";
    shellInit = ''
      if test -r ${config.sops.secrets.gmail_client_id.path}
        set -gx GMAIL_CLIENT_ID     (cat ${config.sops.secrets.gmail_client_id.path})
        set -gx GMAIL_CLIENT_SECRET (cat ${config.sops.secrets.gmail_client_secret.path})
      end

      if test -r ${config.sops.secrets.hf_token.path}
        set -gx HF_TOKEN (cat ${config.sops.secrets.hf_token.path})
      end
    '';
  };

  programs.git = {
    enable      = true;
    userName    = "Paweł Sobczak";
    userEmail   = "github@fixeq.qzz.io";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase        = false;
    };
  };
}
