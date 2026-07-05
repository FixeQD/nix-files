{ config, osConfig, ... }:

let
  gitSecretsFile = "${config.home.homeDirectory}/.config/git/secrets";
in
{
  programs.fish = {
    enable    = true;
    functions.fish_greeting = "fastfetch";
    shellInit = ''
      set -gx GPG_TTY (tty)

      if test -r ${osConfig.sops.secrets.gmail_client_id.path}
        set -gx GMAIL_CLIENT_ID     (cat ${osConfig.sops.secrets.gmail_client_id.path})
        set -gx GMAIL_CLIENT_SECRET (cat ${osConfig.sops.secrets.gmail_client_secret.path})
      end

      if test -r ${osConfig.sops.secrets.hf_token.path}
        set -gx HF_TOKEN (cat ${osConfig.sops.secrets.hf_token.path})
      end
    '';
  };

  programs.git = {
    enable = true;
    includes = [{ path = gitSecretsFile; }];
    settings = {
      init.defaultBranch = "main";
      pull.rebase        = false;
    };
  };

  home.activation.gitSecrets = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$(dirname ${gitSecretsFile})"
    if [ -r "${osConfig.sops.secrets.git_user_name.path}" ]; then
      printf '[user]\n\tname = %s\n\temail = %s\n' \
        "$(cat ${osConfig.sops.secrets.git_user_name.path})" \
        "$(cat ${osConfig.sops.secrets.git_user_email.path})" \
        > "${gitSecretsFile}"
      chmod 600 "${gitSecretsFile}"
    fi
  '';
}
