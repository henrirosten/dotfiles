{pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;
  home = {
    packages = with pkgs; [
      chromium
      firefox
      google-chrome
      libreoffice
      wireshark
    ];
  };
}
