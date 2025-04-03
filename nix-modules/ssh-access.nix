{lib, ...}: {
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      ClientAliveInterval = 60;
    };
  };

  networking.firewall.allowedTCPPorts = [22];

  services.fail2ban.enable = true;

  # SSH config for remote builders need to be in /etc/ssh/ssh_config
  programs.ssh.extraConfig =
    lib.mkAfter
    ''
      Host builder-small-1
      Hostname 127.0.0.1
      Port 2322
      Compression yes
      StrictHostKeyChecking no
      User remote-builder
      IdentityFile /home/hrosten/.ssh/id_microvm_remote_builder

      Host builder-small-2
      Hostname 127.0.0.1
      Port 2422
      Compression yes
      StrictHostKeyChecking no
      User remote-builder
      IdentityFile /home/hrosten/.ssh/id_microvm_remote_builder
    '';
}
