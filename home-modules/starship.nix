{
  programs.starship = {
    # To debug issues with starship, try: starship explain
    enable = true;
    settings = {
      add_newline = true;
      battery.disabled = true;
      git_metrics.disabled = false;
      directory.repo_root_style = "bold underline italic blue";
      # Disable the follwing modules in $HOME folder, or
      # any folder that happens to have .config subfolder:
      python = {
        detect_folders = ["!.config"];
      };
      nodejs = {
        detect_folders = ["!.config"];
      };
      # Somehow starship thinks some CLI are google could, when
      # that's not the case, let's just disable gcloud module:
      gcloud = {
        disabled = true;
      };
    };
  };
}
