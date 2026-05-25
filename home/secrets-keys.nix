{ config, pkgs, ... }:

{
  sops.secrets = {
    auth_key_1 = {
      sopsFile = ./secrets.yaml;
    };
    auth_key_2 = {
      sopsFile = ./secrets.yaml;
    };
    auth_key_3 = {
      sopsFile = ./secrets.yaml;
    };
    auth_key_4 = {
      sopsFile = ./secrets.yaml;
    };
  };

  # ── SSH ───────────────────────────────────────────────────────────────────

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    identityFile = "~/.ssh/id_ed25519_gh";
    serverAliveInterval = 60;
    serverAliveCountMax = 3;
  };

  home.file.".ssh/id_ed25519_gh" = {
    source = config.sops.secrets.auth_key_1.path;
    chmod = "0600";
  };

  home.file.".ssh/id_ed25519_gh.pub" = {
    source = config.sops.secrets.auth_key_2.path;
    chmod = "0644";
  };

  # ── GPG ───────────────────────────────────────────────────────────────────

  programs.gpg = {
    enable = true;
    settings = {
      personal-digest-preferences = "SHA256";
      cert-digest-algo = "SHA256";
      default-preference-list = "SHA256 SHA1 MD5";
      keyid-format = "0xlong";
      with-fingerprint = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentryPackage = pkgs.pinentry-qt;
    defaultCacheTtl = 3600;
    maxCacheTtl = 7200;
  };

  # Import GPG key on activation
  home.activation.importGpgKey = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ -r "${config.sops.secrets.auth_key_3.path}" ]; then
      ${pkgs.gnupg}/bin/gpg --import "${config.sops.secrets.auth_key_3.path}" 2>/dev/null || true
    fi
  '';

  # ── Git signing ───────────────────────────────────────────────────────────

  programs.git.extraConfig = {
    user.signingKey = "F869D8453D757219";
    commit.gpgsign = true;
    tag.gpgsign = true;
  };
}
