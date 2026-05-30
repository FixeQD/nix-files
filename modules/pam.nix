{ ... }: {
  environment.etc."pam.d/quickshell".text = ''
    #%PAM-1.0
    auth       include      system-auth
    account    include      system-auth
    password   include      system-auth
    session    include      system-auth
  '';
}
