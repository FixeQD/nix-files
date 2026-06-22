{ config, ... }:
{
  sops = {
    #$   mkdir -p ~/.config/sops/age
    #$   age-keygen -o ~/.config/sops/age/keys.txt
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    defaultSopsFile = ./secrets.yaml;

    secrets = {
      gmail_client_id     = {};
      gmail_client_secret = {};
      hf_token            = {};
      nvidia_nim_api_key  = {};
      yggdrasil_private_key         = {};
      yggdrasil_multicast_password  = {};
      git_user_name       = {};
      git_user_email      = {};
    };
  };
}
