{ config, osConfig, pkgs, ... }:

{
  # ── SSH ───────────────────────────────────────────────────────────────────

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      serverAliveInterval = 60;
      serverAliveCountMax = 3;
      identityFile = "~/.ssh/id_ed25519_gh";
    };
  };

  home.activation.linkSshKeys = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.ssh"
    ln -sf "${osConfig.sops.secrets.auth_key_1.path}" "$HOME/.ssh/id_ed25519_gh"
    ln -sf "${osConfig.sops.secrets.auth_key_2.path}" "$HOME/.ssh/id_ed25519_gh.pub"
  '';

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
    pinentry.package = pkgs.pinentry-qt;
    defaultCacheTtl = 3600;
    maxCacheTtl = 7200;
  };

  # Import GPG keys on activation
  home.activation.importGpgKey = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ -r "${osConfig.sops.secrets.auth_key_3.path}" ]; then
      ${pkgs.gnupg}/bin/gpg --import "${osConfig.sops.secrets.auth_key_3.path}" 2>/dev/null || true
    fi
    if [ -r "${osConfig.sops.secrets.auth_key_4.path}" ]; then
      ${pkgs.gnupg}/bin/gpg --import "${osConfig.sops.secrets.auth_key_4.path}" 2>/dev/null || true
    fi
  '';

  # ── Yggdrasil ─────────────────────────────────────────────────────────────

  home.activation.linkYggdrasilSecrets = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/yggdrasil"
    ln -sf "${osConfig.sops.secrets.yggdrasil_private_key.path}" "$HOME/.config/yggdrasil/yggdrasil.key"
    ln -sf "${osConfig.sops.secrets.yggdrasil_multicast_password.path}" "$HOME/.config/yggdrasil/multicast_password"
  '';

  # ── Git signing ───────────────────────────────────────────────────────────

  programs.git.settings = {
    user.signingKey = "F869D8453D757219";
    commit.gpgsign = true;
    tag.gpgsign = true;
  };
}
