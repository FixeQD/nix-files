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

  home.file.".ssh/id_ed25519_gh" = {
    source = osConfig.sops.secrets.auth_key_1.path;
  };

  home.file.".ssh/id_ed25519_gh.pub" = {
    source = osConfig.sops.secrets.auth_key_2.path;
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

  home.file.".config/yggdrasil/yggdrasil.key" = {
    source = osConfig.sops.secrets.yggdrasil_private_key.path;
  };

  home.file.".config/yggdrasil/multicast_password" = {
    source = osConfig.sops.secrets.yggdrasil_multicast_password.path;
  };

  # ── Git signing ───────────────────────────────────────────────────────────

  programs.git.settings = {
    user.signingKey = "F869D8453D757219";
    commit.gpgsign = true;
    tag.gpgsign = true;
  };
}
