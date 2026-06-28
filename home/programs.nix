{ config, ... }:

let
  gitSecretsFile = "${config.home.homeDirectory}/.config/git/secrets";
in
{
  programs.fish = {
    enable    = true;
    functions.fish_greeting = "fastfetch";
    shellInit = ''
      set -gx GPG_TTY (tty)

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
    enable = true;
    includes = [{ path = gitSecretsFile; }];
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase        = false;
    };
  };

  home.activation.gitSecrets = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$(dirname ${gitSecretsFile})"
    if [ -r "${config.sops.secrets.git_user_name.path}" ]; then
      printf '[user]\n\tname = %s\n\temail = %s\n' \
        "$(cat ${config.sops.secrets.git_user_name.path})" \
        "$(cat ${config.sops.secrets.git_user_email.path})" \
        > "${gitSecretsFile}"
      chmod 600 "${gitSecretsFile}"
    fi
  '';
}
