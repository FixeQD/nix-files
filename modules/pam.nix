{ ... }: {
  environment.etc."pam.d/quickshell".text = ''
    #%PAM-1.0
    auth required pam_unix.so
  '';
}
