{ config, lib, pkgs, ... }:
let
  user = config.modules.user.name;
in
{
  sops.age.keyFile = "/etc/sops/age/keys.txt";
  sops.defaultSopsFile = ../home/secrets.yaml;

  environment.systemPackages = [ pkgs.sops ];

  sops.secrets = {
    gmail_client_id     = { owner = user; };
    gmail_client_secret = { owner = user; };
    hf_token             = { owner = user; };
    nvidia_nim_api_key   = { owner = user; };

    yggdrasil_private_key        = { owner = user; mode = "0600"; };
    yggdrasil_multicast_password = { owner = user; mode = "0600"; };

    git_user_name  = { owner = user; };
    git_user_email = { owner = user; };

    auth_key_1 = { owner = user; mode = "0600"; };
    auth_key_2 = { owner = user; mode = "0644"; };
    auth_key_3 = { owner = user; };
    auth_key_4 = { owner = user; };

    cloudflared_tunnel_token = { owner = user; mode = "0600"; };
  };
}
